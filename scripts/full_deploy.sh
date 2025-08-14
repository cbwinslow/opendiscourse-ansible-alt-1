#!/usr/bin/env bash
set -euo pipefail

echo "[full-deploy] Starting full deployment pipeline"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

SSH_KEY_NAME=${SSH_KEY_NAME:-opendiscourse}
SERVER_COUNT=${SERVER_COUNT:-1}
NETWORK_NAME=${NETWORK_NAME:-opendiscourse.net}
HCLOUD_TOKEN=${HCLOUD_TOKEN:-${HCLOUD_TOKEN:-}}
AUTO_GENERATE_SECRETS=${AUTO_GENERATE_SECRETS:-true}

if [[ -z "${HCLOUD_TOKEN}" ]]; then
  if command -v bw >/dev/null 2>&1 && [[ -n "${BW_SESSION:-}" ]]; then
    echo "[full-deploy] Attempt Bitwarden export (core)"
    # shellcheck disable=SC1091
    source scripts/bw_export_env.sh core || true
    HCLOUD_TOKEN=${HCLOUD_TOKEN:-}
  fi
fi

if [[ -z "${HCLOUD_TOKEN}" ]]; then
  echo "[full-deploy][WARN] HCLOUD_TOKEN not set; aborting provisioning." >&2
  exit 2
fi

echo "[full-deploy] Ensure python hcloud SDK installed"
python3 - <<'PY'
import importlib, subprocess, sys
pkg='hcloud'
try:
    import importlib; importlib.import_module(pkg)
except ImportError:
    print('[full-deploy] Installing python package: hcloud')
    subprocess.check_call([sys.executable,'-m','pip','install','--user','hcloud'])
PY

echo "[full-deploy] Checking / uploading SSH key '$SSH_KEY_NAME'"
if command -v hcloud >/dev/null 2>&1; then
  KEY_JSON=$(hcloud ssh-key list -o json || echo '[]')
  if [[ "$KEY_JSON" == "[]" ]] || ! echo "$KEY_JSON" | grep -q '"name":"'$SSH_KEY_NAME'"'; then
    PUBKEY_PATH="${HOME}/.ssh/id_ed25519.pub"
    [[ -f "$PUBKEY_PATH" ]] || PUBKEY_PATH="${HOME}/.ssh/id_rsa.pub"
    if [[ ! -f "$PUBKEY_PATH" ]]; then
      echo "[full-deploy] No local pub key found, generating ed25519 key";
      ssh-keygen -t ed25519 -N '' -f "$HOME/.ssh/id_ed25519" -C 'deploy@opendiscourse' >/dev/null
      PUBKEY_PATH="${HOME}/.ssh/id_ed25519.pub"
    fi
    echo "[full-deploy] Uploading SSH key as '$SSH_KEY_NAME'"
    hcloud ssh-key create --name "$SSH_KEY_NAME" --public-key "$(cat "$PUBKEY_PATH")" >/dev/null || echo "[full-deploy][WARN] SSH key upload may have failed; continuing"
  else
    echo "[full-deploy] SSH key already present"
  fi
else
  echo "[full-deploy][WARN] hcloud CLI not installed; skipping SSH key presence check"
fi

echo "[full-deploy] Running provisioning (module path)"
if ! ansible-playbook ansible/playbooks/provision_hetzner.yml \
  -e hcloud_api_token="$HCLOUD_TOKEN" \
  -e server_count="$SERVER_COUNT" \
  -e ssh_key_name="$SSH_KEY_NAME" \
  -e network_name="$NETWORK_NAME" ; then
  echo "[full-deploy][WARN] Module-based provisioning failed; attempting CLI fallback"
  ansible-playbook ansible/playbooks/provision_hetzner_cli.yml \
    -e server_count="$SERVER_COUNT" \
    -e ssh_key_name="$SSH_KEY_NAME" \
    -e network_name="$NETWORK_NAME" || { echo "[full-deploy][ERROR] CLI provisioning failed"; exit 3; }
fi

INV_FILE="ansible/inventory/generated/hetzner.yml"
cli_provision() {
  echo "[full-deploy][CLI] Starting CLI-based provisioning"
  mkdir -p "$(dirname "$INV_FILE")"
  # Network ensure
  if [[ -n "$NETWORK_NAME" ]]; then
    if ! hcloud network list -o json | python3 -c "import sys,json;print(any(n['name']=='$NETWORK_NAME' for n in json.load(sys.stdin)))" | grep -q True; then
      echo "[full-deploy][CLI] Creating network $NETWORK_NAME"
      hcloud network create --name "$NETWORK_NAME" --ip-range 10.20.0.0/16 || true
    else
      echo "[full-deploy][CLI] Network $NETWORK_NAME exists"
    fi
  fi
  # Servers loop
  for i in $(seq 1 "$SERVER_COUNT"); do
    NAME="${server_name_prefix:-ai-srv}-$i"; NAME="${SSH_SERVER_PREFIX:-${SSH_KEY_NAME}}-${i}" # fallback naming adjust if needed
    NAME="${SERVER_NAME_PREFIX:-${SSH_KEY_NAME:-opendiscourse}}-$i"
    # Prefer configured prefix
    if [[ -n "${server_name_prefix:-}" ]]; then NAME="${server_name_prefix}-$i"; fi
    if hcloud server list -o json | grep -q '"name":"'"$NAME"'"'; then
      echo "[full-deploy][CLI] Server $NAME already exists"
    else
      echo "[full-deploy][CLI] Creating server $NAME"
      CREATE_ARGS=(--name "$NAME" --type "$SERVER_TYPE" --image "$SERVER_IMAGE" --location "$SERVER_LOCATION" --ssh-key "$SSH_KEY_NAME")
      [[ -n "$NETWORK_NAME" ]] && CREATE_ARGS+=(--network "$NETWORK_NAME")
      hcloud server create "${CREATE_ARGS[@]}" -o json >/tmp/hcloud_create_$NAME.json || { echo "[full-deploy][CLI][WARN] Create command may have failed for $NAME"; }
    fi
  done
  # Gather final server list
  SERVERS_JSON=$(hcloud server list -o json)
  export SERVERS_JSON SERVER_PREFIX="${server_name_prefix:-${SERVER_NAME_PREFIX:-${SSH_KEY_NAME:-opendiscourse}}}"
  { 
    echo "---"; echo "all:"; echo "  children:"; echo "    ai:"; echo "      hosts:"; 
    python3 - <<'PY'
import os,json
servers=json.loads(os.environ['SERVERS_JSON'])
prefix=os.environ.get('SERVER_PREFIX','ai-srv') + '-'  # include dash
for s in servers:
    if s['name'].startswith(prefix):
        ip=s['public_net']['ipv4']['ip']
        name=s['name']
        print(f"        {name}:\n          ansible_host: {ip}\n          ansible_user: root\n          ansible_python_interpreter: /usr/bin/python3")
PY
  } > "$INV_FILE"
  echo "[full-deploy][CLI] Inventory written $INV_FILE"
}

# Capture configurable server vars (with defaults) for CLI path
: "${server_name_prefix:=ai-srv}"
: "${SERVER_TYPE:=cpx31}"
: "${SERVER_LOCATION:=fsn1}"
: "${SERVER_IMAGE:=ubuntu-24.04}"

if [[ ! -f "$INV_FILE" ]]; then
  echo "[full-deploy] Inventory file not created by Ansible provisioning path"
  if command -v hcloud >/dev/null 2>&1 && [[ "${FORCE_CLI:-0}" == 1 || "${ALLOW_CLI_FALLBACK:-1}" == 1 ]]; then
    cli_provision
  else
    echo "[full-deploy][ERROR] Cannot proceed: inventory missing and CLI fallback disabled" >&2
    exit 4
  fi
fi

echo "[full-deploy] Inventory ready: $INV_FILE"

if [[ "$AUTO_GENERATE_SECRETS" == "true" ]]; then
  if [[ -f scripts/generate_and_update_secrets.sh ]]; then
    echo "[full-deploy] Generating / updating vaulted secrets"
    bash scripts/generate_and_update_secrets.sh || echo "[full-deploy][WARN] Secret generation had issues"
  fi
fi

echo "[full-deploy] Applying main site playbook (initial tags: docker,security)"
ansible-playbook -i "$INV_FILE" ansible/site.yml --tags docker,security || true

echo "[full-deploy] Applying remaining roles (no tag limit)"
ansible-playbook -i "$INV_FILE" ansible/site.yml || true

echo "[full-deploy] Complete"

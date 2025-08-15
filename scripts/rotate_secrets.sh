#!/usr/bin/env bash
set -euo pipefail

# rotate_secrets.sh - Generate or rotate vault-managed secrets (letters only)
# Usage: ./scripts/rotate_secrets.sh [--rotate]
# Requires: ansible-vault in PATH and existing vault file decryptable if present.

ROTATE=false
if [[ "${1:-}" == "--rotate" ]]; then
  ROTATE=true
  echo "[INFO] Rotation mode enabled: existing values will be replaced." >&2
fi

VAULT_FILE="ansible/group_vars/all/vault.yml"
TEMP_VIEW="$(mktemp)"
MERGED_PLAIN="$(mktemp)"

REQUIRED_CMDS=(ansible-vault tr head)
for c in "${REQUIRED_CMDS[@]}"; do
  command -v "$c" >/dev/null || { echo "[ERROR] Missing command: $c" >&2; exit 1; }
done

gen_letters() { tr -dc 'A-Za-z' </dev/urandom | head -c 32; }

# Declare secret keys map (vault variable names)
SECRET_KEYS=(
  vault_postgres_admin_password
  vault_neo4j_auth_password
  vault_minio_root_password
  vault_clickhouse_password
  vault_n8n_encryption_key
  vault_n8n_jwt_secret
  vault_global_jwt_secret
  vault_nextauth_secret
  vault_encryption_key
  vault_langfuse_salt
  vault_dashboard_password
)

if [[ -f "$VAULT_FILE" ]]; then
  echo "[INFO] Existing vault detected. Attempting to view..." >&2
  if ! ansible-vault view "$VAULT_FILE" > "$TEMP_VIEW" 2>/dev/null; then
    echo "[ERROR] Could not decrypt existing vault file. Aborting." >&2
    exit 1
  fi
else
  echo "[INFO] No existing vault file. A new one will be created." >&2
  : > "$TEMP_VIEW"
fi

{
  echo "# GENERATED $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  for key in "${SECRET_KEYS[@]}"; do
    # If key exists and not rotating, preserve
    if grep -qE "^${key}:" "$TEMP_VIEW" && [[ $ROTATE == false ]]; then
      echo "[KEEP] $key" >&2
      grep -E "^${key}:" "$TEMP_VIEW" | head -n1
    else
      newval=$(gen_letters)
      echo "[SET] $key" >&2
      echo "${key}: \"${newval}\""
    fi
  done
} > "$MERGED_PLAIN"

echo "[INFO] Plain merged secrets written to $MERGED_PLAIN" >&2

echo -e "[ACTION] Encrypt & replace with:\n  ansible-vault encrypt $MERGED_PLAIN && mv $MERGED_PLAIN $VAULT_FILE" >&2

echo "[SECURITY] Remove any temporary files if you abort: $TEMP_VIEW $MERGED_PLAIN" >&2

#!/usr/bin/env bash
# Seed Bitwarden with required secret items (idempotent).
# Requires: bw (Bitwarden CLI), jq
# Usage:
#   BW_SESSION=$(bw unlock --raw) ./scripts/bw_seed_items.sh
#   (or) bw login --raw > ~/.cache/bw_session && export BW_SESSION=$(cat ~/.cache/bw_session) && ./scripts/bw_seed_items.sh

set -euo pipefail

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1" >&2; exit 1; }; }
need bw
need jq

if [[ -z "${BW_SESSION:-}" ]]; then
  echo "BW_SESSION not set. Run: export BW_SESSION=$(bw unlock --raw)" >&2
  exit 1
fi

bw sync >/dev/null

# Manifest: category|item_name|type|field_name:source_kind:source_value
# type: login, note, api (we'll map to Bitwarden types: 1=login, 2=note)
# source_kind: literal, generate_hex, generate_pass
MANIFEST=$(cat <<'EOF'
core|hetzner-api-token|note|token:literal:REPLACE_ME
core|postgres-password|note|password:generate_pass:
core|neo4j-password|note|password:generate_pass:
core|rabbitmq-password|note|password:generate_pass:
core|redis-password|note|password:generate_pass:
core|ansible-vault-password|note|vault_password:generate_pass:
ai|openai-api-key|note|api_key:literal:REPLACE_ME
ai|anthropic-api-key|note|api_key:literal:REPLACE_ME
ai|huggingface-token|note|token:literal:REPLACE_ME
ai|weaviate-admin-key|note|api_key:generate_hex:
monitoring|grafana-admin-password|note|password:generate_pass:
monitoring|loki-write-token|note|token:generate_hex:
security|jwt-secret|note|secret:generate_hex:
security|encryption-key|note|key:generate_hex:
external|cloudflare-api-token|note|token:literal:REPLACE_ME
external|aws-access-key|note|access_key:literal:REPLACE_ME
external|aws-secret-key|note|secret_key:literal:REPLACE_ME
EOF
)

rand_pass() { LC_ALL=C tr -dc 'A-Za-z0-9!@#$%^&*()_+-=' </dev/urandom | head -c 32; }
rand_hex() { openssl rand -hex 32; }

create_or_update() {
  local item_name="$1" field_name="$2" value="$3"
  local existing
  if existing=$(bw get item "$item_name" 2>/dev/null); then
    # Update or add field
    local updated
    if echo "$existing" | jq -e --arg f "$field_name" '.fields[]? | select(.name==$f)' >/dev/null; then
      updated=$(echo "$existing" | jq --arg f "$field_name" --arg v "$value" '(.fields[] | select(.name==$f) | .value) |= $v')
    else
      updated=$(echo "$existing" | jq --arg f "$field_name" --arg v "$value" '.fields += [{"name":$f,"value":$v,"type":0}]')
    fi
    printf '%s' "$updated" | bw encode | bw edit item "$(echo "$existing" | jq -r '.id')" >/dev/null
    echo "UPDATED $item_name:$field_name"
  else
    # Create new note item
    local template='{"type":2,"name":"ITEM_NAME","notes":"Managed seed item","fields":[{"name":"FIELD_NAME","value":"FIELD_VALUE","type":0}]}'
    local json=${template/ITEM_NAME/$item_name}
    json=${json/FIELD_NAME/$field_name}
    json=${json/FIELD_VALUE/$value}
    printf '%s' "$json" | bw encode | bw create item >/dev/null
    echo "CREATED $item_name:$field_name"
  fi
}

while IFS='|' read -r category item type field_spec; do
  [[ -z "$category" ]] && continue
  IFS=':' read -r field_name source_kind source_value <<<"$field_spec"
  case "$source_kind" in
    generate_pass) val=$(rand_pass) ;;
    generate_hex) val=$(rand_hex) ;;
    literal) val="$source_value" ;;
    *) echo "Unknown source_kind $source_kind" >&2; exit 1 ;;
  esac
  create_or_update "$item" "$field_name" "$val"

done < <(printf '%s\n' "$MANIFEST")

echo "Seed operation complete. Review items with placeholders (REPLACE_ME) and update manually." >&2

#!/usr/bin/env bash
# Bitwarden environment export helper
# Usage:
#   source scripts/bw_export_env.sh core
#   source scripts/bw_export_env.sh all
# Flags:
#   --dotenv   Write .env file instead of exporting (appends)
#   --print    Print KEY=VAL lines to stdout
#   --help     Show help

set -euo pipefail

CATEGORY="${1:-core}"
MODE_EXPORT=true
MODE_PRINT=false
DOTENV=false

for arg in "$@"; do
  case "$arg" in
    --dotenv) DOTENV=true ; MODE_EXPORT=false ; shift ;;
    --print) MODE_PRINT=true ; shift ;;
    --help)
      cat <<EOF
Bitwarden Export Helper
Examples:
  BW_SESSION=$(bw unlock --raw) source scripts/bw_export_env.sh core
  BW_SESSION=$(bw unlock --raw) scripts/bw_export_env.sh all --print
  BW_SESSION=$(bw unlock --raw) scripts/bw_export_env.sh all --dotenv
EOF
      exit 0 ;;
  esac
done

need() {
  command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1" >&2; exit 1; }
}

need bw
need jq

if [[ -z "${BW_SESSION:-}" ]]; then
  echo "BW_SESSION not set. Attempting unlock..." >&2
  BW_SESSION=$(bw unlock --raw) || { echo "Failed to unlock Bitwarden" >&2; exit 1; }
  export BW_SESSION
fi

bw sync >/dev/null || { echo "bw sync failed" >&2; exit 1; }

# Map: ENV_VAR:item_name:field_name
MAP_CORE=(
  "HCLOUD_TOKEN:hetzner-api-token:token"
  "POSTGRES_PASSWORD:postgres-password:password"
  "NEO4J_PASSWORD:neo4j-password:password"
  "RABBITMQ_PASSWORD:rabbitmq-password:password"
  "REDIS_PASSWORD:redis-password:password"
)

MAP_AI=(
  "OPENAI_API_KEY:openai-api-key:api_key"
  "ANTHROPIC_API_KEY:anthropic-api-key:api_key"
  "HUGGINGFACE_TOKEN:huggingface-token:token"
  "WEAVIATE_ADMIN_KEY:weaviate-admin-key:api_key"
)

MAP_MONITORING=(
  "GRAFANA_ADMIN_PASSWORD:grafana-admin-password:password"
  "LOKI_WRITE_TOKEN:loki-write-token:token"
)

MAP_SECURITY=(
  "JWT_SECRET:jwt-secret:secret"
  "ENCRYPTION_KEY:encryption-key:key"
)

MAP_EXTERNAL=(
  "CLOUDFLARE_API_TOKEN:cloudflare-api-token:token"
  "AWS_ACCESS_KEY_ID:aws-access-key:access_key"
  "AWS_SECRET_ACCESS_KEY:aws-secret-key:secret_key"
)

collect_maps() {
  local set=("${MAP_CORE[@]}")
  case "$CATEGORY" in
    ai) set+=("${MAP_AI[@]}") ;;
    monitoring) set+=("${MAP_MONITORING[@]}") ;;
    security) set+=("${MAP_SECURITY[@]}") ;;
    external) set+=("${MAP_EXTERNAL[@]}") ;;
    all) set+=("${MAP_AI[@]}" "${MAP_MONITORING[@]}" "${MAP_SECURITY[@]}" "${MAP_EXTERNAL[@]}") ;;
    core) : ;;
    *) echo "Unknown category: $CATEGORY" >&2; exit 1 ;;
  esac
  printf '%s\n' "${set[@]}"
}

fetch_field() {
  local item="$1" field="$2"
  local json
  if ! json=$(bw get item "$item" 2>/dev/null); then
    echo "WARN: item $item not found" >&2
    return 1
  fi
  echo "$json" | jq -r --arg f "$field" '.fields[]? | select(.name==$f) | .value' || true
}

OUTPUT_LINES=()
while IFS= read -r line; do
  IFS=":" read -r env item field <<<"$line"
  value=$(fetch_field "$item" "$field") || true
  if [[ -z "$value" || "$value" == "null" ]]; then
    echo "WARN: missing field $field in $item" >&2
    continue
  fi
  OUTPUT_LINES+=("$env=$value")
  if $MODE_EXPORT; then
    export "$env"="$value"
  fi
  if $MODE_PRINT; then
    echo "$env=$value"
  fi
  if $DOTENV; then
    echo "$env=$value" >> .env
  fi

done < <(collect_maps)

if $DOTENV; then
  echo "Appended $((${#OUTPUT_LINES[@]})) entries to .env" >&2
fi

# Summary (stderr)
echo "Loaded ${#OUTPUT_LINES[@]} secrets for category '$CATEGORY'" >&2

#!/bin/bash
# Generate secure passwords and update Ansible Vault
 
# Check for vault password file
if [ ! -f ~/.vault_pass.txt ]; then
  echo "Error: Ansible Vault password file not found at ~/.vault_pass.txt"
  exit 1
fi

# Generate passwords (32 letters only)
generate_secure_password() {
  # Generate 32-character password with letters, numbers and symbols
  LC_ALL=C tr -dc 'A-Za-z0-9!@#$%^&*()_+-=' </dev/urandom | head -c 32
}

# Generate API key (64 hex characters)
generate_api_key() {
  openssl rand -hex 32
}

# Create temporary file
TMP_FILE=$(mktemp)

# Generate password block
cat <<EOF > "$TMP_FILE"
# ==============================
# AUTO-GENERATED SECRETS
# Generated on: $(date)
# ==============================

# --- Core Services ---
postgres_password: $(generate_secure_password)
neo4j_password: $(generate_secure_password)
weaviate_api_key: $(generate_api_key)
rabbitmq_password: $(generate_secure_password)
redis_password: $(generate_secure_password)

# --- AI Services ---
agentic_rag_admin_key: $(generate_api_key)
local_ai_api_key: $(generate_api_key)
openai_api_key: $(generate_api_key)  # Replace with real key
anthropic_api_key: $(generate_api_key)  # Replace with real key

# --- Monitoring ---
grafana_admin_password: $(generate_secure_password)
prometheus_bearer_token: $(generate_api_key)
loki_write_token: $(generate_api_key)

# --- API Security ---
jwt_secret: $(generate_api_key)
encryption_key: $(generate_api_key)
cors_origin_secret: $(generate_api_key)

# --- External Integrations ---
cloudflare_api_token: $(generate_api_key)  # Replace with real token
aws_access_key: $(generate_api_key)
aws_secret_key: $(generate_secure_password)
google_service_account: $(generate_api_key)  # Base64 encoded JSON

# --- Specialized Secrets ---
neo4j_bolt_password: $(generate_secure_password)
weaviate_rw_api_key: $(generate_api_key)
agentic_rag_neo4j_password: $(generate_secure_password)
EOF

# Encrypt and merge with existing secrets
if [ -f ansible/group_vars/all/secrets.yml ]; then
  # Decrypt existing secrets
  ansible-vault decrypt \
    --vault-password-file ~/.vault_pass.txt \
    ansible/group_vars/all/secrets.yml
fi

ansible-vault encrypt_string \
  --vault-password-file ~/.vault_pass.txt \
  --name "local_ai_secrets" \
  "$(cat "$TMP_FILE")" >> ansible/group_vars/all/secrets.yml

# Cleanup
rm "$TMP_FILE"
echo "Secrets updated in ansible/group_vars/all/secrets.yml"
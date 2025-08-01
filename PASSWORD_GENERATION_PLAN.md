# Local AI Password Generation and Security Plan

## Password Requirements
- 32-character passwords using only uppercase/lowercase letters
- Unique for each service
- Stored in Ansible Vault for deployment

## Generated Passwords
```markdown
N8N_ENCRYPTION_KEY: {{generate 32 letters}}
N8N_USER_MANAGEMENT_JWT_SECRET: {{generate 32 letters}}
POSTGRES_PASSWORD: {{generate 32 letters}}
JWT_SECRET: {{generate 32 letters}}
DASHBOARD_PASSWORD: {{generate 32 letters}}
NEO4J_AUTH_PASSWORD: {{generate 32 letters}}  # Format: neo4j/{{password}}
CLICKHOUSE_PASSWORD: {{generate 32 letters}}
MINIO_ROOT_PASSWORD: {{generate 32 letters}}
LANGFUSE_SALT: {{generate 32 letters}}
NEXTAUTH_SECRET: {{generate 32 letters}}
ENCRYPTION_KEY: {{generate 32 letters}}
```

## Security Procedures
1. Add passwords to Ansible Vault:
```bash
ansible-vault edit ansible/group_vars/all/secrets.yml
```

2. Add these entries to secrets.yml:
```yaml
local_ai_n8n_encryption_key: {{vault_encrypted_value}}
local_ai_postgres_password: {{vault_encrypted_value}}
# ... all other passwords ...
```

3. Update .env file template at `ansible/roles/local-ai/templates/.env.j2` with:
```jinja
N8N_ENCRYPTION_KEY={{ local_ai_n8n_encryption_key }}
POSTGRES_PASSWORD={{ local_ai_postgres_password }}
# ... all other variables ...
```

## Deployment Security
- Enable Hetzner firewall
- Restrict SSH access
- Use Cloudflare WAF
- Enable automatic security updates
- Configure Caddy reverse proxy with TLS 1.3

## Next Steps
1. Execute password generation using CLI:
```bash
# Linux/macOS
for var in $(grep '{{generate' PASSWORD_GENERATION_PLAN.md | cut -d: -f1); do
  pass=$(tr -dc 'A-Za-z' </dev/urandom | head -c 32)
  echo "$var: $pass"
done
```

2. Store passwords in Ansible Vault
3. Proceed with role implementation
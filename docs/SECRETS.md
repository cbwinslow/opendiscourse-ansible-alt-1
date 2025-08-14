# Secrets Management Strategy

This document defines how we manage secrets across the project using:

1. Bitwarden (authoritative source for live production/service credentials)
2. Ansible Vault (deployment-time encrypted variables)
3. Ephemeral environment exports for local development / CI
4. Scripted generation for placeholder and bootstrap secrets

---
## Components

### 1. Bitwarden (Primary Source of Truth)
Bitwarden holds all real, long‑lived credentials. Structure:

Collections (or folders):
- Infrastructure / Cloud
  - `hetzner-api-token` (field: `token`)
- Infrastructure / SSH
  - `deploy-ssh-private-key` (attachment)
  - `deploy-ssh-public-key` (field: `public_key`)
- Infrastructure / Ansible
  - `ansible-vault-password` (field: `vault_password`)
- Services / AI
  - `openai-api-key` (field: `api_key`)
  - `anthropic-api-key` (field: `api_key`)
  - `huggingface-token` (field: `token`)
  - `weaviate-admin-key` (field: `api_key`)
- Services / Monitoring
  - `grafana-admin-password` (field: `password`)
  - `loki-write-token` (field: `token`)
- Services / Messaging
  - `rabbitmq-password` (field: `password`)
  - `redis-password` (field: `password`)
- Services / Datastores
  - `postgres-password` (field: `password`)
  - `neo4j-password` (field: `password`)
- API / Security
  - `jwt-secret` (field: `secret`)
  - `encryption-key` (field: `key`)
- External / Integrations
  - `cloudflare-api-token` (field: `token`)
  - `aws-access-key` (field: `access_key`)
  - `aws-secret-key` (field: `secret_key`)

Naming convention: `<domain>-<service>-<purpose>` (all lowercase, dashes).

### 2. Ansible Vault
Vaulted variables aggregate a subset of Bitwarden secrets required at deploy time. Vault file: `ansible/group_vars/all/secrets.yml`.

Guidelines:
- NEVER commit raw secrets; only encrypted vault content.
- Use generated placeholders for any secrets not yet issued; replace via Bitwarden before production.
- Keep vault password only in Bitwarden (`ansible-vault-password`). For local use place it at `~/.vault_pass.txt` (chmod 600); do not commit.

### 3. Local & CI Environment
Environment variables are injected at runtime via a helper script that fetches from Bitwarden using the CLI (`bw`). CI pipelines should:
1. Export `BW_CLIENTID` and `BW_CLIENTSECRET` (if using Bitwarden service account) or use OIDC runner secret.
2. Run `scripts/bw_export_env.sh` (added in repo) to populate required variables.
3. Call Ansible playbooks referencing those env vars (some tasks already read `lookup('env', 'HCLOUD_TOKEN')`).

### 4. Generated / Bootstrap Secrets
`scripts/generate_and_update_secrets.sh` creates strong random values for placeholders and re-encrypts vault content. This is safe for ephemeral/local bootstrap but MUST be reconciled with canonical Bitwarden entries.

---
## Bitwarden CLI Workflow

Prerequisites: Install Bitwarden CLI (`bw`) and `jq`.

```bash
# 1. Login (interactive) – or use service account login
bw login --raw > ~/.cache/bw_session
export BW_SESSION=$(cat ~/.cache/bw_session)

# 2. (Later) Unlock if session expired
export BW_SESSION=$(bw unlock --raw)

# 3. Sync vault
bw sync

# 4. Get a specific field (example Hetzner token)
bw get item hetzner-api-token | jq -r '.fields[] | select(.name=="token").value'
```

---
## Helper Script: Environment Export
Script `scripts/bw_export_env.sh` maps Bitwarden items+fields to environment variable names.

Example mapping excerpt:
```
HCLOUD_TOKEN         <- hetzner-api-token.token
POSTGRES_PASSWORD    <- postgres-password.password
GRAFANA_ADMIN_PASSWORD <- grafana-admin-password.password
```

Usage:
```bash
source scripts/bw_export_env.sh core   # exports core infra secrets
source scripts/bw_export_env.sh all    # exports everything defined
```

The script:
- Verifies `bw` & `jq`
- Ensures `BW_SESSION` is present (or attempts unlock)
- Warns (does not fail) if an item/field missing
- Optionally writes a `.env` file with `--dotenv` flag

---
## Ansible Integration Options

Current (implemented): Environment fallbacks (e.g., `HCLOUD_TOKEN`).

Planned (future): Custom lookup for Bitwarden (could wrap `community.general.onepassword` style or shell out to `bw`). For safety and portability we keep it opt‑in.

Pattern (future example):
```yaml
- set_fact:
    hcloud_api_token_effective: "{{ lookup('env','HCLOUD_TOKEN') | default( lookup('community.general.bitwarden', 'hetzner-api-token token'), true) }}"
```
(Only after adding the appropriate plugin.)

---
## Secret Rotation Procedure
1. Rotate in Bitwarden (generate new value).
2. Re-run `bw sync` & export env (CI or local).
3. If stored in Vault too, decrypt vault, update value, re-encrypt.
4. Redeploy Ansible playbooks (affected services restart).

---
## Adding a New Secret
1. Create Bitwarden item following naming convention; set field name clearly.
2. Add mapping entry in `scripts/bw_export_env.sh`.
3. (Optional) Add placeholder to vault via generator script and reconcile.
4. Document usage in service README / relevant playbook vars file.

---
## Security Notes
- Never echo secrets in CI logs (`set -o history -o histexpand` caution locally).
- Use `umask 077` before writing temporary secret files.
- Purge `.env` files after debugging.
- Consider enabling Bitwarden org policies: Master password strength, 2FA required, disable export by non-admins.

---
## Checklist (Audit Quick View)
- [ ] All production secrets present in Bitwarden
- [ ] Vault contains only deploy-needed subset
- [ ] No plaintext secrets tracked by git (`git grep` audit passes)
- [ ] CI uses service account or OIDC → Bitwarden
- [ ] Rotation procedures tested in staging

---
## Roadmap
- Add destroy/deprovision playbook that also redacts transient secrets
- Implement Bitwarden lookup plugin wrapper
- Integrate secret scanning pre-commit hook

---
Maintainer: Security / DevOps Team

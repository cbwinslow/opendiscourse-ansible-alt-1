# Traefik TLS / ACME Runbook

This runbook explains how to enable and operate Let's Encrypt TLS certificates for the unified stack using Traefik.

## Overview

Traefik supports two ACME challenge methods here:

- HTTP-01 (default fallback if DNS challenge disabled)
- DNS-01 via Cloudflare (recommended for wildcard + avoiding port 80 exposure race conditions)

## Key Variables (defined in `roles/traefik/defaults/main.yml` or group/host vars)

- `traefik_use_letsencrypt` (bool) – Enable ACME at all. Default: `false` until you flip it.
- `traefik_use_dns_challenge` (bool) – Use DNS challenge instead of HTTP. Requires Cloudflare token.
- `traefik_acme_email` – Email for ACME registration (reuse across hosts; rate limiting aware).
- `traefik_acme_file` – Persistent storage path inside host (mounted into container).
- `traefik_dns_provider` – Currently `cloudflare`.
- `traefik_cloudflare_api_token_var` – The environment variable name Traefik expects, default `CF_DNS_API_TOKEN`.
- `traefik_cloudflare_zone_api_token` – Actual token value (SHOULD be injected securely, NOT committed).
- `traefik_use_acme_staging` (bool) – If `true`, uses Let's Encrypt staging for testing (avoids rate limits).

## Secure Token Handling

DO NOT commit real API tokens.

Recommended options:

1. Ansible Vault: place `traefik_cloudflare_zone_api_token: '...'` in `group_vars/ai/vault.yml` and encrypt.
2. Environment injection at runtime: `ANSIBLE_VAULT_PASSWORD_FILE` + vaulted file or `--extra-vars` from CI secret store.
3. Bitwarden CLI (future): fetch then pass via `--extra-vars`.

## Enabling DNS Challenge

1. Supply token securely.
2. Set in appropriate var scope (e.g. `group_vars/ai/traefik.yml`):

```yaml
traefik_use_letsencrypt: true
traefik_use_dns_challenge: true
traefik_use_acme_staging: true   # first run (optional)
```

1. Run ONLY the Traefik role first to validate:

```bash
ansible-playbook -i inventory/generated/hetzner.yml site.yml --tags reverse-proxy
```

1. Check logs:

```bash
docker logs traefik | grep -i acme
```

1. If staging succeeded, flip `traefik_use_acme_staging: false` and re-run the role.

## HTTP Challenge Fallback

Set:

```yaml
traefik_use_letsencrypt: true
traefik_use_dns_challenge: false
```

Ensure port 80 reachable from the internet.

## Wildcards

Wildcard certs only issued via DNS challenge. Add rules/labels using `Host(` service labels already in roles. For wildcard routers you can create dynamic config files under `{{ traefik_config_dir }}/dynamic/`.

## Forcing Renewal

Certificates auto-managed. To force renewal (debugging):

1. Stop container.
2. Backup acme.json.
3. Remove target domain entry or delete file (CAUTION: loses all certs).
4. Start container; Traefik re-requests.

## Troubleshooting Matrix

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| `rateLimit` errors | Too many prod requests | Switch to staging, wait, reduce redeploys |
| `unauthorized` DNS challenge | Token lacks zone DNS edit | Recreate Cloudflare token with Zone:DNS:Edit |
| `NXDOMAIN` in ACME log | DNS record not propagated | Wait / verify `dig` from remote network |
| HTTP challenge timeout | Port 80 blocked | Ensure host firewall / Cloudflare proxy orange-cloud off temporarily |
| Empty `acme.json` | Permissions or path wrong | Ensure file mode 0600 and mounted volume present |

## Validation Play Additions

The site playbook now asserts:

- `traefik_public` network exists.
- Traefik container running.
- Traefik attached to `traefik_public` network.

## Quick Tag Reference

- Deploy whole stack: `--tags app`
- Just Traefik: `--tags reverse-proxy`
- Validation only: `--tags validation`

## Future Hardening (Not Yet Implemented)

- File permissions tightening for `/etc/traefik`.
- Automatic DNS record verification pre-flight.
- Central secrets management (Bitwarden / SOPS).

## Rollback Procedure

1. Revert recent Traefik-related vars commit.
2. Restore previous `acme.json` from backup.
3. Re-run Traefik role only.
4. If still failing, set `traefik_use_letsencrypt: false` temporarily to restore HTTP service.

---
Document maintained automatically; update when variables or role structure changes.

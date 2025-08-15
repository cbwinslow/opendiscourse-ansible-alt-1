# cbw-opendiscourse.net Simplified Stack

Purpose: Minimal, clean Ansible stack deploying a Traefik reverse proxy plus a set of application services each on its own subdomain of `opendiscourse.net`.

## Components

* Docker engine + compose plugin (base role)
* Traefik (reverse proxy, ACME HTTP challenge, staging by default, optional basic-auth on dashboard)
* Services (each separate role & compose):
  * n8n (`n8n.<domain>`)
  * Flowise (`flowise.<domain>`)
  * Open WebUI (`chat.<domain>`)
  * SearxNG (`search.<domain>`)
  * Neo4j Browser (`graph.<domain>`) – NOT secured / auth hardened yet
  * Langfuse (`langfuse.<domain>`) – placeholder env
  * Supabase (core: Postgres, Kong, Studio, PostgREST, GoTrue, Storage, Realtime, Vector + optional: Logflare, Imgproxy, pg-meta, Edge Runtime, Migration Service via feature flags) (`api.<domain>` / `studio.<domain>`)
  * Observability (separate role): Prometheus, Grafana (auto-provisioned Prometheus datasource), Postgres Exporter, Traefik & Kong metrics, plus Loki + Promtail log aggregation

## Layout

```text
cbw-opendiscourse.net/
  ansible.cfg
  site.yml
  inventory/hosts.yml
  group_vars/all.yml
  roles/
    base/
    traefik/
    n8n/
    flowise/
    openwebui/
    searxng/
    neo4j/
    langfuse/
  supabase/
  observability/
```

## Quick Start

1. Edit `inventory/hosts.yml` and set the real server IP & SSH user.
2. Ensure DNS A records exist for all subdomains pointing to the server: `traefik, n8n, flowise, chat, search, graph, langfuse` (and later `api`).
3. (Optional) Create the external Docker network early if you want to test manually:

```bash
ssh user@server sudo docker network create public_proxy || true
```

1. Run the playbook:

```bash
cd cbw-opendiscourse.net
ansible-playbook site.yml -i inventory/hosts.yml
```

1. Access dashboard (staging cert may warn): <https://traefik.opendiscourse.net>

## Switching to Production Certificates

Set `acme_staging: false` in `group_vars/all.yml` and re-run Traefik role:

```bash
ansible-playbook site.yml -i inventory/hosts.yml --tags traefik
```

## Current Security / Hardening Status

Implemented:
 
* Optional Traefik dashboard basic auth (disabled by default) – enable via `traefik_dashboard_auth_enabled: true` and provide `traefik_dashboard_users` htpasswd entries.
* Supabase secret assertion: play fails if obviously insecure defaults still present (length check) – replace with vault values.
* Feature flags to disable unused Supabase services to reduce attack surface.
* Loki + Promtail central log aggregation foundation.

Planned / Pending:
 
* Firewall (UFW) & Fail2ban role
* Neo4j auth enablement & stronger database credentials rotation workflow
* Automated secret generation script & periodic rotation guidance
* Forward-auth / OAuth proxy option for Traefik (beyond basic auth)

## Guiding Principles

* Simplicity first: every service is a small compose project
* Clear domain mapping via variables in one file (`group_vars/all.yml`)
* No premature security until baseline is proven stable
* Each role self-contained and idempotent

## Tags

All major plays/roles now have tags matching the role name. Examples:

```bash
# Deploy only traefik
ansible-playbook site.yml -i inventory/hosts.yml --tags traefik

# Re-run supabase health checks only
ansible-playbook site.yml -i inventory/hosts.yml --tags supabase,health

# Bring up observability stack alone
ansible-playbook site.yml -i inventory/hosts.yml --tags observability
```

## Extending

To add a new service:

1. Create `roles/<service>/templates/docker-compose.yml.j2`
2. Add tasks in `roles/<service>/tasks/main.yml` similar to others.
3. Add domain mapping in `group_vars/all.yml` under `services:`.
4. Append role under the Core services play in `site.yml`.

## Removal / Re-run

Re-running the playbook is idempotent. To remove a service for now manually:

```bash
ssh server
cd /opt/stack/<service>
docker compose down
rm -rf /opt/stack/<service>
```


## Supabase Role & Observability Status

Supabase role now focuses purely on Supabase services. It deploys core components:

* Postgres (db)
* Kong gateway
* Studio
* PostgREST
* GoTrue
* Storage
* Realtime
* Vector

Optional components (feature flags in `group_vars/all.yml` under `supabase:`):

* `enable_logflare`
* `enable_imgproxy`
* `enable_pg_meta`
* `enable_edge_runtime`
* `enable_migration_service`

Set any of these to `false` to exclude the service from the compose deployment.

Observability (separate role) deploys:

* Prometheus
* Grafana (auto-provisioned Prometheus datasource)
* Postgres exporter (runs inside Supabase compose for proximity)
* Loki (log storage) & Promtail (log shipper)
* Scrape targets: Prometheus itself, Postgres exporter, Kong (8100), Traefik (internal metrics entrypoint 9100), Loki, Promtail

Metrics scraped out-of-the-box:

* Postgres exporter (`postgres-exporter:9187`)
* Traefik metrics (`traefik:9100` internal service metrics entrypoint)
* Kong metrics (`kong:8100`)
* Loki metrics (`loki:3100`)
* Promtail metrics (`promtail:9080`)

Add dashboards by placing JSON exports into `/opt/stack/observability/grafana/dashboards` (host path – see role for exact layout). Secrets are insecure placeholders and MUST be rotated before production. Provide real secrets via `group_vars/vault.yml` (encrypted with `ansible-vault`) mapping to variables consumed in `group_vars/all.yml` (e.g. `vault_supabase_jwt_secret`).

### Enabling Traefik Dashboard Auth

1. Generate an htpasswd entry (example using Apache utils):

```bash
htpasswd -nbB admin 'StrongPassword' | sed -e 's/\$/\\$/g'
```

1. Set in `group_vars/all.yml`:

```yaml
traefik_dashboard_auth_enabled: true
traefik_dashboard_users:
  - "admin:$2y$05$...hashed..."
```

1. Re-run:

```bash
ansible-playbook site.yml -i inventory/hosts.yml --tags traefik
```

Dashboard now requires HTTP Basic Auth.

### Disabling Optional Supabase Services

Set the corresponding `supabase.enable_*` flag to `false` and re-run with `--tags supabase`.

### Logs via Loki / Promtail

Promtail currently tails `/var/log/*.log`. Adjust `promtail-config.yml.j2` to add Docker container log paths or journald scraping as needed. Loki retention & storage are local filesystem defaults (tune in `loki-config.yml.j2`).

Health Checks: After deployment the Supabase role probes key endpoints (Kong root, Auth health, REST root, Studio) with retries to ensure readiness before the remaining application services run. Use `--tags supabase,health` to re-run checks without redeploying everything.

---
This baseline gets you a working multi-service routed environment fast. Next steps: choose which hardening & observability layers you want and we’ll layer them in systematically.

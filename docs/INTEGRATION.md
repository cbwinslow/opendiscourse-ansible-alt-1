# Integration Plan for OpenDiscourse AI Stack

## Overview
This document describes the integration strategy for all major applications in the OpenDiscourse stack, including LocalAI, n8n, Supabase, Neo4j, Langfuse, Caddy, SearXNG, Flowise, Qdrant, and the monitoring stack (Prometheus, Grafana, Loki).

## Architecture Diagram

```
[Users]
   |
[WebUI / Caddy]
   |
[FastAPI / n8n / Flowise]
   |
[LocalAI] <-> [Langfuse]
   |
[Supabase (PostgreSQL)] <-> [Qdrant] <-> [Neo4j]
   |
[Monitoring: Prometheus, Grafana, Loki]
```

## Integration Points
- **Single PostgreSQL Instance:** All services requiring a database use the same PostgreSQL instance provided by Supabase.
- **Langfuse:** Observability for LLMs, integrated with LocalAI, FastAPI, Agentic RAG, and n8n.
- **Caddy:** Reverse proxy for all web services, SSL termination, and subdomain routing (all subdomains use `opendiscourse.net`).
- **Monitoring:** Prometheus scrapes metrics from all services, Grafana visualizes, Loki collects logs.
- **Neo4j:** Used for knowledge graph, integrated with Agentic RAG and n8n.
- **Qdrant:** Vector store for RAG, integrated with Agentic RAG and FastAPI.
- **SearXNG:** Search engine, available via Caddy proxy.
- **Flowise:** No-code agent builder, integrated with n8n and FastAPI.

## Monitoring Integration
- All services expose Prometheus metrics endpoints.
- Loki collects logs from Docker containers and systemd services.
- Grafana dashboards are pre-configured for each service.

## No Duplication Policy
- Only one instance of PostgreSQL (Supabase).
- All integrations use shared services where possible.

## Next Steps
Finalize Ansible playbooks for deployment and integration.
Update documentation and logs.

## Shared Variable Groups
All services and roles reference centralized variables defined in `ansible/group_vars/all/secrets.yml`. These variables are grouped by function:

- **Databases:**
  - `postgres_host`, `postgres_port`, `postgres_db`, `postgres_admin_user`, `postgres_admin_password`
  - `neo4j_host`, `neo4j_port`, `neo4j_bolt_port`
- **Monitoring:**
  - `prometheus_host`, `prometheus_port`, `grafana_host`, `grafana_port`, `loki_host`, `loki_port`
- **Messaging:**
  - `rabbitmq_host`, `rabbitmq_port`, `rabbitmq_management_port`, `rabbitmq_default_user`, `rabbitmq_default_pass`
- **Proxies/Networking:**
  - `traefik_host`, `traefik_port`, `nginx_host`, `nginx_port`, `caddy_host`, `caddy_port`
- **AI/LLM/Vector DB:**
  - `localai_host`, `localai_port`, `langfuse_host`, `langfuse_port`, `flowise_host`, `flowise_port`, `graphiti_host`, `graphiti_port`
- **Security:**
  - `security_updates_enabled`, `ufw_allowed_ports`
- **OAuth:**
  - `oauth_host`, `oauth_port`, `oauth_client_id`, `oauth_client_secret`
- **Cloudflare:**
  - `cloudflare_host`, `cloudflare_api_token`, `cloudflare_zone_id`
- **Docker:**
  - `docker_host`, `docker_port`

### Usage
All Ansible roles and playbooks should reference these shared variables for service configuration, connection details, and credentials. This ensures every app uses the same instance and settings, enabling seamless integration and avoiding duplication.

Example (FastAPI):

```yaml
DATABASE_URL: "postgresql://{{ postgres_admin_user }}:{{ postgres_admin_password }}@{{ postgres_host }}:{{ postgres_port }}/{{ postgres_db }}"
```

Example (Prometheus):

```yaml
prometheus_host: "{{ prometheus_host }}"
prometheus_port: "{{ prometheus_port }}"
```

See `ansible/group_vars/all/secrets.yml` for the full list of shared variables.

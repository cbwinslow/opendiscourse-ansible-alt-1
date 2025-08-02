# OpenDiscourse AI Stack Inventory

## Applications Present

| Application      | Purpose                        | Integration Status         | Monitoring Status |
|------------------|--------------------------------|---------------------------|-------------------|
| LocalAI          | LLM Inference                  | Integrated                | Metrics/logs      |
| n8n              | Low-code automation            | Integrated                | Metrics/logs      |
| Supabase         | PostgreSQL DB + Auth           | Integrated (single DB)    | Metrics/logs      |
| Neo4j            | Knowledge Graph                | Integrated                | Metrics/logs      |
| Langfuse         | LLM Observability              | Integrated                | Metrics/logs      |
| Caddy            | Reverse Proxy/SSL              | Integrated                | Metrics/logs      |
| SearXNG          | Metasearch Engine              | Integrated                | Metrics/logs      |
| Flowise          | No-code agent builder          | Integrated                | Metrics/logs      |
| Qdrant           | Vector Store                   | Integrated                | Metrics/logs      |
| FastAPI          | API Layer                      | Integrated                | Metrics/logs      |
| Agentic RAG      | RAG Orchestration              | Integrated                | Metrics/logs      |
| Prometheus       | Metrics Collection             | Integrated                | N/A               |
| Grafana          | Metrics Visualization          | Integrated                | N/A               |
| Loki             | Log Aggregation                | Integrated                | N/A               |
| OpenSearch       | Search/Log Analytics (OLK)     | Missing (to be integrated)| N/A               |

## Applications Missing/To Be Integrated

| Application      | Purpose                        | Notes                     |
|------------------|--------------------------------|---------------------------|
| OpenSearch       | Search/Log Analytics (OLK)     | Needed for OLK stack      |

## Integration Needs
- Integrate OpenSearch for OLK stack (replace ELK Elasticsearch)
- Ensure all roles share data in vector databases (Supabase/Qdrant)
- All applications must expose Prometheus metrics and Loki logs
- Ansible playbooks/roles for all applications and integrations
- Monitoring dashboards for all services

## Next Steps
- Create Ansible roles/playbooks for OpenSearch
- Integrate OpenSearch with Loki and Grafana
- Update all roles to share data in vector DBs
- Ensure monitoring integration for all apps

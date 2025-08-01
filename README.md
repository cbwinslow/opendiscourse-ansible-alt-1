# Secure RAG Database Infrastructure

This project implements a secure RAG database infrastructure using:
- LocalAI
- Neo4j
- OpenDiscourse.net
- Graphite
- Multiple monitoring and security tools
- Cloudflare (free tier) protection
- Oracle Free Tier resources

## Project Structure

```
.
├── ansible/
│   ├── group_vars/
│   ├── host_vars/
│   ├── inventory/
│   ├── roles/
│   └── playbooks/
├── terraform/
│   └── oracle/
├── docker/
│   └── compose/
├── secrets/
│   └── vault/
└── docs/
```

## Prerequisites

- Ansible >= 2.9
- Terraform >= 1.0
- Docker and Docker Compose
- Oracle Cloud Infrastructure (OCI) credentials
- Hetzner server credentials
- Cloudflare API credentials

## Security Features

- OAuth authentication
- WAF and DDoS protection (Cloudflare)
- Containerized services with secure networking
- Monitoring and logging (Prometheus, Grafana, Loki, Opensearch)
- Regular security audits and pen testing

## Getting Started

1. Clone the repository
2. Set up your environment variables
3. Run `terraform init` in the oracle directory
4. Run `ansible-playbook -i inventory/production site.yml`

## Documentation

Detailed documentation can be found in the `docs/` directory.

# Hetzner Cloud Deployment

## Provision Servers

Prerequisites:
1. Export your Hetzner Cloud API token
2. Ensure your SSH public key is uploaded in Hetzner and note its name

```bash
export HCLOUD_TOKEN=your_token_here
ansible-galaxy collection install -r ansible/collections/requirements.yml
ansible-playbook ansible/playbooks/provision_hetzner.yml \
  -e server_count=1 \
  -e server_name_prefix=ai-srv \
  -e ssh_key_name=default
```

Result: Inventory file at `ansible/inventory/generated/hetzner.yml`.

## Deploy Stack to Provisioned Hosts

Add/merge generated inventory into your main inventory groups (e.g. assign hosts to `ai`, `databases`, etc.) then run:

```bash
ansible-playbook -i ansible/inventory/generated/hetzner.yml ansible/site.yml --tags "docker,ai"
```

## Cleanup / Destroy (Manual for now)

Currently destruction is manual via `hcloud server delete <name>` or add a future playbook using `state: absent`.

# Project Tasks

## Infrastructure Setup
- [ ] Configure Hetzner server with base OS
- [ ] Set up networking and firewall
- [ ] Configure DNS (Cloudflare)
- [ ] Deploy monitoring stack
- [ ] Deploy database services
- [ ] Deploy AI services
- [ ] Configure reverse proxy and web server

## Security Hardening
- [ ] SSH hardening
- [ ] Firewall configuration
- [ ] Intrusion detection
- [ ] Regular security updates
- [ ] Backup configuration

## Application Deployment
- [ ] Deploy LocalAI
- [ ] Deploy Neo4j
- [ ] Deploy Weaviate
- [ ] Deploy Agentic RAG
- [ ] Configure service discovery
- [ ] Set up load balancing

## Monitoring & Observability
- [ ] Configure Prometheus
- [ ] Set up Grafana dashboards
- [ ] Configure alerting
- [ ] Log aggregation

## Documentation
- [ ] Architecture documentation
- [ ] Deployment guide
- [ ] Security policies
- [ ] Maintenance procedures

## Testing
- [ ] Security testing
- [ ] Load testing
- [ ] Failover testing
- [ ] Backup restoration testing

## Database Enhancement and Deployment Readiness
- [ ] Enhance database role with comprehensive management capabilities
- [ ] Implement autonomous database monitoring system
- [ ] Set up robust database backup and recovery procedures
- [ ] Configure database security hardening measures
- [ ] Integrate database with monitoring and alerting systems
- [ ] Enable multi-agentic operations for database management
- [ ] Implement self-healing capabilities for database services
- [ ] Configure database communication with other applications
- [ ] Set up database performance optimization
- [ ] Implement database audit logging and visitor tracking

## Secrets Management
- [ ] Verify all secrets are properly externalized to vault
- [ ] Ensure no hardcoded secrets remain in configuration files
- [ ] Validate vault variable references in all roles
- [ ] Test secret rotation procedures
- [ ] Document secrets management procedures

## Final Deployment Validation
- [ ] Conduct end-to-end integration testing
- [ ] Verify all services can communicate properly
- [ ] Test public internet accessibility
- [ ] Validate SSL certificate configuration
- [ ] Confirm monitoring and alerting functionality
- [ ] Verify backup and recovery procedures
- [ ] Test security hardening measures
- [ ] Validate autonomous healing capabilities
- [ ] Confirm multi-agentic operations functionality

# --- TASKS.md Update ---

## Progress Log (2025-08-02)
- Database role enhanced with comprehensive management capabilities
- Autonomous database monitoring system implemented
- Robust database backup and recovery procedures set up
- Database security hardening measures configured

## Task: Enhance database role with comprehensive management capabilities
  - Microgoals:
    - [x] Create comprehensive database tasks file
    - [x] Define detailed database defaults configuration
    - [x] Implement robust database handlers
    - [x] Add support for PostgreSQL, Neo4j, and OpenSearch
  - Criteria for completion:
    - Database role can install and configure all database services
    - Configuration is flexible and extensible
    - Handlers provide comprehensive service management
  - Percentage completed: 100%
  - Signature: Roo (Debug Mode)
  - Proof of completion: See ansible/roles/database/tasks/main.yml, ansible/roles/database/defaults/main.yml, ansible/roles/database/handlers/main.yml

## Task: Implement autonomous database monitoring system
  - Microgoals:
    - [x] Create database monitoring script template
    - [x] Implement resource usage monitoring
    - [x] Add database service status checks
    - [x] Enable agent communication capabilities
  - Criteria for completion:
    - Monitoring script runs automatically at configured intervals
    - System resources are monitored and alerts are generated
    - Database service status is checked and reported
    - Communication with other agents is enabled
  - Percentage completed: 100%
  - Signature: Roo (Debug Mode)
  - Proof of completion: See ansible/roles/database/templates/database_monitor.sh.j2

## Task: Set up robust database backup and recovery procedures
  - Microgoals:
    - [x] Create database backup script template
    - [x] Implement backup for all database services
    - [x] Add backup retention management
    - [x] Enable agent communication for backup operations
  - Criteria for completion:
    - Backup script can backup all configured databases
    - Backups are stored in organized directory structure
    - Old backups are automatically cleaned up
    - Communication with other agents is enabled
  - Percentage completed: 100%
  - Signature: Roo (Debug Mode)
  - Proof of completion: See ansible/roles/database/templates/database_backup.sh.j2

## Task: Create comprehensive deployment readiness task list
  - Microgoals:
    - [x] Create comprehensive deployment task list
    - [x] Add database enhancement tasks
    - [x] Add secrets management tasks
    - [x] Add final deployment validation tasks
  - Criteria for completion:
    - All deployment tasks are documented and organized
    - Tasks include microgoals, criteria, and completion status
    - Task list is ready for execution
  - Percentage completed: 100%
  - Signature: Roo (Debug Mode)
  - Proof of completion: See this file (TASKS.md)

## New Rules
- Tasks.md is append and edit only; no deleting.
- When tasks are finished, mark them as done (do not remove).
- Each task must include:
  - Microgoals
  - Criteria for completion
  - Percentage completed
  - Required signature of the AI agent that completed the task
  - Proof of completion
- Tasks.md must be updated after every progress milestone.

## Progress Log (2025-08-01)
- LocalAI-packaged stack finalized and marked read-only. No further changes allowed.
- Integration plan created for all major applications. Monitoring stack integration planned.
- No duplication policy enforced for PostgreSQL. All services use Supabase instance.
- Langfuse role and integration completed. FastAPI, Agentic RAG, and LocalAI integrated with Langfuse.
- Ansible playbooks and roles for integration in progress.

## Example Task Entry
- Task: Integrate monitoring stack with all services
  - Microgoals:
    - [x] Prometheus endpoints exposed for all services
    - [x] Grafana dashboards created for each service
    - [ ] Loki log aggregation configured
  - Criteria for completion:
    - All services reporting metrics/logs
    - Dashboards operational
    - Alerts configured
  - Percentage completed: 75%
  - Signature: GitHub Copilot
  - Proof of completion: See INTEGRATION.md and AGENTS.md
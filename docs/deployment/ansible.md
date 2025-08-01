# Ansible Deployment Guide

## Prerequisites
- Ansible 2.9+
- Python 3.8+
- Docker and Docker Compose

## Usage
```bash
# Deploy all services
ansible-playbook -i inventory/production site.yml
```

## Inventory
Update `inventory/production` with your server details.

## Test Inventory Configuration
The `ansible/inventory/test/hosts` file has been updated to include configurations for testing purposes. Key changes include:

- **LocalAI Configuration:**
  - Added `local_ai` group and variables.
  - Configured `local_ai` to use a test directory, user, and group.
  - Set up a small model for testing.
  - Enabled Prometheus monitoring for LocalAI.

- **Monitoring Configuration:**
  - Added Prometheus, Grafana, and Loki configurations.
  - Configured ports and paths for monitoring services.

- **Database Configuration:**
  - Added `database_servers` group and variables.
  - Configured PostgreSQL and Neo4j services.

- **Proxy Configuration:**
  - Added `proxy_servers` group and variables.
  - Configured Traefik, Nginx, and Caddy services.

- **General Configuration:**
  - Added `all:vars` group with common variables.
  - Configured SSH settings, Python interpreter, and vault password file.
  - Set up performance tuning and environment settings.

## Variables
- Group variables: `group_vars/all.yml`
- Host variables: `host_vars/`
- Secrets: Use Ansible Vault for sensitive data

## Common Tasks
- Deploy all services: `ansible-playbook -i inventory/production site.yml`
- Deploy specific role: `ansible-playbook -i inventory/production --tags=local-ai site.yml`
- Check syntax: `ansible-playbook --syntax-check site.yml`
## RabbitMQ Tests

The `ansible/playbooks/test-rabbitmq.yml` playbook includes the following tests to verify the RabbitMQ installation:

- **Verify RabbitMQ service is running**: Ensures that the RabbitMQ service is started and enabled.
- **Verify RabbitMQ management interface**: Checks that the RabbitMQ management interface is accessible via HTTP.
- **Display RabbitMQ status**: Provides a debug message indicating that RabbitMQ is running and accessible.
- **Display RabbitMQ connection details**: Outputs the URLs for RabbitMQ management, AMQP port, and Prometheus metrics.
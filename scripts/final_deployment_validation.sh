#!/bin/bash
# Final Deployment Validation Script
# This script validates that all components are ready for deployment

set -e

echo "=== Final Deployment Validation ==="

# Function to log messages
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Function to check if a service is running
check_service() {
    if systemctl is-active --quiet "$1"; then
        log "✓ Service $1 is running"
        return 0
    else
        log "✗ Service $1 is not running"
        return 1
    fi
}

# Function to check if a port is open
check_port() {
    local port=$1
    local service=$2
    if nc -z localhost "$port"; then
        log "✓ Port $port ($service) is open"
        return 0
    else
        log "✗ Port $port ($service) is not open"
        return 1
    fi
}

# Function to check if a command exists
check_command() {
    if command -v "$1" &> /dev/null; then
        log "✓ Command $1 is available"
        return 0
    else
        log "✗ Command $1 is not available"
        return 1
    fi
}

# Function to check if a file exists
check_file() {
    if [ -f "$1" ]; then
        log "✓ File $1 exists"
        return 0
    else
        log "✗ File $1 does not exist"
        return 1
    fi
}

# Function to check if a directory exists
check_directory() {
    if [ -d "$1" ]; then
        log "✓ Directory $1 exists"
        return 0
    else
        log "✗ Directory $1 does not exist"
        return 1
    fi
}

# Function to check Ansible vault
check_vault() {
    if ansible-vault view ansible/group_vars/all/secrets.yml &> /dev/null; then
        log "✓ Ansible vault is accessible"
        return 0
    else
        log "✗ Ansible vault is not accessible"
        return 1
    fi
}

# Function to check database connectivity
check_database_connectivity() {
    local issues_found=0
    
    # Check PostgreSQL
    if command -v pg_isready &> /dev/null; then
        if pg_isready -q; then
            log "✓ PostgreSQL is accepting connections"
        else
            log "✗ PostgreSQL is not accepting connections"
            issues_found=$((issues_found + 1))
        fi
    else
        log "ℹ PostgreSQL not installed, skipping check"
    fi
    
    # Check Neo4j
    if [ -f /etc/neo4j/neo4j.conf ]; then
        local neo4j_port=$(grep "dbms.connector.bolt.listen_address" /etc/neo4j/neo4j.conf | cut -d: -f2)
        if [ -z "$neo4j_port" ]; then
            neo4j_port=7687
        fi
        
        if nc -z localhost "$neo4j_port"; then
            log "✓ Neo4j is accepting connections on port $neo4j_port"
        else
            log "✗ Neo4j is not accepting connections on port $neo4j_port"
            issues_found=$((issues_found + 1))
        fi
    else
        log "ℹ Neo4j not installed, skipping check"
    fi
    
    # Check OpenSearch
    if [ -d /opt/opensearch ]; then
        local opensearch_port=9200
        if nc -z localhost "$opensearch_port"; then
            log "✓ OpenSearch is accepting connections on port $opensearch_port"
        else
            log "✗ OpenSearch is not accepting connections on port $opensearch_port"
            issues_found=$((issues_found + 1))
        fi
    else
        log "ℹ OpenSearch not installed, skipping check"
    fi
    
    return $issues_found
}

# Function to check monitoring systems
check_monitoring() {
    local issues_found=0
    
    # Check Prometheus
    if nc -z localhost 9090; then
        log "✓ Prometheus is running on port 9090"
    else
        log "✗ Prometheus is not running on port 9090"
        issues_found=$((issues_found + 1))
    fi
    
    # Check Grafana
    if nc -z localhost 3000; then
        log "✓ Grafana is running on port 3000"
    else
        log "✗ Grafana is not running on port 3000"
        issues_found=$((issues_found + 1))
    fi
    
    # Check Loki
    if nc -z localhost 3100; then
        log "✓ Loki is running on port 3100"
    else
        log "✗ Loki is not running on port 3100"
        issues_found=$((issues_found + 1))
    fi
    
    return $issues_found
}

# Function to check AI services
check_ai_services() {
    local issues_found=0
    
    # Check LocalAI
    if nc -z localhost 8080; then
        log "✓ LocalAI is running on port 8080"
    else
        log "✗ LocalAI is not running on port 8080"
        issues_found=$((issues_found + 1))
    fi
    
    # Check Langfuse
    if nc -z localhost 3000; then
        log "✓ Langfuse is running on port 3000"
    else
        log "✗ Langfuse is not running on port 3000"
        issues_found=$((issues_found + 1))
    fi
    
    return $issues_found
}

# Function to check web services
check_web_services() {
    local issues_found=0
    
    # Check Caddy
    if nc -z localhost 80; then
        log "✓ Caddy is running on port 80"
    else
        log "✗ Caddy is not running on port 80"
        issues_found=$((issues_found + 1))
    fi
    
    # Check if SSL is configured
    if nc -z localhost 443; then
        log "✓ SSL is configured (port 443 is open)"
    else
        log "✗ SSL may not be configured (port 443 is not open)"
        issues_found=$((issues_found + 1))
    fi
    
    return $issues_found
}

# Function to check security
check_security() {
    local issues_found=0
    
    # Check UFW status
    if ufw status | grep -q "Status: active"; then
        log "✓ UFW firewall is active"
    else
        log "✗ UFW firewall is not active"
        issues_found=$((issues_found + 1))
    fi
    
    # Check SSH
    if nc -z localhost 22; then
        log "✓ SSH is running on port 22"
    else
        log "✗ SSH is not running on port 22"
        issues_found=$((issues_found + 1))
    fi
    
    return $issues_found
}

# Function to check autonomous systems
check_autonomous_systems() {
    local issues_found=0
    
    # Check if database monitoring is scheduled
    if crontab -l 2>/dev/null | grep -q "database_monitor"; then
        log "✓ Database monitoring is scheduled"
    else
        log "✗ Database monitoring is not scheduled"
        issues_found=$((issues_found + 1))
    fi
    
    # Check if database backup is scheduled
    if crontab -l 2>/dev/null | grep -q "database_backup"; then
        log "✓ Database backup is scheduled"
    else
        log "✗ Database backup is not scheduled"
        issues_found=$((issues_found + 1))
    fi
    
    # Check if autonomous manager service exists
    if systemctl list-unit-files | grep -q "database-autonomous-manager"; then
        log "✓ Autonomous database manager service exists"
    else
        log "✗ Autonomous database manager service does not exist"
        issues_found=$((issues_found + 1))
    fi
    
    return $issues_found
}

# Main validation function
main() {
    local total_issues=0
    
    log "Starting deployment validation..."
    
    # Check prerequisites
    log "Checking prerequisites..."
    check_command "ansible" || total_issues=$((total_issues + 1))
    check_command "ansible-playbook" || total_issues=$((total_issues + 1))
    check_command "git" || total_issues=$((total_issues + 1))
    check_command "docker" || total_issues=$((total_issues + 1))
    
    # Check configuration files
    log "Checking configuration files..."
    check_file "ansible/group_vars/all/secrets.yml" || total_issues=$((total_issues + 1))
    check_file "ansible/site.yml" || total_issues=$((total_issues + 1))
    check_directory "ansible/roles" || total_issues=$((total_issues + 1))
    
    # Check vault accessibility
    log "Checking vault accessibility..."
    check_vault || total_issues=$((total_issues + 1))
    
    # Check database systems
    log "Checking database systems..."
    check_database_connectivity || total_issues=$((total_issues + 1))
    
    # Check monitoring systems
    log "Checking monitoring systems..."
    check_monitoring || total_issues=$((total_issues + 1))
    
    # Check AI services
    log "Checking AI services..."
    check_ai_services || total_issues=$((total_issues + 1))
    
    # Check web services
    log "Checking web services..."
    check_web_services || total_issues=$((total_issues + 1))
    
    # Check security
    log "Checking security..."
    check_security || total_issues=$((total_issues + 1))
    
    # Check autonomous systems
    log "Checking autonomous systems..."
    check_autonomous_systems || total_issues=$((total_issues + 1))
    
    # Final assessment
    log "=== Validation Summary ==="
    if [ "$total_issues" -eq 0 ]; then
        log "✓ All validation checks passed! System is ready for deployment."
        log "You can now run: ansible-playbook -i ansible/inventory/production ansible/site.yml"
        exit 0
    else
        log "✗ $total_issues validation check(s) failed. Please address the issues before deployment."
        exit 1
    fi
}

# Run main function
main
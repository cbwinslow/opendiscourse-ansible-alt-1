#!/bin/bash

# Create base directories
mkdir -p ansible/{
  group_vars,
  host_vars,
  library,
  module_utils,
  filter_plugins,
  inventory/group_vars,
  inventory/host_vars,
  roles/{
    common/{tasks,handlers,templates,files,vars,defaults,meta,library,module_utils,lookup_plugins},
    docker/{tasks,handlers,templates,files,vars,defaults,meta},
    reverse_proxy/{tasks,handlers,templates,files,vars,defaults,meta},
    cloudflare/{tasks,handlers,templates,files,vars,defaults,meta},
    oracle_cloud/{tasks,handlers,templates,files,vars,defaults,meta},
    monitoring/{tasks,handlers,templates,files,vars,defaults,meta},
    security/{tasks,handlers,templates,files,vars,defaults,meta},
    database/{tasks,handlers,templates,files,vars,defaults,meta},
    web_apps/{tasks,handlers,templates,files,vars,defaults,meta},
    oauth/{tasks,handlers,templates,files,vars,defaults,meta},
    local-ai/{tasks,handlers,templates,files,vars,defaults,meta},
    neo4j/{tasks,handlers,templates,files,vars,defaults,meta},
    weaviate/{tasks,handlers,templates,files,vars,defaults,meta},
    agentic-rag/{tasks,handlers,templates,files,vars,defaults,meta},
    langfuse/{tasks,handlers,templates,files,vars,defaults,meta},
    observability/{tasks,handlers,templates,files,vars,defaults,meta}
  }
}

# Create documentation structure
mkdir -p docs/{
  architecture,
  deployment,
  security,
  api,
  maintenance,
  operations,
  development,
  testing
}

# Create main playbooks
cat > ansible/site.yml << 'EOL'
---
# Main playbook for RAG Database Infrastructure Deployment

- name: Prepare Hetzner server
  hosts: hetzner
  roles:
    - common
    - security
    - docker
    - monitoring
    - local-ai
    - neo4j
    - graphite
    - weaviate
    - agentic-rag
    - opendiscourse
    - nginx
    - cloudflare

- name: Configure Oracle Free Tier Resources
  hosts: oracle
  roles:
    - role: oracle_db
    - role: oracle_compute
EOL

# Create README.md for each role with basic documentation
echo "Creating role README files..."
for role in common docker reverse_proxy cloudflare oracle_cloud monitoring security database web_apps oauth local-ai neo4j weaviate agentic-rag langfuse observability; do
  mkdir -p "ansible/roles/$role"
  if [ ! -f "ansible/roles/$role/README.md" ]; then
    cat > "ansible/roles/$role/README.md" << EOL
# $role Role

## Description
This role manages the $role component of the OpenDiscourse infrastructure.

## Variables
See `defaults/main.yml` for role variables.

## Dependencies
List any dependencies on other roles or collections.

## Example Playbook
```yaml
- hosts: servers
  roles:
    - { role: $role }
```

## License
Proprietary
EOL
  fi
done

echo "Creating basic meta files..."
for role in common docker reverse_proxy cloudflare oracle_cloud monitoring security database web_apps oauth local-ai neo4j weaviate agentic-rag langfuse observability; do
  mkdir -p "ansible/roles/$role/meta"
  if [ ! -f "ansible/roles/$role/meta/main.yml" ]; then
    cat > "ansible/roles/$role/meta/main.yml" << 'EOL'
---
galaxy_info:
  author: Your Name
  description: Your role description
  company: Your Company
  license: Proprietary
  min_ansible_version: 2.9
  platforms:
    - name: Ubuntu
      versions:
        - focal
        - jammy
  galaxy_tags: []

dependencies: []
EOL
  fi
done

# Create basic handler files
echo "Creating basic handler files..."
for role in common docker reverse_proxy cloudflare oracle_cloud monitoring security database web_apps oauth local-ai neo4j weaviate agentic-rag langfuse observability; do
  mkdir -p "ansible/roles/$role/handlers"
  if [ ! -f "ansible/roles/$role/handlers/main.yml" ]; then
    cat > "ansible/roles/$role/handlers/main.yml" << 'EOL'
---
# handlers file for $role
EOL
  fi
done

# Create basic default variables
echo "Creating default variable files..."
for role in common docker reverse_proxy cloudflare oracle_cloud monitoring security database web_apps oauth local-ai neo4j weaviate agentic-rag langfuse observability; do
  mkdir -p "ansible/roles/$role/defaults"
  if [ ! -f "ansible/roles/$role/defaults/main.yml" ]; then
    cat > "ansible/roles/$role/defaults/main.yml" << 'EOL'
---
# defaults file for $role
EOL
  fi
done

echo "Project structure created successfully!"
echo "Next steps:"
echo "1. Review the generated files"
echo "2. Update variables in group_vars/ and host_vars/"
echo "3. Create your inventory files"
echo "4. Run 'ansible-galaxy install -r requirements.yml' if you have any dependencies"
echo "5. Run your playbooks with 'ansible-playbook -i inventory/production site.yml'"

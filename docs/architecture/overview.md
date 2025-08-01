# System Architecture Overview

## Components
- **Frontend**: Web interface for user interaction
- **Backend**: API services and business logic
- **Databases**: 
  - PostgreSQL with pgvector
  - Neo4j for knowledge graph
  - Weaviate for vector search
- **AI Services**:
  - LocalAI for LLM inference
  - Agentic RAG for document processing
- **Monitoring**:
  - Prometheus
  - Grafana
  - Loki

## Deployment Considerations
- **Frontend**: Deployed using Docker Compose. Ensure the Docker image is up-to-date and the container is running.
- **Backend**: Deployed using Docker Compose. Ensure the Docker image is up-to-date and the container is running.
- **Databases**:
  - **PostgreSQL with pgvector**: Deployed using Docker Compose. Ensure the Docker image is up-to-date and the container is running. Configure the database with the necessary schemas and data.
  - **Neo4j for knowledge graph**: Deployed using Docker Compose. Ensure the Docker image is up-to-date and the container is running. Configure the database with the necessary schemas and data.
  - **Weaviate for vector search**: Deployed using Docker Compose. Ensure the Docker image is up-to-date and the container is running. Configure the database with the necessary schemas and data.
- **AI Services**:
  - **LocalAI for LLM inference**: Deployed using Docker Compose. Ensure the Docker image is up-to-date and the container is running. Configure the service with the necessary models and configurations.
  - **Agentic RAG for document processing**: Deployed using Docker Compose. Ensure the Docker image is up-to-date and the container is running. Configure the service with the necessary models and configurations.
- **Monitoring**:
  - **Prometheus**: Deployed using Docker Compose. Ensure the Docker image is up-to-date and the container is running. Configure the service with the necessary targets and configurations.
  - **Grafana**: Deployed using Docker Compose. Ensure the Docker image is up-to-date and the container is running. Configure the service with the necessary dashboards and data sources.
  - **Loki**: Deployed using Docker Compose. Ensure the Docker image is up-to-date and the container is running. Configure the service with the necessary configurations.
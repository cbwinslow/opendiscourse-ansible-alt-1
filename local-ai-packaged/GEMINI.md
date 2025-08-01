# Gemini Deployment Plan for local-ai-packaged

This document outlines the steps for Gemini to deploy the local-ai-packaged project.

## 1. Analyze Project Structure

Gemini will start by listing all files in the project directory to get a complete overview of the repository. This ensures that all necessary files are in place before starting the deployment process.

## 2. Handle Secrets

1.  **Check for `.env` file**: Gemini will check if a `.env` file already exists.
2.  **Create `.env` file**: If `.env` does not exist, Gemini will copy `.env.example` to `.env`.
3.  **Prompt for Secrets**: Gemini will read the `.env` file and prompt the user to provide the values for the following required environment variables:
    *   `N8N_ENCRYPTION_KEY`
    *   `N8N_USER_MANAGEMENT_JWT_SECRET`
    *   `POSTGRES_PASSWORD`
    *   `JWT_SECRET`
    *   `ANON_KEY`
    *   `SERVICE_ROLE_KEY`
    *   `DASHBOARD_USERNAME`
    *   `DASHBOARD_PASSWORD`
    *   `POOLER_TENANT_ID`
    *   `NEO4J_AUTH`
    *   `CLICKHOUSE_PASSWORD`
    *   `MINIO_ROOT_PASSWORD`
    *   `LANGFUSE_SALT`
    *   `NEXTAUTH_SECRET`
    *   `ENCRYPTION_KEY`
4.  **Populate `.env` file**: Once the user provides the secrets, Gemini will populate the `.env` file with the provided values.

## 3. Execute Deployment

1.  **Determine Profile**: Gemini will ask the user about their GPU setup (Nvidia, AMD, or none) to determine the correct profile to use with the `start_services.py` script.
2.  **Run Deployment Script**: Gemini will execute the `start_services.py` script with the appropriate `--profile` flag. For this local deployment, the `--environment` will be set to `private`.

## 4. Verify Deployment

1.  **Check Docker Containers**: After the deployment script finishes, Gemini will run `docker ps` to check the status of the running containers and verify that all services have started correctly.
2.  **Provide Access URLs**: Gemini will provide the user with the local URLs to access the different services (n8n, Open WebUI, etc.).

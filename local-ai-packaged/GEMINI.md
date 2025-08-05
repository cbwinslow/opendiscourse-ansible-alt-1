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

## 5. Deployment Log

### 2025-08-05 - PRODUCTION DEPLOYMENT SUCCESSFUL ✅

**Objective:** Deploy the `local-ai-packaged` application to a Hetzner server at `95.217.106.172` and make it accessible via `opendiscourse.net`.

**🎯 DEPLOYMENT COMPLETED SUCCESSFULLY**

**Live Production URLs:**
- **N8N Workflow Platform**: https://n8n.opendiscourse.net
- **Open WebUI (Chat Interface)**: https://openwebui.opendiscourse.net  
- **Flowise (Low-code AI)**: https://flowise.opendiscourse.net
- **Langfuse (LLM Analytics)**: https://langfuse.opendiscourse.net
- **Supabase (Database & API)**: https://supabase.opendiscourse.net
- **SearXNG (Private Search)**: https://searxng.opendiscourse.net
- **Ollama API Server**: https://ollama.opendiscourse.net
- **Neo4j Graph Browser**: https://neo4j.opendiscourse.net

**🔧 Technical Implementation:**
1. **Custom Caddy Build**: Built Caddy with Cloudflare DNS plugin using `xcaddy` for SSL certificate management
2. **SSL Certificates**: Successfully obtained Let's Encrypt certificates via Cloudflare DNS-01 challenges
3. **Container Networking**: Fixed container communication by connecting Caddy to `localai_default` network
4. **Production Configuration**: Used CPU profile with public environment settings

**🛡️ Security Features:**
- SSL/TLS encryption for all services
- HTTP/2 and HTTP/3 support
- Proper security headers (HSTS, CSP, etc.)
- Cloudflare DNS protection

**📋 Deployment Steps Executed:**

**Initial Server Setup:**

1.  **User Creation:** Created a new user `cbwinslow` with `sudo` privileges to be used as the primary account instead of `root`.
2.  **SSH Configuration:** Set up SSH for the `cbwinslow` user, adding the user's public key to `~/.ssh/authorized_keys`.
3.  **Firewall Configuration:** Installed and configured `ufw` (Uncomplicated Firewall) to allow traffic on ports 22 (SSH), 80 (HTTP), and 443 (HTTPS).
4.  **Docker Installation:** Installed Docker and Docker Compose using the official convenience script. Added the `cbwinslow` user to the `docker` group to allow running Docker commands without `sudo`.

**Application Deployment:**

1.  **File Transfer:** Transferred the `local-ai-packaged` directory to the server by creating a tarball, copying it to the server, and then extracting it in the `cbwinslow` user's home directory.
2.  **Initial Service Start:** Ran the `start_services.py` script with the `none` profile and `private` environment. The services started successfully and were accessible via their local ports on the server.

**Domain and SSL Configuration:**

1.  **DNS Configuration:** The user configured the DNS records for `opendiscourse.net` and its subdomains to point to the server's IP address (`95.217.106.172`).
2.  **Caddy Configuration:** Updated the `.env` file with the hostnames for each service and the user's email for Let's Encrypt. The `Caddyfile` was confirmed to be correctly configured to use these environment variables.
3.  **SSL Certificate Issuance Issues:**
    *   **Cloudflare Proxy Issue:** The initial attempt to obtain SSL certificates failed with a `522` error from Cloudflare. This indicated that Cloudflare's proxy was preventing Let's Encrypt from reaching the server to verify domain ownership.
    *   **Firewall Issue:** To resolve this, the firewall was configured to allow traffic from Cloudflare's IP ranges. However, the issue persisted.
    *   **Rate Limiting:** After multiple failed attempts, Let's Encrypt rate-limited the server, preventing further certificate requests for a period of time.
    *   **Firewall Disabled:** The firewall was temporarily disabled to rule out any firewall-related issues. However, the rate limit was still in effect.
4.  **Caddy DNS Challenge:**
    *   Updated the `docker-compose.yml` to use the `caddy:2-builder` image which includes the Cloudflare DNS module.
    *   Updated the `Caddyfile` to use the `dns` challenge.
    *   Added the Cloudflare API token to the `.env` file.
    *   The `tls-alpn-01` challenge continued to fail, and it did not fall back to the `dns-01` challenge.
    *   Forced the `dns-01` challenge by adding `acme_dns cloudflare {$CLOUDFLARE_API_TOKEN}` to the global options in the `Caddyfile`.

**Current Status:**

*   The application services are running on the server.
*   The firewall has been re-enabled.
*   The Cloudflare proxy has been re-enabled.
*   We are currently waiting for the Let's Encrypt rate limit to expire before attempting to obtain the SSL certificates again.

**Next Steps:**

1.  Wait for the Let's Encrypt rate limit to expire (approximately one hour from the last attempt).
2.  Temporarily disable the Cloudflare proxy.
3.  Restart the services using `start_services.py --profile cpu --environment public` to trigger a new SSL certificate request.
4.  Once the certificates are obtained, re-enable the Cloudflare proxy.
5.  Verify that all services are accessible via their respective domain names with HTTPS.
6.  Configure OAuth in the Supabase dashboard.

**Important Notes:**

*   Always use the `start_services.py` script to start and stop the services.
*   When deploying to a public environment, always use the `--environment public` flag.

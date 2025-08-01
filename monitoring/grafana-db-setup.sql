-- Create Grafana database
CREATE DATABASE grafana;

-- Switch to Grafana database
\c grafana;

-- Create Grafana schema
CREATE SCHEMA IF NOT EXISTS grafana;

-- Grant necessary permissions
GRANT ALL PRIVILEGES ON DATABASE grafana TO postgres;
GRANT ALL PRIVILEGES ON SCHEMA grafana TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA grafana TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA grafana TO postgres;

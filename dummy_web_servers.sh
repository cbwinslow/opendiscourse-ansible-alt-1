#!/bin/bash
# dummy_web_servers.sh
# Starts dummy HTTP and HTTPS servers on ports 80 and 443 to suppress connection errors

# Function to stop servers
stop_servers() {
  echo "Stopping dummy servers..."
  pkill -f "python3 -m http.server 80" || true
  pkill -f "python3 -c.*http.server.*443" || true
  echo "Dummy servers stopped."
  exit 0
}

# Trap Ctrl+C to stop servers gracefully
trap stop_servers INT TERM

set -e

# Check for root privileges
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root to bind to ports 80 and 443."
  echo "Try: sudo bash dummy_web_servers.sh"
  exit 1
fi

# Start dummy HTTP server on port 80
nohup python3 -m http.server 80 --bind 127.0.0.1 > /tmp/dummy_http.log 2>&1 &
echo "Started dummy HTTP server on port 80 (PID $!)"

# Start dummy HTTPS server on port 443 (self-signed cert)
# Generate cert if not exists
CERT=/tmp/dummy_https.pem
KEY=/tmp/dummy_https.key
if [[ ! -f $CERT || ! -f $KEY ]]; then
  openssl req -x509 -newkey rsa:2048 -keyout $KEY -out $CERT -days 1 -nodes -subj "/CN=localhost"
fi
nohup python3 -c "import http.server, ssl; server = http.server.HTTPServer(('127.0.0.1', 443), http.server.SimpleHTTPRequestHandler); server.socket = ssl.wrap_socket(server.socket, certfile='$CERT', keyfile='$KEY', server_side=True); server.serve_forever()" > /tmp/dummy_https.log 2>&1 &
echo "Started dummy HTTPS server on port 443 (PID $!)"

echo "Dummy servers running. Errors from localhost:80/443 should now be suppressed."
echo "Press Ctrl+C to stop servers."

# Wait indefinitely
while true; do
  sleep 60
done

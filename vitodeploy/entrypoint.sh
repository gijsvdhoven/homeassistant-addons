#!/usr/bin/env bash
set -euo pipefail

# Generate .env from add-on options
cat <<EOF >/var/www/html/.env
APP_KEY=${APP_KEY:-your-32-character-app-key}
NAME=${NAME:-vito}
EMAIL=${EMAIL:-vito@example.com}
PASSWORD=${PASSWORD:-password}
APP_URL=${APP_URL:-http://localhost:8000}
EOF

echo "Starting Vito web server..."
exec apache2ctl -D FOREGROUND

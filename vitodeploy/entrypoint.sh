#!/usr/bin/env sh
set -euo pipefail

# Generate .env from add-on options
cat <<EOF >/var/www/html/.env
APP_KEY=${APP_KEY:-your-32-character-app-key}
NAME=${NAME:-vito}
EMAIL=${EMAIL:-vito@example.com}
PASSWORD=${PASSWORD:-password}
APP_URL=${APP_URL:-http://localhost:8000}
EOF

# Configure Apache for PHP
cat <<EOF >/etc/apache2/conf.d/vito.conf
<Directory "/var/www/html">
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
</Directory>

# PHP configuration
LoadModule php_module /usr/lib/apache2/mod_php83.so
AddType application/x-httpd-php .php
DirectoryIndex index.php index.html
EOF

echo "Starting Vito web server..."
exec httpd -D FOREGROUND

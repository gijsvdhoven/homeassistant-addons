#!/bin/bash

# Check if running with ingress
if command -v bashio &> /dev/null; then
    # Get ingress interface if available
    if bashio::addon.ingress_entry; then
        INGRESS_ENTRY=$(bashio::addon.ingress_entry)
        echo "Ingress enabled with entry: ${INGRESS_ENTRY}"
    fi
    
    # Generate .env from add-on options
    APP_URL=$(bashio::config 'app_url')
    
    # If ingress is enabled, use the ingress URL
    if bashio::var.has_value "${INGRESS_ENTRY}"; then
        # For ingress, we need to set the proper base URL
        APP_URL="/api/hassio_ingress/$(bashio::addon.slug)"
    fi
    
    cat <<EOF >/var/www/html/.env
APP_KEY=$(bashio::config 'app_key')
NAME=$(bashio::config 'name')
EMAIL=$(bashio::config 'email')
PASSWORD=$(bashio::config 'password')
APP_URL=${APP_URL}
EOF
else
    # Fallback for local testing
    cat <<EOF >/var/www/html/.env
APP_KEY=${APP_KEY:-your-32-character-app-key}
NAME=${NAME:-vito}
EMAIL=${EMAIL:-vito@example.com}
PASSWORD=${PASSWORD:-password}
APP_URL=${APP_URL:-http://localhost:8000}
EOF
fi

# Configure Apache for PHP and Ingress
cat <<EOF >/etc/apache2/conf.d/vito.conf
ServerName localhost
DocumentRoot "/var/www/html/public"

<Directory "/var/www/html">
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
</Directory>

<Directory "/var/www/html/public">
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
    
    # Laravel rewrite rules
    RewriteEngine On
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteRule ^ index.php [L]
</Directory>

# PHP configuration
LoadModule php_module /usr/lib/apache2/mod_php83.so
LoadModule rewrite_module /usr/lib/apache2/mod_rewrite.so
AddType application/x-httpd-php .php
DirectoryIndex index.php index.html

# Ingress proxy headers
<IfModule mod_headers.c>
    RequestHeader set X-Forwarded-Proto "https"
    RequestHeader set X-Forwarded-Port "443"
</IfModule>
EOF

# Enable Apache modules
echo "LoadModule rewrite_module /usr/lib/apache2/mod_rewrite.so" >> /etc/apache2/httpd.conf
echo "LoadModule headers_module /usr/lib/apache2/mod_headers.so" >> /etc/apache2/httpd.conf

# Create a basic .htaccess for Laravel if it doesn't exist
if [ ! -f /var/www/html/public/.htaccess ]; then
    cat <<'EOF' >/var/www/html/public/.htaccess
<IfModule mod_rewrite.c>
    <IfModule mod_negotiation.c>
        Options -MultiViews -Indexes
    </IfModule>

    RewriteEngine On

    # Handle Authorization Header
    RewriteCond %{HTTP:Authorization} .
    RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]

    # Redirect Trailing Slashes If Not A Folder...
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteCond %{REQUEST_URI} (.+)/$
    RewriteRule ^ %1 [L,R=301]

    # Send Requests To Front Controller...
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteRule ^ index.php [L]
</IfModule>
EOF
fi

# Check if Vito needs initial setup
if [ ! -f /var/www/html/.env ]; then
    echo "First run - setting up Vito..."
    cd /var/www/html
    
    # Install composer if needed
    if [ ! -f /var/www/html/composer.phar ]; then
        php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
        php composer-setup.php
        php -r "unlink('composer-setup.php');"
    fi
    
    # Install dependencies
    php composer.phar install --no-dev --optimize-autoloader || true
    
    # Generate application key if not provided
    php artisan key:generate || true
fi

# Set permissions
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html
chmod -R 777 /var/www/html/storage
chmod -R 777 /var/www/html/bootstrap/cache || true

echo "Starting Vito web server..."

# Run Apache in foreground
exec httpd -D FOREGROUND -f /etc/apache2/httpd.conf
#!/bin/bash#!/bin/bash#!/bin/bash



echo "=== Vito Home Assistant Add-on (Laravel Sail) ==="



# Set environment variablesecho "=== Vito Home Assistant Add-on Starting ==="echo "=== Vito Home Assistant Add-on Starting ==="

export HOME=/root

export COMPOSER_HOME=/root/.composer



# Source bashio library# Set environment variables for Composer# Set environment variables for Composer

if [ -f /usr/lib/bashio/bashio.sh ]; then

    source /usr/lib/bashio/bashio.shexport HOME=/rootexport HOME=/root

fi

export COMPOSER_HOME=/root/.composerexport COMPOSER_HOME=/root/.composer

# Setup persistent directories

PERSISTENT_DIR="/data"

echo "Setting up persistent directories..."

mkdir -p "${PERSISTENT_DIR}/storage"# Source bashio library if available# Source bashio library if available

mkdir -p "${PERSISTENT_DIR}/ssh-keys"

mkdir -p "${PERSISTENT_DIR}/mysql"if [ -f /usr/lib/bashio/bashio.sh ]; thenif [ -f /usr/lib/bashio/bashio.sh ]; then

mkdir -p "${PERSISTENT_DIR}/redis"

    source /usr/lib/bashio/bashio.sh    source /usr/lib/bashio/bashio.sh

# Load configuration from Home Assistant

echo "Loading configuration..."fifi

NAME=$(bashio::config 'name' 2>/dev/null || echo "Vito Admin")

EMAIL=$(bashio::config 'email' 2>/dev/null || echo "admin@example.com")

PASSWORD=$(bashio::config 'password' 2>/dev/null || echo "password")

APP_URL=$(bashio::config 'app_url' 2>/dev/null || echo "http://homeassistant.local:8089")# Setup persistent directories# Setup persistent directories



echo "Configuration:"PERSISTENT_DIR="/data"PERSISTENT_DIR="/data"

echo "  Admin Name: $NAME"

echo "  Admin Email: $EMAIL"echo "Setting up persistent directories..."echo "Setting up persistent directories..."

echo "  App URL: $APP_URL"

mkdir -p "${PERSISTENT_DIR}/storage"mkdir -p "${PERSISTENT_DIR}/storage"

# Start Docker daemon

echo "Starting Docker daemon..."mkdir -p "${PERSISTENT_DIR}/ssh-keys"mkdir -p "${PERSISTENT_DIR}/ssh-keys"

dockerd &

sleep 5



# Wait for Docker to be ready# Load configuration from Home Assistant# Load configuration from Home Assistant

echo "Waiting for Docker to be ready..."

timeout=30echo "Loading configuration..."echo "Loading configuration..."

while [ $timeout -gt 0 ] && ! docker info >/dev/null 2>&1; do

    echo "  Waiting for Docker... ($timeout seconds left)"NAME=$(bashio::config 'name' 2>/dev/null || echo "Vito Admin")NAME=$(bashio::config 'name' 2>/dev/null || echo "Vito Admin")

    sleep 2

    timeout=$((timeout - 2))EMAIL=$(bashio::config 'email' 2>/dev/null || echo "admin@example.com")  EMAIL=$(bashio::config 'email' 2>/dev/null || echo "admin@example.com")  

done

PASSWORD=$(bashio::config 'password' 2>/dev/null || echo "password")PASSWORD=$(bashio::config 'password' 2>/dev/null || echo "password")

if ! docker info >/dev/null 2>&1; then

    echo "❌ Docker failed to start!"APP_URL=$(bashio::config 'app_url' 2>/dev/null || echo "http://homeassistant.local:8089")APP_URL=$(bashio::config 'app_url' 2>/dev/null || echo "http://homeassistant.local:8089")

    exit 1

fi



echo "✅ Docker is ready"echo "Configuration:"echo "Configuration:"



# Setup Vito environmentecho "  Admin Name: $NAME"echo "  Admin Name: $NAME"

echo "Setting up Vito environment..."

cd /var/www/htmlecho "  Admin Email: $EMAIL"echo "  Admin Email: $EMAIL"



# Generate SSH keys for server management (required by Vito)echo "  App URL: $APP_URL"echo "  App URL: $APP_URL"

echo "Setting up SSH keys..."

SSH_PRIVATE_KEY="${PERSISTENT_DIR}/ssh-keys/ssh-private.pem"

SSH_PUBLIC_KEY="${PERSISTENT_DIR}/ssh-keys/ssh-public.key"

# Generate SSH keys for server management (required by Vito)# Generate or retrieve app key

if [ ! -f "$SSH_PRIVATE_KEY" ]; then

    echo "Generating SSH key pair for server management..."echo "Setting up SSH keys..."APP_KEY_FILE="${PERSISTENT_DIR}/app_key"

    openssl genpkey -algorithm RSA -out "$SSH_PRIVATE_KEY"

    chmod 600 "$SSH_PRIVATE_KEY"SSH_PRIVATE_KEY="${PERSISTENT_DIR}/ssh-keys/ssh-private.pem"if [ ! -f "${APP_KEY_FILE}" ]; then

    ssh-keygen -y -f "$SSH_PRIVATE_KEY" > "$SSH_PUBLIC_KEY"

    echo "SSH keys generated and stored persistently"SSH_PUBLIC_KEY="${PERSISTENT_DIR}/ssh-keys/ssh-public.key"    echo "Generating new app key..."

else

    echo "Using existing SSH keys"    # Try OpenSSL first, fallback to PHP if not available

fi

if [ ! -f "$SSH_PRIVATE_KEY" ]; then    if command -v openssl &> /dev/null; then

# Link persistent storage

if [ ! -L /var/www/html/storage ]; then    echo "Generating SSH key pair for server management..."        APP_KEY="base64:$(openssl rand -base64 32)"

    rm -rf /var/www/html/storage

    ln -sf "${PERSISTENT_DIR}/storage" /var/www/html/storage    openssl genpkey -algorithm RSA -out "$SSH_PRIVATE_KEY"    else

fi

    chmod 600 "$SSH_PRIVATE_KEY"        echo "OpenSSL not available, using PHP for key generation..."

# Ensure storage structure exists

mkdir -p "${PERSISTENT_DIR}/storage"/{app,framework,logs}    ssh-keygen -y -f "$SSH_PRIVATE_KEY" > "$SSH_PUBLIC_KEY"        APP_KEY="base64:$(php -r 'echo base64_encode(random_bytes(32));')"

mkdir -p "${PERSISTENT_DIR}/storage/framework"/{cache,sessions,views,testing}

    echo "SSH keys generated and stored persistently"    fi

# Link SSH keys to Vito storage directory

ln -sf "$SSH_PRIVATE_KEY" "${PERSISTENT_DIR}/storage/ssh-private.pem"else    echo "${APP_KEY}" > "${APP_KEY_FILE}"

ln -sf "$SSH_PUBLIC_KEY" "${PERSISTENT_DIR}/storage/ssh-public.key"

    echo "Using existing SSH keys"    echo "App key saved to persistent storage"

# Setup environment file for Sail

echo "Setting up Vito environment file..."fielse

if [ -f .env.sail ]; then

    cp .env.sail .env    APP_KEY=$(cat "${APP_KEY_FILE}")

    echo "Using .env.sail as base configuration"

else# Setup Vito environment following official documentation    echo "Using existing app key from persistent storage"

    echo "No .env.sail found, creating .env from .env.example"

    if [ -f .env.example ]; thenecho "Setting up Vito environment..."fi

        cp .env.example .env

    elsecd /var/www/html

        echo "Creating basic .env file"

        cat <<EOF >.env# Generate or use persistent .env file

APP_NAME=Vito

APP_ENV=production# Link persistent storage to Laravel storage directoryENV_FILE="${PERSISTENT_DIR}/config/.env"

APP_KEY=

APP_DEBUG=falseif [ ! -L /var/www/html/storage ]; thenif [ ! -f "${ENV_FILE}" ]; then

APP_URL=${APP_URL}

APP_TIMEZONE=UTC    rm -rf /var/www/html/storage    echo "Generating new .env file..."



LOG_CHANNEL=stack    ln -sf "${PERSISTENT_DIR}/storage" /var/www/html/storage    # Generate .env file

LOG_DEPRECATIONS_CHANNEL=null

LOG_LEVEL=debugfi    cat <<EOF >"${ENV_FILE}"



DB_CONNECTION=sqliteAPP_NAME=Vito

DB_DATABASE=/var/www/html/storage/database.sqlite

# Ensure storage structure existsAPP_ENV=production

BROADCAST_DRIVER=log

CACHE_DRIVER=filemkdir -p "${PERSISTENT_DIR}/storage"/{app,framework,logs}APP_KEY=${APP_KEY}

FILESYSTEM_DISK=local

QUEUE_CONNECTION=syncmkdir -p "${PERSISTENT_DIR}/storage/framework"/{cache,sessions,views,testing}APP_DEBUG=false

SESSION_DRIVER=file

SESSION_LIFETIME=120APP_URL=${APP_URL}



MAIL_MAILER=log# Link SSH keys to Vito storage directoryAPP_TIMEZONE=UTC

MAIL_HOST=localhost

MAIL_PORT=1025ln -sf "$SSH_PRIVATE_KEY" "${PERSISTENT_DIR}/storage/ssh-private.pem"

MAIL_USERNAME=null

MAIL_PASSWORD=nullln -sf "$SSH_PUBLIC_KEY" "${PERSISTENT_DIR}/storage/ssh-public.key"LOG_CHANNEL=stack

MAIL_ENCRYPTION=null

MAIL_FROM_ADDRESS="hello@example.com"LOG_LEVEL=info

MAIL_FROM_NAME="\${APP_NAME}"

# Use Vito's sail environment as base and customize

VITE_APP_NAME="\${APP_NAME}"

EOFif [ -f .env.sail ]; thenDB_CONNECTION=sqlite

    fi

fi    cp .env.sail .envDB_DATABASE=database.sqlite



# Customize environment for add-on    echo "Using .env.sail as base configuration"

sed -i "s|^APP_URL=.*|APP_URL=${APP_URL}|" .env

sed -i "s|^DB_CONNECTION=.*|DB_CONNECTION=sqlite|" .envelseBROADCAST_DRIVER=log

sed -i "s|^DB_DATABASE=.*|DB_DATABASE=/var/www/html/storage/database.sqlite|" .env

    echo "No .env.sail found, creating basic .env"CACHE_DRIVER=file

# Generate application key

echo "Generating application key..."    cat <<EOF >.envFILESYSTEM_DRIVER=local

php artisan key:generate --force

APP_NAME=VitoQUEUE_CONNECTION=sync

# Create database file

echo "Setting up database..."APP_ENV=productionSESSION_DRIVER=file

touch /var/www/html/storage/database.sqlite

chmod 666 /var/www/html/storage/database.sqliteAPP_DEBUG=falseSESSION_LIFETIME=120



# Install dependencies if not presentAPP_URL=${APP_URL}

if [ ! -d "vendor" ]; then

    echo "Installing Composer dependencies..."APP_TIMEZONE=UTCMAIL_MAILER=log

    composer install --no-dev --optimize-autoloader

fiMAIL_HOST=localhost



# Install npm dependencies and build assets if neededLOG_CHANNEL=stackMAIL_PORT=587

if [ -f "package.json" ] && [ ! -d "node_modules" ]; then

    echo "Installing npm dependencies..."LOG_DEPRECATIONS_CHANNEL=nullMAIL_USERNAME=null

    npm ci

fiLOG_LEVEL=debugMAIL_PASSWORD=null



if [ -f "vite.config.js" ] && [ ! -d "public/build" ]; thenMAIL_ENCRYPTION=null

    echo "Building frontend assets..."

    npm run buildDB_CONNECTION=sqliteMAIL_FROM_ADDRESS="noreply@vito.dev"

fi

DB_DATABASE=/var/www/html/storage/database.sqliteMAIL_FROM_NAME="Vito"

# Run migrations

echo "Running database migrations..."

php artisan migrate --force

BROADCAST_DRIVER=logADMIN_NAME=${NAME}

# Setup admin user

echo "Setting up admin user..."CACHE_DRIVER=fileADMIN_EMAIL=${EMAIL}

USER_COUNT=$(php artisan tinker --execute="echo App\Models\User::count();" 2>/dev/null | tail -n1 || echo "0")

if [ "$USER_COUNT" = "0" ] || [ "$USER_COUNT" = "" ]; thenFILESYSTEM_DISK=localADMIN_PASSWORD=${PASSWORD}

    echo "Creating admin user..."

    # Try the official user:create command firstQUEUE_CONNECTION=syncEOF

    if php artisan user:create "$NAME" "$EMAIL" "$PASSWORD" 2>/dev/null; then

        echo "✅ Admin user created successfully with user:create command"SESSION_DRIVER=file    echo ".env file created and saved to persistent storage"

    else

        echo "Using tinker to create admin user..."SESSION_LIFETIME=120else

        php artisan tinker --execute="

            \$user = new App\Models\User();    echo "Using existing .env file from persistent storage"

            \$user->name = '$NAME';

            \$user->email = '$EMAIL';MEMCACHED_HOST=127.0.0.1    # Update dynamic values in existing .env

            \$user->password = Hash::make('$PASSWORD');

            \$user->save();    sed -i "s|^APP_URL=.*|APP_URL=${APP_URL}|" "${ENV_FILE}"

            echo '✅ Admin user created successfully with tinker';

        "REDIS_HOST=127.0.0.1    sed -i "s|^DB_DATABASE=.*|DB_DATABASE=database.sqlite|" "${ENV_FILE}"

    fi

elseREDIS_PASSWORD=null    sed -i "s|^ADMIN_NAME=.*|ADMIN_NAME=${NAME}|" "${ENV_FILE}"

    echo "✅ Admin user already exists"

fiREDIS_PORT=6379    sed -i "s|^ADMIN_EMAIL=.*|ADMIN_EMAIL=${EMAIL}|" "${ENV_FILE}"



# Set permissions    sed -i "s|^ADMIN_PASSWORD=.*|ADMIN_PASSWORD=${PASSWORD}|" "${ENV_FILE}"

chown -R www-data:www-data /var/www/html

chown -R www-data:www-data "${PERSISTENT_DIR}"MAIL_MAILER=smtp

chmod -R 755 /var/www/html

chmod -R 777 "${PERSISTENT_DIR}/storage"MAIL_HOST=mailpit    



echo ""MAIL_PORT=1025    # Ensure required variables exist (add if missing)

echo "🎉 Vito is ready!"

echo "📧 Admin Email: $EMAIL"MAIL_USERNAME=null    grep -q "^APP_TIMEZONE=" "${ENV_FILE}" || echo "APP_TIMEZONE=UTC" >> "${ENV_FILE}"

echo "🔑 Admin Password: $PASSWORD"

echo "🌐 Access URL: $APP_URL"MAIL_PASSWORD=null    grep -q "^MAIL_MAILER=" "${ENV_FILE}" || echo "MAIL_MAILER=log" >> "${ENV_FILE}"

echo ""

MAIL_ENCRYPTION=null    grep -q "^MAIL_FROM_ADDRESS=" "${ENV_FILE}" || echo 'MAIL_FROM_ADDRESS="noreply@vito.dev"' >> "${ENV_FILE}"

# Check if Sail is available

if [ -f "./vendor/bin/sail" ]; thenMAIL_FROM_ADDRESS="hello@example.com"fi

    echo "🚢 Starting with Laravel Sail..."

    MAIL_FROM_NAME="\${APP_NAME}"

    # Export necessary environment variables for Sail

    export WWWUSER=1000# Link .env file to Laravel directory

    export WWWGROUP=1000

    AWS_ACCESS_KEY_ID=ln -sf "${ENV_FILE}" /var/www/html/.env

    # Start Laravel Sail (this will start the web server)

    ./vendor/bin/sail up --no-deps laravel.testAWS_SECRET_ACCESS_KEY=

else

    echo "⚠️  Sail not found, starting with PHP built-in server..."AWS_DEFAULT_REGION=us-east-1# Debug: Show .env file contents and database path

    

    # Optimize LaravelAWS_BUCKET=echo "=== .env file contents ==="

    php artisan config:cache

    php artisan route:cacheAWS_USE_PATH_STYLE_ENDPOINT=falsecat /var/www/html/.env | grep -E "(DB_DATABASE|APP_KEY|APP_URL)" || echo "Could not read .env file"

    php artisan view:cache

    echo "=========================="

    # Start PHP built-in server as fallback

    php artisan serve --host=0.0.0.0 --port=8000PUSHER_APP_ID=

fi
PUSHER_APP_KEY=# Configure Apache for PHP and Ingress

PUSHER_APP_SECRET=cat <<EOF >/etc/apache2/conf.d/vito.conf

PUSHER_HOST=ServerName localhost

PUSHER_PORT=443DocumentRoot "/var/www/html/public"

PUSHER_SCHEME=https

PUSHER_APP_CLUSTER=mt1<Directory "/var/www/html">

    Options FollowSymLinks

VITE_APP_NAME="\${APP_NAME}"    AllowOverride All

VITE_PUSHER_APP_KEY="\${PUSHER_APP_KEY}"    Require all granted

VITE_PUSHER_HOST="\${PUSHER_HOST}"</Directory>

VITE_PUSHER_PORT="\${PUSHER_PORT}"

VITE_PUSHER_SCHEME="\${PUSHER_SCHEME}"<Directory "/var/www/html/public">

VITE_PUSHER_APP_CLUSTER="\${PUSHER_APP_CLUSTER}"    Options FollowSymLinks

EOF    AllowOverride All

fi    Require all granted

</Directory>

# Customize environment for add-on

sed -i "s|^APP_URL=.*|APP_URL=${APP_URL}|" .env# PHP configuration

sed -i "s|^DB_DATABASE=.*|DB_DATABASE=/var/www/html/storage/database.sqlite|" .envAddType application/x-httpd-php .php

DirectoryIndex index.php index.html

# Generate application key if neededEOF

echo "Generating application key..."

php artisan key:generate --force# Enable Apache modules (check if not already enabled)

if ! grep -q "^LoadModule rewrite_module" /etc/apache2/httpd.conf; then

# Create database file    echo "LoadModule rewrite_module /usr/lib/apache2/mod_rewrite.so" >> /etc/apache2/httpd.conf

echo "Setting up database..."fi

touch /var/www/html/storage/database.sqliteif ! grep -q "^LoadModule headers_module" /etc/apache2/httpd.conf; then

    echo "LoadModule headers_module /usr/lib/apache2/mod_headers.so" >> /etc/apache2/httpd.conf

# Run migrationsfi

echo "Running database migrations..."

php artisan migrate --force# Create .htaccess for Laravel

cat <<'EOF' >/var/www/html/public/.htaccess

# Check if admin user exists, create if not<IfModule mod_rewrite.c>

echo "Setting up admin user..."    <IfModule mod_negotiation.c>

USER_COUNT=$(php artisan tinker --execute="echo App\Models\User::count();" 2>/dev/null | tail -n1 || echo "0")        Options -MultiViews -Indexes

if [ "$USER_COUNT" = "0" ] || [ "$USER_COUNT" = "" ]; then    </IfModule>

    echo "Creating admin user..."

    php artisan user:create "$NAME" "$EMAIL" "$PASSWORD" 2>/dev/null || {    RewriteEngine On

        echo "user:create command not found, using tinker..."

        php artisan tinker --execute="    # Handle Authorization Header

            \$user = new App\Models\User();    RewriteCond %{HTTP:Authorization} .

            \$user->name = '$NAME';    RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]

            \$user->email = '$EMAIL';

            \$user->password = Hash::make('$PASSWORD');    # Redirect Trailing Slashes If Not A Folder...

            \$user->save();    RewriteCond %{REQUEST_FILENAME} !-d

            echo 'Admin user created successfully';    RewriteCond %{REQUEST_URI} (.+)/$

        "    RewriteRule ^ %1 [L,R=301]

    }

else    # Handle Front Controller...

    echo "Admin user already exists"    RewriteCond %{REQUEST_FILENAME} !-d

fi    RewriteCond %{REQUEST_FILENAME} !-f

    RewriteRule ^ index.php [L]

# Clear and optimize caches</IfModule>

echo "Optimizing application..."EOF

php artisan config:cache

php artisan route:cache# Install Vito dependencies if not already installed

php artisan view:cacheif [ ! -f /var/www/html/vendor/autoload.php ]; then

    echo "Installing Vito dependencies..."

# Set proper permissions    cd /var/www/html

echo "Setting permissions..."    

chown -R apache:apache /var/www/html    # Install Composer dependencies

chown -R apache:apache "${PERSISTENT_DIR}"    if command -v composer &> /dev/null; then

chmod -R 755 /var/www/html        composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist

chmod -R 777 "${PERSISTENT_DIR}/storage"    fi

chmod 666 "/var/www/html/storage/database.sqlite"fi



# Configure Apache for PHP# Setup Laravel application

cat <<EOF >/etc/apache2/conf.d/vito.confif [ -f /var/www/html/artisan ] && [ -f /var/www/html/vendor/autoload.php ]; then

ServerName localhost    cd /var/www/html

DocumentRoot "/var/www/html/public"    

    # Link persistent storage to Laravel storage directory

<Directory "/var/www/html">    if [ ! -L /var/www/html/storage ]; then

    Options FollowSymLinks        rm -rf /var/www/html/storage

    AllowOverride All        ln -sf "${PERSISTENT_DIR}/storage" /var/www/html/storage

    Require all granted    fi

</Directory>    

    # Link persistent bootstrap cache

<Directory "/var/www/html/public">    if [ ! -L /var/www/html/bootstrap/cache ]; then

    Options FollowSymLinks        rm -rf /var/www/html/bootstrap/cache

    AllowOverride All        ln -sf "${PERSISTENT_DIR}/bootstrap/cache" /var/www/html/bootstrap/cache

    Require all granted    fi

</Directory>    

    # Ensure storage structure exists

AddType application/x-httpd-php .php    mkdir -p "${PERSISTENT_DIR}/storage"/{app,framework,logs}

DirectoryIndex index.php index.html    mkdir -p "${PERSISTENT_DIR}/storage/framework"/{cache,sessions,views,testing}

EOF    

    # Create database file in storage directory

# Enable Apache modules    touch "${PERSISTENT_DIR}/storage/database.sqlite"

echo "LoadModule rewrite_module /usr/lib/apache2/mod_rewrite.so" >> /etc/apache2/httpd.conf    

echo "LoadModule headers_module /usr/lib/apache2/mod_headers.so" >> /etc/apache2/httpd.conf    # Test database connection before migration

    echo "Testing database connection..."

echo ""    DB_PATH="${PERSISTENT_DIR}/storage/database.sqlite"

echo "🎉 Vito is ready!"    if [ -f "$DB_PATH" ]; then

echo "📧 Admin Email: $EMAIL"        echo "Database file exists at: $DB_PATH"

echo "🔑 Admin Password: $PASSWORD"          ls -la "$DB_PATH"

echo "🌐 Access URL: $APP_URL"        echo "Laravel should see it as: database.sqlite (relative to storage directory)"

echo ""        echo "Actual Laravel storage path: /var/www/html/storage/"

echo "Starting Apache web server..."        ls -la /var/www/html/storage/database.sqlite 2>/dev/null || echo "Symlink check failed"

    else

# Run Apache in foreground        echo "ERROR: Database file not found at: $DB_PATH"

exec httpd -D FOREGROUND -f /etc/apache2/httpd.conf    fi
    
    # Migrate database
    php artisan migrate --force 2>/dev/null || true
    
    # Check if we need to create an admin user
    echo "Checking for admin user..."
    USER_COUNT=$(php artisan tinker --execute="echo App\Models\User::count();" 2>/dev/null || echo "0")
    if [ "$USER_COUNT" = "0" ]; then
        echo "Creating admin user..."
        php artisan tinker --execute="
            \$user = new App\Models\User();
            \$user->name = '$NAME';
            \$user->email = '$EMAIL';
            \$user->password = Hash::make('$PASSWORD');
            \$user->save();
            echo 'Admin user created: ' . \$user->email;
        " 2>/dev/null || echo "Could not create admin user"
    else
        echo "Admin user already exists (user count: $USER_COUNT)"
    fi
    
    # Cache configuration
    php artisan config:clear
    php artisan cache:clear
    php artisan view:clear
    php artisan route:clear
    
    # Generate application key if needed
    if ! grep -q "APP_KEY=base64:" /var/www/html/.env; then
        echo "Generating application key..."
        php artisan key:generate --force
    fi
    
    # Check if frontend assets need to be built
    if [ ! -d "/var/www/html/public/build" ] && [ -f "/var/www/html/package.json" ]; then
        echo "Frontend assets missing, checking if we can build them..."
        if command -v npm >/dev/null 2>&1; then
            echo "Building frontend assets with npm..."
            cd /var/www/html
            npm install --production 2>/dev/null || echo "npm install failed"
            npm run build 2>/dev/null || echo "npm run build failed" 
        else
            echo "npm not available, frontend assets will need to be pre-built"
        fi
    fi
fi

# Set proper permissions
chown -R apache:apache /var/www/html
chown -R apache:apache "${PERSISTENT_DIR}"
chmod -R 755 /var/www/html
chmod -R 777 "${PERSISTENT_DIR}/storage" 2>/dev/null || true
chmod -R 777 "${PERSISTENT_DIR}/bootstrap/cache" 2>/dev/null || true
chmod -R 755 "${PERSISTENT_DIR}/config" 2>/dev/null || true
chmod 666 "${PERSISTENT_DIR}/storage/database.sqlite" 2>/dev/null || true

echo "Starting Vito web server on port 80..."

# Debug Apache and Laravel setup
echo "=== Apache and Laravel Debug ==="
echo "Document root contents:"
ls -la /var/www/html/public/ | head -10
echo ""
echo "Checking key Laravel files:"
test -f /var/www/html/public/index.php && echo "✓ index.php exists" || echo "✗ index.php missing"
test -f /var/www/html/artisan && echo "✓ artisan exists" || echo "✗ artisan missing"  
test -f /var/www/html/vendor/autoload.php && echo "✓ vendor/autoload.php exists" || echo "✗ vendor/autoload.php missing"
test -f /var/www/html/.env && echo "✓ .env exists" || echo "✗ .env missing"
echo ""
echo "Checking frontend assets:"
ls -la /var/www/html/public/build/ 2>/dev/null | head -5 || echo "No build directory found"
ls -la /var/www/html/public/css/ 2>/dev/null | head -3 || echo "No css directory found"  
ls -la /var/www/html/public/js/ 2>/dev/null | head -3 || echo "No js directory found"
echo ""
echo "Laravel routes check:"
cd /var/www/html
php artisan route:list 2>/dev/null | head -5 || echo "Could not list routes"
echo ""
echo "Apache config test:"
httpd -t -f /etc/apache2/httpd.conf
echo ""
echo "Testing web server after startup (in background):"
{
    sleep 5  # Wait for Apache to start
    echo "Testing homepage..."
    curl -s -o /tmp/test_response.html -w "HTTP Status: %{http_code}\n" http://localhost/ || echo "Could not connect to localhost"
    echo "Response size: $(wc -c < /tmp/test_response.html 2>/dev/null || echo '0') bytes"
    
    echo "Testing direct PHP file:"
    curl -s -w "HTTP Status: %{http_code}\n" http://localhost/index.php || echo "Could not connect to index.php"
    
    echo "Checking Apache error log:"
    tail -n 5 /var/log/apache2/error.log 2>/dev/null || echo "No error log found"
} &
echo "Background test started..."
echo "================================"

# Run Apache in foreground
exec httpd -D FOREGROUND -f /etc/apache2/httpd.conf
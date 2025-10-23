# Vito Home Assistant Add-on (with Ingress Support)

This add-on brings Vito server management interface to Home Assistant with full Ingress support.

## Features
- ✅ Full Home Assistant Ingress support (access through HA sidebar)
- ✅ Works with Alpine Linux base image
- ✅ Automatic configuration through HA options
- ✅ No "s6-overlay PID 1" errors
- ✅ Laravel/Vito compatible Apache configuration
- ✅ Persistent storage support

## Installation

1. **Copy files to your Home Assistant add-ons folder:**
   ```
   /addons/vitodeploy/
   ├── config.yaml
   ├── Dockerfile
   └── run.sh
   ```

2. **Reload Add-on Store:**
   - Go to Settings → Add-ons → Add-on Store
   - Click ⋮ (three dots) → Check for updates

3. **Install the add-on:**
   - Find "Vito" in Local add-ons
   - Click Install

## Configuration

### Basic Options:
```yaml
app_key: "base64:YOUR-32-CHARACTER-KEY-HERE"  # Generate with: openssl rand -base64 32
name: "vito"
email: "admin@example.com"
password: "your-secure-password"
app_url: "http://homeassistant.local:8123"  # Your HA URL
```

### Access Methods:

1. **Via Ingress (Recommended):**
   - Enable "Show in sidebar" in add-on configuration
   - Access through Home Assistant sidebar

2. **Direct Access (Optional):**
   - Configure a port in the add-on Network settings
   - Access at: `http://homeassistant.local:PORT`

## Key Changes Made:

### 1. Fixed s6-overlay PID 1 error:
- Added `init: false` to config.yaml
- Using simple CMD instead of s6-overlay services

### 2. Ingress Support:
- Added ingress configuration in config.yaml
- Apache configured to handle proxy headers
- Automatic base URL detection for ingress

### 3. Laravel/Vito Compatibility:
- Document root set to `/var/www/html/public`
- Laravel rewrite rules configured
- All required PHP extensions installed
- Composer included for dependency management

## Troubleshooting

### If you get permission errors:
```bash
# SSH into Home Assistant
docker exec -it addon_local_vito /bin/bash
chmod -R 777 /var/www/html/storage
chmod -R 777 /var/www/html/bootstrap/cache
```

### If Ingress doesn't work:
1. Check that ingress is enabled in config.yaml
2. Restart the add-on
3. Clear browser cache
4. Check logs for errors

### Database Configuration:
Vito uses SQLite by default. For MySQL:
1. Install MariaDB add-on
2. Update Vito's .env file with database credentials

## Environment Variables

The add-on automatically sets these Laravel environment variables:
- `APP_KEY` - Application encryption key
- `APP_URL` - Automatically set for ingress or direct access
- `DB_CONNECTION` - Default: sqlite
- `DB_DATABASE` - Default: /var/www/html/database/database.sqlite

## Logs

View logs in:
- Home Assistant: Settings → Add-ons → Vito → Logs
- Container: `/var/www/html/storage/logs/laravel.log`

## Security Notes

⚠️ **Important:**
- Generate a unique APP_KEY for production
- Use strong passwords
- Consider SSL/TLS for external access
- Regularly update the add-on

## Support

- Vito Documentation: https://vitodeploy.com/docs
- Home Assistant Forums: https://community.home-assistant.io
- GitHub Issues: [Your repository]

## Version
- Add-on Version: 1.3.0
- Base: Alpine Linux with PHP 8.3
- Apache: 2.4.x
- Supports: Home Assistant 2024.1+

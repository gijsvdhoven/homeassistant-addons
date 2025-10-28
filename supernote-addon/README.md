# Home Assistant Add-on: Supernote Private Cloud

[![GitHub Release][releases-shield]][releases]
[![GitHub Activity][commits-shield]][commits]
[![License][license-shield]][license]

![Supports aarch64 Architecture][aarch64-shield]
![Supports amd64 Architecture][amd64-shield]
![Supports armhf Architecture][armhf-shield]
![Supports armv7 Architecture][armv7-shield]
![Supports i386 Architecture][i386-shield]

_Private cloud solution for Supernote devices with file synchronization and management._

![Supernote Private Cloud](https://raw.githubusercontent.com/supernote-community/supernote-private-cloud-addon/main/images/screenshot.png)

## About

This Home Assistant add-on provides a complete private cloud solution for Supernote devices. It allows you to:

- 📱 Sync files between your Supernote device and your home server
- 🗂️ Manage and organize your notes and documents
- 🔄 Automatic file conversion and processing
- 💾 Backup and restore your important documents
- 🌐 Web-based interface for easy management
- 🔒 Complete privacy with local hosting

The add-on includes all necessary services:

- **MariaDB** for database storage
- **Redis** for caching and session management
- **Notelib** service for note processing
- **Web interface** for file management
- **API backend** for device synchronization

## Installation

### Method 1: Add Custom Repository

1. Navigate to **Supervisor** → **Add-on Store** in Home Assistant
2. Click the **⋮** menu in the top right corner
3. Select **Repositories**
4. Add this repository URL:
   ```
   https://github.com/supernote-community/supernote-private-cloud-addon
   ```
5. Find "Supernote Private Cloud" in the add-on store and click **Install**

### Method 2: Manual Installation

1. Copy the add-on folder to `/addons/supernote_private_cloud/`
2. Restart Home Assistant
3. Go to **Supervisor** → **Add-on Store**
4. Find "Supernote Private Cloud" and click **Install**

## Configuration

### Basic Configuration

```yaml
mysql_root_password: "your-secure-root-password"
mysql_password: "your-secure-user-password"
redis_password: "your-secure-redis-password"
log_level: "info"
ssl_enabled: false
backup_enabled: true
max_file_size: 104857600
session_timeout: 3600
```

### Configuration Options

| Option                | Type   | Default               | Description                                                   |
| --------------------- | ------ | --------------------- | ------------------------------------------------------------- |
| `mysql_root_password` | string | `SupernoteRoot2025!`  | MySQL root password                                           |
| `mysql_password`      | string | `SupernoteUser2025!`  | MySQL application user password                               |
| `redis_password`      | string | `RedisSupernote2025!` | Redis password                                                |
| `log_level`           | list   | `info`                | Log level (trace, debug, info, notice, warning, error, fatal) |
| `ssl_enabled`         | bool   | `false`               | Enable SSL/TLS                                                |
| `ssl_certfile`        | string | -                     | SSL certificate file (in `/ssl/` folder)                      |
| `ssl_keyfile`         | string | -                     | SSL private key file (in `/ssl/` folder)                      |
| `backup_enabled`      | bool   | `true`                | Enable automatic backups                                      |
| `max_file_size`       | int    | `104857600`           | Maximum file size in bytes (100MB)                            |
| `session_timeout`     | int    | `3600`                | Session timeout in seconds                                    |

### Security Configuration

**⚠️ Important Security Notes:**

1. **Change all default passwords** before first use
2. **Use strong, unique passwords** for all services
3. **Enable SSL** for production use with valid certificates
4. **Restrict network access** if not needed externally

### SSL Configuration

To enable SSL:

1. Place your SSL certificate and key files in the `/ssl/` Home Assistant folder
2. Set `ssl_enabled: true`
3. Set `ssl_certfile` and `ssl_keyfile` to your certificate file names
4. Restart the add-on

Example SSL configuration:

```yaml
ssl_enabled: true
ssl_certfile: "supernote.crt"
ssl_keyfile: "supernote.key"
```

## Usage

### First Time Setup

1. Install and start the add-on
2. Wait for all services to initialize (check the logs)
3. Open the Web UI from the add-on page or navigate to `http://[HA_IP]:19072`
4. Login with default credentials:
   - **Username:** `admin`
   - **Password:** `admin123`
5. **Immediately change the default password!**

### Web Interface

The web interface provides:

- File browser and management
- Upload and download capabilities
- User management
- System settings and configuration
- Backup and restore options
- Device synchronization status

### Supernote Device Configuration

Configure your Supernote device to sync with your private cloud:

1. Go to **Settings** → **Cloud** on your Supernote device
2. Select **Private Cloud**
3. Enter your Home Assistant IP address and port (19072)
4. Use your login credentials
5. Configure sync settings as desired

### API Access

The add-on provides REST API access for integration:

- **API Endpoint:** `http://[HA_IP]:19071/api/`
- **Authentication:** Bearer token or session-based
- **Documentation:** Available in the web interface under API docs

## Data Storage

### Home Assistant Integration

The add-on integrates with Home Assistant's storage system:

- **`/share/supernote/`** - Main data storage (accessible from other add-ons)
- **`/addon_config/supernote_private_cloud/`** - Configuration and logs
- **`/media/supernote/`** - Media files (accessible from Media tab)

### Backup and Restore

#### Automatic Backups

When `backup_enabled: true`, the add-on creates automatic backups:

- Daily database backups
- Weekly full data backups
- Stored in `/addon_config/supernote_private_cloud/backups/`

#### Manual Backup

Create manual backups through:

1. Web interface → Settings → Backup
2. Home Assistant → Supervisor → Add-ons → Supernote Private Cloud → Create backup

#### Restore Process

1. Stop the add-on
2. Replace data files with backup files
3. Restart the add-on
4. Check logs for successful restore

## Troubleshooting

### Common Issues

#### Add-on Won't Start

1. Check the logs for specific error messages
2. Verify all passwords are set correctly
3. Ensure sufficient disk space (minimum 2GB free)
4. Check for port conflicts with other services

#### Cannot Access Web Interface

1. Verify the add-on is running and healthy
2. Check if port 19072 is accessible
3. Ensure no firewall blocking the connection
4. Try accessing via Home Assistant's Ingress panel

#### Database Connection Errors

1. Check MySQL service status in logs
2. Verify database passwords in configuration
3. Ensure database initialization completed successfully
4. Check disk space for database files

#### Sync Issues with Supernote Device

1. Verify network connectivity between device and Home Assistant
2. Check credentials and server settings on device
3. Review API logs for authentication errors
4. Ensure device firmware is compatible

### Log Analysis

View detailed logs:

```bash
# From Home Assistant CLI
docker logs addon_supernote_private_cloud

# From add-on interface
# Go to Add-on → Supernote Private Cloud → Log tab
```

### Performance Optimization

For better performance:

1. Allocate sufficient RAM (minimum 2GB recommended)
2. Use SSD storage for database files
3. Configure log rotation to prevent disk fill
4. Monitor resource usage through Home Assistant

### Reset to Default

To completely reset the add-on:

1. Stop the add-on
2. Remove addon configuration: `/addon_config/supernote_private_cloud/`
3. Clear shared data: `/share/supernote/`
4. Restart the add-on (will reinitialize)

## Advanced Configuration

### Custom Database Configuration

For advanced users, you can mount custom MySQL configuration:

1. Create `/addon_config/supernote_private_cloud/mysql/my.cnf`
2. Add your custom MySQL settings
3. Restart the add-on

### Integration with Other Add-ons

The add-on can integrate with:

- **File Browser** - Access files through `/share/supernote/`
- **Samba** - Share files over network
- **Backup add-ons** - Include in Home Assistant backups
- **VPN add-ons** - Secure remote access

### Home Assistant Automation

Create automations based on Supernote events:

```yaml
automation:
  - alias: "Notify on Supernote Sync"
    trigger:
      - platform: webhook
        webhook_id: "supernote_sync"
    action:
      - service: notify.mobile_app
        data:
          message: "Supernote files synchronized"
```

## Support and Contributing

### Getting Help

- **Documentation:** [GitHub Wiki](https://github.com/supernote-community/supernote-private-cloud-addon/wiki)
- **Issues:** [GitHub Issues](https://github.com/supernote-community/supernote-private-cloud-addon/issues)
- **Community:** [Home Assistant Community Forum](https://community.home-assistant.io/)
- **Discord:** [Supernote Community](https://discord.gg/supernote)

### Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Submit a pull request with detailed description

### Reporting Issues

When reporting issues, please include:

- Home Assistant version
- Add-on version
- Configuration (without passwords)
- Relevant log entries
- Steps to reproduce

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and changes.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Disclaimer

This add-on is a community project and is not officially affiliated with Supernote or Home Assistant. Use at your own risk and ensure you have proper backups of your important data.

[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[armhf-shield]: https://img.shields.io/badge/armhf-yes-green.svg
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg
[i386-shield]: https://img.shields.io/badge/i386-yes-green.svg
[commits-shield]: https://img.shields.io/github/commit-activity/y/supernote-community/supernote-private-cloud-addon.svg
[commits]: https://github.com/supernote-community/supernote-private-cloud-addon/commits/main
[license-shield]: https://img.shields.io/github/license/supernote-community/supernote-private-cloud-addon.svg
[license]: https://github.com/supernote-community/supernote-private-cloud-addon/blob/main/LICENSE
[releases-shield]: https://img.shields.io/github/release/supernote-community/supernote-private-cloud-addon.svg
[releases]: https://github.com/supernote-community/supernote-private-cloud-addon/releases

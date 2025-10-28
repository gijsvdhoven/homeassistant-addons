# Changelog

All notable changes to this Home Assistant add-on will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2025-10-28

### Added

- Initial release of Supernote Private Cloud Home Assistant Add-on
- Complete integration with Home Assistant Supervisor
- Multi-architecture support (amd64, aarch64, armv7, armhf, i386)
- Web UI accessible through Home Assistant interface
- Automatic service management with Supervisor
- Integrated database initialization and management
- SSL/TLS support with Home Assistant certificate management
- Backup and restore functionality
- Configuration through Home Assistant UI
- Health checks and automatic service recovery
- Integration with Home Assistant storage system (`/share`, `/addon_config`, `/media`)

### Features

- **MariaDB Database**: Persistent storage for application data
- **Redis Cache**: Session management and caching
- **Notelib Service**: Note processing and conversion service
- **Web Interface**: Complete file management interface
- **API Backend**: RESTful API for device synchronization
- **Nginx Proxy**: Reverse proxy for service routing
- **File Management**: Upload, download, organize documents
- **User Management**: Multi-user support with authentication
- **Device Sync**: Compatible with Supernote device synchronization
- **Automatic Backups**: Scheduled database and file backups

### Security

- Configurable passwords for all services
- SSL/TLS encryption support
- Home Assistant integration security
- Isolated container environment
- Secure file permissions and user management

### Configuration Options

- `mysql_root_password`: Configurable MySQL root password
- `mysql_password`: Configurable application database password
- `redis_password`: Configurable Redis password
- `log_level`: Adjustable logging levels
- `ssl_enabled`: SSL/TLS encryption toggle
- `ssl_certfile`: SSL certificate file path
- `ssl_keyfile`: SSL private key file path
- `backup_enabled`: Automatic backup configuration
- `max_file_size`: Maximum upload file size limit
- `session_timeout`: User session timeout configuration

### Technical Details

- **Base Image**: Alpine Linux with multi-arch support
- **Services**: Supervisor-managed service orchestration
- **Database**: MariaDB with automatic initialization
- **Cache**: Redis with password protection
- **Web Server**: Nginx reverse proxy
- **File Storage**: Persistent volumes with Home Assistant integration
- **Networking**: Internal service communication with external access
- **Health Monitoring**: Container health checks and service monitoring

### Compatibility

- **Home Assistant**: Core 2023.1.0+
- **Supervisor**: 2023.01.0+
- **Architecture**: amd64, aarch64, armv7, armhf, i386
- **Supernote Devices**: A5X, A6X, and compatible models
- **Browser Support**: Modern web browsers with HTML5 support

### Known Limitations

- Requires minimum 2GB RAM for optimal performance
- Minimum 50GB disk space recommended
- Network connectivity required for device synchronization
- SSL certificates must be managed through Home Assistant

### Installation Notes

- First installation may take 5-10 minutes for complete initialization
- Default credentials: `admin` / `admin123` (must be changed immediately)
- Database initialization includes required tables and default configuration
- All services start automatically and include health monitoring

### Future Enhancements (Planned)

- Integration with Home Assistant notifications
- Automated backup scheduling through HA
- Enhanced device management interface
- Multiple cloud storage backend support
- Advanced user permission management
- API integration with Home Assistant entities
- Mobile app notifications through HA companion app

---

## Version History Reference

### Versioning Scheme

- **Major.Minor.Patch** (e.g., 1.2.0)
- **Major**: Breaking changes or major feature additions
- **Minor**: New features, improvements, or significant updates
- **Patch**: Bug fixes, security updates, or minor improvements

### Support Policy

- **Current Version**: Full support with updates and bug fixes
- **Previous Minor**: Security updates and critical bug fixes
- **Older Versions**: End of life, upgrade recommended

### Upgrade Notes

- Always backup your configuration and data before upgrading
- Review changelog for breaking changes
- Test in development environment when possible
- Monitor logs after upgrade for any issues

---

For detailed installation and configuration instructions, see [README.md](README.md).

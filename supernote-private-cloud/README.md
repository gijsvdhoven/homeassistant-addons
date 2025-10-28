# Supernote Private Cloud Add-on

![Supernote Logo](https://img.shields.io/badge/Supernote-Private%20Cloud-blue)
![Version](https://img.shields.io/badge/version-1.2.0-green)
![Supports amd64 Architecture](https://img.shields.io/badge/amd64-yes-green)
![Supports aarch64 Architecture](https://img.shields.io/badge/aarch64-yes-green)

Deploy Supernote Private Cloud using the official installation script. This add-on provides a simple way to run the official Supernote Private Cloud installation within your Home Assistant environment.

## About

This add-on downloads and executes the official Supernote Private Cloud installation script from `https://supernote-private-cloud.supernote.com/cloud/install.sh`. It provides:

- **Official Installation**: Uses the exact same script provided by Supernote
- **Automatic Setup**: Handles Docker, database, and service configuration automatically
- **Web Interface**: Access your notes through a modern web interface on port 9888
- **Full Compatibility**: 100% compatible with official Supernote devices and features
- **Self-contained**: All services run within the Home Assistant environment

## Installation

1. **Add this repository to your Home Assistant Add-on Store**:
   - Navigate to **Supervisor** → **Add-on Store** → **⋮** → **Repositories**
   - Add: `https://github.com/gijsvdhoven/homeassistant-addons`

2. **Install the add-on**:
   - Find "Supernote Private Cloud" in the add-on store
   - Click **Install**

3. **Configure the add-on** (optional):
   - Most settings use the official defaults
   - Customize install URL or data directory if needed

4. **Start the add-on**:
   - Click **Start**
   - Check the logs for installation progress (first run takes several minutes)

## Configuration

```yaml
install_url: "https://supernote-private-cloud.supernote.com/cloud/install.sh"
auto_update: true
log_level: "info"
data_directory: "/share/supernote"
```

### Configuration Options

- **install_url**: URL to the official Supernote installation script (default: official URL)
- **auto_update**: Whether to run the install script again if already installed (default: true)
- **log_level**: Set logging verbosity (debug, info, warning, error)
- **data_directory**: Directory where Supernote data will be stored (default: /share/supernote)

## Usage

Once the add-on is running, you can access the Supernote Private Cloud through multiple interfaces:

### Web Interface
- **Main Interface**: `http://homeassistant.local:9888`
- Access your notes, upload files, and manage your Supernote library

### API Access
- **API Endpoint**: `http://homeassistant.local:8080`
- **Backend Service**: `http://homeassistant.local:19071`
- **Note Library**: `http://homeassistant.local:6000`

### Database and Cache (for advanced users)
- **Database (MariaDB)**: `http://homeassistant.local:3306`
- **Cache (Redis)**: `http://homeassistant.local:6379`

### Configuring Your Supernote Device

1. **Access device settings** on your Supernote
2. **Navigate to Cloud Settings**
3. **Enter your Home Assistant details**:
   - Server: `http://your-home-assistant-ip:9888`
   - Check the add-on logs for any credentials if required

## Features

### 🎯 Official Installation
- Uses the exact same installation script provided by Supernote
- 100% compatibility with official features and updates
- Automatic download of latest components

### 🔐 Security
- All security features from the official script
- Automatic password generation
- Isolated container environment

### 📁 Data Management
- Persistent data storage in `/share/supernote`
- Automatic database setup and initialization
- File integrity verification

### 🔧 Maintenance
- Built-in service monitoring
- Automatic service recovery
- Docker container management

## How It Works

This add-on works by:

1. **Downloading** the official Supernote Private Cloud installation script
2. **Setting up** a Docker environment within the add-on container
3. **Executing** the installation script, which:
   - Downloads and configures MariaDB
   - Sets up Redis for caching
   - Installs the Supernote services (notelib, supernote-service)
   - Configures the web interface
   - Initializes the database with required tables
4. **Monitoring** services and ensuring they stay running

## Data Storage

The add-on stores all data in `/share/supernote/` which includes:

- **docker-compose.yml**: Service configuration (created by install script)
- **Database files**: MariaDB data
- **Configuration**: Service settings and credentials
- **Notes & Files**: Your uploaded notes and documents
- **Logs**: Application and service logs

## First Run

The first time you start the add-on, it will:

1. Download the official installation script
2. Install Docker components
3. Download Supernote container images
4. Set up the database
5. Start all services

This process can take 10-15 minutes depending on your internet connection and system performance.

## Troubleshooting

### Common Issues

#### Add-on won't start
- Check system requirements (2+ CPU cores, 2GB+ RAM, 50GB+ disk space)
- Ensure ports 9888, 8080, 19071, 6000, 3306, 6379 are available
- Review add-on logs for specific errors

#### Installation script fails
- Check internet connectivity
- Verify the install_url is accessible
- Look for error messages in the logs
- Try restarting the add-on

#### Services not accessible
- Wait for complete installation (check logs)
- Verify all services are running: `docker ps` in the add-on terminal
- Check if ports are properly exposed

### Log Analysis

Important log messages to look for:
- `Installation script downloaded successfully`
- `Supernote Private Cloud installation completed successfully`
- `Service on port XXXX is ready`
- `Supernote Private Cloud is running`

### Getting Help

If you encounter issues:
1. Check the add-on logs first
2. Verify your system meets the requirements
3. Try stopping and starting the add-on
4. Open an issue on GitHub with logs and system details

## Comparison with Manual Installation

| Feature | This Add-on | Manual Installation |
|---------|-------------|-------------------|
| Installation | One-click in Home Assistant | Manual server setup |
| Updates | Managed through add-on | Manual script execution |
| Integration | Native Home Assistant UI | Separate web interface |
| Backups | Home Assistant backup system | Manual backup setup |
| Monitoring | Add-on logs and status | Manual monitoring |
| Port Management | Automatic | Manual configuration |

## Support

- **Documentation**: This README and logs
- **Issues**: [GitHub Issues](https://github.com/gijsvdhoven/homeassistant-addons/issues)
- **Official Supernote Support**: [Supernote Website](https://supernote.com)
- **Home Assistant Community**: [Community Forum](https://community.home-assistant.io/)

## Credits

- **Supernote**: For creating the amazing e-ink devices and providing the installation script
- **Original Script**: All functionality is provided by the official Supernote installation script
- **Home Assistant Community**: For the excellent add-on framework

## License

This project is licensed under the MIT License. The Supernote Private Cloud software and installation script are owned by Supernote and subject to their terms and conditions.

---

**Note**: This add-on is not officially affiliated with Supernote. It simply provides an easy way to run the official Supernote Private Cloud installation script within Home Assistant.
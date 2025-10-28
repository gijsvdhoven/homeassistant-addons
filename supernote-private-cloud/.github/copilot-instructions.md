# Copilot Instructions - Supernote Private Cloud Add-on

## Project Overview

This is a **Home Assistant add-on** that wraps the official Supernote Private Cloud installation script in a containerized environment. The add-on uses a **Docker-in-Docker** architecture to execute the upstream installation script while providing Home Assistant integration.

## Architecture Pattern

- **Wrapper approach**: Downloads and executes the official Supernote installation script (`https://supernote-private-cloud.supernote.com/cloud/install.sh`)
- **Docker-in-Docker**: The add-on container runs Docker daemon to manage the services created by the upstream script
- **Service delegation**: MariaDB, Redis, Notelib, and Supernote services run as separate containers within the add-on container
- **Port mapping**: Exposes 6 ports (9888 web UI, 8080 API, 19071 backend, 6000 notelib, 3306 MariaDB, 6379 Redis)

## Key Files & Responsibilities

- `config.yaml`: Home Assistant add-on manifest (ports, privileges, schema validation)
- `run.sh`: Main orchestration script (downloads installer, manages Docker daemon, monitors services)
- `Dockerfile`: Sets up Alpine base with Docker, curl, and health checks
- `README.md`: User-facing documentation with setup instructions and troubleshooting

## Configuration Patterns

**Add-on Configuration (`config.yaml`)**:

- Uses JSON format despite `.yaml` extension (Home Assistant convention)
- Requires `privileged: ["SYS_ADMIN", "NET_ADMIN"]` and `docker_api: true` for Docker-in-Docker
- Maps `/share` and `/backup` directories for persistent storage

**Runtime Configuration (`run.sh`)**:

- Uses `bashio::config` functions to read add-on options
- Exports environment variables for the installation script
- Persistent data stored in `/share/supernote` (configurable via `data_directory` option)

## Development Workflows

**Testing Changes**:

```bash
# Build and test locally (if in repository root)
docker build --build-arg BUILD_FROM=ghcr.io/home-assistant/amd64-base:latest -t supernote-test .
docker run --privileged -v /var/run/docker.sock:/var/run/docker.sock supernote-test
```

**Log Analysis**:

- Add-on logs: Home Assistant Supervisor → Add-ons → Supernote Private Cloud → Logs
- Application logs: `/share/supernote/addon.log` (dual logging to both HA and file)
- Service logs: `docker-compose logs` within the data directory

**Version Updates**:

- **Automatic**: Git pre-commit hook auto-bumps version when core files change (`run.sh`, `Dockerfile`, `config.yaml`)
- **Manual**: Use `./bump-version.sh [patch|minor|major] [custom-version]` for immediate version bumps
- **Management**: Use `./auto-version.sh [enable|disable|status|test]` to control automatic versioning
- **GitHub Actions**: Auto-bumps version on push and creates releases
- **Files synced**: `config.yaml`, `Dockerfile` labels, `run.sh` log message, and `README.md` badge
- Installation script URL should remain pointing to official Supernote endpoint

## Critical Dependencies

- **Docker-in-Docker**: Requires `docker_api: true` and privileged container access
- **Official Script**: Never modify the upstream installation script - this add-on's value is 100% compatibility
- **Bashio**: Home Assistant's add-on framework for configuration and logging (`bashio::log.*`, `bashio::config`)
- **Network Access**: Must download from `supernote-private-cloud.supernote.com`

## Service Monitoring Pattern

The `run.sh` script implements a monitoring loop that:

1. Checks Docker Compose service health every 5 minutes
2. Restarts failed services automatically using `docker-compose restart`
3. Uses signal handlers (`trap cleanup SIGTERM SIGINT`) for graceful shutdown

## Common Issues & Debugging

- **"readonly variable" errors**: Variables in `run.sh` use a pattern of `DEFAULT_*` constants and runtime assignment to avoid readonly conflicts
- **Installation failures**: Check internet connectivity and script download from official URL
- **Service startup**: Wait 10-15 minutes on first run for container downloads and database initialization
- **Port conflicts**: Ensure ports 9888, 8080, 19071, 6000, 3306, 6379 are available on host
- **Docker daemon issues**: Check privileged mode and Docker API access in add-on configuration
- **Docker startup failures**: The script includes Docker version checks, PID monitoring, and recursive restart logic for robustness

## Integration Points

- **Home Assistant**: Web UI accessible via Ingress on port 9888
- **External Access**: All services expose standard ports for direct device configuration
- **Data Persistence**: Uses Home Assistant's `/share` directory for automatic backup inclusion
- **Configuration**: Standard Home Assistant add-on options pattern with schema validation

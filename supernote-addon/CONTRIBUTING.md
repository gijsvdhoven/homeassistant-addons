# Contributing to Supernote Private Cloud Home Assistant Add-on

We welcome contributions to the Supernote Private Cloud Home Assistant Add-on! This document provides guidelines for contributing to the project.

## 🤝 How to Contribute

### Reporting Issues

1. **Search existing issues** first to avoid duplicates
2. **Use the issue templates** when available
3. **Provide detailed information** including:
   - Home Assistant version
   - Add-on version
   - Architecture (amd64, aarch64, etc.)
   - Steps to reproduce
   - Expected vs actual behavior
   - Relevant log entries (without sensitive information)

### Feature Requests

1. **Check existing feature requests** to avoid duplicates
2. **Describe the use case** clearly
3. **Explain the expected behavior**
4. **Consider implementation complexity**

### Code Contributions

1. **Fork the repository**
2. **Create a feature branch** from `main`
3. **Make your changes** following the coding standards
4. **Test thoroughly** on at least one architecture
5. **Update documentation** if needed
6. **Submit a pull request**

## 🏗️ Development Setup

### Prerequisites

- Docker 20.10+
- Docker Buildx (for multi-arch builds)
- Home Assistant development environment (optional)
- Basic knowledge of:
  - Docker containers
  - Home Assistant add-ons
  - Bash scripting
  - YAML configuration

### Local Development

1. **Clone the repository:**

   ```bash
   git clone https://github.com/supernote-community/supernote-private-cloud-addon.git
   cd supernote-private-cloud-addon
   ```

2. **Build the add-on:**

   ```bash
   ./build.sh build amd64  # Build for your architecture
   ```

3. **Test locally:**
   ```bash
   # Install in Home Assistant development environment
   cp -r . /path/to/homeassistant/addons/supernote_private_cloud/
   ```

### Testing

#### Unit Testing

- Validate configuration files: `./build.sh validate`
- Test build process: `./build.sh build [arch]`
- Check Dockerfile syntax: `docker build --no-cache .`

#### Integration Testing

- Test in Home Assistant Supervisor
- Verify service startup and health checks
- Test web interface functionality
- Validate device synchronization

#### Multi-Architecture Testing

```bash
# Build for all supported architectures
./build.sh build

# Test specific architecture
./build.sh build aarch64
```

## 📋 Coding Standards

### File Structure

```
supernote-addon/
├── config.yaml           # Add-on configuration
├── Dockerfile            # Container definition
├── README.md             # User documentation
├── CHANGELOG.md          # Version history
├── LICENSE               # License file
├── build.sh              # Build script
├── rootfs/               # Container file system
│   ├── usr/local/bin/    # Executable scripts
│   ├── etc/              # Configuration files
│   ├── app/              # Application files
│   └── docker-entrypoint-initdb.d/  # Database init
├── icon.png              # Add-on icon
├── logo.png              # Add-on logo
└── repository.yaml       # Repository metadata
```

### Configuration Standards

#### config.yaml

- Use semantic versioning for `version`
- Include all required fields
- Provide meaningful descriptions
- Use appropriate data types in schema
- Include reasonable defaults

#### Dockerfile

- Use official Home Assistant base images
- Multi-stage builds when appropriate
- Minimize image size
- Proper security practices
- Clear labeling

#### Scripts

- Use `#!/bin/bash` shebang
- Set `set -e` for error handling
- Include proper logging
- Validate inputs
- Handle edge cases

### Documentation Standards

- **Clear and concise** language
- **Step-by-step instructions** where appropriate
- **Code examples** with syntax highlighting
- **Screenshots** for UI elements (when applicable)
- **Table of contents** for longer documents
- **Links to related documentation**

## 🔧 Add-on Architecture

### Service Components

1. **MariaDB**: Database storage
2. **Redis**: Cache and session management
3. **Notelib**: Note processing service
4. **Supernote Service**: Main application backend
5. **Nginx**: Reverse proxy and web server

### File System Layout

- `/app/data/`: Persistent application data
- `/app/logs/`: Application logs
- `/app/config/`: Service configurations
- `/app/backups/`: Backup storage
- `/share/supernote/`: Home Assistant shared storage
- `/addon_config/`: Add-on specific configuration

### Service Communication

- Internal Docker networking
- Environment variable configuration
- Health check endpoints
- Supervisor process management

## 🐛 Debugging

### Common Issues

1. **Build failures**: Check Dockerfile syntax and base image
2. **Service startup**: Review supervisor logs and health checks
3. **Database issues**: Verify initialization scripts and permissions
4. **Network problems**: Check port configurations and firewall

### Logging

- Add-on logs: Home Assistant → Supervisor → Add-ons → Supernote Private Cloud → Log
- Service logs: `/app/logs/` directory
- System logs: `docker logs addon_supernote_private_cloud`

### Debug Mode

Enable debug logging in `config.yaml`:

```yaml
log_level: debug
```

## 📦 Release Process

### Version Management

1. **Update version** in `config.yaml`
2. **Update CHANGELOG.md** with changes
3. **Tag the release** in Git
4. **Build and test** all architectures
5. **Create GitHub release**

### Release Checklist

- [ ] Version updated in config.yaml
- [ ] CHANGELOG.md updated
- [ ] Documentation reviewed
- [ ] All architectures build successfully
- [ ] Integration tests pass
- [ ] Security review completed
- [ ] GitHub release created
- [ ] Add-on store updated

## 🔐 Security Considerations

### Security Best Practices

1. **Input validation** for all user inputs
2. **Secure defaults** in configuration
3. **Minimal privileges** for services
4. **Regular updates** of base images and dependencies
5. **Sensitive data handling** (passwords, tokens)

### Security Review Process

1. **Static analysis** of code and configuration
2. **Dependency scanning** for vulnerabilities
3. **Container security** best practices
4. **Network security** configuration
5. **Data protection** measures

## 📄 License

By contributing to this project, you agree that your contributions will be licensed under the MIT License.

## 🆘 Getting Help

- **Documentation**: Check README.md and wiki
- **Issues**: Search GitHub issues
- **Community**: Home Assistant Community Forum
- **Discord**: Supernote Community Discord server

## 🙏 Recognition

Contributors will be recognized in:

- CHANGELOG.md for significant contributions
- GitHub contributors list
- Special mentions for major features or fixes

Thank you for contributing to the Supernote Private Cloud Home Assistant Add-on!

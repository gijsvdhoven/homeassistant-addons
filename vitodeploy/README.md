# Vito Home Assistant Add-on (Fixed for s6-overlay)

This add-on has been updated to work properly with Home Assistant's s6-overlay init system.

## Directory Structure

```
vitodeploy/
├── config.yaml           # Add-on configuration
├── Dockerfile           # Build instructions
└── rootfs/              # s6-overlay service files
    └── etc/
        └── s6-overlay/
            └── s6-rc.d/
                ├── vito/
                │   ├── run      # Main service script
                │   ├── finish   # Cleanup script
                │   └── type     # Service type (longrun)
                └── user/
                    └── contents.d/
                        └── vito # Service registration

```

## What was fixed:

1. **Removed the old entrypoint.sh** - Home Assistant add-ons don't use custom entrypoints
2. **Created proper s6-overlay service structure** - Services run under s6 supervision
3. **Used bashio for configuration** - Proper way to read add-on options
4. **Fixed PID 1 issue** - s6-overlay now runs as PID 1 as required

## Installation:

1. Copy the entire `vitodeploy` folder to your Home Assistant add-ons directory
2. Rebuild the add-on
3. Configure your settings in the add-on configuration page
4. Start the add-on

## Notes:

- The Apache service will run under s6 supervision
- Logs will be properly handled by Home Assistant
- The service will restart automatically if it crashes
- Configuration is read from Home Assistant's add-on options using bashio

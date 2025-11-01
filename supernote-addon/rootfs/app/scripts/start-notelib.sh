#!/bin/bash
# Start Notelib Service on port 6000

echo "Starting Notelib Service..."

cd /app/notelib || {
    echo "ERROR: Notelib directory not found at /app/notelib"
    echo "Service binaries may not have been copied during build"
    exit 1
}

# Find and run the notelib service
# This assumes the service is a Java application or binary
# Adjust based on actual service structure
if [ -f "start.sh" ]; then
    exec ./start.sh
elif [ -f "notelib.jar" ]; then
    exec java -jar notelib.jar
elif [ -f "notelib" ]; then
    exec ./notelib
else
    echo "ERROR: Could not find notelib executable"
    echo "Contents of /app/notelib:"
    ls -la /app/notelib
    exit 1
fi
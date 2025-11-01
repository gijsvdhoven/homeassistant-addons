#!/bin/bash
# Start Supernote Service on ports 19071 (backend API), 8080, and 9888 (frontend)

echo "Starting Supernote Service..."

cd /app/supernote-service || {
    echo "ERROR: Supernote service directory not found at /app/supernote-service"
    echo "Service binaries may not have been copied during build"
    exit 1
}

# Find and run the supernote service
# This assumes the service is a Java application or binary
# Adjust based on actual service structure
if [ -f "start.sh" ]; then
    exec ./start.sh
elif [ -f "supernote-service.jar" ]; then
    exec java -jar supernote-service.jar
elif [ -f "supernote-service" ]; then
    exec ./supernote-service
else
    echo "ERROR: Could not find supernote-service executable"
    echo "Contents of /app/supernote-service:"
    ls -la /app/supernote-service
    exit 1
fi
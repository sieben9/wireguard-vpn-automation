#!/bin/sh

# Error handling
set -e

echo "WireGuard Health Check"
echo "---------------------"

# Check if Docker is running
echo "Checking Docker service..."
if ! docker info >/dev/null 2>&1; then
  echo "Error: Docker is not running. Please start Docker and try again."
  exit 1
fi
echo "✓ Docker is running"

# Check if WireGuard container exists
echo "Checking WireGuard container..."
if ! docker ps -a | grep -q wireguard; then
  echo "Error: WireGuard container not found. Has it been created?"
  exit 1
fi
echo "✓ WireGuard container exists"

# Check if WireGuard container is running
echo "Checking if WireGuard container is running..."
if ! docker ps | grep -q wireguard; then
  echo "Error: WireGuard container is not running."
  echo "Run './bin/start.sh' to start it."
  exit 1
fi
echo "✓ WireGuard container is running"

# Check WireGuard interface
echo "Checking WireGuard interface inside container..."
if ! docker exec wireguard ip a | grep -q wg0; then
  echo "Error: WireGuard interface (wg0) not found in container."
  exit 1
fi
echo "✓ WireGuard interface is configured"

# Check listening port
LISTEN_PORT=$(grep -E "SERVERPORT" docker-compose.yml | cut -d= -f2 | head -1 | tr -d '[:space:]')
if [ -z "$LISTEN_PORT" ]; then
  LISTEN_PORT=51820
fi

echo "Checking if WireGuard is listening on UDP port $LISTEN_PORT..."
if ! docker exec wireguard netstat -lun | grep -q ":$LISTEN_PORT"; then
  echo "Warning: Could not confirm WireGuard is listening on port $LISTEN_PORT."
else
  echo "✓ WireGuard is listening on port $LISTEN_PORT"
fi

# Show WireGuard status
echo
echo "WireGuard Status:"
docker exec wireguard wg show | cat

echo
echo "All checks completed. WireGuard appears to be running correctly." 
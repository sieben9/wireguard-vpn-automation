#!/bin/sh

# Error handling
set -e

# Function to validate IP address
is_valid_ip() {
  case $1 in
    *[!0-9.]*)
      return 1
      ;;
  esac
  
  local IFS=.
  set -- $1
  [ $# -eq 4 ] && [ ${1:-666} -le 255 ] && [ ${2:-666} -le 255 ] && [ ${3:-666} -le 255 ] && [ ${4:-666} -le 255 ]
}

# Function to check if command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Check for dependencies
echo "Checking dependencies..."
if ! command_exists docker; then
  echo "Error: Docker is not installed. Please install Docker and try again."
  exit 1
fi

if ! command_exists docker-compose; then
  echo "Warning: docker-compose is not installed. Please install Docker Compose and try again."
  exit 1
fi

echo "WireGuard VPN Setup - Configuration Assistant"
echo "--------------------------------------------"
echo

# Ask for IP address
while true; do
  echo "Please enter your public IP address:"
  read -r server_ip
  
  if is_valid_ip "$server_ip"; then
    break
  else
    echo "Invalid IP address format. Please try again."
  fi
done

# Update docker-compose.yml
echo "Updating docker-compose.yml..."
if ! sed -i.bak "s/your\.server\.ip\.address/$server_ip/g" docker-compose.yml; then
  echo "Error: Failed to update docker-compose.yml"
  exit 1
fi
rm -f docker-compose.yml.bak

# Ask for port
echo "Do you want to use the default port 51820? [Y/n]"
read -r port_answer
if [ "$port_answer" = "n" ] || [ "$port_answer" = "N" ]; then
  while true; do
    echo "Please enter your desired port (1-65535):"
    read -r server_port
    
    if [ "$server_port" -gt 0 ] && [ "$server_port" -lt 65536 ] 2>/dev/null; then
      break
    else
      echo "Invalid port number. Please enter a number between 1 and 65535."
    fi
  done
  
  if ! sed -i.bak "s/SERVERPORT=51820/SERVERPORT=$server_port/g" docker-compose.yml; then
    echo "Error: Failed to update port in docker-compose.yml"
    exit 1
  fi
  rm -f docker-compose.yml.bak
  echo "Port has been changed to $server_port."
else
  echo "Default port 51820 will be used."
  server_port=51820
fi

# Check if port is open
echo "Checking if port $server_port is available..."
if command_exists nc; then
  if nc -z localhost "$server_port" 2>/dev/null; then
    echo "Warning: Port $server_port is already in use on this machine."
    echo "This may cause conflicts when starting the WireGuard container."
    echo "Do you want to continue anyway? [y/N]"
    read -r continue_anyway
    if [ "$continue_anyway" != "y" ] && [ "$continue_anyway" != "Y" ]; then
      echo "Setup aborted. Please choose a different port or free up port $server_port."
      exit 1
    fi
  else
    echo "Port $server_port appears to be available."
  fi
else
  echo "Note: 'nc' command not found. Cannot check if port is already in use."
fi

# Ask for DNS server
echo "Do you want to use the default DNS server 1.1.1.1 (Cloudflare)? [Y/n]"
read -r dns_answer
if [ "$dns_answer" = "n" ] || [ "$dns_answer" = "N" ]; then
  echo "Please enter your desired DNS server:"
  read -r dns_server
  
  if ! sed -i.bak "s/PEERDNS=1\.1\.1\.1/PEERDNS=$dns_server/g" docker-compose.yml; then
    echo "Error: Failed to update DNS server in docker-compose.yml"
    exit 1
  fi
  rm -f docker-compose.yml.bak
  echo "DNS server has been changed to $dns_server."
else
  echo "Default DNS server 1.1.1.1 will be used."
fi

# Ask for timezone
echo "Do you want to use the default timezone Europe/Berlin? [Y/n]"
read -r tz_answer
if [ "$tz_answer" = "n" ] || [ "$tz_answer" = "N" ]; then
  echo "Please enter your desired timezone (e.g. Europe/Vienna):"
  read -r timezone
  
  if ! sed -i.bak "s/TZ=Europe\/Berlin/TZ=$timezone/g" docker-compose.yml; then
    echo "Error: Failed to update timezone in docker-compose.yml"
    exit 1
  fi
  rm -f docker-compose.yml.bak
  echo "Timezone has been changed to $timezone."
else
  echo "Default timezone Europe/Berlin will be used."
fi

# Ask for number of peers to create
echo
echo "How many peer configurations would you like to create? [0-10]"
read -r num_peers

# Validate input is a number
if ! [ "$num_peers" -eq "$num_peers" ] 2>/dev/null; then
  echo "Invalid input. Setting number of peers to 0."
  num_peers=0
elif [ "$num_peers" -lt 0 ] || [ "$num_peers" -gt 10 ]; then
  echo "Number out of range. Setting number of peers to 0."
  num_peers=0
fi

# Create peer directories
if [ "$num_peers" -gt 0 ]; then
  echo "Creating $num_peers peer directories..."
  for i in $(seq 1 "$num_peers"); do
    mkdir -p "config/peer_$i"
    touch "config/peer_$i/peer$i.conf.bak"
    echo "# Peer $i configuration template - will be replaced by WireGuard" > "config/peer_$i/peer$i.conf.bak"
    echo "Created config/peer_$i/"
  done
  echo "Peer directories created. They will be populated when the WireGuard container starts."
fi

# Make admin scripts executable
chmod +x admin/*.sh 2>/dev/null || true
chmod +x bin/*.sh

echo
echo "Configuration completed. You can now start the WireGuard VPN server with:"
echo "./bin/start.sh"
echo
echo "To set up the VPN server as a systemd service, follow the instructions in the README.md"
echo
echo "For administration tasks, check the scripts in the admin/ directory:"
echo "- ./admin/add-peer.sh     - Add a new peer"
echo "- ./admin/remove-peer.sh  - Remove a peer"
echo "- ./admin/backup.sh       - Backup configurations"
echo "- ./admin/restore.sh      - Restore from backup"
echo "- ./admin/health-check.sh - Check if WireGuard is running correctly"
echo "- ./admin/update.sh       - Check for updates"
#!/bin/sh

# Error handling
set -e

# Get the port from docker-compose.yml
LISTEN_PORT=$(grep -E "SERVERPORT" docker-compose.yml | cut -d= -f2 | head -1 | tr -d '[:space:]')
if [ -z "$LISTEN_PORT" ]; then
  LISTEN_PORT=51820
fi

echo "WireGuard Firewall Setup"
echo "------------------------"
echo
echo "This script will configure your firewall to allow WireGuard VPN traffic on port $LISTEN_PORT/UDP."
echo "Supported firewalls: ufw, firewalld, iptables"
echo

# Detect firewall
if command -v ufw >/dev/null 2>&1 && ufw status >/dev/null 2>&1; then
  FIREWALL="ufw"
  echo "Detected firewall: UFW (Uncomplicated Firewall)"
elif command -v firewall-cmd >/dev/null 2>&1; then
  FIREWALL="firewalld"
  echo "Detected firewall: firewalld"
elif command -v iptables >/dev/null 2>&1; then
  FIREWALL="iptables"
  echo "Detected firewall: iptables"
else
  FIREWALL="unknown"
  echo "Warning: Could not detect a supported firewall."
  echo "You will need to manually configure your firewall to allow UDP traffic on port $LISTEN_PORT."
  exit 1
fi

# Ask for confirmation
echo "Do you want to configure $FIREWALL to allow WireGuard traffic? [y/N]"
read -r confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
  echo "Firewall setup aborted."
  exit 0
fi

# Configure the firewall
case $FIREWALL in
  ufw)
    echo "Configuring UFW..."
    sudo ufw allow "$LISTEN_PORT"/udp
    echo "Firewall rule added. Current UFW status:"
    sudo ufw status
    ;;
  firewalld)
    echo "Configuring firewalld..."
    sudo firewall-cmd --permanent --add-port="$LISTEN_PORT"/udp
    sudo firewall-cmd --reload
    echo "Firewall rule added. Current firewalld status:"
    sudo firewall-cmd --list-all
    ;;
  iptables)
    echo "Configuring iptables..."
    sudo iptables -A INPUT -p udp --dport "$LISTEN_PORT" -j ACCEPT
    echo "Firewall rule added, but it may not persist after reboot."
    echo "To make it persistent, you should save your iptables rules according to your distribution."
    echo "Common methods:"
    echo "- Debian/Ubuntu: sudo netfilter-persistent save"
    echo "- CentOS/RHEL: sudo service iptables save"
    ;;
esac

echo
echo "Firewall configuration completed successfully!"
echo "WireGuard VPN traffic on port $LISTEN_PORT/UDP is now allowed." 
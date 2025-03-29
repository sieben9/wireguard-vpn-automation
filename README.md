# WireGuard VPN Server Setup

This repository contains an automated configuration for a WireGuard VPN server running with Docker.

## Quick Start

```bash
# One-line setup and start:
git clone https://github.com/sieben9/wireguard-vpn-automation.git && cd wireguard-vpn-automation && ./setup.sh && ./bin/start.sh && ./admin/show-config.sh
```

## Prerequisites

- Docker
- Docker Compose
- A server with a public IP address
- Port 51820 (UDP) must be open

## Installation

1. Clone the repository:
```bash
git clone https://github.com/sieben9/wireguard-vpn-automation.git
cd wireguard-vpn-automation
```

2. Run the setup script:
```bash
./setup.sh
```
   The setup will ask for:
   - Your public IP address
   - Port configuration (default: 51820)
   - DNS server (default: 1.1.1.1)
   - Timezone (default: Europe/Berlin)
   - Number of peer configurations to create

3. Configure your firewall:
```bash
./admin/firewall-setup.sh
```

4. Start the server:
```bash
./bin/start.sh
```

5. View your configuration:
```bash
./admin/show-config.sh
```

## Production Deployment

For a production environment, it's recommended to install the repository in `/opt/`:

```bash
# Clone to /opt/ (requires root)
sudo git clone https://github.com/sieben9/wireguard-vpn-automation.git /opt/wireguard-vpn-automation
cd /opt/wireguard-vpn-automation

# Set proper permissions
sudo chown -R $(id -u):$(id -g) /opt/wireguard-vpn-automation

# Run setup and start server
./setup.sh
./bin/start.sh
```

The systemd service file and Alpine init scripts are already configured to work with this location.

### Kernel Module Support

If your system doesn't have WireGuard kernel support built-in (older kernels), you may need to uncomment the line in `docker-compose.yml` that mounts `/lib/modules`:

```yaml
volumes:
  - wireguard-config:/config
  - ./config:/etc/wireguard/peers
  - /lib/modules:/lib/modules:ro  # Uncomment this line
```

This is typically only needed for older systems. Modern kernels (5.6+) have built-in WireGuard support.

## Repository Structure

```
wireguard-vpn-automation/
├── admin/              # Administration scripts
│   ├── add-peer.sh     # Add a new peer
│   ├── backup.sh       # Create configuration backup
│   ├── firewall-setup.sh # Configure firewall
│   ├── health-check.sh # Check WireGuard status
│   ├── log-rotate.sh   # Rotate container logs
│   ├── remove-peer.sh  # Remove a peer
│   ├── restore.sh      # Restore from backup
│   ├── show-config.sh  # Show peer configurations
│   └── update.sh       # Update installation
├── backups/            # Directory for backups
├── bin/                # Basic operation scripts
│   ├── pull.sh         # Git pull
│   ├── restart.sh      # Restart container
│   ├── start.sh        # Start container
│   └── stop.sh         # Stop container
├── config/             # Peer configurations
│   └── peer_*/         # Individual peer directories
├── logs/               # Container logs
├── .systemd/           # Systemd service files
├── docker-compose.yml  # Docker configuration
├── setup.sh            # Initial setup script
└── README.md           # This documentation
```

## Configuration

Configuration is managed through the `docker-compose.yml` file. Key settings:

- Server URL: Your public IP address
- Port: 51820 (default)
- DNS: 1.1.1.1 (Cloudflare)
- Internal subnet: 10.13.13.0/29

## Client Configuration

Client configuration files are stored in the `config` directory. When you run the setup script, it will create the number of peer directories you specify.

Each peer directory (peer_1, peer_2, etc.) will contain:
- A template file (peer1.conf.bak) that will be used by WireGuard to generate the actual configuration

When the WireGuard container starts, it will automatically generate the actual peer configurations based on your server settings.

### Managing Peers

To add a new peer:
```bash
./admin/add-peer.sh phone
```

To remove a peer:
```bash
./admin/remove-peer.sh phone
```

To view peer configurations:
```bash
./admin/show-config.sh
```

### Mobile Device Setup

To generate QR codes for mobile devices:

```bash
# Generate QR code for a specific client
docker exec wireguard wg showconf wg0 | qrencode -t ansiutf8

# Or for a specific peer configuration file
cat config/peer_1/peer1.conf | qrencode -t ansiutf8
```

Note: You'll need to install `qrencode` on your system if not already present:
- Debian/Ubuntu: `apt-get install qrencode`
- Alpine: `apk add qrencode`
- macOS: `brew install qrencode`

## System Integration

### Systemd Service (Linux)

To set up the WireGuard server as a systemd service:

1. Copy the contents of the directory to `/opt/wireguard-vpn-setup/`
2. Copy the service file:
```bash
sudo cp .systemd/wireguard.service /etc/systemd/system/
```
3. Enable the systemd service:
```bash
sudo systemctl enable wireguard.service
sudo systemctl start wireguard.service
```

### Alpine Linux (OpenRC)

For Alpine Linux or other systems without systemd:

```bash
sudo ./admin/alpine-init.sh
sudo rc-update add wireguard default
sudo rc-service wireguard start
```

## Administration

This repository includes several administration scripts to help manage your WireGuard VPN server:

### Health Checks

To check if your WireGuard server is running correctly:
```bash
./admin/health-check.sh
```

### Backup and Restore

To backup your configuration:
```bash
./admin/backup.sh
```

To restore from a backup:
```bash
./admin/restore.sh backups/wireguard-backup-20230101-120000.tar.gz
```

### Updates

To check for and apply updates:
```bash
./admin/update.sh
```

### Log Management

To rotate container logs:
```bash
./admin/log-rotate.sh
```

## Troubleshooting

If you encounter issues:

1. Check the health of the server:
```bash
./admin/health-check.sh
```

2. View container logs:
```bash
docker logs wireguard
```

3. Restart the service:
```bash
./bin/restart.sh
```
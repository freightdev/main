#!/bin/bash
set -e

# Base Configs
BASE_DIR="${BASE_DIR:=$HOME/core}"
CF_DIR="${CF_DIR:=/etc/cloudflared}"
ENV_FILE="${ENV_DIR:=$BASE_DIR/envs/cloudflared.env}"

# Check if core directory exists
if [ ! -d "$BASE_DIR" ]; then
    echo "Error: core directory not found!"
    exit 1
fi

# Load environment variables
if [ -f "$ENV_FILE" ]; then
    export $(cat "$ENV_FILE" | grep -v '^#' | xargs)
else
    echo "Error: $ENV_FILE not found!"
    exit 1
fi

#####################################
# CLOUDFLARED SETUP
#####################################
echo "=== Cloudflare Tunnel Setup ==="
echo "Installing Cloudflared..."

# Install dependencies
echo "Installing Dependencies"
sudo apt update
sudo apt install -y wget gettext

# Create cloudflared user
echo "Creating Cloudflared User Account"
sudo useradd -m -s /bin/bash cloudflared 2>/dev/null || echo "User cloudflared already exists"

# Download cloudflared binary
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    DOWNLOAD_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64"
elif [ "$ARCH" = "aarch64" ]; then
    DOWNLOAD_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

echo "Installing cloudflared from latest GitHub release."
wget -O /tmp/cloudflared "$DOWNLOAD_URL"
sudo mv /tmp/cloudflared /usr/local/bin/cloudflared
sudo chmod 755 /usr/local/bin/cloudflared

# Create cloudflared config directory if needed
sudo mkdir -p "$CF_DIR"
sudo chown cloudflared:cloudflared "$CF_DIR"
sudo chmod 750 "$CF_DIR"

# Copy cloudflared credentials and certificate
sudo cp "$BASE_DIR"/keys/cloudflared/* "$CF_DIR"
sudo chown -R cloudflared:cloudflared "$CF_DIR"
sudo chmod 600 "$CF_DIR"/*.json "$CF_DIR"/*.pem 2>/dev/null || true

#####################################
# DYNAMIC CONFIG GENERATION
#####################################
echo "=== Generating Dynamic Config ==="

# Start building config file
cat > /tmp/cloudflared-config.yml <<EOF
tunnel: $TUNNEL_TOKEN
credentials-file: $TUNNEL_CERTS

ingress:
EOF

# Parse SERVICES variable (format: "service1:port1,service2:port2,service3:port3")
if [ -n "$SERVICES" ]; then
    IFS=',' read -ra SERVICE_ARRAY <<< "$SERVICES"
    for service in "${SERVICE_ARRAY[@]}"; do
        IFS=':' read -r name port <<< "$service"
        # Properly append to the file
        cat >> /tmp/cloudflared-config.yml <<SERVICEEOF
  # $name
  - hostname: $name.$HWY_DOMAIN
    service: http://localhost:$port
    originRequest:
      noTLSVerify: true

SERVICEEOF
        echo "  ✓ Added route: $name.$HWY_DOMAIN -> localhost:$port"
    done
else
    echo "Warning: No SERVICES defined in env file"
fi

# Add catch-all
cat >> /tmp/cloudflared-config.yml <<EOF
  # Catch-all (Required)
  - service: http_status:404
EOF

# Move config to final location
sudo mv /tmp/cloudflared-config.yml "$CF_DIR"/config.yml
sudo chown cloudflared:cloudflared "$CF_DIR"/config.yml
sudo chmod 644 "$CF_DIR"/config.yml

echo ""
echo "Generated config:"
cat "$CF_DIR"/config.yml

#########################################
# SYSTEMD SETUP
#########################################
echo ""
echo "=== Systemd Service Setup ==="

# Copy systemd service files
sudo cp "$BASE_DIR"/services/cloudflared.service /etc/systemd/system/cloudflared.service

# Enable and start services
sudo systemctl daemon-reload
sudo systemctl enable cloudflared
sudo systemctl restart cloudflared

# Wait a moment for startup
sleep 2

# Check status
sudo systemctl status cloudflared --no-pager

#####################################
# VERIFICATION
#####################################
echo ""
echo "✓ Cloudflared setup complete!"
echo ""
echo "Verify tunnel with:"
echo "  sudo cloudflared tunnel ingress validate --config /etc/cloudflared/config.yml"
echo ""
echo "View logs:"
echo "  sudo journalctl -u cloudflared -f"
echo ""
echo "Test routes:"
if [ -n "$SERVICES" ]; then
    IFS=',' read -ra SERVICE_ARRAY <<< "$SERVICES"
    for service in "${SERVICE_ARRAY[@]}"; do
        IFS=':' read -r name port <<< "$service"
        echo "  https://$name.$HWY_DOMAIN"
    done
fi
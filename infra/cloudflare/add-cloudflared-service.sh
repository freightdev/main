#!/bin/bash
set -e

# Usage: ./add-cloudflare-service.sh <service-name> <port>
# Example: ./add-cloudflare-service.sh nextcloud 8080

if [ $# -ne 2 ]; then
    echo "Usage: $0 <service-name> <port>"
    echo "Example: $0 nextcloud 8080"
    exit 1
fi

SERVICE_NAME=$1
SERVICE_PORT=$2
BASE_DIR="${BASE_DIR:=$HOME/core}"
CF_DIR="/etc/cloudflared"
ENV_FILE="$BASE_DIR/envs/cloudflared.env"

# Load domain from env
if [ -f "$ENV_FILE" ]; then
    export $(cat "$ENV_FILE" | grep HWY_DOMAIN | xargs)
else
    echo "Error: $ENV_FILE not found!"
    exit 1
fi

echo "Adding service: $SERVICE_NAME on port $SERVICE_PORT"
echo "Domain: $SERVICE_NAME.$HWY_DOMAIN"

# Backup current config
sudo cp "$CF_DIR/config.yml" "$CF_DIR/config.yml.backup"

# Create temp file with new service inserted before catch-all
sudo awk -v name="$SERVICE_NAME" -v port="$SERVICE_PORT" -v domain="$HWY_DOMAIN" '
/^  - service: http_status:404/ {
    print "  # " name
    print "  - hostname: " name "." domain
    print "    service: http://localhost:" port
    print "    originRequest:"
    print "      noTLSVerify: true"
    print ""
}
{print}
' "$CF_DIR/config.yml" | sudo tee "$CF_DIR/config.yml.new" > /dev/null

# Replace config
sudo mv "$CF_DIR/config.yml.new" "$CF_DIR/config.yml"
sudo chown cloudflared:cloudflared "$CF_DIR/config.yml"
sudo chmod 644 "$CF_DIR/config.yml"

# Validate config
echo ""
echo "Validating configuration..."
sudo cloudflared tunnel ingress validate --config "$CF_DIR/config.yml"

# Restart service
echo ""
echo "Restarting cloudflared..."
sudo systemctl restart cloudflared
sleep 2
sudo systemctl status cloudflared --no-pager

echo ""
echo "✓ Service added successfully!"
echo "  Access at: https://$SERVICE_NAME.$HWY_DOMAIN"
echo ""
echo "Backup saved to: $CF_DIR/config.yml.backup"
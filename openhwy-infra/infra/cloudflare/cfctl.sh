#!/bin/bash
set -e

# Cloudflare Tunnel Control Manager
VERSION="1.0.0"
BASE_DIR="${BASE_DIR:=$HOME/core}"
CF_DIR="/etc/cloudflared"
ENV_FILE="$BASE_DIR/envs/cloudflared.env"
CONFIG_FILE="$CF_DIR/config.yml"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Load environment
load_env() {
    if [ -f "$ENV_FILE" ]; then
        export $(cat "$ENV_FILE" | grep -v '^#' | xargs)
    else
        echo -e "${RED}Error: $ENV_FILE not found!${NC}"
        exit 1
    fi
}

# Check if running as root for certain operations
check_sudo() {
    if [ "$EUID" -ne 0 ]; then 
        echo -e "${RED}This command requires sudo${NC}"
        exit 1
    fi
}

# Add service
add_service() {
    if [ $# -ne 2 ]; then
        echo "Usage: cfctrl add <name> <port>"
        echo "Example: cfctrl add nextcloud 8080"
        exit 1
    fi
    
    SERVICE_NAME=$1
    SERVICE_PORT=$2
    
    load_env
    
    echo -e "${BLUE}Adding service: ${SERVICE_NAME} on port ${SERVICE_PORT}${NC}"
    
    # Backup current config
    sudo cp "$CONFIG_FILE" "$CONFIG_FILE.backup"
    
    # Check if service already exists
    if sudo grep -q "hostname: $SERVICE_NAME.$HWY_DOMAIN" "$CONFIG_FILE"; then
        echo -e "${YELLOW}Service $SERVICE_NAME already exists!${NC}"
        exit 1
    fi
    
    # Insert before catch-all
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
    ' "$CONFIG_FILE" | sudo tee "$CONFIG_FILE.new" > /dev/null
    
    sudo mv "$CONFIG_FILE.new" "$CONFIG_FILE"
    sudo chown cloudflared:cloudflared "$CONFIG_FILE"
    
    # Validate
    if ! sudo cloudflared tunnel ingress validate --config "$CONFIG_FILE" 2>/dev/null; then
        echo -e "${RED}Config validation failed! Restoring backup...${NC}"
        sudo mv "$CONFIG_FILE.backup" "$CONFIG_FILE"
        exit 1
    fi
    
    # Restart service
    sudo systemctl restart cloudflared
    
    echo -e "${GREEN}✓ Service added: https://$SERVICE_NAME.$HWY_DOMAIN${NC}"
    echo -e "${YELLOW}Run 'cfctrl update-dns' to create DNS records${NC}"
}

# Remove service
remove_service() {
    if [ $# -ne 1 ]; then
        echo "Usage: cfctrl remove <name>"
        exit 1
    fi
    
    SERVICE_NAME=$1
    load_env
    
    echo -e "${BLUE}Removing service: ${SERVICE_NAME}${NC}"
    
    # Backup
    sudo cp "$CONFIG_FILE" "$CONFIG_FILE.backup"
    
    # Remove service block (service name through empty line)
    sudo awk -v name="$SERVICE_NAME" -v domain="$HWY_DOMAIN" '
    /^  # '"$SERVICE_NAME"'$/ {skip=1; next}
    skip && /^$/ {skip=0; next}
    !skip {print}
    ' "$CONFIG_FILE" | sudo tee "$CONFIG_FILE.new" > /dev/null
    
    sudo mv "$CONFIG_FILE.new" "$CONFIG_FILE"
    sudo chown cloudflared:cloudflared "$CONFIG_FILE"
    
    # Validate and restart
    sudo cloudflared tunnel ingress validate --config "$CONFIG_FILE"
    sudo systemctl restart cloudflared
    
    echo -e "${GREEN}✓ Service removed${NC}"
}

# List services
list_services() {
    load_env
    
    echo -e "${BLUE}=== Cloudflare Tunnel Services ===${NC}"
    echo ""
    
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${RED}Config file not found!${NC}"
        exit 1
    fi
    
    # Parse config and display
    sudo grep -E "hostname:|service: http" "$CONFIG_FILE" | \
    grep -v "http_status:404" | \
    paste -d' ' - - | \
    awk '{
        split($2, hostname, ":")
        split($4, service, ":")
        gsub(/^ +| +$/, "", hostname[2])
        gsub(/\/\/localhost/, "", service[2])
        printf "%-30s -> localhost:%s\n", hostname[2], service[3]
    }'
    
    echo ""
    echo -e "${YELLOW}Tunnel Status:${NC}"
    sudo systemctl status cloudflared --no-pager | grep -E "Active:|Main PID:"
}

# Update DNS records
update_dns() {
    load_env
    
    if [ -z "$CF_API_TOKEN" ] || [ -z "$CF_ZONE_ID" ]; then
        echo -e "${RED}Error: CF_API_TOKEN or CF_ZONE_ID not set in $ENV_FILE${NC}"
        echo "Get your API token from: https://dash.cloudflare.com/profile/api-tokens"
        exit 1
    fi
    
    echo -e "${BLUE}=== Updating Cloudflare DNS Records ===${NC}"
    
    # Get all hostnames from config
    HOSTNAMES=$(sudo grep "hostname:" "$CONFIG_FILE" | awk '{print $3}' | grep -v "^$")
    
    for hostname in $HOSTNAMES; do
        # Extract subdomain
        subdomain=${hostname%.$HWY_DOMAIN}
        
        echo -e "${YELLOW}Processing: $hostname${NC}"
        
        # Check if record exists
        RECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records?name=$hostname" \
            -H "Authorization: Bearer $CF_API_TOKEN" \
            -H "Content-Type: application/json" | jq -r '.result[0].id // empty')
        
        if [ -n "$RECORD_ID" ] && [ "$RECORD_ID" != "null" ]; then
            echo -e "  ${GREEN}✓ DNS record already exists${NC}"
        else
            # Create CNAME
            RESULT=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records" \
                -H "Authorization: Bearer $CF_API_TOKEN" \
                -H "Content-Type: application/json" \
                --data "{\"type\":\"CNAME\",\"name\":\"$subdomain\",\"content\":\"$TUNNEL_TOKEN.cfargotunnel.com\",\"ttl\":1,\"proxied\":true}")
            
            if echo "$RESULT" | jq -e '.success' > /dev/null 2>&1; then
                echo -e "  ${GREEN}✓ DNS record created${NC}"
            else
                echo -e "  ${RED}✗ Failed to create DNS record${NC}"
                echo "$RESULT" | jq -r '.errors[0].message // "Unknown error"'
            fi
        fi
    done
    
    echo -e "${GREEN}DNS update complete!${NC}"
}

# Show config
show_config() {
    if [ -f "$CONFIG_FILE" ]; then
        sudo cat "$CONFIG_FILE"
    else
        echo -e "${RED}Config file not found!${NC}"
    fi
}

# Restart tunnel
restart() {
    echo -e "${BLUE}Restarting cloudflared...${NC}"
    sudo systemctl restart cloudflared
    sleep 2
    sudo systemctl status cloudflared --no-pager
}

# Show logs
logs() {
    sudo journalctl -u cloudflared -f
}

# Validate config
validate() {
    echo -e "${BLUE}Validating configuration...${NC}"
    if sudo cloudflared tunnel ingress validate --config "$CONFIG_FILE"; then
        echo -e "${GREEN}✓ Configuration is valid${NC}"
    else
        echo -e "${RED}✗ Configuration has errors${NC}"
        exit 1
    fi
}

# Main menu
show_help() {
    cat << EOF
${BLUE}Cloudflare Tunnel Control Manager v${VERSION}${NC}

Usage: cfctrl <command> [options]

${GREEN}Service Management:${NC}
  add <name> <port>     Add a new service
  remove <name>         Remove a service
  list                  List all services
  
${GREEN}DNS Management:${NC}
  update-dns            Create/update DNS CNAME records
  
${GREEN}Operations:${NC}
  restart               Restart cloudflared service
  validate              Validate configuration
  logs                  View live logs
  config                Show current configuration
  
${GREEN}Examples:${NC}
  cfctrl add nextcloud 8080
  cfctrl remove nextcloud
  cfctrl list
  cfctrl update-dns
  cfctrl logs

${YELLOW}Note: Most commands require sudo${NC}
EOF
}

# Main command router
case "${1:-help}" in
    add)
        check_sudo
        add_service "$2" "$3"
        ;;
    remove)
        check_sudo
        remove_service "$2"
        ;;
    list)
        list_services
        ;;
    update-dns)
        update_dns
        ;;
    config)
        show_config
        ;;
    restart)
        check_sudo
        restart
        ;;
    logs)
        logs
        ;;
    validate)
        validate
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac
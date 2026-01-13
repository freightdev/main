#!/usr/bin/env bash
# NixOS-specific deployment script for agentic system

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}   Agentic System - NixOS Deployment${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo ""

# ==========================================
# Configuration
# ==========================================

# Node configurations
CALLBOX_IP="${CALLBOX_IP:-192.168.1.10}"
GPUBOX_IP="${GPUBOX_IP:-192.168.1.20}"
WORKBOX_IP="${WORKBOX_IP:-192.168.1.30}"
DEVBOX_IP="${DEVBOX_IP:-192.168.1.40}"

CONTROLLER_IP="$WORKBOX_IP"

# Installation path
INSTALL_PATH="/opt/agentic-system"

# ==========================================
# Functions
# ==========================================

check_nix() {
    if ! command -v nix &> /dev/null; then
        echo -e "${RED}✗ Nix not found. This script requires NixOS.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Nix found${NC}"
}

check_flakes() {
    if ! nix flake --version &> /dev/null 2>&1; then
        echo -e "${YELLOW}⚠ Flakes not enabled. Enabling...${NC}"
        mkdir -p ~/.config/nix
        echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
        echo -e "${GREEN}✓ Flakes enabled${NC}"
    else
        echo -e "${GREEN}✓ Flakes already enabled${NC}"
    fi
}

build_with_nix() {
    echo -e "${YELLOW}Building agentic system with Nix...${NC}"
    cd "$WORKSPACE_ROOT"
    
    # Enter dev shell and build
    nix develop -c cargo build --release --workspace
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Build successful${NC}"
    else
        echo -e "${RED}✗ Build failed${NC}"
        exit 1
    fi
}

install_to_system() {
    echo -e "${YELLOW}Installing to $INSTALL_PATH...${NC}"
    
    # Create installation directory
    sudo mkdir -p "$INSTALL_PATH"
    sudo chown -R agentic:agentic "$INSTALL_PATH" 2>/dev/null || true
    
    # Copy binaries
    sudo cp -r "$WORKSPACE_ROOT/target/release/controller" "$INSTALL_PATH/" 2>/dev/null || true
    sudo cp -r "$WORKSPACE_ROOT/target/release/callbox-worker" "$INSTALL_PATH/" 2>/dev/null || true
    sudo cp -r "$WORKSPACE_ROOT/target/release/gpubox-worker" "$INSTALL_PATH/" 2>/dev/null || true
    sudo cp -r "$WORKSPACE_ROOT/target/release/workbox-worker" "$INSTALL_PATH/" 2>/dev/null || true
    sudo cp -r "$WORKSPACE_ROOT/target/release/devbox-worker" "$INSTALL_PATH/" 2>/dev/null || true
    
    echo -e "${GREEN}✓ Installed to $INSTALL_PATH${NC}"
}

setup_nixos_module() {
    local node=$1
    echo -e "${YELLOW}Setting up NixOS module for $node...${NC}"
    
    # Copy NixOS configuration
    local nix_config="/etc/nixos/agentic-system.nix"
    sudo cp "$WORKSPACE_ROOT/nix/agentic-system.nix" "$nix_config"
    
    # Add to configuration.nix if not already there
    if ! grep -q "agentic-system.nix" /etc/nixos/configuration.nix; then
        echo -e "${YELLOW}Adding agentic-system to configuration.nix...${NC}"
        sudo sed -i '/imports = \[/a\    ./agentic-system.nix' /etc/nixos/configuration.nix
        echo -e "${GREEN}✓ Added to configuration.nix${NC}"
    fi
}

rebuild_nixos() {
    echo -e "${YELLOW}Rebuilding NixOS configuration...${NC}"
    sudo nixos-rebuild switch
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ NixOS rebuild successful${NC}"
    else
        echo -e "${RED}✗ NixOS rebuild failed${NC}"
        exit 1
    fi
}

start_services() {
    local hostname=$(hostname)
    echo -e "${YELLOW}Starting services for $hostname...${NC}"
    
    case $hostname in
        callbox)
            sudo systemctl start agentic-callbox-worker
            sudo systemctl enable agentic-callbox-worker
            echo -e "${GREEN}✓ callbox worker started${NC}"
            ;;
        gpubox)
            sudo systemctl start agentic-gpubox-worker
            sudo systemctl enable agentic-gpubox-worker
            echo -e "${GREEN}✓ gpubox worker started${NC}"
            ;;
        workbox)
            sudo systemctl start agentic-controller
            sudo systemctl enable agentic-controller
            sudo systemctl start agentic-workbox-worker
            sudo systemctl enable agentic-workbox-worker
            echo -e "${GREEN}✓ controller and workbox worker started${NC}"
            ;;
        *)
            echo -e "${YELLOW}⚠ Unknown hostname: $hostname${NC}"
            ;;
    esac
}

check_services() {
    local hostname=$(hostname)
    echo -e "${YELLOW}Checking services for $hostname...${NC}"
    echo ""
    
    case $hostname in
        callbox)
            systemctl status agentic-callbox-worker --no-pager | head -10
            ;;
        gpubox)
            systemctl status agentic-gpubox-worker --no-pager | head -10
            ;;
        workbox)
            echo -e "${BLUE}Controller:${NC}"
            systemctl status agentic-controller --no-pager | head -10
            echo ""
            echo -e "${BLUE}Worker:${NC}"
            systemctl status agentic-workbox-worker --no-pager | head -10
            ;;
    esac
}

create_user() {
    echo -e "${YELLOW}Creating agentic user...${NC}"
    
    if ! id "agentic" &>/dev/null; then
        sudo useradd -r -s /bin/bash -d /opt/agentic-system -m agentic
        echo -e "${GREEN}✓ User created${NC}"
    else
        echo -e "${YELLOW}⚠ User already exists${NC}"
    fi
}

deploy_with_flake() {
    echo -e "${YELLOW}Deploying with Nix flake...${NC}"
    cd "$WORKSPACE_ROOT/nix"
    
    # Build using flake
    nix build
    
    # Copy result to installation path
    if [ -L result ]; then
        sudo cp -r result/* "$INSTALL_PATH/"
        echo -e "${GREEN}✓ Deployed with flake${NC}"
    fi
}

show_logs() {
    local hostname=$(hostname)
    local service=""
    
    case $hostname in
        callbox)
            service="agentic-callbox-worker"
            ;;
        gpubox)
            service="agentic-gpubox-worker"
            ;;
        workbox)
            service="agentic-controller"
            ;;
    esac
    
    if [ -n "$service" ]; then
        echo -e "${YELLOW}Recent logs for $service:${NC}"
        sudo journalctl -u "$service" -n 50 --no-pager
    fi
}

# ==========================================
# Main Deployment
# ==========================================

case "${1:-all}" in
    check)
        check_nix
        check_flakes
        ;;
    
    build)
        check_nix
        build_with_nix
        ;;
    
    install)
        create_user
        install_to_system
        ;;
    
    configure)
        local hostname=$(hostname)
        setup_nixos_module "$hostname"
        ;;
    
    rebuild)
        rebuild_nixos
        ;;
    
    start)
        start_services
        ;;
    
    status)
        check_services
        ;;
    
    logs)
        show_logs
        ;;
    
    all)
        echo -e "${BLUE}Step 1/7: Checking environment...${NC}"
        check_nix
        check_flakes
        echo ""
        
        echo -e "${BLUE}Step 2/7: Creating user...${NC}"
        create_user
        echo ""
        
        echo -e "${BLUE}Step 3/7: Building system...${NC}"
        build_with_nix
        echo ""
        
        echo -e "${BLUE}Step 4/7: Installing binaries...${NC}"
        install_to_system
        echo ""
        
        echo -e "${BLUE}Step 5/7: Configuring NixOS module...${NC}"
        setup_nixos_module "$(hostname)"
        echo ""
        
        echo -e "${BLUE}Step 6/7: Rebuilding NixOS...${NC}"
        rebuild_nixos
        echo ""
        
        echo -e "${BLUE}Step 7/7: Starting services...${NC}"
        start_services
        echo ""
        
        echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}   Deployment Complete!${NC}"
        echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
        echo ""
        echo "Check status:"
        echo "  ./nix-deploy.sh status"
        echo ""
        echo "View logs:"
        echo "  ./nix-deploy.sh logs"
        echo ""
        echo "Controller endpoint: http://$CONTROLLER_IP:8080"
        ;;
    
    flake)
        deploy_with_flake
        ;;
    
    stop)
        local hostname=$(hostname)
        echo -e "${YELLOW}Stopping services...${NC}"
        
        case $hostname in
            callbox)
                sudo systemctl stop agentic-callbox-worker
                ;;
            gpubox)
                sudo systemctl stop agentic-gpubox-worker
                ;;
            workbox)
                sudo systemctl stop agentic-controller
                sudo systemctl stop agentic-workbox-worker
                ;;
        esac
        echo -e "${GREEN}✓ Services stopped${NC}"
        ;;
    
    restart)
        local hostname=$(hostname)
        echo -e "${YELLOW}Restarting services...${NC}"
        
        case $hostname in
            callbox)
                sudo systemctl restart agentic-callbox-worker
                ;;
            gpubox)
                sudo systemctl restart agentic-gpubox-worker
                ;;
            workbox)
                sudo systemctl restart agentic-controller
                sudo systemctl restart agentic-workbox-worker
                ;;
        esac
        echo -e "${GREEN}✓ Services restarted${NC}"
        ;;
    
    *)
        echo "Usage: $0 {check|build|install|configure|rebuild|start|status|logs|all|flake|stop|restart}"
        echo ""
        echo "Commands:"
        echo "  check      - Check NixOS environment"
        echo "  build      - Build with Nix"
        echo "  install    - Install binaries to system"
        echo "  configure  - Set up NixOS module"
        echo "  rebuild    - Rebuild NixOS configuration"
        echo "  start      - Start services"
        echo "  status     - Check service status"
        echo "  logs       - View service logs"
        echo "  all        - Full deployment (recommended)"
        echo "  flake      - Deploy using flake"
        echo "  stop       - Stop services"
        echo "  restart    - Restart services"
        exit 1
        ;;
esac

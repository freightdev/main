#!/usr/bin/env bash
# Deployment script for agentic system across your infrastructure

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}   Agentic System Deployment${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo ""

# ==========================================
# Configuration
# ==========================================

# Your node IPs (update these)
CALLBOX_IP="${CALLBOX_IP:-192.168.1.10}"
GPUBOX_IP="${GPUBOX_IP:-192.168.1.20}"
WORKBOX_IP="${WORKBOX_IP:-192.168.1.30}"
DEVBOX_IP="${DEVBOX_IP:-192.168.1.40}"

# Controller will run on workbox (most powerful)
CONTROLLER_IP="$WORKBOX_IP"

# SurrealDB connection
SURREAL_HOST="${SURREAL_HOST:-127.0.0.1:8000}"

# Model paths
LLAMA_MODEL="${LLAMA_MODEL:-/models/llama-3.1-8b.gguf}"
CANDLE_MODEL="${CANDLE_MODEL:-/models/codellama-34b}"
OPENVINO_MODEL="${OPENVINO_MODEL:-/models/llama-3.1-8b-int4-ov}"

# ==========================================
# Functions
# ==========================================

check_dependency() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}✗ $1 not found${NC}"
        return 1
    else
        echo -e "${GREEN}✓ $1 found${NC}"
        return 0
    fi
}

build_system() {
    echo -e "${YELLOW}Building agentic system...${NC}"
    cd "$WORKSPACE_ROOT"
    
    # Build in release mode
    cargo build --release --workspace
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Build successful${NC}"
    else
        echo -e "${RED}✗ Build failed${NC}"
        exit 1
    fi
}

deploy_controller() {
    echo -e "${YELLOW}Deploying controller to workbox ($CONTROLLER_IP)...${NC}"
    
    # Create systemd service
    sudo tee /etc/systemd/system/agentic-controller.service > /dev/null << EOF
[Unit]
Description=Agentic System Controller
After=network.target surrealdb.service

[Service]
Type=simple
User=$USER
WorkingDirectory=$WORKSPACE_ROOT
Environment="SURREAL_HOST=$SURREAL_HOST"
Environment="ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY"
Environment="OPENAI_API_KEY=$OPENAI_API_KEY"
ExecStart=$WORKSPACE_ROOT/target/release/controller
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable agentic-controller
    sudo systemctl restart agentic-controller
    
    echo -e "${GREEN}✓ Controller deployed${NC}"
}

deploy_callbox_worker() {
    echo -e "${YELLOW}Deploying callbox worker...${NC}"
    
    sudo tee /etc/systemd/system/agentic-callbox-worker.service > /dev/null << EOF
[Unit]
Description=Agentic System - callbox Worker
After=network.target llamacpp.service

[Service]
Type=simple
User=$USER
WorkingDirectory=$WORKSPACE_ROOT
Environment="WORKER_ID=callbox-01"
Environment="WORKER_BACKEND=cpu"
Environment="WORKER_MEMORY_GB=12"
Environment="LLAMA_CPP_MODEL_PATH=$LLAMA_MODEL"
Environment="CONTROLLER_URL=http://$CONTROLLER_IP:8080"
ExecStart=$WORKSPACE_ROOT/target/release/callbox-worker
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable agentic-callbox-worker
    sudo systemctl restart agentic-callbox-worker
    
    echo -e "${GREEN}✓ callbox worker deployed${NC}"
}

deploy_gpubox_worker() {
    echo -e "${YELLOW}Deploying gpubox worker...${NC}"
    
    sudo tee /etc/systemd/system/agentic-gpubox-worker.service > /dev/null << EOF
[Unit]
Description=Agentic System - gpubox Worker
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$WORKSPACE_ROOT
Environment="WORKER_ID=gpubox-01"
Environment="WORKER_BACKEND=gpu"
Environment="WORKER_MEMORY_GB=32"
Environment="CANDLE_MODEL_PATH=$CANDLE_MODEL"
Environment="CUDA_VISIBLE_DEVICES=0"
Environment="CONTROLLER_URL=http://$CONTROLLER_IP:8080"
ExecStart=$WORKSPACE_ROOT/target/release/gpubox-worker
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable agentic-gpubox-worker
    sudo systemctl restart agentic-gpubox-worker
    
    echo -e "${GREEN}✓ gpubox worker deployed${NC}"
}

deploy_workbox_worker() {
    echo -e "${YELLOW}Deploying workbox worker...${NC}"
    
    sudo tee /etc/systemd/system/agentic-workbox-worker.service > /dev/null << EOF
[Unit]
Description=Agentic System - workbox Worker
After=network.target llamacpp.service

[Service]
Type=simple
User=$USER
WorkingDirectory=$WORKSPACE_ROOT
Environment="WORKER_ID=workbox-01"
Environment="WORKER_BACKEND=cpu"
Environment="WORKER_MEMORY_GB=24"
Environment="LLAMA_CPP_MODEL_PATH=$LLAMA_MODEL"
Environment="CONTROLLER_URL=http://$CONTROLLER_IP:8080"
ExecStart=$WORKSPACE_ROOT/target/release/workbox-worker
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable agentic-workbox-worker
    sudo systemctl restart agentic-workbox-worker
    
    echo -e "${GREEN}✓ workbox worker deployed${NC}"
}

deploy_devbox_worker() {
    echo -e "${YELLOW}Deploying devbox worker...${NC}"
    
    sudo tee /etc/systemd/system/agentic-devbox-worker.service > /dev/null << EOF
[Unit]
Description=Agentic System - devbox Worker (NPU)
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$WORKSPACE_ROOT
Environment="WORKER_ID=devbox-01"
Environment="WORKER_BACKEND=npu"
Environment="WORKER_MEMORY_GB=16"
Environment="OPENVINO_MODEL_PATH=$OPENVINO_MODEL"
Environment="CONTROLLER_URL=http://$CONTROLLER_IP:8080"
ExecStart=$WORKSPACE_ROOT/target/release/devbox-worker
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable agentic-devbox-worker
    sudo systemctl restart agentic-devbox-worker
    
    echo -e "${GREEN}✓ devbox worker deployed${NC}"
}

check_services() {
    echo -e "${YELLOW}Checking service status...${NC}"
    echo ""
    
    services=(
        "agentic-controller"
        "agentic-callbox-worker"
        "agentic-gpubox-worker"
        "agentic-workbox-worker"
        "agentic-devbox-worker"
    )
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet $service; then
            echo -e "${GREEN}✓ $service: running${NC}"
        else
            echo -e "${RED}✗ $service: not running${NC}"
        fi
    done
}

show_logs() {
    echo -e "${YELLOW}Recent logs:${NC}"
    echo ""
    sudo journalctl -u agentic-controller -n 20 --no-pager
}

# ==========================================
# Main Deployment
# ==========================================

case "${1:-all}" in
    build)
        build_system
        ;;
    
    controller)
        deploy_controller
        ;;
    
    callbox)
        deploy_callbox_worker
        ;;
    
    gpubox)
        deploy_gpubox_worker
        ;;
    
    workbox)
        deploy_workbox_worker
        ;;
    
    devbox)
        deploy_devbox_worker
        ;;
    
    all)
        echo "Checking dependencies..."
        check_dependency cargo
        check_dependency systemctl
        echo ""
        
        build_system
        echo ""
        
        deploy_controller
        deploy_callbox_worker
        deploy_gpubox_worker
        deploy_workbox_worker
        deploy_devbox_worker
        echo ""
        
        echo -e "${GREEN}Waiting for services to start...${NC}"
        sleep 5
        echo ""
        
        check_services
        echo ""
        
        echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}   Deployment Complete!${NC}"
        echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
        echo ""
        echo "Controller: http://$CONTROLLER_IP:8080"
        echo ""
        echo "To check logs:"
        echo "  sudo journalctl -u agentic-controller -f"
        echo "  sudo journalctl -u agentic-callbox-worker -f"
        echo "  sudo journalctl -u agentic-gpubox-worker -f"
        echo ""
        echo "To stop all services:"
        echo "  sudo systemctl stop agentic-*"
        ;;
    
    status)
        check_services
        ;;
    
    logs)
        show_logs
        ;;
    
    stop)
        echo -e "${YELLOW}Stopping all services...${NC}"
        sudo systemctl stop agentic-*
        echo -e "${GREEN}✓ All services stopped${NC}"
        ;;
    
    restart)
        echo -e "${YELLOW}Restarting all services...${NC}"
        sudo systemctl restart agentic-*
        echo -e "${GREEN}✓ All services restarted${NC}"
        ;;
    
    *)
        echo "Usage: $0 {build|controller|callbox|gpubox|workbox|devbox|all|status|logs|stop|restart}"
        exit 1
        ;;
esac

#!/bin/bash
# Automated Boundary Setup for 4-Laptop Mesh
# Run with: sudo bash setup-boundary.sh [controller|worker]

set -e

BOUNDARY_VERSION="0.15.0"
CONTROLLER_IP="192.168.1.100"  # Change this to your controller laptop IP

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
   error "Please run as root (sudo)"
fi

ROLE=${1:-worker}

if [[ ! "$ROLE" =~ ^(controller|worker)$ ]]; then
    error "Usage: $0 [controller|worker]"
fi

info "Setting up Boundary as: $ROLE"

# =============================================================================
# INSTALL BOUNDARY
# =============================================================================

install_boundary() {
    info "Installing Boundary ${BOUNDARY_VERSION}..."
    
    if command -v boundary &> /dev/null; then
        info "Boundary already installed: $(boundary version)"
        return
    fi
    
    cd /tmp
    wget -q "https://releases.hashicorp.com/boundary/${BOUNDARY_VERSION}/boundary_${BOUNDARY_VERSION}_linux_amd64.zip"
    unzip -q boundary_${BOUNDARY_VERSION}_linux_amd64.zip
    mv boundary /usr/local/bin/
    chmod +x /usr/local/bin/boundary
    rm boundary_${BOUNDARY_VERSION}_linux_amd64.zip
    
    info "Boundary installed: $(boundary version)"
}

# =============================================================================
# GENERATE KMS KEYS
# =============================================================================

generate_kms_keys() {
    info "Generating KMS keys..."
    
    # Generate three unique keys
    KEY_ROOT=$(openssl rand -base64 32)
    KEY_WORKER=$(openssl rand -base64 32)
    KEY_RECOVERY=$(openssl rand -base64 32)
    
    cat > /tmp/kms-keys.txt <<EOF
# SAVE THESE KEYS - You'll need them for workers!

root_key="$KEY_ROOT"
worker_auth_key="$KEY_WORKER"
recovery_key="$KEY_RECOVERY"
EOF
    
    warn "KMS keys saved to: /tmp/kms-keys.txt"
    warn "IMPORTANT: Share worker_auth_key with all workers!"
}

# =============================================================================
# SETUP CONTROLLER
# =============================================================================

setup_controller() {
    info "Setting up Boundary Controller..."
    
    # Install Docker if not present
    if ! command -v docker &> /dev/null; then
        info "Installing Docker..."
        curl -fsSL https://get.docker.com | sh
        systemctl enable docker
        systemctl start docker
    fi
    
    # Setup PostgreSQL
    info "Setting up PostgreSQL for Boundary..."
    docker run -d \
        --name boundary-postgres \
        --restart unless-stopped \
        -e POSTGRES_DB=boundary \
        -e POSTGRES_USER=boundary \
        -e POSTGRES_PASSWORD=boundary_secure_pass_$(openssl rand -hex 8) \
        -p 5432:5432 \
        -v boundary-db:/var/lib/postgresql/data \
        postgres:15
    
    sleep 10
    
    # Get password
    DB_PASS=$(docker inspect boundary-postgres | jq -r '.[0].Config.Env[] | select(startswith("POSTGRES_PASSWORD=")) | split("=")[1]')
    
    info "PostgreSQL password: $DB_PASS"
    echo "DB_PASSWORD=$DB_PASS" > /root/.boundary-db-pass
    
    # Generate KMS keys
    generate_kms_keys
    source /tmp/kms-keys.txt
    
    # Get local IP
    LOCAL_IP=$(hostname -I | awk '{print $1}')
    
    # Create config directory
    mkdir -p /etc/boundary
    
    # Create controller config
    cat > /etc/boundary/controller.hcl <<EOF
disable_mlock = true

controller {
  name = "$(hostname)-controller"
  description = "Primary Boundary Controller"
  
  database {
    url = "postgresql://boundary:${DB_PASS}@localhost:5432/boundary?sslmode=disable"
  }
  
  public_cluster_addr = "${LOCAL_IP}:9201"
}

listener "tcp" {
  address = "0.0.0.0:9200"
  purpose = "api"
  tls_disable = true
  cors_enabled = true
  cors_allowed_origins = ["*"]
}

listener "tcp" {
  address = "0.0.0.0:9201"
  purpose = "cluster"
  tls_disable = true
}

listener "tcp" {
  address = "0.0.0.0:9203"
  purpose = "ops"
  tls_disable = true
}

kms "aead" {
  purpose = "root"
  aead_type = "aes-gcm"
  key = "${root_key}"
  key_id = "global_root"
}

kms "aead" {
  purpose = "worker-auth"
  aead_type = "aes-gcm"
  key = "${worker_auth_key}"
  key_id = "global_worker-auth"
}

kms "aead" {
  purpose = "recovery"
  aead_type = "aes-gcm"
  key = "${recovery_key}"
  key_id = "global_recovery"
}
EOF

    # Initialize database
    info "Initializing Boundary database..."
    boundary database init -config=/etc/boundary/controller.hcl > /tmp/boundary-init.txt
    
    warn "Database initialized! Output saved to: /tmp/boundary-init.txt"
    warn "IMPORTANT: Save the admin password and auth method ID!"
    cat /tmp/boundary-init.txt
    
    # Create systemd service
    cat > /etc/systemd/system/boundary-controller.service <<EOF
[Unit]
Description=Boundary Controller
After=network.target docker.service

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/boundary server -config=/etc/boundary/controller.hcl
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable boundary-controller
    systemctl start boundary-controller
    
    sleep 5
    
    info "Controller started!"
    systemctl status boundary-controller --no-pager
    
    # Setup local worker
    setup_worker_config "$worker_auth_key" "$LOCAL_IP"
    
    info "✅ Controller setup complete!"
    info "Web UI: http://${LOCAL_IP}:9200"
    info "Admin credentials in: /tmp/boundary-init.txt"
    info "Share with workers: /tmp/kms-keys.txt (worker_auth_key)"
}

# =============================================================================
# SETUP WORKER
# =============================================================================

setup_worker_config() {
    WORKER_KEY=${1:-}
    CONTROLLER=${2:-$CONTROLLER_IP}
    
    if [ -z "$WORKER_KEY" ]; then
        warn "Enter worker auth key:"
        read -r WORKER_KEY
    fi
    
    LOCAL_IP=$(hostname -I | awk '{print $1}')
    
    mkdir -p /etc/boundary
    
    cat > /etc/boundary/worker.hcl <<EOF
disable_mlock = true

worker {
  name = "$(hostname)-worker"
  description = "Worker on $(hostname)"
  
  controllers = ["${CONTROLLER}:9201"]
  
  public_addr = "${LOCAL_IP}:9202"
  
  tags {
    hostname = ["$(hostname)"]
    ip = ["${LOCAL_IP}"]
    type = ["laptop"]
    os = ["linux"]
  }
}

listener "tcp" {
  address = "0.0.0.0:9202"
  purpose = "proxy"
  tls_disable = true
}

kms "aead" {
  purpose = "worker-auth"
  aead_type = "aes-gcm"
  key = "${WORKER_KEY}"
  key_id = "global_worker-auth"
}
EOF

    cat > /etc/systemd/system/boundary-worker.service <<EOF
[Unit]
Description=Boundary Worker
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/boundary server -config=/etc/boundary/worker.hcl
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable boundary-worker
    systemctl start boundary-worker
    
    sleep 3
    
    info "✅ Worker started!"
    systemctl status boundary-worker --no-pager
}

# =============================================================================
# FIREWALL SETUP
# =============================================================================

setup_firewall() {
    if command -v ufw &> /dev/null; then
        info "Configuring firewall..."
        
        if [ "$ROLE" = "controller" ]; then
            ufw allow 9200/tcp comment 'Boundary API'
            ufw allow 9201/tcp comment 'Boundary Cluster'
            ufw allow 9203/tcp comment 'Boundary Ops'
        fi
        
        ufw allow 9202/tcp comment 'Boundary Worker Proxy'
        
        info "Firewall rules added"
    fi
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    info "Starting Boundary setup..."
    
    install_boundary
    
    if [ "$ROLE" = "controller" ]; then
        setup_controller
    else
        info "Setting up as worker..."
        setup_worker_config
    fi
    
    setup_firewall
    
    info "✅ Setup complete!"
    
    if [ "$ROLE" = "controller" ]; then
        LOCAL_IP=$(hostname -I | awk '{print $1}')
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "🎉 Boundary Controller Ready!"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Web UI:    http://${LOCAL_IP}:9200"
        echo "Admin:     See /tmp/boundary-init.txt"
        echo "DB Pass:   See /root/.boundary-db-pass"
        echo "KMS Keys:  See /tmp/kms-keys.txt"
        echo ""
        echo "Share worker_auth_key with other laptops!"
        echo ""
        echo "Next steps:"
        echo "1. Login to Web UI"
        echo "2. Setup other laptops as workers"
        echo "3. Create targets"
        echo ""
    else
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "🎉 Boundary Worker Ready!"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Worker connected to: ${CONTROLLER_IP}:9201"
        echo "Check status: sudo systemctl status boundary-worker"
        echo ""
    fi
}

main

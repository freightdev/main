# Boundary 4-Laptop Home Lab Setup

## Network Topology

```
┌─────────────────────────────────────────────────────┐
│  LAPTOP 1 (Controller + Worker)                     │
│  boundary-controller.local                          │
│  Role: Control Plane + Gateway                      │
│  IP: 192.168.1.100                                  │
│  ┌──────────────┐  ┌──────────────┐                │
│  │ Controller   │  │   Worker 1   │                │
│  │ (Port 9200)  │  │ (Port 9202)  │                │
│  └──────────────┘  └──────────────┘                │
│  └─ Runs: PostgreSQL (Boundary DB)                  │
│  └─ Access: Web UI, API                             │
└─────────────────────────────────────────────────────┘
              ▲
              │ Workers connect to Controller
              │
    ┌─────────┼─────────┬─────────────┐
    │         │         │             │
    ▼         ▼         ▼             ▼
┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐
│ LAPTOP 2│ │ LAPTOP 3│ │ LAPTOP 4│ │ Future  │
│ Worker 2│ │ Worker 3│ │ Worker 4│ │ Workers │
│ Dev Env │ │Databases│ │ Apps    │ │         │
└─────────┘ └─────────┘ └─────────┘ └─────────┘
```

## Prerequisites

All laptops need:
- Docker installed OR Boundary binary
- Same local network (192.168.1.x)
- mDNS/Avahi for .local resolution (optional)

---

## LAPTOP 1: Controller + Worker Setup

### Step 1: Install Boundary

```bash
# Download Boundary
wget https://releases.hashicorp.com/boundary/0.15.0/boundary_0.15.0_linux_amd64.zip
unzip boundary_0.15.0_linux_amd64.zip
sudo mv boundary /usr/local/bin/
sudo chmod +x /usr/local/bin/boundary

# Verify
boundary version
```

### Step 2: Setup PostgreSQL (Boundary Database)

```bash
# Using Docker (easiest)
docker run -d \
  --name boundary-postgres \
  --restart unless-stopped \
  -e POSTGRES_DB=boundary \
  -e POSTGRES_USER=boundary \
  -e POSTGRES_PASSWORD=boundary_secure_pass \
  -p 5432:5432 \
  -v boundary-db:/var/lib/postgresql/data \
  postgres:15

# Wait for PostgreSQL to be ready
sleep 10

# Initialize Boundary database
boundary database init \
  -config=/dev/stdin <<EOF
disable_mlock = true

controller {
  database {
    url = "postgresql://boundary:boundary_secure_pass@localhost:5432/boundary?sslmode=disable"
  }
}
EOF

# SAVE THE OUTPUT! It contains:
# - Initial admin password
# - Auth method ID
# - Recovery config
```

### Step 3: Create Controller Configuration

```bash
sudo mkdir -p /etc/boundary

# Get your laptop's local IP
LOCAL_IP=$(hostname -I | awk '{print $1}')

# Create controller config
sudo tee /etc/boundary/controller.hcl <<EOF
disable_mlock = true

controller {
  name = "laptop1-controller"
  description = "Primary Boundary Controller"
  
  database {
    url = "postgresql://boundary:boundary_secure_pass@localhost:5432/boundary?sslmode=disable"
  }
  
  public_cluster_addr = "$LOCAL_IP:9201"
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
  key = "sP1fnF5Xz85RrXyELHFeZg9Ad2qt4Z4bgNHVGtD6ung="
  key_id = "global_root"
}

kms "aead" {
  purpose = "worker-auth"
  aead_type = "aes-gcm"
  key = "8fZBjCUfN0TzjEGLQldGY4+iE9AkOvCfjh7+p0GtRBQ="
  key_id = "global_worker-auth"
}

kms "aead" {
  purpose = "recovery"
  aead_type = "aes-gcm"
  key = "8fZBjCUfN0TzjEGLQldGY4+iE9AkOvCfjh7+p0GtRBQ="
  key_id = "global_recovery"
}
EOF

# Generate new KMS keys (IMPORTANT: Use your own!)
echo "⚠️  GENERATE UNIQUE KMS KEYS:"
boundary config encrypt -format=json | jq -r '.kms.root.config.key'
```

### Step 4: Start Controller

```bash
# Create systemd service
sudo tee /etc/systemd/system/boundary-controller.service <<EOF
[Unit]
Description=Boundary Controller
After=network.target postgresql.service

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/boundary server -config=/etc/boundary/controller.hcl
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Start controller
sudo systemctl daemon-reload
sudo systemctl enable boundary-controller
sudo systemctl start boundary-controller

# Check status
sudo systemctl status boundary-controller

# Check logs
sudo journalctl -u boundary-controller -f
```

### Step 5: Initialize Admin User

```bash
# Authenticate as admin (use password from database init)
boundary authenticate password \
  -auth-method-id=ampw_1234567890 \
  -login-name=admin

# Set environment variable
export BOUNDARY_ADDR=http://localhost:9200

# Change admin password
boundary accounts change-password \
  -id=acctpw_1234567890 \
  -current-password=<initial-password> \
  -new-password=YourNewSecurePassword123!
```

### Step 6: Setup Worker 1 (on same laptop)

```bash
# Create worker config
sudo tee /etc/boundary/worker.hcl <<EOF
disable_mlock = true

worker {
  name = "laptop1-worker"
  description = "Worker on controller laptop"
  
  controllers = ["$LOCAL_IP:9201"]
  
  public_addr = "$LOCAL_IP:9202"
  
  tags {
    type = ["controller-laptop", "primary"]
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
  key = "8fZBjCUfN0TzjEGLQldGY4+iE9AkOvCfjh7+p0GtRBQ="
  key_id = "global_worker-auth"
}
EOF

# Create systemd service
sudo tee /etc/systemd/system/boundary-worker.service <<EOF
[Unit]
Description=Boundary Worker
After=network.target boundary-controller.service

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/boundary server -config=/etc/boundary/worker.hcl
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Start worker
sudo systemctl daemon-reload
sudo systemctl enable boundary-worker
sudo systemctl start boundary-worker

# Check status
sudo systemctl status boundary-worker
```

---

## LAPTOP 2, 3, 4: Worker Setup

Run this on each laptop:

```bash
# Install Boundary
wget https://releases.hashicorp.com/boundary/0.15.0/boundary_0.15.0_linux_amd64.zip
unzip boundary_0.15.0_linux_amd64.zip
sudo mv boundary /usr/local/bin/
sudo chmod +x /usr/local/bin/boundary

# Get local IP
LOCAL_IP=$(hostname -I | awk '{print $1}')

# Set controller IP (Laptop 1's IP)
CONTROLLER_IP="192.168.1.100"

# Create worker config
sudo mkdir -p /etc/boundary
sudo tee /etc/boundary/worker.hcl <<EOF
disable_mlock = true

worker {
  name = "$(hostname)-worker"
  description = "Worker on $(hostname)"
  
  controllers = ["$CONTROLLER_IP:9201"]
  
  public_addr = "$LOCAL_IP:9202"
  
  tags {
    hostname = ["$(hostname)"]
    type = ["dev-laptop"]
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
  key = "8fZBjCUfN0TzjEGLQldGY4+iE9AkOvCfjh7+p0GtRBQ="
  key_id = "global_worker-auth"
}
EOF

# Create systemd service
sudo tee /etc/systemd/system/boundary-worker.service <<EOF
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

# Start worker
sudo systemctl daemon-reload
sudo systemctl enable boundary-worker
sudo systemctl start boundary-worker

# Check status
sudo systemctl status boundary-worker
```

---

## Setup Admin Access from All Laptops

### On Laptop 1 (Controller)

```bash
# Login as admin
export BOUNDARY_ADDR=http://192.168.1.100:9200
boundary authenticate password \
  -auth-method-id=<auth-method-id> \
  -login-name=admin

# Create admin users for each laptop
boundary users create \
  -name=laptop2-admin \
  -description="Admin user for Laptop 2" \
  -scope-id=global

boundary users create \
  -name=laptop3-admin \
  -description="Admin user for Laptop 3" \
  -scope-id=global

boundary users create \
  -name=laptop4-admin \
  -description="Admin user for Laptop 4" \
  -scope-id=global

# Set passwords
boundary accounts create password \
  -auth-method-id=<auth-method-id> \
  -login-name=laptop2-admin \
  -password=SecurePass2!

boundary accounts create password \
  -auth-method-id=<auth-method-id> \
  -login-name=laptop3-admin \
  -password=SecurePass3!

boundary accounts create password \
  -auth-method-id=<auth-method-id> \
  -login-name=laptop4-admin \
  -password=SecurePass4!

# Add to admin role
ADMIN_ROLE_ID=$(boundary roles list -scope-id=global -format=json | jq -r '.items[] | select(.name=="Administration") | .id')

boundary roles add-principals \
  -id=$ADMIN_ROLE_ID \
  -principal=<laptop2-admin-user-id>

boundary roles add-principals \
  -id=$ADMIN_ROLE_ID \
  -principal=<laptop3-admin-user-id>

boundary roles add-principals \
  -id=$ADMIN_ROLE_ID \
  -principal=<laptop4-admin-user-id>
```

### On Other Laptops (2, 3, 4)

```bash
# Set controller address
export BOUNDARY_ADDR=http://192.168.1.100:9200

# Authenticate
boundary authenticate password \
  -auth-method-id=<auth-method-id> \
  -login-name=laptop2-admin

# Save auth token
echo "export BOUNDARY_ADDR=http://192.168.1.100:9200" >> ~/.bashrc
echo "export BOUNDARY_TOKEN=\$(cat ~/.boundary-token)" >> ~/.bashrc
```

---

## Create Access Targets

### Example 1: SSH to Any Laptop

```bash
# On Laptop 1 (as admin)
boundary targets create tcp \
  -name="laptop2-ssh" \
  -description="SSH to Laptop 2" \
  -default-port=22 \
  -address="192.168.1.101" \
  -scope-id=<project-scope-id>

boundary targets create tcp \
  -name="laptop3-ssh" \
  -description="SSH to Laptop 3" \
  -default-port=22 \
  -address="192.168.1.102" \
  -scope-id=<project-scope-id>

boundary targets create tcp \
  -name="laptop4-ssh" \
  -description="SSH to Laptop 4" \
  -default-port=22 \
  -address="192.168.1.103" \
  -scope-id=<project-scope-id>
```

### Example 2: Database Access

```bash
# If Laptop 3 runs SurrealDB
boundary targets create tcp \
  -name="laptop3-surrealdb" \
  -description="SurrealDB on Laptop 3" \
  -default-port=8000 \
  -address="192.168.1.102" \
  -scope-id=<project-scope-id>

# If Laptop 4 runs PostgreSQL
boundary targets create tcp \
  -name="laptop4-postgres" \
  -description="PostgreSQL on Laptop 4" \
  -default-port=5432 \
  -address="192.168.1.103" \
  -scope-id=<project-scope-id>
```

### Example 3: Web Services

```bash
# If Laptop 2 runs a web app on port 3000
boundary targets create tcp \
  -name="laptop2-webapp" \
  -description="Web app on Laptop 2" \
  -default-port=3000 \
  -address="192.168.1.101" \
  -scope-id=<project-scope-id>
```

---

## Usage Examples

### From Any Laptop - Connect to Another via SSH

```bash
# List available targets
boundary targets list

# Connect to Laptop 2 via SSH
boundary connect ssh -target-name=laptop2-ssh

# Or by target ID
boundary connect ssh -target-id=ttcp_1234567890
```

### From Any Laptop - Access Database

```bash
# Connect to SurrealDB on Laptop 3
boundary connect -target-name=laptop3-surrealdb

# This opens a local proxy, then connect:
surreal sql --conn http://localhost:PORT --ns prod --db main
```

### From Any Laptop - Access Web App

```bash
# Create tunnel to web app on Laptop 2
boundary connect -target-name=laptop2-webapp -listen-port=8080

# Then open browser:
open http://localhost:8080
```

---

## Web UI Access

### Access Boundary Admin UI

From any browser on the network:
```
http://192.168.1.100:9200
```

Login with your admin credentials.

---

## Advanced: Dynamic Host Catalog

Instead of static targets, use dynamic discovery:

```bash
# Create host catalog
boundary host-catalogs create static \
  -name="laptop-network" \
  -description="All laptops in home lab" \
  -scope-id=<project-scope-id>

# Add host sets
boundary host-sets create static \
  -name="dev-laptops" \
  -description="Development laptops" \
  -host-catalog-id=<catalog-id>

# Add hosts dynamically
boundary hosts create static \
  -name="laptop2" \
  -address="192.168.1.101" \
  -host-catalog-id=<catalog-id>

boundary hosts create static \
  -name="laptop3" \
  -address="192.168.1.102" \
  -host-catalog-id=<catalog-id>

boundary hosts create static \
  -name="laptop4" \
  -address="192.168.1.103" \
  -host-catalog-id=<catalog-id>
```

---

## Troubleshooting

### Check Controller Status
```bash
# On Laptop 1
sudo systemctl status boundary-controller
sudo journalctl -u boundary-controller -f
```

### Check Worker Status
```bash
# On any laptop
sudo systemctl status boundary-worker
sudo journalctl -u boundary-worker -f
```

### Test Connectivity
```bash
# From any laptop
curl http://192.168.1.100:9200/v1/scopes

# Check workers
boundary workers list
```

### Common Issues

**Workers not connecting:**
```bash
# Check firewall
sudo ufw allow 9201/tcp  # Controller cluster port
sudo ufw allow 9202/tcp  # Worker proxy port

# Check KMS key matches
grep "worker-auth" /etc/boundary/*.hcl
```

**Can't authenticate:**
```bash
# Verify auth method
boundary auth-methods list

# Reset password
boundary accounts change-password -id=<account-id>
```

---

## Security Hardening (Optional)

### Enable TLS

Generate certificates:
```bash
# Create CA
openssl req -x509 -newkey rsa:4096 -days 365 -nodes \
  -keyout ca-key.pem -out ca-cert.pem \
  -subj "/CN=Boundary CA"

# Create server cert
openssl req -newkey rsa:4096 -nodes \
  -keyout server-key.pem -out server-req.pem \
  -subj "/CN=boundary-controller.local"

openssl x509 -req -in server-req.pem -days 365 \
  -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial \
  -out server-cert.pem
```

Update configs:
```hcl
listener "tcp" {
  address = "0.0.0.0:9200"
  purpose = "api"
  tls_disable = false
  tls_cert_file = "/etc/boundary/certs/server-cert.pem"
  tls_key_file = "/etc/boundary/certs/server-key.pem"
}
```

---

## Quick Reference Card

```bash
# Controller (Laptop 1)
http://192.168.1.100:9200  # Admin UI
192.168.1.100:9201         # Cluster port (workers connect here)

# Common Commands
boundary authenticate password -auth-method-id=<id> -login-name=admin
boundary targets list
boundary connect ssh -target-name=<name>
boundary workers list
boundary sessions list

# Helper Aliases
alias b='boundary'
alias bauth='boundary authenticate password'
alias btargets='boundary targets list'
alias bssh='boundary connect ssh'
alias bworkers='boundary workers list'
```

---

## Next Steps

1. ✅ Setup controller on Laptop 1
2. ✅ Setup workers on Laptops 2, 3, 4
3. ✅ Create admin users for each laptop
4. ✅ Add SSH targets for each laptop
5. ✅ Test connections
6. 🔄 Add more targets (databases, services)
7. 🔄 Setup session recording (optional)
8. 🔄 Enable TLS (production)

Your 4-laptop mesh is now a zero-trust access network! 🎉

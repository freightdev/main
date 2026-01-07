# NixOS Deployment Guide

## 🎯 Overview

Your infrastructure runs on NixOS, which provides declarative, reproducible system configuration. This guide shows how to deploy the agentic system across your NixOS nodes.

## 📦 Your NixOS Nodes

| Node | Hostname | Specs | Purpose |
|------|----------|-------|---------|
| callbox | callbox | 4vCPU, 12GB RAM | CPU worker (chat, simple tasks) |
| gpubox | gpubox | 8vCPU+GPU, 32GB RAM | GPU worker (code generation) |
| workbox | workbox | 20vCPU, 24GB RAM | Controller + CPU worker |

## 🚀 Quick Start (Per Node)

### 1. Initial Setup

```bash
cd agentic-system

# Check your NixOS environment
./scripts/nix-deploy.sh check

# Should output:
# ✓ Nix found
# ✓ Flakes already enabled
```

### 2. Full Deployment

Run this on **each node** (callbox, gpubox, workbox):

```bash
sudo ./scripts/nix-deploy.sh all
```

This will:
1. ✅ Check Nix environment
2. ✅ Create `agentic` system user
3. ✅ Build with Nix dev shell
4. ✅ Install to `/opt/agentic-system`
5. ✅ Add NixOS module to `/etc/nixos/`
6. ✅ Rebuild NixOS configuration
7. ✅ Start systemd services

### 3. Verify

```bash
# Check service status
./scripts/nix-deploy.sh status

# View logs
./scripts/nix-deploy.sh logs

# On workbox, check controller endpoint
curl http://localhost:8080/health
```

## 📋 Detailed Steps

### On callbox

```bash
# SSH into callbox
ssh callbox

cd /path/to/agentic-system

# Deploy
sudo ./scripts/nix-deploy.sh all

# Check it's running
systemctl status agentic-callbox-worker

# View logs
journalctl -u agentic-callbox-worker -f
```

### On gpubox

```bash
# SSH into gpubox
ssh gpubox

cd /path/to/agentic-system

# Deploy (includes NVIDIA/CUDA setup)
sudo ./scripts/nix-deploy.sh all

# Check GPU access
nvidia-smi

# Check service
systemctl status agentic-gpubox-worker
```

### On workbox (Controller + Worker)

```bash
# SSH into workbox
ssh workbox

cd /path/to/agentic-system

# Set API keys first
export ANTHROPIC_API_KEY="your-key"
export OPENAI_API_KEY="your-key"

# Deploy
sudo ./scripts/nix-deploy.sh all

# Check both services
systemctl status agentic-controller
systemctl status agentic-workbox-worker

# Controller should be accessible
curl http://localhost:8080/health
```

## 🔧 NixOS Configuration Details

### What Gets Added to Your System

The deployment adds a NixOS module at `/etc/nixos/agentic-system.nix` and imports it in your `configuration.nix`:

```nix
# /etc/nixos/configuration.nix
{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./agentic-system.nix  # <- Added automatically
  ];
  
  # ... rest of your config
}
```

### Services Created

Depending on the node:

**callbox:**
- `agentic-callbox-worker.service`

**gpubox:**
- `agentic-gpubox-worker.service`
- NVIDIA drivers and CUDA configured

**workbox:**
- `agentic-controller.service`
- `agentic-workbox-worker.service`

### User and Permissions

A system user is created:
```bash
User: agentic
Group: agentic
Home: /opt/agentic-system
```

All services run as this user with security hardening:
- `NoNewPrivileges=true`
- `PrivateTmp=true`
- `ProtectSystem=strict`

## 🎨 Using Nix Flakes (Alternative Method)

### Enable Flakes

If not already enabled:

```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

### Build with Flake

```bash
cd agentic-system/nix

# Build the system
nix build

# Enter dev shell
nix develop

# Inside dev shell, build Rust project
cargo build --release --workspace
```

### Deploy with Flake

```bash
# Build and deploy using flake
./scripts/nix-deploy.sh flake
```

## 🔍 Management Commands

### Check Status

```bash
./scripts/nix-deploy.sh status
```

### View Logs

```bash
# Recent logs
./scripts/nix-deploy.sh logs

# Follow logs live
sudo journalctl -u agentic-controller -f
sudo journalctl -u agentic-callbox-worker -f
sudo journalctl -u agentic-gpubox-worker -f
```

### Restart Services

```bash
# Restart on current node
./scripts/nix-deploy.sh restart

# Or manually
sudo systemctl restart agentic-controller
sudo systemctl restart agentic-callbox-worker
```

### Stop Services

```bash
./scripts/nix-deploy.sh stop
```

### Rebuild After Changes

```bash
# After modifying code
./scripts/nix-deploy.sh build
./scripts/nix-deploy.sh install
./scripts/nix-deploy.sh restart
```

## 🏗️ Development Workflow on NixOS

### 1. Enter Development Shell

```bash
cd agentic-system
nix develop
```

You get:
- ✅ Latest Rust toolchain
- ✅ rust-analyzer
- ✅ All dependencies
- ✅ cargo-watch for auto-rebuild

### 2. Make Changes

```bash
# In the dev shell
cargo watch -x "build --release"
```

### 3. Test Locally

```bash
# Run controller
cargo run -p controller

# Run workers (separate terminals)
cargo run -p callbox-worker
cargo run -p gpubox-worker
cargo run -p workbox-worker
```

### 4. Deploy to System

```bash
exit  # Exit dev shell
./scripts/nix-deploy.sh build
./scripts/nix-deploy.sh install
./scripts/nix-deploy.sh restart
```

## 🔐 Environment Variables

Set these before deployment:

```bash
# On workbox (controller needs API keys)
export ANTHROPIC_API_KEY="sk-ant-..."
export OPENAI_API_KEY="sk-..."

# Optional: Custom model paths
export LLAMA_MODEL="/models/llama-3.1-8b.gguf"
export CANDLE_MODEL="/models/codellama-34b"
export OPENVINO_MODEL="/models/llama-3.1-8b-int4-ov"

# SurrealDB connection
export SURREAL_HOST="127.0.0.1:8000"
export SURREAL_PASSWORD="your-password"
```

To persist them, add to `/etc/nixos/agentic-system.nix`:

```nix
systemd.services.agentic-controller = {
  serviceConfig = {
    Environment = [
      "ANTHROPIC_API_KEY=sk-ant-..."
      "OPENAI_API_KEY=sk-..."
    ];
  };
};
```

Then rebuild:
```bash
sudo nixos-rebuild switch
```

## 🐛 Troubleshooting

### "Flakes not enabled"

```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

### "Build failed"

```bash
# Enter dev shell and check errors
nix develop
cargo build --release --workspace
```

### "Service won't start"

```bash
# Check logs
journalctl -u agentic-callbox-worker -n 100

# Check if binary exists
ls -la /opt/agentic-system/callbox-worker

# Check permissions
sudo chown -R agentic:agentic /opt/agentic-system
```

### "Can't find CUDA" (gpubox)

```bash
# Verify NVIDIA driver
nvidia-smi

# Check NixOS config has GPU support
cat /etc/nixos/agentic-system.nix | grep nvidia

# Rebuild NixOS
sudo nixos-rebuild switch
```

### "Controller not accessible"

```bash
# Check if running
systemctl status agentic-controller

# Check port is open
ss -tlnp | grep 8080

# Check firewall
sudo iptables -L | grep 8080
```

## 📝 Rollback

If something goes wrong:

```bash
# NixOS makes this easy - rollback to previous generation
sudo nixos-rebuild switch --rollback

# Or choose specific generation
sudo nixos-rebuild switch --rollback 2

# List generations
nix-env --list-generations --profile /nix/var/nix/profiles/system
```

## 🔄 Updates

### Update Rust Toolchain

```bash
cd agentic-system
nix flake update
nix develop
```

### Update System

```bash
# Pull latest changes
git pull

# Rebuild
./scripts/nix-deploy.sh all
```

## 📊 Monitoring

### Systemd Status

```bash
# All services
systemctl list-units 'agentic-*'

# Specific service details
systemctl show agentic-controller
```

### Resource Usage

```bash
# CPU/Memory per service
systemd-cgtop

# Specific service
systemctl status agentic-gpubox-worker
```

### Logs

```bash
# All agentic logs
journalctl -u 'agentic-*' -f

# Specific time range
journalctl -u agentic-controller --since "1 hour ago"

# With priority
journalctl -u agentic-controller -p err
```

## 🎯 Next Steps

1. ✅ Deploy to all three nodes (callbox, gpubox, workbox)
2. ✅ Verify services are running
3. ✅ Test controller endpoint on workbox
4. ✅ Try a simple conversation
5. ✅ Integrate with your existing SurrealDB
6. ✅ Connect to your FED-APP

Your NixOS nodes are now running a distributed AI orchestration system!

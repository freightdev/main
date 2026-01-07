# Per-Node Configuration Examples

This directory contains example NixOS configurations for each of your nodes.

## Usage

Copy the appropriate configuration to your node and include it in `/etc/nixos/configuration.nix`:

```bash
# On callbox
sudo cp callbox-example.nix /etc/nixos/
sudo nano /etc/nixos/configuration.nix
# Add: imports = [ ./callbox-example.nix ];
sudo nixos-rebuild switch
```

## Files

- `callbox-example.nix` - Configuration for callbox (4vCPU, 12GB RAM)
- `gpubox-example.nix` - Configuration for gpubox (8vCPU+GPU, 32GB RAM)
- `workbox-example.nix` - Configuration for workbox (20vCPU, 24GB RAM)
- `devbox-example.nix` - Configuration for devbox (22vCPU+NPU, 16GB RAM)

## Integration with Existing Config

These are meant to be included alongside your existing NixOS configuration, not replace it. They add:

1. The agentic system user
2. Systemd services for workers/controller
3. Required packages
4. Firewall rules
5. GPU/NPU configuration (where applicable)

Your existing configurations in `cfgs/nodes/` will still be read by the agentic system at runtime.

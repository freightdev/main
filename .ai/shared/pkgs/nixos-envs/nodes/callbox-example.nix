# callbox Node Configuration
# 4vCPU, 12GB RAM, CPU-only
# Purpose: Chat, simple queries, lightweight operations

{ config, pkgs, lib, ... }:

{
  # Hostname
  networking.hostName = "callbox";
  
  # Import the main agentic system module
  imports = [
    ../agentic-system.nix
  ];
  
  # Node-specific optimizations
  boot.kernelParams = [ 
    "mitigations=off"  # Performance boost for trusted environment
  ];
  
  # CPU governor for performance
  powerManagement.cpuFreqGovernor = "performance";
  
  # Increase file limits for worker
  security.pam.loginLimits = [
    { domain = "agentic"; type = "soft"; item = "nofile"; value = "65536"; }
    { domain = "agentic"; type = "hard"; item = "nofile"; value = "65536"; }
  ];
  
  # callbox-specific environment
  systemd.services.agentic-callbox-worker = {
    environment = {
      # Optimize for chat/lightweight tasks
      RUST_LOG = "info";
      WORKER_THREADS = "4";
    };
  };
  
  # Monitoring tools
  environment.systemPackages = with pkgs; [
    htop
    iotop
    nethogs
  ];
  
  # Optional: Automatic log rotation
  services.logrotate = {
    enable = true;
    settings = {
      "/var/log/agentic-callbox-worker.log" = {
        frequency = "daily";
        rotate = 7;
        compress = true;
      };
    };
  };
}

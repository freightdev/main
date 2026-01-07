# workbox Node Configuration
# 20vCPU, 24GB RAM, iGPU
# Purpose: Controller + Analysis worker (the brain of the system)

{ config, pkgs, lib, ... }:

{
  # Hostname
  networking.hostName = "workbox";
  
  # Import the main agentic system module
  imports = [
    ../agentic-system.nix
  ];
  
  # This is the controller node - more services needed
  systemd.services.agentic-controller = {
    environment = {
      RUST_LOG = "info";
      CONTROLLER_PORT = "8080";
      CONTROLLER_WORKERS = "20";
      
      # API keys (set these securely)
      # Better: use agenix or sops-nix for secrets
      ANTHROPIC_API_KEY = lib.mkDefault "";
      OPENAI_API_KEY = lib.mkDefault "";
      
      # SurrealDB connection
      SURREAL_HOST = "127.0.0.1:8000";
    };
    
    serviceConfig = {
      # Allow network binding
      AmbientCapabilities = "CAP_NET_BIND_SERVICE";
    };
  };
  
  # Controller needs to communicate with workers
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 
      8080  # Controller API
      8081  # Worker communication
      8082  # Metrics
    ];
  };
  
  # Performance optimizations for multi-core
  boot.kernelParams = [ 
    "mitigations=off"
    "transparent_hugepage=always"
  ];
  
  powerManagement.cpuFreqGovernor = "performance";
  
  # Increase connection limits for controller
  boot.kernel.sysctl = {
    "net.core.somaxconn" = 4096;
    "net.ipv4.tcp_max_syn_backlog" = 8192;
    "net.ipv4.ip_local_port_range" = "1024 65535";
    "net.core.rmem_max" = 134217728;
    "net.core.wmem_max" = 134217728;
  };
  
  # File limits for controller (handles many connections)
  security.pam.loginLimits = [
    { domain = "agentic"; type = "soft"; item = "nofile"; value = "1048576"; }
    { domain = "agentic"; type = "hard"; item = "nofile"; value = "1048576"; }
  ];
  
  # Additional packages for the controller node
  environment.systemPackages = with pkgs; [
    htop
    iotop
    nethogs
    tcpdump
    strace
    
    # For debugging
    gdb
    valgrind
    
    # Monitoring
    prometheus-node-exporter
  ];
  
  # Enable Prometheus node exporter for monitoring
  services.prometheus.exporters.node = {
    enable = true;
    port = 9100;
    enabledCollectors = [ "systemd" "processes" ];
  };
  
  # Reverse proxy (optional, if you want HTTPS)
  # services.nginx = {
  #   enable = true;
  #   recommendedProxySettings = true;
  #   virtualHosts."agentic.local" = {
  #     locations."/" = {
  #       proxyPass = "http://127.0.0.1:8080";
  #     };
  #   };
  # };
  
  # Log aggregation
  services.journald.extraConfig = ''
    SystemMaxUse=1G
    MaxRetentionSec=1week
  '';
}

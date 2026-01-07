# NixOS Deployment Configuration for Agentic System

{ config, pkgs, lib, ... }:

let
  agenticSystemRoot = "/opt/agentic-system";
  user = "agentic";
  group = "agentic";
  
  # Node-specific configurations
  nodeConfigs = {
    callbox = {
      workerId = "callbox-01";
      backend = "cpu";
      memoryGb = "12";
      vcpus = "4";
      modelPath = "/models/llama-3.1-8b.gguf";
    };
    
    gpubox = {
      workerId = "gpubox-01";
      backend = "gpu";
      memoryGb = "32";
      vcpus = "8";
      modelPath = "/models/codellama-34b";
      cudaDevice = "0";
    };
    
    workbox = {
      workerId = "workbox-01";
      backend = "cpu";
      memoryGb = "24";
      vcpus = "20";
      modelPath = "/models/llama-3.1-8b.gguf";
      isController = true;
    };
  };

in {
  # Create dedicated user for the agentic system
  users.users.${user} = {
    isSystemUser = true;
    group = group;
    description = "Agentic System Service User";
    home = agenticSystemRoot;
    createHome = true;
  };

  users.groups.${group} = {};

  # System packages needed
  environment.systemPackages = with pkgs; [
    rustup
    gcc
    pkg-config
    openssl
    # Add CUDA support for gpubox
    (lib.mkIf (config.networking.hostName == "gpubox") cudaPackages.cudatoolkit)
  ];

  # Enable Rust overlay for latest toolchain
  nixpkgs.overlays = [
    (import (builtins.fetchTarball "https://github.com/oxalica/rust-overlay/archive/master.tar.gz"))
  ];

  # CALLBOX Configuration
  systemd.services.agentic-callbox-worker = lib.mkIf (config.networking.hostName == "callbox") {
    description = "Agentic System - callbox Worker";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    
    serviceConfig = {
      Type = "simple";
      User = user;
      Group = group;
      WorkingDirectory = agenticSystemRoot;
      ExecStart = "${agenticSystemRoot}/target/release/callbox-worker";
      Restart = "on-failure";
      RestartSec = "10s";
      
      # Environment variables
      Environment = [
        "WORKER_ID=${nodeConfigs.callbox.workerId}"
        "WORKER_BACKEND=${nodeConfigs.callbox.backend}"
        "WORKER_MEMORY_GB=${nodeConfigs.callbox.memoryGb}"
        "LLAMA_CPP_MODEL_PATH=${nodeConfigs.callbox.modelPath}"
        "RUST_LOG=info"
      ];
      
      # Security hardening
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [ agenticSystemRoot ];
    };
  };

  # GPUBOX Configuration
  systemd.services.agentic-gpubox-worker = lib.mkIf (config.networking.hostName == "gpubox") {
    description = "Agentic System - gpubox Worker (GPU)";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    
    serviceConfig = {
      Type = "simple";
      User = user;
      Group = group;
      WorkingDirectory = agenticSystemRoot;
      ExecStart = "${agenticSystemRoot}/target/release/gpubox-worker";
      Restart = "on-failure";
      RestartSec = "10s";
      
      # Environment variables
      Environment = [
        "WORKER_ID=${nodeConfigs.gpubox.workerId}"
        "WORKER_BACKEND=${nodeConfigs.gpubox.backend}"
        "WORKER_MEMORY_GB=${nodeConfigs.gpubox.memoryGb}"
        "CANDLE_MODEL_PATH=${nodeConfigs.gpubox.modelPath}"
        "CUDA_VISIBLE_DEVICES=${nodeConfigs.gpubox.cudaDevice}"
        "RUST_LOG=info"
      ];
      
      # Security hardening (less restrictive for GPU access)
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ReadWritePaths = [ agenticSystemRoot "/dev/nvidia0" "/dev/nvidiactl" ];
      
      # GPU access
      SupplementaryGroups = [ "video" ];
    };
  };

  # WORKBOX Configuration (Controller + Worker)
  systemd.services.agentic-controller = lib.mkIf (config.networking.hostName == "workbox") {
    description = "Agentic System Controller";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    
    serviceConfig = {
      Type = "simple";
      User = user;
      Group = group;
      WorkingDirectory = agenticSystemRoot;
      ExecStart = "${agenticSystemRoot}/target/release/controller";
      Restart = "on-failure";
      RestartSec = "10s";
      
      # Environment variables
      Environment = [
        "RUST_LOG=info"
        "CONTROLLER_PORT=8080"
      ];
      
      # Security hardening
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [ agenticSystemRoot ];
    };
  };

  systemd.services.agentic-workbox-worker = lib.mkIf (config.networking.hostName == "workbox") {
    description = "Agentic System - workbox Worker";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "agentic-controller.service" ];
    
    serviceConfig = {
      Type = "simple";
      User = user;
      Group = group;
      WorkingDirectory = agenticSystemRoot;
      ExecStart = "${agenticSystemRoot}/target/release/workbox-worker";
      Restart = "on-failure";
      RestartSec = "10s";
      
      # Environment variables
      Environment = [
        "WORKER_ID=${nodeConfigs.workbox.workerId}"
        "WORKER_BACKEND=${nodeConfigs.workbox.backend}"
        "WORKER_MEMORY_GB=${nodeConfigs.workbox.memoryGb}"
        "LLAMA_CPP_MODEL_PATH=${nodeConfigs.workbox.modelPath}"
        "RUST_LOG=info"
      ];
      
      # Security hardening
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [ agenticSystemRoot ];
    };
  };

  # Firewall rules for inter-node communication
  networking.firewall = {
    allowedTCPPorts = [ 8080 8081 8082 ];
    allowedUDPPorts = [ ];
  };

  # Optional: Enable CUDA for gpubox
  hardware.opengl = lib.mkIf (config.networking.hostName == "gpubox") {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  services.xserver.videoDrivers = lib.mkIf (config.networking.hostName == "gpubox") [ "nvidia" ];
  hardware.nvidia = lib.mkIf (config.networking.hostName == "gpubox") {
    modesetting.enable = true;
    powerManagement.enable = false;
    open = false;
    nvidiaSettings = true;
  };
}

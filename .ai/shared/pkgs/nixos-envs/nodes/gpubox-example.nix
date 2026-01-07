# gpubox Node Configuration
# 8vCPU, 32GB RAM, GPU 4GB VRAM
# Purpose: Code generation, heavy model inference, GPU-intensive tasks

{ config, pkgs, lib, ... }:

{
  # Hostname
  networking.hostName = "gpubox";
  
  # Import the main agentic system module
  imports = [
    ../agentic-system.nix
  ];
  
  # Enable NVIDIA drivers
  services.xserver.videoDrivers = [ "nvidia" ];
  
  # NVIDIA configuration
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    
    # Use the appropriate driver package
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
  
  # OpenGL for compute
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
    
    extraPackages = with pkgs; [
      libGL
      libGLU
    ];
  };
  
  # CUDA packages
  environment.systemPackages = with pkgs; [
    cudatoolkit
    cudaPackages.cudnn
    linuxPackages.nvidia_x11
    nvtop  # GPU monitoring
    
    # Development tools
    htop
    nvitop
  ];
  
  # GPU-specific environment variables
  systemd.services.agentic-gpubox-worker = {
    environment = {
      CUDA_VISIBLE_DEVICES = "0";
      CUDA_CACHE_PATH = "/var/cache/cuda";
      RUST_LOG = "info";
      WORKER_THREADS = "8";
    };
    
    serviceConfig = {
      # GPU access
      DeviceAllow = [
        "/dev/nvidia0 rw"
        "/dev/nvidiactl rw"
        "/dev/nvidia-uvm rw"
        "/dev/nvidia-modeset rw"
      ];
    };
  };
  
  # Create CUDA cache directory
  systemd.tmpfiles.rules = [
    "d /var/cache/cuda 0755 agentic agentic -"
  ];
  
  # Increase shared memory for large models
  boot.kernel.sysctl = {
    "kernel.shmmax" = 34359738368;  # 32GB
    "kernel.shmall" = 8388608;
  };
  
  # Performance tuning
  powerManagement.cpuFreqGovernor = "performance";
  
  # Firewall for GPU metrics (if using Prometheus)
  networking.firewall.allowedTCPPorts = [ 9100 ];
}

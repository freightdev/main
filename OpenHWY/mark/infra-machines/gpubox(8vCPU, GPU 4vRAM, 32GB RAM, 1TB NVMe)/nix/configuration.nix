{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./flake.nix
  ];

  networking.hostName = "callbox";

  # Enable your AI platform
  services.ai-platform = {
    enable = true;
    openwebuiPort = 3000;
    ollamaNodes = [
      "node1.local:11434"
      "node2.local:11434"
      "node3.local:11434"
      "node4.local:11434"
    ];
  };

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    git
    htop
    duckdb
  ];

  system.stateVersion = "24.05";
}

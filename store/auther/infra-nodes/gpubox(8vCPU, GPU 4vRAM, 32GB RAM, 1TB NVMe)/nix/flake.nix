{
  description = "AI Orchestration Platform - Callbox";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in
      {
        # Development shell
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Container orchestration
            nomad
            consul

            # AI/ML
            ollama

            # Automation
            # n8n (you'll need to package this or use docker)

            # Databases
            duckdb

            # Web
            nginx

            # Utils
            jq
            curl
            podman
            terraform
          ];

          shellHook = ''
            echo "🤖 AI Orchestration Environment Ready"
            echo "Hostname: callbox"
            echo ""
            echo "Available services:"
            echo "  - Nomad: nomad agent -dev"
            echo "  - Consul: consul agent -dev"
            echo "  - Ollama: ollama serve"
            echo ""
          '';
        };

        # NixOS module for your services
        nixosModules.ai-platform = { config, lib, pkgs, ... }: {
          options.services.ai-platform = {
            enable = lib.mkEnableOption "AI Orchestration Platform";

            openwebuiPort = lib.mkOption {
              type = lib.types.port;
              default = 3000;
              description = "Port for OpenWebUI";
            };

            ollamaNodes = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [];
              description = "List of Ollama node addresses";
            };
          };

          config = lib.mkIf config.services.ai-platform.enable {
            # Nomad
            services.nomad = {
              enable = true;
              settings = {
                server = {
                  enabled = true;
                  bootstrap_expect = 1;
                };
                client = {
                  enabled = true;
                };
                datacenter = "ai-lab";
              };
            };

            # Consul
            services.consul = {
              enable = true;
              extraConfig = {
                datacenter = "ai-lab";
                server = true;
                bootstrap_expect = 1;
                ui_config = {
                  enabled = true;
                };
              };
            };

            # Ollama
            services.ollama = {
              enable = true;
              acceleration = "cuda"; # or "rocm" for AMD
              host = "0.0.0.0";
              port = 11434;
            };

            # Nginx reverse proxy
            services.nginx = {
              enable = true;
              recommendedProxySettings = true;
              recommendedTlsSettings = true;

              upstreams.ollama = {
                servers = builtins.listToAttrs (
                  builtins.map (node: {
                    name = node;
                    value = { };
                  }) config.services.ai-platform.ollamaNodes
                );
              };

              virtualHosts."ollama.local" = {
                locations."/" = {
                  proxyPass = "http://ollama";
                  extraConfig = ''
                    proxy_set_header Host $host;
                    proxy_set_header X-Real-IP $remote_addr;
                  '';
                };
              };
            };

            # Open firewall ports
            networking.firewall.allowedTCPPorts = [
              3000  # OpenWebUI
              4646  # Nomad
              8500  # Consul
              11434 # Ollama
              80    # Nginx
              443   # Nginx SSL
            ];
          };
        };
      }
    );
}

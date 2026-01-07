{
  description = "Agentic Rust System - Distributed AI Orchestration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, rust-overlay, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };
        
        rustToolchain = pkgs.rust-bin.stable.latest.default.override {
          extensions = [ "rust-src" "rust-analyzer" ];
        };

        # Build the agentic system
        agenticSystem = pkgs.rustPlatform.buildRustPackage rec {
          pname = "agentic-system";
          version = "0.1.0";
          
          src = ../.;
          
          cargoLock = {
            lockFile = ../Cargo.lock;
          };
          
          nativeBuildInputs = with pkgs; [
            pkg-config
            rustToolchain
          ];
          
          buildInputs = with pkgs; [
            openssl
            # Add more dependencies as needed
          ];
          
          # Build all workspace members
          cargoBuildFlags = [ "--workspace" ];
          
          meta = with pkgs.lib; {
            description = "Distributed AI orchestration system";
            homepage = "https://github.com/yourusername/agentic-system";
            license = licenses.mit;
            maintainers = [ ];
          };
        };

      in {
        packages = {
          default = agenticSystem;
          agentic-system = agenticSystem;
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            rustToolchain
            pkg-config
            openssl
            cargo-watch
            cargo-edit
            rust-analyzer
          ];
          
          shellHook = ''
            echo "🚀 Agentic System Development Environment"
            echo "Rust version: $(rustc --version)"
            echo ""
            echo "Available commands:"
            echo "  cargo build --release     # Build all crates"
            echo "  cargo test                # Run tests"
            echo "  cargo run -p controller   # Run controller"
            echo "  cargo run -p callbox-worker   # Run callbox worker"
            echo "  cargo run -p gpubox-worker    # Run gpubox worker"
            echo "  cargo run -p workbox-worker   # Run workbox worker"
          '';
        };

        # NixOS module
        nixosModules.default = import ./agentic-system.nix;
      }
    ) // {
      # Per-node configurations
      nixosConfigurations = {
        callbox = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./agentic-system.nix
            ({ config, ... }: {
              networking.hostName = "callbox";
            })
          ];
        };

        gpubox = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./agentic-system.nix
            ({ config, ... }: {
              networking.hostName = "gpubox";
            })
          ];
        };

        workbox = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./agentic-system.nix
            ({ config, ... }: {
              networking.hostName = "workbox";
            })
          ];
        };
      };
    };
}

# shell.nix - Quick development environment
# Usage: nix-shell

{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    # Rust toolchain
    rustc
    cargo
    rustfmt
    clippy
    rust-analyzer
    
    # Build dependencies
    pkg-config
    openssl
    
    # Development tools
    cargo-watch
    cargo-edit
    cargo-expand
    
    # System tools
    git
    
    # Optional: CUDA for GPU development
    # Uncomment if you're on gpubox
    # cudatoolkit
  ];
  
  # Environment variables
  RUST_BACKTRACE = "1";
  RUST_LOG = "info";
  
  shellHook = ''
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🚀 Agentic System - Development Environment"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📦 Rust: $(rustc --version)"
    echo "📦 Cargo: $(cargo --version)"
    echo ""
    echo "🛠️  Available commands:"
    echo "  cargo build --release          # Build all crates"
    echo "  cargo test                     # Run tests"
    echo "  cargo watch -x 'check'         # Auto-check on changes"
    echo "  cargo run -p controller        # Run controller"
    echo "  cargo run -p callbox-worker    # Run callbox worker"
    echo "  cargo run -p gpubox-worker     # Run gpubox worker"
    echo "  cargo run -p workbox-worker    # Run workbox worker"
    echo ""
    echo "📚 Documentation:"
    echo "  cargo doc --open               # Open Rust docs"
    echo ""
    echo "🔧 Deployment:"
    echo "  ./scripts/nix-deploy.sh all    # Deploy to current node"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  '';
}

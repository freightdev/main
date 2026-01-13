#!/usr/bin/env bash
# Example script to start different workers

set -e

WORKER_TYPE="${1:-cpu}"
WORKER_ID="${2:-worker-$(date +%s)}"

echo "Starting $WORKER_TYPE worker with ID: $WORKER_ID"

case $WORKER_TYPE in
  cpu)
    echo "Starting CPU worker (llama.cpp backend)"
    export WORKER_BACKEND="cpu"
    export WORKER_MEMORY_GB="32"
    export LLAMA_CPP_MODEL_PATH="/models/llama-3.1-8b.gguf"
    ;;
    
  gpu)
    echo "Starting GPU worker (Candle backend)"
    export WORKER_BACKEND="gpu"
    export WORKER_MEMORY_GB="24"
    export CANDLE_MODEL_PATH="/models/codellama-34b"
    export CUDA_VISIBLE_DEVICES="0"
    ;;
    
  npu)
    echo "Starting NPU worker (OpenVINO backend)"
    export WORKER_BACKEND="npu"
    export WORKER_MEMORY_GB="10"
    export OPENVINO_MODEL_PATH="/models/llama-3.1-8b-int4-ov"
    ;;
    
  *)
    echo "Unknown worker type: $WORKER_TYPE"
    echo "Usage: $0 [cpu|gpu|npu] [worker-id]"
    exit 1
    ;;
esac

export WORKER_ID="$WORKER_ID"

# Start the worker
# cargo run -p worker --release
echo "Would start worker with:"
echo "  Type: $WORKER_BACKEND"
echo "  ID: $WORKER_ID"
echo "  Memory: $WORKER_MEMORY_GB GB"

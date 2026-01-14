# Agentic System Configuration

[controls]
max_concurrent_tasks = {}
task_timeout_seconds = {}
enable_external_help = {}

[workers]
ip = <>
[[workers.cpu]]
id = {}
backend = {}
model_path = {}
context_size = {}
memory_gb = {}
task_types = {}

# GPU Worker (Candle)
[[workers.gpu]]
id = {}
backend = {}
model_path = {}
device = {}
memory_gb = {}
task_types = {}

# NPU Worker (OpenVINO)
[[workers.npu]]
id = {}
backend = {}
model_path = {}
device = {}
memory_gb = {}
task_types = {}

# External API configuration
[external_models]
enable_claude = {}
enable_openai = {}
fallback_to_external = {}

[external_models.{}]
model = {}
max_tokens = {}
# API key should be set via {} env var

[external_models.{}]
model = {}
max_tokens = {}
# API key should be set via {} env var

# Resource limits
[resources]
max_memory_per_worker_gb = {}
max_cpu_percent = {}
max_gpu_memory_gb = {}

# Task scheduling
[scheduling]
strategy = {}  # Options: least_loaded, round_robin, priority
enable_task_dependencies = {}
max_retries = {}

# Logging
[logging]
level = {}  # Options: trace, debug, info, warn, error
format = {}  # Options: json, pretty, markdown
log_to_file = {}
log_file_path = {}

# Distributed settings
[distributed]
enable = {}
coordinator_host = {}
coordinator_port = {}
heartbeat_interval_seconds = {}

# Crate builder settings
[crate_builder]
workspace_root = {}
auto_compile = {}
run_tests_before_deploy = {}

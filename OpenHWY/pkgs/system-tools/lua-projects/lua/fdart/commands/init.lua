-- lua/rustydart/commands/init.lua
-- Initialize rustydart in a project

local config = require("config")
local logger = require("logger")
local utils = require("utils")

local M = {}

local DEFAULT_CONFIG = [[
# rustydart configuration
project_root: .
lib_dir: lib
deep_scan: true
backup: true
verbose: false
log_level: info
quiet: false

# File patterns
include_patterns:
  - "%.dart$"
  
exclude_patterns:
  - "%.g%.dart$"
  - "%.freezed%.dart$"
  - "%.mocks%.dart$"
  
exclude_dirs:
  - "%.git"
  - "%.dart_tool"
  - "build"
  - "test"

# Analysis settings
max_file_size: 500
max_fix_iterations: 5
auto_pubget: true
auto_format: true

# Barrel settings
barrel_filename: index.dart
auto_barrel: true

# AI/Ollama settings
ollama:
  enabled: false
  host: localhost
  port: 11434
  model: codellama:13b
  timeout: 300
  max_context_lines: 100
  allow_command_execution: false
  allowed_commands:
    - rustydart
    - flutter
    - dart
    - git
    - tree
    - cat
    - grep
    - find
  system_prompt: |
    You are an expert Flutter/Dart developer assistant.
    You help fix code issues, suggest improvements, and can execute safe commands.
    Always explain your reasoning and be precise with code suggestions.

# Import organization
import_order:
  - "dart:"
  - "package:flutter/"
  - "package:"
  - relative

# Cache settings
use_cache: true
cache_file: .rustydart_cache.json
cache_ttl: 3600

# Output settings
output_format: pretty
color: true
icons: true
]]

function M.run(opts)
  local config_file = opts.params.config or ".rustydart.yaml"
  
  -- Check if config already exists
  if utils.file_exists(config_file) then
    if not opts.params.force then
      logger.warn("Configuration file already exists: " .. config_file)
      logger.info("Use --force to overwrite")
      return false
    else
      logger.warn("Overwriting existing configuration...")
    end
  end
  
  -- Check if this is a Flutter/Dart project
  if not utils.file_exists("pubspec.yaml") then
    logger.warn("pubspec.yaml not found - this may not be a Flutter/Dart project")
    logger.info("Continuing anyway...")
  end
  
  -- Write config file
  logger.info("Creating configuration file: " .. config_file)
  
  local file = io.open(config_file, "w")
  if not file then
    logger.error("Failed to create configuration file")
    return false
  end
  
  file:write(DEFAULT_CONFIG)
  file:close()
  
  logger.success("✓ Configuration file created: " .. config_file)
  logger.info("")
  logger.info("Next steps:")
  logger.info("  1. Edit " .. config_file .. " to customize settings")
  logger.info("  2. Run 'rustydart doctor' to verify setup")
  logger.info("  3. Run 'rustydart fix' to auto-fix imports")
  
  return true
end

return M
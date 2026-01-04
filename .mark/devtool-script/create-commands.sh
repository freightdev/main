#!/bin/bash
# create_commands.sh - Generate all missing command files

COMMANDS_DIR="lua/rustydart/commands"

# Create directory if it doesn't exist
mkdir -p "$COMMANDS_DIR"

# Create init.lua command
cat > "$COMMANDS_DIR/init.lua" << 'EOF'
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
  - build
  - test

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
  allow_command_execution: false
  allowed_commands:
    - rustydart
    - flutter
    - dart
    - git

# Import organization
import_order:
  - "dart:"
  - "package:flutter/"
  - "package:"
  - relative

# Cache settings
use_cache: true
cache_ttl: 3600

# Output settings
output_format: pretty
color: true
icons: true
]]

function M.run(opts)
  local config_file = opts.params.config or ".rustydart.yaml"
  
  if utils.file_exists(config_file) then
    logger.warn("Configuration file already exists: " .. config_file)
    logger.info("Use --force to overwrite")
    
    if not opts.params.force then
      return false
    end
  end
  
  logger.info("Creating configuration file: " .. config_file)
  
  local file = io.open(config_file, "w")
  if not file then
    logger.error("Failed to create configuration file")
    return false
  end
  
  file:write(DEFAULT_CONFIG)
  file:close()
  
  logger.success("✓ Configuration file created: " .. config_file)
  logger.info("Edit the file to customize settings")
  logger.info("Run 'rustydart doctor' to verify setup")
  
  return true
end

return M
EOF

# Create config_cmd.lua command
cat > "$COMMANDS_DIR/config_cmd.lua" << 'EOF'
-- lua/rustydart/commands/config_cmd.lua
-- Manage configuration

local config = require("config")
local logger = require("logger")

local M = {}

function M.run(opts)
  local args = opts.args or {}
  local action = args[1]
  
  if not action or action == "show" then
    -- Show all configuration
    logger.info("Current configuration:")
    local cfg = config.get_all()
    for k, v in pairs(cfg) do
      print(string.format("%s = %s", k, tostring(v)))
    end
    return true
  end
  
  if action == "get" then
    local key = args[2]
    if not key then
      logger.error("Usage: rustydart config get <key>")
      return false
    end
    
    local value = config.get(key)
    if value ~= nil then
      print(value)
      return true
    else
      logger.error("Key not found: " .. key)
      return false
    end
  end
  
  if action == "set" then
    local key = args[2]
    local value = args[3]
    
    if not key or not value then
      logger.error("Usage: rustydart config set <key> <value>")
      return false
    end
    
    config.set(key, value)
    local ok, err = config.save()
    
    if ok then
      logger.success("✓ Configuration updated")
      return true
    else
      logger.error("Failed to save configuration: " .. (err or "unknown error"))
      return false
    end
  end
  
  logger.error("Unknown action: " .. action)
  logger.info("Available actions: show, get, set")
  return false
end

return M
EOF

# Create analyze.lua command
cat > "$COMMANDS_DIR/analyze.lua" << 'EOF'
-- lua/rustydart/commands/analyze.lua
-- Code analysis command

local logger = require("logger")
local analyzer = require("analyzer")
local config = require("config")

local M = {}

function M.run(opts)
  local dir = opts.params.dir or config.get("lib_dir") or "lib"
  
  logger.info("Analyzing code in: " .. dir)
  
  local results = analyzer.analyze_directory(dir)
  
  if not results then
    logger.error("Analysis failed")
    return false
  end
  
  logger.success("✓ Analysis complete")
  
  -- Display results
  logger.info("\nResults:")
  logger.info("  Files analyzed: " .. (results.file_count or 0))
  logger.info("  Total lines: " .. (results.line_count or 0))
  logger.info("  Issues found: " .. (results.issue_count or 0))
  
  if results.issues and #results.issues > 0 then
    logger.info("\nIssues:")
    for _, issue in ipairs(results.issues) do
      logger.warn("  " .. issue)
    end
  end
  
  return true
end

return M
EOF

# Create fix.lua command
cat > "$COMMANDS_DIR/fix.lua" << 'EOF'
-- lua/rustydart/commands/fix.lua
-- Auto-fix imports command

local logger = require("logger")
local fixer = require("fixer")
local config = require("config")

local M = {}

function M.run(opts)
  local dir = opts.params.dir or config.get("lib_dir") or "lib"
  local dry_run = opts.params["dry-run"] or false
  
  if dry_run then
    logger.info("Checking imports in: " .. dir .. " (dry-run)")
  else
    logger.info("Fixing imports in: " .. dir)
  end
  
  local results = fixer.fix_directory(dir, {
    dry_run = dry_run,
    backup = not opts.params["no-backup"],
    verbose = opts.params.verbose
  })
  
  if not results then
    logger.error("Fix failed")
    return false
  end
  
  if dry_run then
    logger.success("✓ Check complete")
  else
    logger.success("✓ Fix complete")
  end
  
  logger.info("  Files processed: " .. (results.files_processed or 0))
  logger.info("  Imports added: " .. (results.imports_added or 0))
  logger.info("  Imports removed: " .. (results.imports_removed or 0))
  
  return true
end

return M
EOF

# Create debug.lua command  
cat > "$COMMANDS_DIR/debug.lua" << 'EOF'
-- lua/rustydart/commands/debug.lua
-- Debug and auto-fix build errors

local logger = require("logger")
local config = require("config")

local M = {}

function M.run(opts)
  logger.info("Running Flutter build with debugging...")
  
  local mode = opts.params.mode or "analyze"
  local cmd = mode == "run" and "flutter run" or "flutter analyze"
  
  logger.info("Executing: " .. cmd)
  
  local handle = io.popen(cmd .. " 2>&1")
  if not handle then
    logger.error("Failed to execute command")
    return false
  end
  
  local output = handle:read("*a")
  local success = handle:close()
  
  print(output)
  
  if success then
    logger.success("✓ No issues found")
    return true
  else
    logger.warn("Issues detected - checking for auto-fixable problems...")
    
    -- Try to auto-fix common issues
    if output:match("import") or output:match("not found") then
      logger.info("Attempting to fix imports...")
      local fixer = require("fixer")
      local dir = config.get("lib_dir") or "lib"
      fixer.fix_directory(dir, { verbose = opts.params.verbose })
      
      logger.info("Re-running analysis...")
      os.execute(cmd)
    end
    
    return false
  end
end

return M
EOF

# Create remaining stub commands
for cmd in ai barrel build clean deps find format index organize_imports scaffold stats tree watch cmd; do
  cat > "$COMMANDS_DIR/${cmd}.lua" << EOF
-- lua/rustydart/commands/${cmd}.lua
-- ${cmd} command

local logger = require("logger")

local M = {}

function M.run(opts)
  logger.info("${cmd} command")
  logger.warn("This command is not yet fully implemented")
  logger.info("Coming soon!")
  return true
end

return M
EOF
done

echo "✓ All command files created in $COMMANDS_DIR"
echo "Run: chmod +x create_commands.sh && ./create_commands.sh"
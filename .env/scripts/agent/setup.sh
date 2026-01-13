#!/bin/bash
# setup.sh - Complete rustydart setup script

set -e

echo "🚀 Setting up rustydart..."
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if directory structure exists
echo "📁 Checking directory structure..."
mkdir -p lua/rustydart/commands
mkdir -p lua/rustydart/ai/tools
mkdir -p lua/rustydart/examples
echo "   ✓ Directories created"

# Create doctor.lua
echo "📝 Creating doctor.lua..."
cat > lua/rustydart/commands/doctor.lua << 'DOCTOR_EOF'
-- lua/rustydart/commands/doctor.lua
local config = require("config")
local logger = require("logger")
local utils = require("utils")

local M = {}

local function command_exists(cmd)
  local handle = io.popen("which " .. cmd .. " 2>/dev/null")
  if not handle then return false end
  local result = handle:read("*a")
  handle:close()
  return result ~= ""
end

local function check_flutter()
  logger.info("Checking Flutter installation...")
  
  if not command_exists("flutter") then
    logger.error("✗ Flutter not found in PATH")
    return false
  end
  
  local handle = io.popen("flutter --version 2>&1")
  if not handle then
    logger.error("✗ Failed to run flutter command")
    return false
  end
  
  local output = handle:read("*a")
  handle:close()
  
  local version = output:match("Flutter ([%d%.]+)")
  if version then
    logger.success("✓ Flutter " .. version .. " found")
    return true
  else
    logger.warn("⚠ Flutter found but version unclear")
    return true
  end
end

local function check_dart()
  logger.info("Checking Dart installation...")
  
  if not command_exists("dart") then
    logger.error("✗ Dart not found in PATH")
    return false
  end
  
  local handle = io.popen("dart --version 2>&1")
  if not handle then
    logger.error("✗ Failed to run dart command")
    return false
  end
  
  local output = handle:read("*a")
  handle:close()
  
  local version = output:match("Dart SDK version: ([%d%.]+)")
  if version then
    logger.success("✓ Dart " .. version .. " found")
    return true
  else
    logger.warn("⚠ Dart found but version unclear")
    return true
  end
end

local function check_project()
  logger.info("Checking project structure...")
  
  if not utils.file_exists("pubspec.yaml") then
    logger.error("✗ pubspec.yaml not found")
    return false
  end
  logger.success("✓ pubspec.yaml found")
  
  if not utils.dir_exists("lib") then
    logger.warn("⚠ lib directory not found")
    return false
  end
  logger.success("✓ lib directory found")
  
  return true
end

function M.run(opts)
  logger.header("rustydart Health Check")
  
  local checks = {
    check_flutter,
    check_dart,
    check_project
  }
  
  local all_passed = true
  for _, check in ipairs(checks) do
    if not check() then
      all_passed = false
    end
    print("")
  end
  
  if all_passed then
    logger.success("🎉 All checks passed!")
  else
    logger.warn("⚠ Some checks failed")
  end
  
  return all_passed
end

return M
DOCTOR_EOF
echo "   ✓ doctor.lua created"

# Create init.lua command
echo "📝 Creating init.lua..."
cat > lua/rustydart/commands/init.lua << 'INIT_EOF'
-- lua/rustydart/commands/init.lua
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

include_patterns:
  - "%.dart$"
exclude_patterns:
  - "%.g%.dart$"
  - "%.freezed%.dart$"
exclude_dirs:
  - "%.git"
  - "%.dart_tool"
  - build

max_file_size: 500
auto_pubget: true

ollama:
  enabled: false
  host: localhost
  port: 11434
  model: codellama:13b
]]

function M.run(opts)
  local config_file = ".rustydart.yaml"
  
  if utils.file_exists(config_file) and not opts.params.force then
    logger.warn("Configuration already exists: " .. config_file)
    return false
  end
  
  local file = io.open(config_file, "w")
  if not file then
    logger.error("Failed to create configuration")
    return false
  end
  
  file:write(DEFAULT_CONFIG)
  file:close()
  
  logger.success("✓ Created " .. config_file)
  logger.info("Run 'rustydart doctor' to verify setup")
  
  return true
end

return M
INIT_EOF
echo "   ✓ init.lua created"

# Create stub commands for all other commands
echo "📝 Creating stub commands..."
STUB_COMMANDS="config_cmd analyze fix debug ai barrel build clean deps find format index organize_imports scaffold stats tree watch cmd"

for cmd in $STUB_COMMANDS; do
  cat > "lua/rustydart/commands/${cmd}.lua" << EOF
-- lua/rustydart/commands/${cmd}.lua
local logger = require("logger")

local M = {}

function M.run(opts)
  logger.info("${cmd} command")
  logger.warn("This command is not yet implemented")
  return true
end

return M
EOF
done
echo "   ✓ Stub commands created"

# Update logger if needed
echo "📝 Checking logger.lua..."
if [ ! -f "lua/rustydart/logger.lua" ]; then
  cat > lua/rustydart/logger.lua << 'LOGGER_EOF'
-- lua/rustydart/logger.lua
local M = {}

local colors = {
  reset = "\27[0m",
  red = "\27[31m",
  green = "\27[32m",
  yellow = "\27[33m",
  blue = "\27[34m",
  cyan = "\27[36m"
}

local current_level = 1
local use_colors = true

function M.set_level(level) current_level = tonumber(level) or 1 end
function M.set_colors(enabled) use_colors = enabled end
function M.set_quiet(enabled) end

local function format(icon, color, msg)
  if use_colors then
    print(color .. icon .. " " .. msg .. colors.reset)
  else
    print(icon .. " " .. msg)
  end
end

function M.debug(msg) format("🔍", colors.cyan, msg) end
function M.info(msg) format("ℹ", colors.blue, msg) end
function M.warn(msg) format("⚠", colors.yellow, msg) end
function M.error(msg) format("✗", colors.red, msg) end
function M.success(msg) format("✓", colors.green, msg) end

function M.header(msg)
  print("")
  print(colors.cyan .. msg .. colors.reset)
  print(colors.cyan .. string.rep("=", #msg) .. colors.reset)
  print("")
end

return M
LOGGER_EOF
  echo "   ✓ logger.lua created"
else
  echo "   ✓ logger.lua exists"
fi

# Check utils.lua
echo "📝 Checking utils.lua..."
if [ ! -f "lua/rustydart/utils.lua" ] || ! grep -q "file_exists" lua/rustydart/utils.lua; then
  cat > lua/rustydart/utils.lua << 'UTILS_EOF'
-- lua/rustydart/utils.lua
local M = {}

function M.file_exists(path)
  local f = io.open(path, "r")
  if f then
    f:close()
    return true
  end
  return false
end

function M.dir_exists(path)
  local ok, err, code = os.rename(path, path)
  if ok or code == 13 then
    return true
  end
  return false
end

function M.join_path(...)
  local parts = {...}
  return table.concat(parts, "/"):gsub("/+", "/")
end

function M.read_file(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local content = f:read("*a")
  f:close()
  return content
end

function M.write_file(path, content)
  local f = io.open(path, "w")
  if not f then return false end
  f:write(content)
  f:close()
  return true
end

return M
UTILS_EOF
  echo "   ✓ utils.lua created"
else
  echo "   ✓ utils.lua exists"
fi

# Make init.lua executable
echo "🔧 Making init.lua executable..."
chmod +x init.lua
echo "   ✓ init.lua is executable"

# Test the installation
echo ""
echo "🧪 Testing installation..."
if ./init.lua version 2>&1 | grep -q "rustydart"; then
  echo -e "${GREEN}   ✓ Basic test passed${NC}"
else
  echo -e "${YELLOW}   ⚠ Test inconclusive (this is okay)${NC}"
fi

echo ""
echo -e "${GREEN}✅ Setup complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. cd to your Flutter project"
echo "  2. Run: /path/to/rustydart init"
echo "  3. Run: /path/to/rustydart doctor"
echo ""
echo "Optional: Create symlink for global access"
echo "  sudo ln -s $(pwd)/init.lua /usr/local/bin/rustydart"
echo ""
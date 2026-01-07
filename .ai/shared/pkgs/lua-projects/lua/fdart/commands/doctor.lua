-- lua/rustydart/commands/doctor.lua
-- Health check command - verifies project setup and dependencies

local config = require("config")
local logger = require("logger")
local utils = require("utils")

local M = {}

-- Check if a command exists
local function command_exists(cmd)
  local handle = io.popen("which " .. cmd .. " 2>/dev/null")
  if not handle then return false end
  local result = handle:read("*a")
  handle:close()
  return result ~= ""
end

-- Check Flutter installation
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

-- Check Dart installation
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

-- Check project structure
local function check_project_structure()
  logger.info("Checking project structure...")
  
  local project_root = config.get("project_root") or "."
  local lib_dir = config.get("lib_dir") or "lib"
  
  -- Check pubspec.yaml
  local pubspec_path = utils.join_path(project_root, "pubspec.yaml")
  if not utils.file_exists(pubspec_path) then
    logger.error("✗ pubspec.yaml not found at: " .. pubspec_path)
    logger.info("  This doesn't appear to be a Flutter/Dart project")
    return false
  end
  logger.success("✓ pubspec.yaml found")
  
  -- Check lib directory
  local lib_path = utils.join_path(project_root, lib_dir)
  if not utils.dir_exists(lib_path) then
    logger.warn("⚠ lib directory not found at: " .. lib_path)
    return false
  end
  logger.success("✓ lib directory found")
  
  -- Check for main.dart
  local main_path = utils.join_path(lib_path, "main.dart")
  if utils.file_exists(main_path) then
    logger.success("✓ main.dart found")
  else
    logger.warn("⚠ main.dart not found (might be a package)")
  end
  
  return true
end

-- Check configuration
local function check_config()
  logger.info("Checking rustydart configuration...")
  
  local config_files = {
    ".rustydart.yaml",
    ".rustydart.yml",
    ".rustydart.json",
    "rustydart.config.lua"
  }
  
  local found = false
  for _, file in ipairs(config_files) do
    if utils.file_exists(file) then
      logger.success("✓ Configuration found: " .. file)
      found = true
      break
    end
  end
  
  if not found then
    logger.warn("⚠ No configuration file found")
    logger.info("  Run 'rustydart init' to create one")
    return false
  end
  
  return true
end

-- Check dependencies
local function check_dependencies()
  logger.info("Checking dependencies...")
  
  -- Check for .dart_tool
  if utils.dir_exists(".dart_tool") then
    logger.success("✓ Dependencies appear to be installed")
  else
    logger.warn("⚠ .dart_tool not found")
    logger.info("  Run 'flutter pub get' to install dependencies")
    return false
  end
  
  return true
end

-- Check Ollama (if enabled)
local function check_ollama()
  local ollama_config = config.get("ollama") or {}
  
  if not ollama_config.enabled then
    logger.info("Ollama integration: disabled")
    return true
  end
  
  logger.info("Checking Ollama integration...")
  
  if not command_exists("ollama") then
    logger.warn("⚠ Ollama not found in PATH")
    logger.info("  Install from: https://ollama.com")
    return false
  end
  
  logger.success("✓ Ollama found")
  
  -- Try to connect to Ollama server
  local host = ollama_config.host or "localhost"
  local port = ollama_config.port or 11434
  local url = string.format("http://%s:%d/api/tags", host, port)
  
  local cmd = string.format("curl -s -m 2 %s 2>/dev/null", url)
  local handle = io.popen(cmd)
  if handle then
    local result = handle:read("*a")
    handle:close()
    
    if result and result ~= "" then
      logger.success("✓ Ollama server responding at " .. host .. ":" .. port)
      
      -- Check if model exists
      local model = ollama_config.model
      if model and result:find(model, 1, true) then
        logger.success("✓ Model '" .. model .. "' available")
      elseif model then
        logger.warn("⚠ Model '" .. model .. "' not found")
        logger.info("  Run: ollama pull " .. model)
      end
      
      return true
    else
      logger.warn("⚠ Ollama server not responding")
      logger.info("  Run: ollama serve")
      return false
    end
  end
  
  logger.warn("⚠ Could not check Ollama connection")
  return false
end

-- Main run function
function M.run(opts)
  logger.info("Running rustydart health check...\n")
  
  local checks = {
    { name = "Flutter", func = check_flutter },
    { name = "Dart", func = check_dart },
    { name = "Project Structure", func = check_project_structure },
    { name = "Configuration", func = check_config },
    { name = "Dependencies", func = check_dependencies },
    { name = "Ollama", func = check_ollama }
  }
  
  local all_passed = true
  local results = {}
  
  for _, check in ipairs(checks) do
    local success = check.func()
    results[check.name] = success
    all_passed = all_passed and success
    print("") -- Empty line between checks
  end
  
  -- Summary
  logger.info("=== Health Check Summary ===")
  for _, check in ipairs(checks) do
    local status = results[check.name] and "✓" or "✗"
    local msg = string.format("%s %s", status, check.name)
    if results[check.name] then
      logger.success(msg)
    else
      logger.error(msg)
    end
  end
  
  if all_passed then
    logger.success("\n🎉 All checks passed!")
  else
    logger.warn("\n⚠ Some checks failed - see details above")
  end
  
  return all_passed
end

return M
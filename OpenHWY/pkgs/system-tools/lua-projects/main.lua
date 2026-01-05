#!/usr/bin/env lua
-- fdart/init.lua
-- Flutter Dart Development Toolkit with AI Integration
-- Version 5.0.0
-- 
-- Main entry point that orchestrates all modules

local base_path = debug.getinfo(1, "S").source:match("@(.*/)")
package.path = package.path .. ";" .. base_path .. "lua/?.lua"

-- Core modules
local config = require("fdart.config")
local cli = require("fdart.cli")
local logger = require("fdart.logger")
local commands = require("fdart.commands")

-- Feature modules
local ai = require("fdart.ai.ollama")
local analyzer = require("fdart.analyzer")
local fixer = require("fdart.fixer")
local indexer = require("fdart.indexer")

local M = {}

-- Initialize the application
function M.init()
  -- Load configuration
  local ok, err = config.load()
  if not ok then
    logger.error("Failed to load configuration: " .. (err or "unknown error"))
    os.exit(1)
  end
  
  -- Set up logger with config
  logger.set_level(config.get("log_level") or "info")
  logger.set_quiet(config.get("quiet") or false)
  
  return true
end

-- Main execution
function M.run(args)
  if not M.init() then
    return false
  end
  
  -- Parse command line arguments
  local cmd, opts = cli.parse(args)
  
  if not cmd then
    cli.show_help()
    os.exit(1)
  end
  
  -- Execute command
  local command_func = commands.get(cmd)
  if not command_func then
    logger.error("Unknown command: " .. cmd)
    logger.info("Run 'fdart help' for usage information")
    os.exit(1)
  end
  
  -- Run the command
  local success, result = pcall(command_func, opts)
  
  if not success then
    logger.error("Command failed: " .. tostring(result))
    os.exit(1)
  end
  
  return result
end

-- Run if executed directly
if arg and arg[0]:match("init%.lua$") or arg[0]:match("fdart$") then
  local success = M.run(arg)
  os.exit(success and 0 or 1)
end

return M
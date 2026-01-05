-- fdart/lua/fdart/cli.lua
-- Command line argument parser

local logger = require("fdart.logger")
local M = {}

-- Parse command line arguments
function M.parse(args)
  if not args or #args == 0 then
    return nil, {}
  end
  
  local command = nil
  local options = {
    flags = {},
    params = {},
    positional = {}
  }
  
  local i = 1
  while i <= #args do
    local arg = args[i]
    
    -- Check for command (first non-option argument)
    if not command and not arg:match("^%-") then
      command = arg
      i = i + 1
    -- Long option with value: --key=value
    elseif arg:match("^%-%-([^=]+)=(.+)$") then
      local key, value = arg:match("^%-%-([^=]+)=(.+)$")
      options.params[key] = M.parse_value(value)
      i = i + 1
    -- Long option: --key
    elseif arg:match("^%-%-(.+)$") then
      local key = arg:match("^%-%-(.+)$")
      -- Check if next arg is a value
      if i < #args and not args[i + 1]:match("^%-") then
        i = i + 1
        options.params[key] = M.parse_value(args[i])
      else
        options.flags[key] = true
      end
      i = i + 1
    -- Short option: -k
    elseif arg:match("^%-(.+)$") then
      local keys = arg:match("^%-(.+)$")
      -- Handle combined short flags: -vdf
      for j = 1, #keys do
        local key = keys:sub(j, j)
        options.flags[key] = true
      end
      i = i + 1
    -- Positional argument
    else
      table.insert(options.positional, arg)
      i = i + 1
    end
  end
  
  return command, options
end

-- Parse value (convert to appropriate type)
function M.parse_value(value)
  -- Boolean
  if value == "true" then return true end
  if value == "false" then return false end
  
  -- Number
  local num = tonumber(value)
  if num then return num end
  
  -- Array (comma-separated)
  if value:match(",") then
    local arr = {}
    for item in value:gmatch("[^,]+") do
      table.insert(arr, M.parse_value(item:match("^%s*(.-)%s*$")))
    end
    return arr
  end
  
  -- String
  return value
end

-- Get option value with default
function M.get_option(options, key, default)
  -- Check params first
  if options.params[key] ~= nil then
    return options.params[key]
  end
  
  -- Check flags
  if options.flags[key] ~= nil then
    return options.flags[key]
  end
  
  -- Check short form mapping
  local short_forms = {
    d = "dir",
    v = "verbose",
    q = "quiet",
    f = "force",
    h = "help",
    n = "dry-run",
  }
  
  local short_key = nil
  for short, long in pairs(short_forms) do
    if long == key then
      short_key = short
      break
    end
  end
  
  if short_key and options.flags[short_key] then
    return true
  end
  
  return default
end

-- Check if flag is set
function M.has_flag(options, flag)
  return options.flags[flag] == true
end

-- Get positional argument
function M.get_positional(options, index, default)
  return options.positional[index] or default
end

-- Show help
function M.show_help()
  local c = logger.colors
  local i = logger.icons
  
  print(string.format([[
%s%s%s fdart - Flutter Dart Development Toolkit %s%s

%sUSAGE:%s
  fdart <command> [options]

%sCOMMANDS:%s

  %sCore Commands:%s
    init                    Initialize fdart in current project
    config                  Manage configuration
    doctor                  Run comprehensive health check
    
  %sCode Analysis:%s
    analyze                 Analyze code quality and patterns
    index                   Build symbol index from barrel files
    stats                   Show project statistics
    tree                    Display project structure
    find <query>            Find symbols by name
    
  %sCode Fixing:%s
    fix                     Auto-fix missing imports
    check                   Check imports (dry-run)
    format                  Format Dart code
    organize-imports        Organize and sort imports
    
  %sBarrel Management:%s
    barrel-create           Generate index.dart files
    barrel-update           Update existing barrels
    barrel-clean            Remove unused barrel exports
    
  %sBuilding & Debugging:%s
    debug                   Auto-debug and fix build errors
    run                     Run app with auto-fixing
    build                   Build project with diagnostics
    clean                   Clean build artifacts
    
  %sAI Assistant (Ollama):%s
    ai <prompt>             Ask AI for help
    ai-fix                  Let AI analyze and fix issues
    ai-review               Get AI code review
    ai-chat                 Interactive AI chat session
    
  %sUtilities:%s
    deps                    Analyze dependencies
    scaffold                Create project structure
    watch                   Watch for changes and auto-fix
    cmd <command>           Execute shell command (AI use)

%sOPTIONS:%s
  -d, --dir <path>          Target directory (default: current)
  -v, --verbose             Enable verbose logging
  -q, --quiet               Minimal output (errors only)
  -f, --force               Force operation without prompts
  -n, --dry-run             Preview changes without applying
  --no-backup               Don't create backup files
  --no-color                Disable colored output
  --config <path>           Use specific config file
  -h, --help                Show this help message

%sAI/OLLAMA OPTIONS:%s
  --model <name>            Ollama model to use
  --host <host>             Ollama host (default: localhost)
  --port <port>             Ollama port (default: 11434)
  --allow-commands          Allow AI to execute commands (USE WITH CAUTION)

%sEXAMPLES:%s

  %s# Initialize fdart in your project%s
  fdart init

  %s# Auto-fix all import issues%s
  fdart fix --dir lib

  %s# Debug and auto-fix build errors%s
  fdart debug --verbose

  %s# Ask AI for help with errors%s
  fdart ai "Why is my Flutter build failing?"

  %s# Let AI analyze and fix issues automatically%s
  fdart ai-fix --allow-commands

  %s# Interactive AI chat session%s
  fdart ai-chat

  %s# Generate all barrel files%s
  fdart barrel-create --dir lib

  %s# Watch for changes and auto-fix%s
  fdart watch --dir lib

  %s# Run health check%s
  fdart doctor

%sCONFIGURATION:%s

  fdart looks for configuration in these files (in order):
    .fdart.yaml, .fdart.yml, .fdart.json, fdart.config.lua

  Example .fdart.yaml:
    ollama:
      enabled: true
      host: 192.168.1.100
      model: codellama:13b
      allow_command_execution: false
    
    deep_scan: true
    auto_pubget: true
    max_fix_iterations: 5

%sFor more information, visit:%s https://github.com/yourusername/fdart

]], 
  c.bold, c.blue, i.flutter, i.dart, c.reset,
  c.bold, c.reset,
  c.bold, c.reset,
  c.cyan, c.reset,
  c.cyan, c.reset,
  c.cyan, c.reset,
  c.cyan, c.reset,
  c.cyan, c.reset,
  c.green, c.reset,
  c.cyan, c.reset,
  c.bold, c.reset,
  c.bold, c.reset,
  c.bold, c.reset,
  c.dim, c.reset,
  c.dim, c.reset,
  c.dim, c.reset,
  c.dim, c.reset,
  c.dim, c.reset,
  c.dim, c.reset,
  c.dim, c.reset,
  c.dim, c.reset,
  c.dim, c.reset,
  c.bold, c.reset,
  c.bold, c.reset
  ))
end

-- Show version
function M.show_version()
  print(string.format("fdart version 5.0.0"))
end

return M
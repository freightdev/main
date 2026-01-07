-- fdart/lua/fdart/commands.lua
-- Command registry and execution

local config = require("fdart.config")
local logger = require("fdart.logger")
local cli = require("fdart.cli")

local M = {}
M.commands = {}

-- Register a command
function M.register(name, handler, description)
  M.commands[name] = {
    handler = handler,
    description = description
  }
end

-- Get command handler
function M.get(name)
  local cmd = M.commands[name]
  return cmd and cmd.handler
end

-- List all commands
function M.list()
  local list = {}
  for name, cmd in pairs(M.commands) do
    table.insert(list, {name = name, description = cmd.description})
  end
  table.sort(list, function(a, b) return a.name < b.name end)
  return list
end

-- Initialize all command handlers
function M.init()
  
  -- init: Initialize project
  M.register("init", function(opts)
    local init = require("fdart.commands.init")
    return init.run(opts)
  end, "Initialize fdart in current project")
  
  -- config: Manage configuration
  M.register("config", function(opts)
    local config_cmd = require("fdart.commands.config_cmd")
    return config_cmd.run(opts)
  end, "Manage configuration")
  
  -- doctor: Health check
  M.register("doctor", function(opts)
    local doctor = require("fdart.commands.doctor")
    return doctor.run(opts)
  end, "Run comprehensive health check")
  
  -- analyze: Code analysis
  M.register("analyze", function(opts)
    local analyze = require("fdart.commands.analyze")
    return analyze.run(opts)
  end, "Analyze code quality")
  
  -- fix: Auto-fix imports
  M.register("fix", function(opts)
    local fix = require("fdart.commands.fix")
    return fix.run(opts)
  end, "Auto-fix missing imports")
  
  -- check: Check imports (dry-run)
  M.register("check", function(opts)
    opts.params = opts.params or {}
    opts.params["dry-run"] = true
    local fix = require("fdart.commands.fix")
    return fix.run(opts)
  end, "Check imports without modifying")
  
  -- debug: Auto-debug build errors
  M.register("debug", function(opts)
    local debug = require("fdart.commands.debug")
    return debug.run(opts)
  end, "Auto-debug and fix build errors")
  
  -- run: Run with auto-fixing
  M.register("run", function(opts)
    opts.params = opts.params or {}
    opts.params.mode = "run"
    local debug = require("fdart.commands.debug")
    return debug.run(opts)
  end, "Run app with auto-fixing")
  
  -- barrel-create: Generate barrels
  M.register("barrel-create", function(opts)
    local barrel = require("fdart.commands.barrel")
    return barrel.create(opts)
  end, "Generate index.dart files")
  
  -- barrel-update: Update barrels
  M.register("barrel-update", function(opts)
    local barrel = require("fdart.commands.barrel")
    return barrel.update(opts)
  end, "Update existing barrels")
  
  -- barrel-clean: Clean barrels
  M.register("barrel-clean", function(opts)
    local barrel = require("fdart.commands.barrel")
    return barrel.clean(opts)
  end, "Remove unused barrel exports")
  
  -- index: Build symbol index
  M.register("index", function(opts)
    local index = require("fdart.commands.index")
    return index.run(opts)
  end, "Build symbol index")
  
  -- stats: Project statistics
  M.register("stats", function(opts)
    local stats = require("fdart.commands.stats")
    return stats.run(opts)
  end, "Show project statistics")
  
  -- tree: Project tree
  M.register("tree", function(opts)
    local tree = require("fdart.commands.tree")
    return tree.run(opts)
  end, "Display project structure")
  
  -- find: Find symbols
  M.register("find", function(opts)
    local find = require("fdart.commands.find")
    return find.run(opts)
  end, "Find symbols by name")
  
  -- deps: Dependency analysis
  M.register("deps", function(opts)
    local deps = require("fdart.commands.deps")
    return deps.run(opts)
  end, "Analyze dependencies")
  
  -- clean: Clean artifacts
  M.register("clean", function(opts)
    local clean = require("fdart.commands.clean")
    return clean.run(opts)
  end, "Clean build artifacts")
  
  -- scaffold: Create structure
  M.register("scaffold", function(opts)
    local scaffold = require("fdart.commands.scaffold")
    return scaffold.run(opts)
  end, "Create project structure")
  
  -- watch: Watch for changes
  M.register("watch", function(opts)
    local watch = require("fdart.commands.watch")
    return watch.run(opts)
  end, "Watch for changes")
  
  -- format: Format code
  M.register("format", function(opts)
    local format = require("fdart.commands.format")
    return format.run(opts)
  end, "Format Dart code")
  
  -- organize-imports: Organize imports
  M.register("organize-imports", function(opts)
    local organize = require("fdart.commands.organize_imports")
    return organize.run(opts)
  end, "Organize and sort imports")
  
  -- AI commands
  M.register("ai", function(opts)
    local ai = require("fdart.commands.ai")
    return ai.prompt(opts)
  end, "Ask AI for help")
  
  M.register("ai-fix", function(opts)
    local ai = require("fdart.commands.ai")
    return ai.fix(opts)
  end, "Let AI analyze and fix issues")
  
  M.register("ai-review", function(opts)
    local ai = require("fdart.commands.ai")
    return ai.review(opts)
  end, "Get AI code review")
  
  M.register("ai-chat", function(opts)
    local ai = require("fdart.commands.ai")
    return ai.chat(opts)
  end, "Interactive AI chat")
  
  -- cmd: Execute shell command (for AI)
  M.register("cmd", function(opts)
    local cmd = require("fdart.commands.cmd")
    return cmd.run(opts)
  end, "Execute shell command")
  
  -- build: Build project
  M.register("build", function(opts)
    local build = require("fdart.commands.build")
    return build.run(opts)
  end, "Build project")
  
  -- help: Show help
  M.register("help", function(opts)
    cli.show_help()
    return true
  end, "Show help message")
  
  -- version: Show version
  M.register("version", function(opts)
    cli.show_version()
    return true
  end, "Show version")
end

-- Initialize commands on module load
M.init()

return M
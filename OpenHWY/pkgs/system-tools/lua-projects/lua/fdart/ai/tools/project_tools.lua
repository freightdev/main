-- fdart/lua/ai/tools/project_tools.lua
-- Flutter/Dart project-specific tools

local utils = require("utils")
local config = require("config")
local tool_registry = require("ai.tool_registry")

local M = {}

function M.init()
  -- Analyze project structure
  tool_registry.register({
    name = "analyze_project",
    description = "Analyze Flutter/Dart project structure and dependencies",
    category = "project",
    safety_level = "safe",
    parameters = {
      {name = "path", type = "path", required = false, default = ".", description = "Project root path"}
    },
    execute = function(params)
      local project_root = utils.find_project_root(params.path)
      if not project_root then
        return nil, "No Flutter project found (missing pubspec.yaml)"
      end
      
      -- Parse pubspec.yaml
      local pubspec_path = project_root .. "/pubspec.yaml"
      local pubspec = utils.parse_pubspec(pubspec_path)
      
      if not pubspec then
        return nil, "Failed to parse pubspec.yaml"
      end
      
      -- Scan for Dart files
      local dart_files = {}
      local total_lines = 0
      
      utils.scan_directory(project_root, function(file_path)
        local content = utils.read_file(file_path)
        if content then
          local line_count = select(2, content:gsub('\n', '\n')) + 1
          total_lines = total_lines + line_count
          table.insert(dart_files, {
            path = utils.get_relative_path(project_root, file_path),
            lines = line_count
          })
        end
      end, {
        include_patterns = {"%.dart$"},
        exclude_patterns = config.get("exclude_patterns"),
        exclude_dirs = config.get("exclude_dirs")
      })
      
      return {
        root = project_root,
        name = pubspec.name,
        version = pubspec.version,
        dependencies = pubspec.dependencies,
        dev_dependencies = pubspec.dev_dependencies,
        dart_files = {
          count = #dart_files,
          total_lines = total_lines,
          files = dart_files
        }
      }
    end
  })
  
  -- Run Flutter/Dart commands
  tool_registry.register({
    name = "run_flutter_command",
    description = "Execute a Flutter CLI command",
    category = "project",
    safety_level = "caution",
    requires_confirmation = true,
    parameters = {
      {name = "command", type = "string", required = true, description = "Flutter command (e.g., 'pub get', 'analyze', 'test')"},
      {name = "args", type = "string", required = false, default = "", description = "Additional arguments"}
    },
    execute = function(params)
      local allowed_commands = {"pub", "analyze", "test", "format", "doctor", "clean", "build"}
      
      local base_cmd = params.command:match("^(%S+)")
      local is_allowed = false
      for _, allowed in ipairs(allowed_commands) do
        if base_cmd == allowed then
          is_allowed = true
          break
        end
      end
      
      if not is_allowed then
        return nil, "Command not allowed: " .. base_cmd
      end
      
      local full_cmd = string.format("flutter %s %s", params.command, params.args)
      local output, success = utils.execute(full_cmd)
      
      return {
        command = full_cmd,
        success = success ~= nil,
        output = output
      }
    end
  })
  
  -- Create barrel file
  tool_registry.register({
    name = "create_barrel",
    description = "Create or update a barrel file (index.dart) for a directory",
    category = "project",
    safety_level = "safe",
    parameters = {
      {name = "directory", type = "path", required = true, description = "Directory to create barrel for"},
      {name = "recursive", type = "boolean", required = false, default = false, description = "Include subdirectories"}
    },
    execute = function(params)
      if not utils.dir_exists(params.directory) then
        return nil, "Directory does not exist: " .. params.directory
      end
      
      local exports = {}
      local export_pattern = "export '%s';"
      
      utils.scan_directory(params.directory, function(file_path)
        local rel_path = utils.get_relative_path(params.directory, file_path)
        local filename = rel_path:match("([^/]+)$")
        
        -- Skip the barrel file itself and generated files
        if filename ~= "index.dart" and not filename:match("%.g%.dart$") and not filename:match("%.freezed%.dart$") then
          table.insert(exports, string.format(export_pattern, rel_path))
        end
      end, {
        max_depth = params.recursive and 10 or 0,
        include_patterns = {"%.dart$"},
        exclude_patterns = config.get("exclude_patterns"),
        exclude_dirs = config.get("exclude_dirs")
      })
      
      -- Sort exports
      table.sort(exports)
      
      -- Build barrel content
      local header = config.get("barrel_header", "")
      local content = header .. table.concat(exports, "\n") .. "\n"
      
      local barrel_path = params.directory .. "/" .. config.get("barrel_filename", "index.dart")
      local success = utils.write_file(barrel_path, content)
      
      if not success then
        return nil, "Failed to write barrel file"
      end
      
      return {
        path = barrel_path,
        exports = #exports,
        content = content
      }
    end
  })
  
  -- Organize imports
  tool_registry.register({
    name = "organize_imports",
    description = "Organize and sort imports in a Dart file",
    category = "project",
    safety_level = "caution",
    parameters = {
      {name = "file", type = "path", required = true, description = "Dart file to organize"},
      {name = "backup", type = "boolean", required = false, default = true, description = "Create backup"}
    },
    execute = function(params)
      local content = utils.read_file(params.file)
      if not content then
        return nil, "Failed to read file: " .. params.file
      end
      
      -- Extract imports
      local imports = {
        dart = {},
        flutter = {},
        package = {},
        relative = {}
      }
      
      local non_import_lines = {}
      local in_imports = false
      
      for line in content:gmatch("[^\r\n]+") do
        local import_match = line:match("^import%s+['\"](.+)['\"]")
        
        if import_match then
          in_imports = true
          if import_match:match("^dart:") then
            table.insert(imports.dart, line)
          elseif import_match:match("^package:flutter/") then
            table.insert(imports.flutter, line)
          elseif import_match:match("^package:") then
            table.insert(imports.package, line)
          else
            table.insert(imports.relative, line)
          end
        else
          if in_imports and line:match("^%s*$") then
            -- Skip blank lines in import section
          else
            if in_imports then
              in_imports = false
            end
            table.insert(non_import_lines, line)
          end
        end
      end
      
      -- Sort each group
      for _, group in pairs(imports) do
        table.sort(group)
      end
      
      -- Build organized content
      local organized = {}
      local order = config.get("import_order", {"dart", "flutter", "package", "relative"})
      
      for _, group_name in ipairs(order) do
        if #imports[group_name] > 0 then
          for _, import_line in ipairs(imports[group_name]) do
            table.insert(organized, import_line)
          end
          table.insert(organized, "")
        end
      end
      
      -- Add rest of file
      for _, line in ipairs(non_import_lines) do
        table.insert(organized, line)
      end
      
      local new_content = table.concat(organized, "\n")
      
      -- Backup if requested
      if params.backup then
        utils.backup_file(params.file)
      end
      
      -- Write organized content
      local success = utils.write_file(params.file, new_content)
      if not success then
        return nil, "Failed to write organized file"
      end
      
      return {
        file = params.file,
        import_groups = {
          dart = #imports.dart,
          flutter = #imports.flutter,
          package = #imports.package,
          relative = #imports.relative
        },
        total_imports = #imports.dart + #imports.flutter + #imports.package + #imports.relative
      }
    end
  })
  
  -- Refactor: rename symbol
  tool_registry.register({
    name = "rename_symbol",
    description = "Rename a class, function, or variable across the project",
    category = "project",
    safety_level = "dangerous",
    requires_confirmation = true,
    parameters = {
      {name = "old_name", type = "string", required = true, description = "Current symbol name"},
      {name = "new_name", type = "string", required = true, description = "New symbol name"},
      {name = "scope", type = "path", required = false, default = ".", description = "Directory scope for rename"}
    },
    execute = function(params)
      local files_changed = 0
      local occurrences_changed = 0
      
      utils.scan_directory(params.scope, function(file_path)
        local content = utils.read_file(file_path)
        if not content then return end
        
        -- Create backup
        utils.backup_file(file_path)
        
        -- Count and replace
        local new_content, count = content:gsub("%f[%w]" .. params.old_name .. "%f[%W]", params.new_name)
        
        if count > 0 then
          utils.write_file(file_path, new_content)
          files_changed = files_changed + 1
          occurrences_changed = occurrences_changed + count
        end
      end, {
        include_patterns = {"%.dart$"},
        exclude_patterns = config.get("exclude_patterns"),
        exclude_dirs = config.get("exclude_dirs")
      })
      
      return {
        old_name = params.old_name,
        new_name = params.new_name,
        files_changed = files_changed,
        occurrences_changed = occurrences_changed
      }
    end
  })
  
  return true
end

return M
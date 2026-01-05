-- fdart/lua/ai/tools/file_tools.lua
-- File system operation tools for AI

local utils = require("utils")
local config = require("config")
local tool_registry = require("ai.tool_registry")

local M = {}

-- Initialize and register all file tools
function M.init()
  -- Read file tool
  tool_registry.register({
    name = "read_file",
    description = "Read the contents of a file",
    category = "file",
    safety_level = "safe",
    parameters = {
      {name = "path", type = "path", required = true, description = "Path to the file to read"},
      {name = "max_lines", type = "number", required = false, default = -1, description = "Maximum lines to read (-1 for all)"}
    },
    execute = function(params)
      local content = utils.read_file(params.path)
      if not content then
        return nil, "Failed to read file: " .. params.path
      end
      
      if params.max_lines > 0 then
        local lines = {}
        local count = 0
        for line in content:gmatch("[^\r\n]+") do
          table.insert(lines, line)
          count = count + 1
          if count >= params.max_lines then break end
        end
        content = table.concat(lines, "\n")
      end
      
      return {
        path = params.path,
        content = content,
        size = #content
      }
    end
  })
  
  -- Write file tool
  tool_registry.register({
    name = "write_file",
    description = "Write content to a file (creates or overwrites)",
    category = "file",
    safety_level = "caution",
    requires_confirmation = true,
    parameters = {
      {name = "path", type = "path", required = true, description = "Path to the file to write"},
      {name = "content", type = "string", required = true, description = "Content to write"},
      {name = "backup", type = "boolean", required = false, default = true, description = "Create backup if file exists"}
    },
    execute = function(params)
      -- Create backup if requested and file exists
      if params.backup and utils.file_exists(params.path) then
        local backup_ok = utils.backup_file(params.path)
        if not backup_ok then
          return nil, "Failed to create backup"
        end
      end
      
      local success = utils.write_file(params.path, params.content)
      if not success then
        return nil, "Failed to write file: " .. params.path
      end
      
      return {
        path = params.path,
        size = #params.content,
        backup_created = params.backup and utils.file_exists(params.path .. ".backup")
      }
    end
  })
  
  -- Append to file tool
  tool_registry.register({
    name = "append_file",
    description = "Append content to the end of a file",
    category = "file",
    safety_level = "caution",
    parameters = {
      {name = "path", type = "path", required = true, description = "Path to the file"},
      {name = "content", type = "string", required = true, description = "Content to append"}
    },
    execute = function(params)
      local existing = utils.read_file(params.path) or ""
      local new_content = existing .. params.content
      
      local success = utils.write_file(params.path, new_content)
      if not success then
        return nil, "Failed to append to file: " .. params.path
      end
      
      return {
        path = params.path,
        appended_bytes = #params.content,
        total_size = #new_content
      }
    end
  })
  
  -- List directory tool
  tool_registry.register({
    name = "list_directory",
    description = "List files and directories in a path",
    category = "file",
    safety_level = "safe",
    parameters = {
      {name = "path", type = "path", required = true, description = "Directory path to list"},
      {name = "pattern", type = "string", required = false, description = "Optional pattern to filter results"}
    },
    execute = function(params)
      if not utils.dir_exists(params.path) then
        return nil, "Directory does not exist: " .. params.path
      end
      
      local entries = {}
      local lfs = require("lfs")
      
      for entry in lfs.dir(params.path) do
        if entry ~= "." and entry ~= ".." then
          if not params.pattern or entry:match(params.pattern) then
            local full_path = params.path .. "/" .. entry
            local attr = lfs.attributes(full_path)
            
            if attr then
              table.insert(entries, {
                name = entry,
                type = attr.mode,
                size = attr.size,
                modified = attr.modification
              })
            end
          end
        end
      end
      
      return {
        path = params.path,
        count = #entries,
        entries = entries
      }
    end
  })
  
  -- Create directory tool
  tool_registry.register({
    name = "create_directory",
    description = "Create a new directory (including parent directories)",
    category = "file",
    safety_level = "safe",
    parameters = {
      {name = "path", type = "path", required = true, description = "Directory path to create"}
    },
    execute = function(params)
      if utils.dir_exists(params.path) then
        return {path = params.path, existed = true}
      end
      
      local success = utils.mkdir(params.path)
      if not success then
        return nil, "Failed to create directory: " .. params.path
      end
      
      return {
        path = params.path,
        created = true
      }
    end
  })
  
  -- Delete file tool
  tool_registry.register({
    name = "delete_file",
    description = "Delete a file",
    category = "file",
    safety_level = "dangerous",
    requires_confirmation = true,
    parameters = {
      {name = "path", type = "path", required = true, description = "Path to the file to delete"},
      {name = "backup", type = "boolean", required = false, default = true, description = "Create backup before deleting"}
    },
    execute = function(params)
      if not utils.file_exists(params.path) then
        return nil, "File does not exist: " .. params.path
      end
      
      -- Create backup if requested
      if params.backup then
        local backup_ok = utils.backup_file(params.path)
        if not backup_ok then
          return nil, "Failed to create backup"
        end
      end
      
      local success = os.remove(params.path)
      if not success then
        return nil, "Failed to delete file: " .. params.path
      end
      
      return {
        path = params.path,
        deleted = true,
        backup_created = params.backup
      }
    end
  })
  
  -- Move/rename file tool
  tool_registry.register({
    name = "move_file",
    description = "Move or rename a file",
    category = "file",
    safety_level = "caution",
    requires_confirmation = true,
    parameters = {
      {name = "source", type = "path", required = true, description = "Source file path"},
      {name = "destination", type = "path", required = true, description = "Destination file path"}
    },
    execute = function(params)
      if not utils.file_exists(params.source) then
        return nil, "Source file does not exist: " .. params.source
      end
      
      if utils.file_exists(params.destination) then
        return nil, "Destination already exists: " .. params.destination
      end
      
      local cmd = string.format("mv '%s' '%s'", params.source, params.destination)
      local success = os.execute(cmd) == 0
      
      if not success then
        return nil, "Failed to move file"
      end
      
      return {
        source = params.source,
        destination = params.destination,
        moved = true
      }
    end
  })
  
  -- Copy file tool
  tool_registry.register({
    name = "copy_file",
    description = "Copy a file to a new location",
    category = "file",
    safety_level = "safe",
    parameters = {
      {name = "source", type = "path", required = true, description = "Source file path"},
      {name = "destination", type = "path", required = true, description = "Destination file path"},
      {name = "overwrite", type = "boolean", required = false, default = false, description = "Overwrite if destination exists"}
    },
    execute = function(params)
      if not utils.file_exists(params.source) then
        return nil, "Source file does not exist: " .. params.source
      end
      
      if utils.file_exists(params.destination) and not params.overwrite then
        return nil, "Destination already exists (use overwrite=true to replace)"
      end
      
      local cmd = string.format("cp '%s' '%s'", params.source, params.destination)
      local success = os.execute(cmd) == 0
      
      if not success then
        return nil, "Failed to copy file"
      end
      
      return {
        source = params.source,
        destination = params.destination,
        copied = true
      }
    end
  })
  
  -- Search in files tool
  tool_registry.register({
    name = "search_in_files",
    description = "Search for a pattern in files",
    category = "file",
    safety_level = "safe",
    parameters = {
      {name = "pattern", type = "string", required = true, description = "Pattern to search for"},
      {name = "path", type = "path", required = false, default = ".", description = "Directory to search in"},
      {name = "file_pattern", type = "string", required = false, description = "File pattern to filter (e.g., '%.dart$')"}
    },
    execute = function(params)
      local results = {}
      
      utils.scan_directory(params.path, function(file_path)
        local content = utils.read_file(file_path)
        if content then
          local line_num = 0
          for line in content:gmatch("[^\r\n]+") do
            line_num = line_num + 1
            if line:match(params.pattern) then
              table.insert(results, {
                file = file_path,
                line = line_num,
                content = line
              })
            end
          end
        end
      end, {
        include_patterns = params.file_pattern and {params.file_pattern} or config.get("include_patterns"),
        exclude_patterns = config.get("exclude_patterns"),
        exclude_dirs = config.get("exclude_dirs")
      })
      
      return {
        pattern = params.pattern,
        path = params.path,
        match_count = #results,
        results = results
      }
    end
  })
  
  return true
end

return M
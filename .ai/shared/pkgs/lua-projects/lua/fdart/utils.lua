-- fdart/lua/fdart/utils.lua
-- Common utility functions

local lfs = require("lfs")
local M = {}

-- File operations
function M.read_file(path)
  local file = io.open(path, "r")
  if not file then return nil end
  local content = file:read("*all")
  file:close()
  return content
end

function M.write_file(path, content)
  local file = io.open(path, "w")
  if not file then return false end
  file:write(content)
  file:close()
  return true
end

function M.file_exists(path)
  local attr = lfs.attributes(path)
  return attr ~= nil and attr.mode == "file"
end

function M.dir_exists(path)
  local attr = lfs.attributes(path)
  return attr ~= nil and attr.mode == "directory"
end

function M.mkdir(path)
  return os.execute("mkdir -p " .. path) == 0
end

-- Backup file
function M.backup_file(path)
  local content = M.read_file(path)
  if not content then return false end
  return M.write_file(path .. ".backup", content)
end

-- Execute command
function M.execute(cmd)
  local handle = io.popen(cmd .. " 2>&1")
  if not handle then return nil, "Failed to execute" end
  
  local output = handle:read("*all")
  local success = handle:close()
  
  return output, success
end

-- Find project root (looks for pubspec.yaml)
function M.find_project_root(start_dir)
  start_dir = start_dir or lfs.currentdir()
  local current = start_dir
  
  for i = 1, 10 do
    if M.file_exists(current .. "/pubspec.yaml") then
      return current
    end
    
    local parent = current:match("(.+)/[^/]+$")
    if not parent or parent == current then break end
    current = parent
  end
  
  return nil
end

-- Get relative path
function M.get_relative_path(base, full)
  local escaped_base = base:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%1")
  local rel = full:gsub("^" .. escaped_base .. "/?", "")
  return rel
end

-- Scan directory recursively
function M.scan_directory(dir, callback, options)
  options = options or {}
  local depth = options.depth or 0
  local max_depth = options.max_depth or math.huge
  local exclude_dirs = options.exclude_dirs or {}
  local include_patterns = options.include_patterns or {}
  local exclude_patterns = options.exclude_patterns or {}
  
  if depth > max_depth then return end
  
  for entry in lfs.dir(dir) do
    if entry ~= "." and entry ~= ".." then
      local full_path = dir .. "/" .. entry
      local attr = lfs.attributes(full_path)
      
      if attr then
        if attr.mode == "directory" then
          -- Check if directory should be excluded
          local excluded = false
          for _, pattern in ipairs(exclude_dirs) do
            if entry:match(pattern) then
              excluded = true
              break
            end
          end
          
          if not excluded then
            M.scan_directory(full_path, callback, {
              depth = depth + 1,
              max_depth = max_depth,
              exclude_dirs = exclude_dirs,
              include_patterns = include_patterns,
              exclude_patterns = exclude_patterns
            })
          end
          
        elseif attr.mode == "file" then
          -- Check if file matches include patterns
          local included = #include_patterns == 0
          for _, pattern in ipairs(include_patterns) do
            if full_path:match(pattern) then
              included = true
              break
            end
          end
          
          if included then
            -- Check if file should be excluded
            local excluded = false
            for _, pattern in ipairs(exclude_patterns) do
              if full_path:match(pattern) then
                excluded = true
                break
              end
            end
            
            if not excluded then
              callback(full_path, attr)
            end
          end
        end
      end
    end
  end
end

-- Parse pubspec.yaml
function M.parse_pubspec(path)
  local content = M.read_file(path)
  if not content then return nil end
  
  local info = {
    name = content:match("name:%s*([%w_]+)"),
    version = content:match("version:%s*([%d%.%+%-]+)"),
    description = content:match("description:%s*([^\n]+)"),
    dependencies = {},
    dev_dependencies = {}
  }
  
  local in_deps = false
  local in_dev_deps = false
  
  for line in content:gmatch("[^\r\n]+") do
    if line:match("^dependencies:") then
      in_deps = true
      in_dev_deps = false
    elseif line:match("^dev_dependencies:") then
      in_dev_deps = true
      in_deps = false
    elseif line:match("^%S") then
      in_deps = false
      in_dev_deps = false
    elseif in_deps and line:match("^%s+([%w_]+):") then
      local dep = line:match("^%s+([%w_]+):")
      table.insert(info.dependencies, dep)
    elseif in_dev_deps and line:match("^%s+([%w_]+):") then
      local dep = line:match("^%s+([%w_]+):")
      table.insert(info.dev_dependencies, dep)
    end
  end
  
  return info
end

-- Deep copy table
function M.deep_copy(obj)
  if type(obj) ~= 'table' then return obj end
  local copy = {}
  for k, v in pairs(obj) do
    copy[k] = M.deep_copy(v)
  end
  return copy
end

-- Merge tables
function M.merge(base, overlay)
  for k, v in pairs(overlay) do
    if type(v) == "table" and type(base[k]) == "table" then
      M.merge(base[k], v)
    else
      base[k] = v
    end
  end
end

-- Check if string matches any pattern
function M.matches_any(str, patterns)
  for _, pattern in ipairs(patterns) do
    if str:match(pattern) then
      return true
    end
  end
  return false
end

-- Split string
function M.split(str, delimiter)
  local result = {}
  local pattern = string.format("([^%s]+)", delimiter)
  for match in str:gmatch(pattern) do
    table.insert(result, match)
  end
  return result
end

-- Trim whitespace
function M.trim(str)
  return str:match("^%s*(.-)%s*$")
end

-- Format time duration
function M.format_duration(seconds)
  if seconds < 60 then
    return string.format("%.2fs", seconds)
  elseif seconds < 3600 then
    return string.format("%.1fm", seconds / 60)
  else
    return string.format("%.1fh", seconds / 3600)
  end
end

-- Format file size
function M.format_size(bytes)
  if bytes < 1024 then
    return string.format("%dB", bytes)
  elseif bytes < 1024 * 1024 then
    return string.format("%.1fKB", bytes / 1024)
  else
    return string.format("%.1fMB", bytes / (1024 * 1024))
  end
end

-- Get current timestamp
function M.timestamp()
  return os.time()
end

-- Format timestamp
function M.format_timestamp(ts)
  return os.date("%Y-%m-%d %H:%M:%S", ts)
end

-- Check if tool is available
function M.has_command(cmd)
  local result = os.execute(string.format("which %s > /dev/null 2>&1", cmd))
  return result == 0
end

-- Ensure directory exists
function M.ensure_dir(path)
  if not M.dir_exists(path) then
    return M.mkdir(path)
  end
  return true
end

-- Get file extension
function M.get_extension(path)
  return path:match("%.([^%.]+)$")
end

-- Get filename without extension
function M.get_basename(path)
  local name = path:match("([^/]+)$")
  return name:match("(.+)%.[^%.]+$") or name
end

-- Get directory name
function M.get_dirname(path)
  return path:match("(.+)/[^/]+$") or "."
end

return M
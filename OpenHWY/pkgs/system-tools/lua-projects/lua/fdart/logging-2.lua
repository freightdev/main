-- lua/rustydart/logger.lua
-- Enhanced logging system with colors and levels

local M = {}

-- ANSI color codes
local colors = {
  reset = "\27[0m",
  bold = "\27[1m",
  red = "\27[31m",
  green = "\27[32m",
  yellow = "\27[33m",
  blue = "\27[34m",
  magenta = "\27[35m",
  cyan = "\27[36m",
  white = "\27[37m",
  gray = "\27[90m"
}

-- Log levels
local levels = {
  debug = 0,
  info = 1,
  warn = 2,
  error = 3,
  success = 1
}

-- Current settings
local current_level = levels.info
local use_colors = true
local quiet_mode = false

-- Set log level
function M.set_level(level)
  if type(level) == "string" then
    current_level = levels[level:lower()] or levels.info
  elseif type(level) == "number" then
    current_level = level
  end
end

-- Enable/disable colors
function M.set_colors(enabled)
  use_colors = enabled
end

-- Enable/disable quiet mode
function M.set_quiet(enabled)
  quiet_mode = enabled
end

-- Format message with color
local function format_message(level, icon, color, message)
  if quiet_mode and level < levels.warn then
    return
  end
  
  local prefix = icon and (icon .. " ") or ""
  
  if use_colors then
    io.write(color .. prefix .. message .. colors.reset .. "\n")
  else
    io.write(prefix .. message .. "\n")
  end
  io.flush()
end

-- Debug message
function M.debug(message)
  if current_level <= levels.debug then
    format_message(levels.debug, "🔍", colors.gray, "[DEBUG] " .. message)
  end
end

-- Info message
function M.info(message)
  if current_level <= levels.info then
    format_message(levels.info, "ℹ", colors.blue, message)
  end
end

-- Warning message
function M.warn(message)
  if current_level <= levels.warn then
    format_message(levels.warn, "⚠", colors.yellow, message)
  end
end

-- Error message
function M.error(message)
  if current_level <= levels.error then
    format_message(levels.error, "✗", colors.red, message)
  end
end

-- Success message
function M.success(message)
  if current_level <= levels.success then
    format_message(levels.success, "✓", colors.green, message)
  end
end

-- Custom colored message
function M.colored(message, color)
  if use_colors and colors[color] then
    io.write(colors[color] .. message .. colors.reset .. "\n")
  else
    io.write(message .. "\n")
  end
  io.flush()
end

-- Progress indicator
function M.progress(message)
  if not quiet_mode then
    if use_colors then
      io.write(colors.cyan .. "⏳ " .. message .. colors.reset)
    else
      io.write("* " .. message)
    end
    io.flush()
  end
end

-- Complete progress (call after progress)
function M.done()
  if not quiet_mode then
    if use_colors then
      io.write(colors.green .. " ✓" .. colors.reset .. "\n")
    else
      io.write(" Done\n")
    end
    io.flush()
  end
end

-- Fail progress (call after progress)
function M.failed()
  if not quiet_mode then
    if use_colors then
      io.write(colors.red .. " ✗" .. colors.reset .. "\n")
    else
      io.write(" Failed\n")
    end
    io.flush()
  end
end

-- Header
function M.header(message)
  if not quiet_mode then
    local separator = string.rep("=", #message)
    print("")
    if use_colors then
      print(colors.bold .. colors.cyan .. message .. colors.reset)
      print(colors.cyan .. separator .. colors.reset)
    else
      print(message)
      print(separator)
    end
    print("")
  end
end

-- Subheader
function M.subheader(message)
  if not quiet_mode then
    print("")
    if use_colors then
      print(colors.bold .. message .. colors.reset)
    else
      print(message)
    end
  end
end

-- Print without formatting
function M.print(message)
  print(message)
end

-- Print blank line
function M.blank()
  print("")
end

return M
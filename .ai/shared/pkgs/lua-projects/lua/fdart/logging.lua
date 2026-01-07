-- fdart/lua/fdart/logger.lua
-- Comprehensive logging system with colors and formatting

local M = {}

-- ANSI color codes
M.colors = {
  reset = "\27[0m",
  bold = "\27[1m",
  dim = "\27[2m",
  underline = "\27[4m",
  
  -- Foreground colors
  black = "\27[30m",
  red = "\27[31m",
  green = "\27[32m",
  yellow = "\27[33m",
  blue = "\27[34m",
  magenta = "\27[35m",
  cyan = "\27[36m",
  white = "\27[37m",
  
  -- Bright foreground colors
  bright_black = "\27[90m",
  bright_red = "\27[91m",
  bright_green = "\27[92m",
  bright_yellow = "\27[93m",
  bright_blue = "\27[94m",
  bright_magenta = "\27[95m",
  bright_cyan = "\27[96m",
  bright_white = "\27[97m",
  
  -- Background colors
  bg_red = "\27[41m",
  bg_green = "\27[42m",
  bg_yellow = "\27[43m",
  bg_blue = "\27[44m",
}

-- Icons
M.icons = {
  info = "ℹ",
  success = "✔",
  warning = "⚠",
  error = "✘",
  debug = "◆",
  trace = "▸",
  
  arrow = "→",
  bullet = "•",
  circle = "○",
  
  -- Feature icons
  search = "🔍",
  fix = "🔧",
  barrel = "📦",
  file = "📄",
  folder = "📁",
  rocket = "🚀",
  dart = "🎯",
  flutter = "📱",
  tree = "🌳",
  bug = "🐛",
  magic = "✨",
  fire = "🔥",
  chart = "📊",
  book = "📚",
  tool = "🛠️",
  zap = "⚡",
  shield = "🛡️",
  brain = "🧠",
  hammer = "🔨",
  wrench = "🔧",
  robot = "🤖",
  thinking = "🤔",
  sparkles = "✨",
}

-- Log levels
M.levels = {
  trace = 0,
  debug = 1,
  info = 2,
  success = 3,
  warning = 4,
  error = 5,
  fatal = 6,
}

-- Current settings
M.current_level = M.levels.info
M.quiet = false
M.use_colors = true
M.use_icons = true
M.log_file = nil
M.stats = {
  errors = 0,
  warnings = 0,
  info = 0,
}

-- Set log level
function M.set_level(level)
  if type(level) == "string" then
    level = M.levels[level:lower()]
  end
  M.current_level = level or M.levels.info
end

-- Set quiet mode
function M.set_quiet(quiet)
  M.quiet = quiet
end

-- Enable/disable colors
function M.set_colors(enabled)
  M.use_colors = enabled
end

-- Enable/disable icons
function M.set_icons(enabled)
  M.use_icons = enabled
end

-- Set log file
function M.set_log_file(path)
  M.log_file = path
end

-- Format message with color and icon
function M.format(level, message, ...)
  local formatted = string.format(message, ...)
  
  local color = M.colors.white
  local icon = ""
  
  if level == "trace" then
    color = M.colors.dim
    icon = M.icons.trace
  elseif level == "debug" then
    color = M.colors.bright_black
    icon = M.icons.debug
  elseif level == "info" then
    color = M.colors.cyan
    icon = M.icons.info
  elseif level == "success" then
    color = M.colors.green
    icon = M.icons.success
  elseif level == "warning" then
    color = M.colors.yellow
    icon = M.icons.warning
  elseif level == "error" then
    color = M.colors.red
    icon = M.icons.error
  elseif level == "fatal" then
    color = M.colors.bg_red .. M.colors.white .. M.colors.bold
    icon = M.icons.error
  end
  
  local prefix = ""
  if M.use_icons then
    prefix = icon .. " "
  end
  
  if M.use_colors then
    return string.format("%s%s%s%s", color, prefix, formatted, M.colors.reset)
  else
    return prefix .. formatted
  end
end

-- Core logging function
function M.log(level, message, ...)
  local level_num = M.levels[level] or M.levels.info
  
  -- Check if we should log this level
  if level_num < M.current_level then
    return
  end
  
  -- Skip if quiet (except errors)
  if M.quiet and level_num < M.levels.error then
    return
  end
  
  -- Update stats
  if level == "error" or level == "fatal" then
    M.stats.errors = M.stats.errors + 1
  elseif level == "warning" then
    M.stats.warnings = M.stats.warnings + 1
  else
    M.stats.info = M.stats.info + 1
  end
  
  local formatted = M.format(level, message, ...)
  print(formatted)
  
  -- Write to log file if configured
  if M.log_file then
    local f = io.open(M.log_file, "a")
    if f then
      f:write(os.date("%Y-%m-%d %H:%M:%S") .. " [" .. level:upper() .. "] " .. 
              string.format(message, ...) .. "\n")
      f:close()
    end
  end
end

-- Convenience functions
function M.trace(message, ...)
  M.log("trace", message, ...)
end

function M.debug(message, ...)
  M.log("debug", message, ...)
end

function M.info(message, ...)
  M.log("info", message, ...)
end

function M.success(message, ...)
  M.log("success", message, ...)
end

function M.warn(message, ...)
  M.log("warning", message, ...)
end

function M.warning(message, ...)
  M.log("warning", message, ...)
end

function M.error(message, ...)
  M.log("error", message, ...)
end

function M.fatal(message, ...)
  M.log("fatal", message, ...)
  os.exit(1)
end

-- Print header
function M.header(message, ...)
  local formatted = string.format(message, ...)
  local line = string.rep("━", #formatted)
  
  if M.use_colors then
    print(string.format("\n%s%s%s%s", M.colors.bold, M.colors.blue, formatted, M.colors.reset))
    print(string.format("%s%s%s", M.colors.blue, line, M.colors.reset))
  else
    print("\n" .. formatted)
    print(line)
  end
end

-- Print section
function M.section(message, ...)
  local formatted = string.format(message, ...)
  
  if M.use_colors then
    print(string.format("\n%s%s%s", M.colors.bold, formatted, M.colors.reset))
  else
    print("\n" .. formatted)
  end
end

-- Print separator
function M.separator()
  if M.use_colors then
    print(string.format("%s%s%s", M.colors.dim, string.rep("─", 50), M.colors.reset))
  else
    print(string.rep("-", 50))
  end
end

-- Print table (for structured data)
function M.table(data, columns)
  if not data or #data == 0 then return end
  
  -- Calculate column widths
  local widths = {}
  for i, col in ipairs(columns) do
    widths[i] = #col.header
    for _, row in ipairs(data) do
      local value = tostring(row[col.key] or "")
      if #value > widths[i] then
        widths[i] = #value
      end
    end
  end
  
  -- Print header
  local header = ""
  for i, col in ipairs(columns) do
    header = header .. string.format("%-" .. widths[i] .. "s  ", col.header)
  end
  
  if M.use_colors then
    print(string.format("%s%s%s", M.colors.bold, header, M.colors.reset))
    print(string.format("%s%s%s", M.colors.dim, string.rep("─", #header), M.colors.reset))
  else
    print(header)
    print(string.rep("-", #header))
  end
  
  -- Print rows
  for _, row in ipairs(data) do
    local line = ""
    for i, col in ipairs(columns) do
      local value = tostring(row[col.key] or "")
      line = line .. string.format("%-" .. widths[i] .. "s  ", value)
    end
    print(line)
  end
end

-- Progress bar
function M.progress(current, total, message)
  if M.quiet then return end
  
  local width = 40
  local percent = math.floor((current / total) * 100)
  local filled = math.floor((current / total) * width)
  local bar = string.rep("█", filled) .. string.rep("░", width - filled)
  
  local line = string.format("\r%s [%s] %d%% (%d/%d)", 
    message or "Progress", bar, percent, current, total)
  
  if M.use_colors then
    io.write(string.format("%s%s%s", M.colors.cyan, line, M.colors.reset))
  else
    io.write(line)
  end
  
  if current == total then
    io.write("\n")
  end
  
  io.flush()
end

-- Spinner (for long operations)
M.spinner_chars = {"⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"}
M.spinner_index = 1

function M.spin(message)
  if M.quiet then return end
  
  local char = M.spinner_chars[M.spinner_index]
  M.spinner_index = M.spinner_index % #M.spinner_chars + 1
  
  if M.use_colors then
    io.write(string.format("\r%s%s %s%s", M.colors.cyan, char, message, M.colors.reset))
  else
    io.write(string.format("\r%s %s", char, message))
  end
  
  io.flush()
end

function M.stop_spin()
  io.write("\r" .. string.rep(" ", 80) .. "\r")
  io.flush()
end

-- Get stats
function M.get_stats()
  return M.stats
end

-- Reset stats
function M.reset_stats()
  M.stats = {
    errors = 0,
    warnings = 0,
    info = 0,
  }
end

return M
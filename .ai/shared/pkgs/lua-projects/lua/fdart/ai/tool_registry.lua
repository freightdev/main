-- fdart/lua/ai/tool_registry.lua
-- Central tool registry and execution system with security controls

local config = require("config")
local utils = require("utils")

local M = {}

M.tools = {}
M.execution_log = {}

-- Tool definition structure
-- {
--   name = "tool_name",
--   description = "What the tool does",
--   parameters = {
--     {name = "param1", type = "string", required = true, description = "..."},
--     {name = "param2", type = "number", required = false, default = 0, description = "..."}
--   },
--   execute = function(params) ... end,
--   requires_confirmation = false, -- Ask user before executing
--   safety_level = "safe" | "caution" | "dangerous",
--   allowed_commands = {}, -- For command-based tools
-- }

-- Register a new tool
function M.register(tool)
  if not tool.name or not tool.execute then
    return false, "Tool must have name and execute function"
  end
  
  tool.parameters = tool.parameters or {}
  tool.safety_level = tool.safety_level or "safe"
  tool.requires_confirmation = tool.requires_confirmation or false
  tool.category = tool.category or "general"
  
  M.tools[tool.name] = tool
  return true
end

-- Unregister a tool
function M.unregister(name)
  M.tools[name] = nil
end

-- Get tool by name
function M.get(name)
  return M.tools[name]
end

-- List all available tools
function M.list(category)
  local tools = {}
  for name, tool in pairs(M.tools) do
    if not category or tool.category == category then
      table.insert(tools, {
        name = name,
        description = tool.description,
        category = tool.category,
        safety_level = tool.safety_level
      })
    end
  end
  return tools
end

-- Validate parameters
function M.validate_params(tool, params)
  params = params or {}
  
  for _, param_def in ipairs(tool.parameters) do
    local value = params[param_def.name]
    
    -- Check required parameters
    if param_def.required and value == nil then
      return false, string.format("Missing required parameter: %s", param_def.name)
    end
    
    -- Set defaults
    if value == nil and param_def.default ~= nil then
      params[param_def.name] = param_def.default
    end
    
    -- Type checking
    if value ~= nil then
      local expected_type = param_def.type
      local actual_type = type(value)
      
      if expected_type == "path" then
        if actual_type ~= "string" then
          return false, string.format("Parameter %s must be a path string", param_def.name)
        end
      elseif expected_type ~= actual_type then
        return false, string.format("Parameter %s must be of type %s, got %s", 
          param_def.name, expected_type, actual_type)
      end
    end
  end
  
  return true, params
end

-- Check if tool execution is allowed
function M.is_allowed(tool_name)
  local allow_execution = config.get("ollama.allow_command_execution", false)
  
  if not allow_execution then
    return false, "Command execution is disabled in config"
  end
  
  local tool = M.tools[tool_name]
  if not tool then
    return false, "Tool not found"
  end
  
  -- Check safety level in dry-run mode
  if config.get("dry_run", false) and tool.safety_level == "dangerous" then
    return false, "Dangerous tools disabled in dry-run mode"
  end
  
  return true
end

-- Execute a tool
function M.execute(tool_name, params, options)
  options = options or {}
  
  local tool = M.tools[tool_name]
  if not tool then
    return nil, string.format("Tool '%s' not found", tool_name)
  end
  
  -- Check if allowed
  local allowed, err = M.is_allowed(tool_name)
  if not allowed then
    return nil, err
  end
  
  -- Validate parameters
  local valid, validated_params = M.validate_params(tool, params)
  if not valid then
    return nil, validated_params -- error message
  end
  
  -- Confirmation for dangerous operations
  if tool.requires_confirmation and not options.skip_confirmation then
    if not M.confirm_execution(tool, validated_params) then
      return nil, "Execution cancelled by user"
    end
  end
  
  -- Log execution attempt
  local log_entry = {
    tool = tool_name,
    params = validated_params,
    timestamp = os.time(),
    safety_level = tool.safety_level
  }
  
  -- Execute
  local success, result = pcall(tool.execute, validated_params, options)
  
  log_entry.success = success
  log_entry.result = success and result or nil
  log_entry.error = not success and result or nil
  
  table.insert(M.execution_log, log_entry)
  
  if not success then
    return nil, result
  end
  
  return result
end

-- Confirm execution with user
function M.confirm_execution(tool, params)
  -- In a real implementation, this would show a prompt
  -- For now, we'll use config settings
  local auto_approve = config.get("ollama.auto_approve_tools", false)
  if auto_approve then
    return true
  end
  
  print(string.format("\n⚠️  Tool '%s' requires confirmation", tool.name))
  print(string.format("Description: %s", tool.description))
  print(string.format("Safety level: %s", tool.safety_level))
  print("\nParameters:")
  for k, v in pairs(params) do
    print(string.format("  %s = %s", k, tostring(v)))
  end
  print("\nAllow execution? (y/N): ")
  
  local answer = io.read()
  return answer and answer:lower() == "y"
end

-- Get execution log
function M.get_log(limit)
  limit = limit or 10
  local log = {}
  local start = math.max(1, #M.execution_log - limit + 1)
  
  for i = start, #M.execution_log do
    table.insert(log, M.execution_log[i])
  end
  
  return log
end

-- Clear execution log
function M.clear_log()
  M.execution_log = {}
end

-- Generate tool descriptions for AI prompt
function M.get_tool_descriptions(category)
  local descriptions = {}
  
  for name, tool in pairs(M.tools) do
    if not category or tool.category == category then
      local param_desc = {}
      for _, param in ipairs(tool.parameters) do
        local req = param.required and "required" or "optional"
        table.insert(param_desc, string.format("  - %s (%s, %s): %s", 
          param.name, param.type, req, param.description))
      end
      
      local desc = string.format(
        "## %s\n%s\n\nParameters:\n%s\n\nSafety: %s",
        name,
        tool.description,
        table.concat(param_desc, "\n"),
        tool.safety_level
      )
      
      table.insert(descriptions, desc)
    end
  end
  
  return table.concat(descriptions, "\n\n---\n\n")
end

-- Parse AI tool call from response
-- Expected format: TOOL_CALL: tool_name(param1="value1", param2=123)
function M.parse_tool_call(text)
  local tool_pattern = "TOOL_CALL:%s*([%w_]+)%((.*)%)"
  local tool_name, params_str = text:match(tool_pattern)
  
  if not tool_name then
    return nil
  end
  
  local params = {}
  
  -- Parse parameters
  for param_pair in params_str:gmatch("([^,]+)") do
    local key, value = param_pair:match('%s*([%w_]+)%s*=%s*"([^"]*)"')
    if not key then
      key, value = param_pair:match('%s*([%w_]+)%s*=%s*(%S+)')
      if key then
        -- Try to convert to number
        local num = tonumber(value)
        if num then
          value = num
        elseif value == "true" then
          value = true
        elseif value == "false" then
          value = false
        end
      end
    end
    
    if key then
      params[key] = value
    end
  end
  
  return {
    tool = tool_name,
    params = params
  }
end

-- Execute tools from AI response
function M.execute_from_response(response, options)
  local results = {}
  
  -- Look for tool calls in the response
  for line in response:gmatch("[^\r\n]+") do
    local tool_call = M.parse_tool_call(line)
    
    if tool_call then
      local result, err = M.execute(tool_call.tool, tool_call.params, options)
      
      table.insert(results, {
        tool = tool_call.tool,
        params = tool_call.params,
        success = result ~= nil,
        result = result,
        error = err
      })
    end
  end
  
  return results
end

return M
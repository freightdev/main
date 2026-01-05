-- fdart/lua/fdart/ai/ollama.lua
-- Ollama AI integration with command execution capabilities

local config = require("fdart.config")
local logger = require("fdart.logger")
local utils = require("fdart.utils")

local M = {}

-- HTTP client (simple implementation)
function M.http_request(method, url, body, timeout)
  timeout = timeout or 300
  
  local cmd
  if body then
    -- POST request with JSON body
    local tmp_file = os.tmpname()
    local f = io.open(tmp_file, "w")
    f:write(body)
    f:close()
    
    cmd = string.format(
      "curl -s -X %s '%s' -H 'Content-Type: application/json' -d @%s --max-time %d",
      method, url, tmp_file, timeout
    )
  else
    -- GET request
    cmd = string.format("curl -s -X %s '%s' --max-time %d", method, url, timeout)
  end
  
  logger.trace("HTTP request: %s", cmd)
  
  local handle = io.popen(cmd)
  if not handle then
    return nil, "Failed to execute curl"
  end
  
  local response = handle:read("*a")
  local success = handle:close()
  
  if body then
    os.remove(tmp_file)
  end
  
  if not success then
    return nil, "Request failed"
  end
  
  return response
end

-- Parse JSON (simple implementation)
function M.json_decode(str)
  local json_ok, json = pcall(require, "dkjson")
  if not json_ok then
    json_ok, json = pcall(require, "cjson")
  end
  
  if json_ok then
    return json.decode(str)
  end
  
  -- Fallback: very basic JSON parsing
  return nil, "JSON library not available"
end

function M.json_encode(obj)
  local json_ok, json = pcall(require, "dkjson")
  if not json_ok then
    json_ok, json = pcall(require, "cjson")
  end
  
  if json_ok then
    return json.encode(obj)
  end
  
  return nil, "JSON library not available"
end

-- Get Ollama API endpoint
function M.get_endpoint(path)
  local host = config.get("ollama.host", "localhost")
  local port = config.get("ollama.port", 11434)
  return string.format("http://%s:%d%s", host, port, path)
end

-- Check if Ollama is available
function M.is_available()
  local url = M.get_endpoint("/api/tags")
  local response, err = M.http_request("GET", url, nil, 5)
  
  if not response then
    return false, err
  end
  
  local data = M.json_decode(response)
  return data ~= nil
end

-- List available models
function M.list_models()
  local url = M.get_endpoint("/api/tags")
  local response, err = M.http_request("GET", url)
  
  if not response then
    return nil, err
  end
  
  local data = M.json_decode(response)
  if not data or not data.models then
    return nil, "Invalid response from Ollama"
  end
  
  local models = {}
  for _, model in ipairs(data.models) do
    table.insert(models, model.name)
  end
  
  return models
end

-- Generate completion (streaming)
function M.generate(prompt, model, options)
  model = model or config.get("ollama.model", "codellama:13b")
  options = options or {}
  
  local system_prompt = config.get("ollama.system_prompt", "")
  local timeout = config.get("ollama.timeout", 300)
  
  local request_body = {
    model = model,
    prompt = prompt,
    system = system_prompt,
    stream = false,
    options = {
      temperature = options.temperature or 0.7,
      top_p = options.top_p or 0.9,
      num_predict = options.max_tokens or 2048,
    }
  }
  
  local body_json = M.json_encode(request_body)
  if not body_json then
    return nil, "Failed to encode request"
  end
  
  local url = M.get_endpoint("/api/generate")
  
  logger.debug("Sending request to Ollama: %s", model)
  logger.spin("Waiting for AI response...")
  
  local response, err = M.http_request("POST", url, body_json, timeout)
  
  logger.stop_spin()
  
  if not response then
    return nil, err or "Request failed"
  end
  
  local data = M.json_decode(response)
  if not data then
    return nil, "Invalid JSON response"
  end
  
  if data.error then
    return nil, data.error
  end
  
  return data.response, nil, data
end

-- Chat completion (multi-turn conversation)
function M.chat(messages, model, options)
  model = model or config.get("ollama.model", "codellama:13b")
  options = options or {}
  
  local timeout = config.get("ollama.timeout", 300)
  
  local request_body = {
    model = model,
    messages = messages,
    stream = false,
    options = {
      temperature = options.temperature or 0.7,
    }
  }
  
  local body_json = M.json_encode(request_body)
  if not body_json then
    return nil, "Failed to encode request"
  end
  
  local url = M.get_endpoint("/api/chat")
  
  logger.spin("Waiting for AI response...")
  
  local response, err = M.http_request("POST", url, body_json, timeout)
  
  logger.stop_spin()
  
  if not response then
    return nil, err or "Request failed"
  end
  
  local data = M.json_decode(response)
  if not data or not data.message then
    return nil, "Invalid response"
  end
  
  return data.message.content, nil, data
end

-- Execute command (for AI agent capabilities)
function M.execute_command(command, context)
  local allow_commands = config.get("ollama.allow_command_execution", false)
  
  if not allow_commands then
    return nil, "Command execution is disabled. Enable with --allow-commands or in config"
  end
  
  -- Security: Check if command is in allowed list
  local allowed_commands = config.get("ollama.allowed_commands", {})
  local cmd_name = command:match("^(%S+)")
  
  local is_allowed = false
  for _, allowed in ipairs(allowed_commands) do
    if cmd_name == allowed or command:match("^" .. allowed .. "%s") then
      is_allowed = true
      break
    end
  end
  
  if not is_allowed then
    logger.warn("Command not in allowed list: %s", cmd_name)
    return nil, string.format("Command '%s' is not allowed", cmd_name)
  end
  
  logger.info("Executing: %s", command)
  
  local handle = io.popen(command .. " 2>&1")
  if not handle then
    return nil, "Failed to execute command"
  end
  
  local output = handle:read("*a")
  local success = handle:close()
  
  return {
    output = output,
    success = success,
    command = command
  }
end

-- Build context for AI from project
function M.build_context(options)
  options = options or {}
  local context = {}
  
  -- Get project info
  local project_root = utils.find_project_root() or "."
  table.insert(context, "Project Root: " .. project_root)
  
  -- Get pubspec info
  local pubspec_path = project_root .. "/pubspec.yaml"
  if utils.file_exists(pubspec_path) then
    local pubspec_content = utils.read_file(pubspec_path)
    if pubspec_content then
      -- Extract key info
      local name = pubspec_content:match("name:%s*([%w_]+)")
      local version = pubspec_content:match("version:%s*([%d%.]+)")
      
      if name then
        table.insert(context, "Package Name: " .. name)
      end
      if version then
        table.insert(context, "Version: " .. version)
      end
    end
  end
  
  -- Get recent errors if requested
  if options.include_errors then
    local errors = options.errors or M.get_recent_errors()
    if errors and #errors > 0 then
      table.insert(context, "\nRecent Errors:")
      for i, error in ipairs(errors) do
        if i <= 5 then -- Limit to 5 errors
          table.insert(context, "  " .. error)
        end
      end
    end
  end
  
  -- Get file tree if requested
  if options.include_tree then
    local tree_output = M.execute_command(string.format("tree -L 2 -I 'build|.dart_tool' %s", project_root))
    if tree_output and tree_output.output then
      table.insert(context, "\nProject Structure:")
      -- Limit lines
      local lines = {}
      for line in tree_output.output:gmatch("[^\r\n]+") do
        table.insert(lines, line)
        if #lines >= config.get("ollama.max_context_lines", 100) then
          break
        end
      end
      table.insert(context, table.concat(lines, "\n"))
    end
  end
  
  return table.concat(context, "\n")
end

-- Get recent Flutter errors
function M.get_recent_errors()
  -- Try to run flutter analyze
  local handle = io.popen("flutter analyze 2>&1")
  if not handle then return {} end
  
  local output = handle:read("*a")
  handle:close()
  
  local errors = {}
  for line in output:gmatch("[^\r\n]+") do
    if line:match("error") or line:match("Error") then
      table.insert(errors, line)
    end
  end
  
  return errors
end

-- Parse AI response for commands
function M.parse_commands(response)
  local commands = {}
  
  -- Look for command blocks in various formats
  -- Format 1: ```fdart cmd <command>```
  for cmd in response:gmatch("```fdart cmd ([^\n]+)") do
    table.insert(commands, cmd)
  end
  
  -- Format 2: `fdart cmd <command>`
  for cmd in response:gmatch("`fdart cmd ([^`]+)`") do
    table.insert(commands, cmd)
  end
  
  -- Format 3: EXECUTE: <command>
  for cmd in response:gmatch("EXECUTE:%s*([^\n]+)") do
    table.insert(commands, cmd)
  end
  
  return commands
end

-- AI-assisted fix workflow
function M.ai_fix_workflow(options)
  options = options or {}
  
  logger.header("AI-Assisted Fix Workflow")
  
  -- Step 1: Gather context
  logger.info("Gathering project context...")
  local context = M.build_context({
    include_errors = true,
    include_tree = false
  })
  
  -- Step 2: Get recent errors
  logger.info("Analyzing errors...")
  local errors = M.get_recent_errors()
  
  if #errors == 0 then
    logger.success("No errors found! Project is clean.")
    return true
  end
  
  logger.warn("Found %d errors", #errors)
  
  -- Step 3: Ask AI for help
  local prompt = string.format([[
I have a Flutter/Dart project with the following errors:

%s

Project Context:
%s

Please analyze these errors and suggest fixes. For each fix:
1. Explain what's wrong
2. Provide the exact command to fix it (use: fdart cmd <command>)
3. Explain why this fix will work

Be specific and actionable.
]], table.concat(errors, "\n"), context)
  
  logger.info("Consulting AI...")
  local response, err = M.generate(prompt, options.model)
  
  if not response then
    logger.error("AI request failed: %s", err)
    return false
  end
  
  -- Step 4: Display AI response
  logger.section("AI Analysis:")
  print(response)
  
  -- Step 5: Parse and execute commands if allowed
  local commands = M.parse_commands(response)
  
  if #commands > 0 then
    logger.section("Found %d suggested commands", #commands)
    
    for i, cmd in ipairs(commands) do
      logger.info("%d. %s", i, cmd)
    end
    
    if config.get("ollama.allow_command_execution", false) then
      logger.info("\nExecuting commands...")
      
      for i, cmd in ipairs(commands) do
        logger.info("Executing %d/%d: %s", i, #commands, cmd)
        local result = M.execute_command(cmd)
        
        if result and result.success then
          logger.success("Command succeeded")
          if result.output and result.output ~= "" then
            logger.debug("Output: %s", result.output:sub(1, 200))
          end
        else
          logger.error("Command failed")
          if result and result.output then
            logger.error("Error: %s", result.output:sub(1, 200))
          end
        end
      end
    else
      logger.warn("Command execution is disabled")
      logger.info("Enable with: --allow-commands or set ollama.allow_command_execution=true in config")
    end
  end
  
  return true
end

-- Interactive chat session
function M.chat_session(options)
  options = options or {}
  
  logger.header("Interactive AI Chat Session")
  logger.info("Type 'exit' or 'quit' to end session")
  logger.info("Type 'context' to refresh project context")
  logger.info("Type 'execute <cmd>' to run a command\n")
  
  local messages = {}
  
  -- Add system message
  table.insert(messages, {
    role = "system",
    content = config.get("ollama.system_prompt", "You are a Flutter/Dart expert assistant.")
  })
  
  -- Add initial context
  local context = M.build_context({include_errors = true})
  table.insert(messages, {
    role = "system",
    content = "Project Context:\n" .. context
  })
  
  while true do
    io.write(logger.colors.cyan .. "You: " .. logger.colors.reset)
    io.flush()
    
    local input = io.read("*line")
    
    if not input or input == "exit" or input == "quit" then
      logger.info("Ending chat session")
      break
    end
    
    if input == "context" then
      context = M.build_context({include_errors = true, include_tree = true})
      logger.info("Context refreshed")
      table.insert(messages, {
        role = "system",
        content = "Updated Project Context:\n" .. context
      })
      goto continue
    end
    
    if input:match("^execute%s+") then
      local cmd = input:match("^execute%s+(.+)$")
      local result = M.execute_command(cmd)
      if result then
        logger.success("Executed: %s", cmd)
        print(result.output)
      else
        logger.error("Command execution failed")
      end
      goto continue
    end
    
    -- Add user message
    table.insert(messages, {
      role = "user",
      content = input
    })
    
    -- Get AI response
    local response, err = M.chat(messages, options.model)
    
    if not response then
      logger.error("AI error: %s", err)
      goto continue
    end
    
    -- Add assistant response
    table.insert(messages, {
      role = "assistant",
      content = response
    })
    
    -- Display response
    print(logger.colors.green .. "AI: " .. logger.colors.reset .. response .. "\n")
    
    -- Check for commands in response
    local commands = M.parse_commands(response)
    if #commands > 0 and config.get("ollama.allow_command_execution", false) then
      logger.info("AI suggested commands. Execute? (y/n)")
      local confirm = io.read("*line")
      if confirm:lower() == "y" or confirm:lower() == "yes" then
        for _, cmd in ipairs(commands) do
          M.execute_command(cmd)
        end
      end
    end
    
    ::continue::
  end
end

return M
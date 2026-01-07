-- fdart/lua/ai/ollama.lua
-- Ollama API client with streaming, context management, and tool execution

local json = require("dkjson") or require("cjson")
local config = require("config")
local utils = require("utils")

local M = {}

-- Client state
M.conversation_history = {}
M.context_window = {}
M.last_request_time = 0
M.rate_limit_delay = 1.0 -- seconds between requests

-- Initialize the AI client
function M.init(options)
  options = options or {}
  M.config = {
    host = options.host or config.get("ollama.host", "localhost"),
    port = options.port or config.get("ollama.port", 11434),
    model = options.model or config.get("ollama.model", "codellama:13b"),
    timeout = options.timeout or config.get("ollama.timeout", 300),
    max_context_lines = options.max_context_lines or config.get("ollama.max_context_lines", 100),
    system_prompt = options.system_prompt or config.get("ollama.system_prompt", ""),
    temperature = options.temperature or 0.7,
    top_p = options.top_p or 0.9,
    stream = options.stream ~= false, -- default true
  }
  
  M.base_url = string.format("http://%s:%d", M.config.host, M.config.port)
  return M
end

-- Check if Ollama is available
function M.is_available()
  local cmd = string.format("curl -s --connect-timeout 2 %s/api/tags > /dev/null 2>&1", M.base_url)
  return os.execute(cmd) == 0
end

-- Get available models
function M.list_models()
  local cmd = string.format("curl -s %s/api/tags", M.base_url)
  local output, success = utils.execute(cmd)
  
  if not success or not output then
    return nil, "Failed to fetch models"
  end
  
  local data = json.decode(output)
  if not data or not data.models then
    return nil, "Invalid response"
  end
  
  local models = {}
  for _, model in ipairs(data.models) do
    table.insert(models, model.name)
  end
  
  return models
end

-- Build the request payload
function M.build_request(prompt, options)
  options = options or {}
  
  local messages = {}
  
  -- Add system prompt
  if M.config.system_prompt and M.config.system_prompt ~= "" then
    table.insert(messages, {
      role = "system",
      content = M.config.system_prompt
    })
  end
  
  -- Add conversation history if enabled
  if options.use_history ~= false then
    for _, msg in ipairs(M.conversation_history) do
      table.insert(messages, msg)
    end
  end
  
  -- Add context if provided
  if options.context then
    table.insert(messages, {
      role = "system",
      content = "## Current Context:\n" .. options.context
    })
  end
  
  -- Add the user prompt
  table.insert(messages, {
    role = "user",
    content = prompt
  })
  
  return {
    model = options.model or M.config.model,
    messages = messages,
    stream = options.stream ~= nil and options.stream or M.config.stream,
    options = {
      temperature = options.temperature or M.config.temperature,
      top_p = options.top_p or M.config.top_p,
      num_predict = options.max_tokens or -1,
    }
  }
end

-- Make a request to Ollama (non-streaming)
function M.generate(prompt, options)
  options = options or {}
  options.stream = false
  
  -- Rate limiting
  local now = os.time()
  local elapsed = now - M.last_request_time
  if elapsed < M.rate_limit_delay then
    local sleep_time = M.rate_limit_delay - elapsed
    os.execute(string.format("sleep %.2f", sleep_time))
  end
  M.last_request_time = os.time()
  
  local request = M.build_request(prompt, options)
  local payload = json.encode(request)
  
  -- Escape payload for shell
  payload = payload:gsub("'", "'\\''")
  
  local cmd = string.format(
    "curl -s -X POST %s/api/chat -H 'Content-Type: application/json' -d '%s' --max-time %d",
    M.base_url,
    payload,
    M.config.timeout
  )
  
  local output, success = utils.execute(cmd)
  
  if not success or not output then
    return nil, "Request failed"
  end
  
  local response = json.decode(output)
  if not response or not response.message then
    return nil, "Invalid response format"
  end
  
  -- Add to conversation history
  if options.save_history ~= false then
    table.insert(M.conversation_history, {role = "user", content = prompt})
    table.insert(M.conversation_history, {role = "assistant", content = response.message.content})
    
    -- Trim history if too long
    M.trim_history()
  end
  
  return response.message.content, response
end

-- Stream a request to Ollama
function M.generate_stream(prompt, callback, options)
  options = options or {}
  options.stream = true
  
  local request = M.build_request(prompt, options)
  local payload = json.encode(request)
  payload = payload:gsub("'", "'\\''")
  
  local cmd = string.format(
    "curl -s -X POST %s/api/chat -H 'Content-Type: application/json' -d '%s' --max-time %d",
    M.base_url,
    payload,
    M.config.timeout
  )
  
  -- Stream handling
  local handle = io.popen(cmd)
  if not handle then
    return nil, "Failed to start stream"
  end
  
  local full_response = ""
  
  for line in handle:lines() do
    if line ~= "" then
      local chunk = json.decode(line)
      if chunk and chunk.message and chunk.message.content then
        full_response = full_response .. chunk.message.content
        if callback then
          callback(chunk.message.content, chunk.done)
        end
      end
    end
  end
  
  handle:close()
  
  -- Save to history
  if options.save_history ~= false then
    table.insert(M.conversation_history, {role = "user", content = prompt})
    table.insert(M.conversation_history, {role = "assistant", content = full_response})
    M.trim_history()
  end
  
  return full_response
end

-- Trim conversation history to stay within context limits
function M.trim_history(max_messages)
  max_messages = max_messages or 10
  
  while #M.conversation_history > max_messages do
    table.remove(M.conversation_history, 1)
  end
end

-- Clear conversation history
function M.clear_history()
  M.conversation_history = {}
end

-- Add context from files
function M.add_file_context(file_path, options)
  options = options or {}
  local max_lines = options.max_lines or M.config.max_context_lines
  
  local content = utils.read_file(file_path)
  if not content then
    return nil, "Cannot read file"
  end
  
  local lines = {}
  for line in content:gmatch("[^\r\n]+") do
    table.insert(lines, line)
    if #lines >= max_lines then break end
  end
  
  local context = {
    file = file_path,
    content = table.concat(lines, "\n"),
    line_count = #lines,
    truncated = #lines >= max_lines
  }
  
  table.insert(M.context_window, context)
  return context
end

-- Build context string from context window
function M.get_context_string()
  if #M.context_window == 0 then
    return nil
  end
  
  local parts = {"## Project Context\n"}
  
  for _, ctx in ipairs(M.context_window) do
    table.insert(parts, string.format("\n### File: %s", ctx.file))
    if ctx.truncated then
      table.insert(parts, string.format("(showing first %d lines)", ctx.line_count))
    end
    table.insert(parts, "```dart")
    table.insert(parts, ctx.content)
    table.insert(parts, "```\n")
  end
  
  return table.concat(parts, "\n")
end

-- Clear context window
function M.clear_context()
  M.context_window = {}
end

-- Ask a question with automatic context
function M.ask(prompt, options)
  options = options or {}
  
  if not options.context and #M.context_window > 0 then
    options.context = M.get_context_string()
  end
  
  if options.stream then
    return M.generate_stream(prompt, options.callback, options)
  else
    return M.generate(prompt, options)
  end
end

-- Get model info
function M.model_info()
  local cmd = string.format("curl -s -X POST %s/api/show -d '{\"name\":\"%s\"}'", M.base_url, M.config.model)
  local output, success = utils.execute(cmd)
  
  if not success or not output then
    return nil, "Failed to get model info"
  end
  
  return json.decode(output)
end

return M
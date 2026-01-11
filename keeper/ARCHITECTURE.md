# ARCHITECTURE.md

## Project Identity

**Name:** Moonrust
**Type:** Multi-agent AI orchestration system with controller/worker architecture
**Primary Language:** Rust
**Deployment Target:** 4 distributed AI systems with load balancing

---

## Vision Statement

<!-- What is this system supposed to DO? Why does it exist? -->

**Purpose:**
[Example: "This is an AI agent orchestration system that manages multiple specialized workers to handle different types of tasks - web search, code execution, RAG queries, MCP tool usage, etc. The goal is to have a configurable, scalable system where I can add new capabilities without rewriting core logic."]

**End Goal:**
[Example: "A production-ready agent system that can handle concurrent requests across 4 distributed nodes, with automatic load balancing, proper error handling, and easy configuration for adding new tools/workers."]

---

## Current State

### What Works

- [ ] Controller receives requests
- [ ] Workers can be spawned
- [ ] Web search tool integration
- [ ] [List everything that actually works right now]
- [ ]

### What's Broken

- [ ] Workers not communicating properly with controller
- [ ] Crate loading is inconsistent
- [ ] [List what broke when you changed architecture]
- [ ]

### What Changed (Why It Broke)

**Previous Architecture:**
[Example: "Workers were directly importing crates and tools"]

**New Architecture:**
[Example: "Moved to API gateway pattern but didn't finish the routing"]

**The Breakage:**
[Example: "Workers lost access to tools because the gateway isn't implemented"]

---

## System Architecture

### High-Level Component Diagram

```
[User/System Request]
        ↓
   [Controller]
        ↓
   [Worker Pool]
    /    |    \
[Worker] [Worker] [Worker]
   |       |       |
[Tools/Crates via API Gateway]
   |       |       |
[WebSearch] [RAG] [MCP] [Other]
```

### Core Components

#### 1. Controller

**Responsibility:**

- [ ] Receive incoming requests
- [ ] Route to appropriate worker type
- [ ] Aggregate responses
- [ ] Handle errors and retries
- [ ] [Other responsibilities]

**Current Implementation Status:**
[Implemented / Partially Working / Broken / Not Started]

**Desired Behavior:**

```
- Receives request with task type
- Checks worker pool availability
- Assigns task to worker
- Monitors worker progress
- Returns consolidated result
```

#### 2. Workers

**Types of Workers:**

1. **[Worker Type 1 - e.g., "SearchWorker"]**
   - Purpose: [What it does]
   - Tools it uses: [List]
   - Communication pattern: [How it talks to controller]

2. **[Worker Type 2 - e.g., "RAGWorker"]**
   - Purpose: [What it does]
   - Tools it uses: [List]
   - Communication pattern: [How it talks to controller]

3. **[Worker Type 3]**
   - Purpose:
   - Tools it uses:
   - Communication pattern:

**Worker Lifecycle:**

```
Spawn → Initialize → Wait for Task → Execute → Report Back → Wait/Shutdown
```

**Current Worker State:**
[How are workers currently implemented? Tokio tasks? Threads? Actors?]

#### 3. Tools & Crates

**Available Tools:**

- [ ] Web Search (via [which crate/API?])
- [ ] RAG Server (location: [path/url])
- [ ] MCP Server (location: [path/url])
- [ ] DuckDB Conversation Indexer (status: [working/not working])
- [ ] [Other tools]

**Tool Access Pattern:**
**Current:** [How do workers access tools now?]
**Desired:** All tool access through API Gateway

---

## API Gateway & Load Balancing

### API Gateway Requirements

**Purpose:** Centralize all tool/crate access behind a single gateway

**Gateway Should Handle:**

- [ ] Authentication/authorization (if needed)
- [ ] Rate limiting
- [ ] Request routing to appropriate tool
- [ ] Error handling and retries
- [ ] Logging/monitoring

**Gateway Endpoints Needed:**

```
POST /tools/search      -> Web search
POST /tools/rag         -> RAG query
POST /tools/mcp         -> MCP tool execution
GET  /tools/status      -> Health check
[List all endpoints you need]
```

**Current Status:** [Not Implemented / Partially Implemented / Working]

### Load Balancing with Pingora

**Target Setup:**

- 4 distributed AI systems
- Pingora-based load balancer
- Simple round-robin or least-connections strategy

**Priority:** [After main system works / Before production / Not urgent]

**Configuration Needed:**

```toml
# Example of what you envision
[load_balancer]
strategy = "round-robin"
nodes = [
    "system1:8080",
    "system2:8080",
    "system3:8080",
    "system4:8080"
]
health_check_interval = 30
```

---

## Communication & Data Flow

### Request Flow

```
1. Request arrives at Controller
   Input: { task_type: "search", query: "rust async", params: {...} }

2. Controller selects Worker
   Logic: [How does it choose? Round-robin? By task type? Worker availability?]

3. Worker receives task
   Format: [What does the task struct look like?]

4. Worker executes using Tools
   Via: [API Gateway / Direct import / Message passing?]

5. Worker returns result
   Format: [What does response look like?]

6. Controller processes result
   Action: [Aggregate? Forward directly? Transform?]

7. Response sent back
   Output: [Final format]
```

### Message Passing

**Current Implementation:**
[Channels? Queues? HTTP? gRPC?]

**Desired Pattern:**
[What do you want? Tokio mpsc? Actor model? Something else?]

---

## Configuration System

### What Needs to Be Configurable?

- [ ] Number of workers per type
- [ ] Tool endpoints/URLs
- [ ] API keys/credentials
- [ ] Timeout values
- [ ] Retry logic
- [ ] Logging levels
- [ ] [Other config items]

### Configuration Format

**Preferred:** [TOML / YAML / JSON / Environment Variables / All of the above]

**Example Config Structure:**

```toml
[controller]
max_workers = 10
request_timeout = 30

[workers.search]
pool_size = 3
enabled = true

[workers.rag]
pool_size = 2
enabled = true
endpoint = "http://localhost:8001"

[tools]
api_gateway_url = "http://localhost:8000"

[tools.search]
provider = "duckduckgo"
rate_limit = 10

[tools.rag]
embedding_model = "all-MiniLM-L6-v2"
```

---

## Dependencies & Crates

### Core Dependencies

_[List will come from your Cargo.toml, but note which ones are critical]_

**Essential Crates:**

- `tokio` - [Why? Async runtime]
- `[crate name]` - [Purpose]
- `[crate name]` - [Purpose]

**Tool-Specific Crates:**

- `reqwest` - [HTTP client for API calls?]
- `[crate name]` - [Purpose]

**Optional/Feature-Flagged:**

- `[crate name]` - [When is this used?]

---

## Error Handling Strategy

### Current Approach

[How are errors handled now? Result types? Unwraps? Panics?]

### Desired Approach

**Error Types Needed:**

- [ ] WorkerError (worker crashes, timeouts)
- [ ] ToolError (tool unavailable, API failures)
- [ ] ConfigError (bad configuration)
- [ ] NetworkError (connectivity issues)
- [ ] [Other error types]

**Recovery Strategy:**

- Worker fails: [Retry? Spawn new worker? Fail request?]
- Tool unavailable: [Fallback? Queue? Fail?]
- Controller crash: [How to handle?]

---

## Testing Strategy

### What Needs Tests?

- [ ] Controller routing logic
- [ ] Worker task execution
- [ ] Tool integration (mock API calls)
- [ ] Error handling and recovery
- [ ] Configuration loading
- [ ] [Other test scenarios]

### Current Test Coverage

[Percentage if known, or just: None / Some / Good]

---

## External Systems & Integrations

### Systems Already Built

1. **MCP Server**
   - Location: [path/url]
   - Status: [Working / Needs integration]
   - How to access: [Protocol, endpoints]

2. **RAG Server**
   - Location: [path/url]
   - Status: [Working / Needs integration]
   - Implementation: [Python? Rust? Language/framework]

3. **DuckDB Conversation Indexer**
   - Location: [path/url]
   - Status: [Working / Not tested]
   - Purpose: [Index chat conversations for retrieval]

4. **[Other systems]**
   - Location:
   - Status:
   - Purpose:

### Integration Requirements

**For each external system, specify:**

- Communication protocol (HTTP REST, gRPC, direct function calls)
- Authentication needed (API keys, tokens, none)
- Expected request/response format
- Error handling approach

---

## File Structure

### Current Structure

```
project/
├── Cargo.toml
├── src/
│   ├── main.rs          [Current state: ?]
│   ├── lib.rs           [Current state: ?]
│   ├── controller.rs    [Exists? What's in it?]
│   ├── workers/
│   │   ├── mod.rs
│   │   ├── [worker files]
│   ├── tools/
│   │   ├── mod.rs
│   │   ├── [tool files]
│   └── [other modules]
└── [other directories]
```

### Desired Structure

```
project/
├── Cargo.toml
├── config/
│   └── default.toml
├── src/
│   ├── main.rs          [Just the runner]
│   ├── lib.rs           [Core system exports]
│   ├── controller/
│   │   ├── mod.rs
│   │   └── [controller logic]
│   ├── workers/
│   │   ├── mod.rs
│   │   ├── base.rs      [Worker trait]
│   │   ├── search.rs
│   │   ├── rag.rs
│   │   └── [other workers]
│   ├── tools/
│   │   ├── mod.rs
│   │   ├── gateway.rs   [API gateway client]
│   │   └── [tool interfaces]
│   ├── types/
│   │   ├── mod.rs
│   │   ├── requests.rs
│   │   ├── responses.rs
│   │   └── errors.rs
│   └── config.rs
├── tests/
│   ├── integration/
│   └── unit/
└── examples/
    └── basic_usage.rs
```

---

## Development Phases

### Phase 1: Core Architecture [Current Focus]

**Goal:** Get controller → worker → tool flow working

**Tasks:**

- [ ] Define clear interfaces (traits) for Controller, Worker, Tool
- [ ] Implement basic Controller that can spawn workers
- [ ] Implement one Worker type that can execute a task
- [ ] Test the flow end-to-end with mock tool
- [ ]

**Success Criteria:**

- Can send request to controller
- Controller spawns appropriate worker
- Worker executes and returns result
- No panics, proper error handling

### Phase 2: Tool Integration

**Goal:** Connect to actual external tools/services

**Tasks:**

- [ ] Implement API Gateway client (or direct integration)
- [ ] Connect to MCP server
- [ ] Connect to RAG server
- [ ] Connect to web search
- [ ]

**Success Criteria:**

- All tools accessible from workers
- Proper error handling for tool failures
- Can execute real tasks end-to-end

### Phase 3: Configuration & Robustness

**Goal:** Make system configurable and production-ready

**Tasks:**

- [ ] Implement configuration system
- [ ] Add comprehensive error handling
- [ ] Add logging/monitoring
- [ ] Add tests
- [ ]

### Phase 4: Distribution & Scaling [Future]

**Goal:** Deploy across 4 systems with load balancing

**Tasks:**

- [ ] Implement Pingora load balancer
- [ ] Deploy to 4 nodes
- [ ] Add health checks
- [ ] Add monitoring
- [ ]

---

## Open Questions & Decisions Needed

### Architecture Decisions

- [ ] Should workers be long-lived or spawned per-request?
- [ ] Async channels or sync? (tokio::mpsc vs std::sync::mpsc)
- [ ] Actor model (like Actix) or manual task spawning?
- [ ] How to handle worker crashes? Supervisor pattern?

### Implementation Decisions

- [ ] API Gateway: build it or use existing tool?
- [ ] Configuration: single file or multiple?
- [ ] Logging: tracing vs log crate?
- [ ] Database for state? Or keep everything in-memory?

### Tool Integration Questions

- [ ] Can all tools be accessed over HTTP? Or some need direct linking?
- [ ] Do tools need authentication?
- [ ] What's the expected latency for each tool?

---

## Performance Requirements

### Target Metrics

- Request latency: [X ms / don't care yet]
- Concurrent requests: [X per second / don't care yet]
- Worker pool size: [X workers / configurable]
- Tool timeout: [X seconds per tool call]

### Resource Constraints

- Memory: [Any limits?]
- CPU: [Any limits?]
- Network: [Local only? Cross-region?]

---

## Security Considerations

### Current Security

[None / API keys in config / Other]

### Needed Security

- [ ] API authentication for gateway
- [ ] Secrets management (API keys, tokens)
- [ ] Input validation
- [ ] Rate limiting
- [ ] [Other security needs]

---

## Documentation Needs

### Code Documentation

- [ ] Inline comments for complex logic
- [ ] Doc comments for public APIs
- [ ] Examples in docs

### User Documentation

- [ ] README with setup instructions
- [ ] Configuration guide
- [ ] API documentation (if exposing API)
- [ ] Troubleshooting guide

---

## Success Criteria

### Minimum Viable Product (MVP)

**The system works when:**

1. [ ] I can send a request to the controller
2. [ ] Controller routes it to the right worker
3. [ ] Worker uses appropriate tool
4. [ ] Result comes back correctly
5. [ ] Errors are handled gracefully

### Production Ready

**The system is production-ready when:**

1. [ ] All MVP criteria met
2. [ ] Deployed across 4 systems
3. [ ] Load balancer distributing traffic
4. [ ] Monitoring and logging in place
5. [ ] Can handle [X] concurrent requests
6. [ ] Fails gracefully under load

---

## Notes & Brain Dump

<!-- Use this section to dump any additional thoughts, ideas, or context -->

**Things I'm not sure about:**

- [List anything you're uncertain about]

**Things I want to add later:**

- [Future features not needed now]

**References:**

- [Links to docs, similar projects, articles that inspired this]

**Random thoughts:**

- [Anything else that doesn't fit above]

---

## How to Use This Template

1. **Fill it out section by section** - Don't try to do it all at once
2. **Be honest** - If something is broken, say it's broken
3. **Use placeholders** - Put `[TODO]` or `[Figure this out later]` if you don't know yet
4. **It's okay to not know** - The point is to get clarity, not pretend you have all answers
5. **Update it** - This is a living document, change it as you figure stuff out

**Priority sections to fill out first:**

1. Vision Statement
2. Current State
3. System Architecture (Core Components)
4. Communication & Data Flow
5. Phase 1 tasks

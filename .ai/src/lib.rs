use async_trait::async_trait;
use shared_types::*;
use std::sync::Arc;

/// Trait for model inference backends
#[async_trait]
pub trait ModelBackend: Send + Sync {
    async fn infer(&self, prompt: String) -> Result<String>;
    fn backend_type(&self) -> ComputeBackend;
    fn is_available(&self) -> bool;
    async fn warmup(&mut self) -> Result<()>;
}

/// CPU backend using llama.cpp
pub struct LlamaCppBackend {
    model_path: String,
    context_size: usize,
    is_loaded: bool,
}

impl LlamaCppBackend {
    pub fn new(model_path: String, context_size: usize) -> Self {
        Self {
            model_path,
            context_size,
            is_loaded: false,
        }
    }
}

#[async_trait]
impl ModelBackend for LlamaCppBackend {
    async fn infer(&self, prompt: String) -> Result<String> {
        if !self.is_loaded {
            return Err(AgentError::ModelError("Model not loaded".to_string()));
        }

        // TODO: Actual llama.cpp integration
        // This would use the llama-cpp-rs bindings or similar
        Ok(format!("[CPU/llama.cpp] Response to: {}", prompt))
    }

    fn backend_type(&self) -> ComputeBackend {
        ComputeBackend::CPU
    }

    fn is_available(&self) -> bool {
        // Check if llama.cpp is available
        true
    }

    async fn warmup(&mut self) -> Result<()> {
        // Load model into memory
        self.is_loaded = true;
        Ok(())
    }
}

/// GPU backend using Candle
pub struct CandleBackend {
    model_path: String,
    device: String,
    is_loaded: bool,
}

impl CandleBackend {
    pub fn new(model_path: String) -> Self {
        Self {
            model_path,
            device: "cuda:0".to_string(),
            is_loaded: false,
        }
    }
}

#[async_trait]
impl ModelBackend for CandleBackend {
    async fn infer(&self, prompt: String) -> Result<String> {
        if !self.is_loaded {
            return Err(AgentError::ModelError("Model not loaded".to_string()));
        }

        #[cfg(feature = "gpu")]
        {
            // TODO: Actual Candle integration
            // This would use candle-core and candle-nn
            Ok(format!("[GPU/Candle] Response to: {}", prompt))
        }

        #[cfg(not(feature = "gpu"))]
        {
            Err(AgentError::ModelError(
                "GPU feature not enabled".to_string(),
            ))
        }
    }

    fn backend_type(&self) -> ComputeBackend {
        ComputeBackend::GPU
    }

    fn is_available(&self) -> bool {
        #[cfg(feature = "gpu")]
        {
            // Check if CUDA/ROCm is available
            true
        }
        #[cfg(not(feature = "gpu"))]
        {
            false
        }
    }

    async fn warmup(&mut self) -> Result<()> {
        self.is_loaded = true;
        Ok(())
    }
}

/// NPU backend using OpenVINO
pub struct OpenVinoBackend {
    model_path: String,
    device: String,
    is_loaded: bool,
}

impl OpenVinoBackend {
    pub fn new(model_path: String) -> Self {
        Self {
            model_path,
            device: "NPU".to_string(),
            is_loaded: false,
        }
    }
}

#[async_trait]
impl ModelBackend for OpenVinoBackend {
    async fn infer(&self, prompt: String) -> Result<String> {
        if !self.is_loaded {
            return Err(AgentError::ModelError("Model not loaded".to_string()));
        }

        // TODO: Actual OpenVINO integration
        Ok(format!("[NPU/OpenVINO] Response to: {}", prompt))
    }

    fn backend_type(&self) -> ComputeBackend {
        ComputeBackend::NPU
    }

    fn is_available(&self) -> bool {
        // Check if NPU device is available
        true
    }

    async fn warmup(&mut self) -> Result<()> {
        self.is_loaded = true;
        Ok(())
    }
}

/// External API backends (Claude, OpenAI)
pub struct ExternalModelClient {
    provider: ModelProvider,
    api_key: Option<String>,
}

impl ExternalModelClient {
    pub fn new(provider: ModelProvider, api_key: Option<String>) -> Self {
        Self { provider, api_key }
    }

    pub async fn call(&self, prompt: String) -> Result<String> {
        match &self.provider {
            ModelProvider::Claude { model } => self.call_claude(model, prompt).await,
            ModelProvider::OpenAI { model } => self.call_openai(model, prompt).await,
            ModelProvider::Local { .. } => {
                Err(AgentError::ExternalApiError("Not an external provider".to_string()))
            }
        }
    }

    async fn call_claude(&self, model: &str, prompt: String) -> Result<String> {
        let api_key = self
            .api_key
            .as_ref()
            .ok_or_else(|| AgentError::ExternalApiError("No API key".to_string()))?;

        let client = reqwest::Client::new();
        let response = client
            .post("https://api.anthropic.com/v1/messages")
            .header("x-api-key", api_key)
            .header("anthropic-version", "2023-06-01")
            .json(&serde_json::json!({
                "model": model,
                "max_tokens": 1024,
                "messages": [{"role": "user", "content": prompt}]
            }))
            .send()
            .await
            .map_err(|e| AgentError::ExternalApiError(e.to_string()))?;

        let data: serde_json::Value = response
            .json()
            .await
            .map_err(|e| AgentError::ExternalApiError(e.to_string()))?;

        Ok(data["content"][0]["text"]
            .as_str()
            .unwrap_or("No response")
            .to_string())
    }

    async fn call_openai(&self, model: &str, prompt: String) -> Result<String> {
        let api_key = self
            .api_key
            .as_ref()
            .ok_or_else(|| AgentError::ExternalApiError("No API key".to_string()))?;

        let client = reqwest::Client::new();
        let response = client
            .post("https://api.openai.com/v1/chat/completions")
            .header("Authorization", format!("Bearer {}", api_key))
            .json(&serde_json::json!({
                "model": model,
                "messages": [{"role": "user", "content": prompt}]
            }))
            .send()
            .await
            .map_err(|e| AgentError::ExternalApiError(e.to_string()))?;

        let data: serde_json::Value = response
            .json()
            .await
            .map_err(|e| AgentError::ExternalApiError(e.to_string()))?;

        Ok(data["choices"][0]["message"]["content"]
            .as_str()
            .unwrap_or("No response")
            .to_string())
    }
}

/// Router that selects the appropriate backend
pub struct ModelRouter {
    backends: Vec<Arc<dyn ModelBackend>>,
    external_client: Option<ExternalModelClient>,
}

impl ModelRouter {
    pub fn new() -> Self {
        Self {
            backends: Vec::new(),
            external_client: None,
        }
    }

    pub fn add_backend(&mut self, backend: Arc<dyn ModelBackend>) {
        self.backends.push(backend);
    }

    pub fn set_external_client(&mut self, client: ExternalModelClient) {
        self.external_client = Some(client);
    }

    pub async fn route(&self, prompt: String, preferred_backend: Option<ComputeBackend>) -> Result<String> {
        // If preferred backend specified, try to use it
        if let Some(backend_type) = preferred_backend {
            for backend in &self.backends {
                if backend.backend_type() == backend_type && backend.is_available() {
                    return backend.infer(prompt).await;
                }
            }
        }

        // Otherwise, use first available backend
        for backend in &self.backends {
            if backend.is_available() {
                return backend.infer(prompt).await;
            }
        }

        Err(AgentError::ResourceExhausted("No backends available".to_string()))
    }

    pub async fn ask_for_help(&self, context: String, question: String) -> Result<String> {
        if let Some(client) = &self.external_client {
            let prompt = format!("Context: {}\n\nQuestion: {}", context, question);
            client.call(prompt).await
        } else {
            Err(AgentError::ExternalApiError("No external client configured".to_string()))
        }
    }
}

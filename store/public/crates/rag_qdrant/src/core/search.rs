// lib/ai-crates/qdrant-rag/src/search.rs

use serde::{Deserialize, Serialize};

#[derive(Debug, Clone)]
pub struct SearchQuery {
    pub text: String,
    pub top_k: Option<usize>,
    pub threshold: Option<f32>,
    pub filter: Option<SearchFilter>,
}

impl SearchQuery {
    pub fn new(text: impl Into<String>) -> Self {
        Self {
            text: text.into(),
            top_k: None,
            threshold: None,
            filter: None,
        }
    }

    pub fn with_top_k(mut self, top_k: usize) -> Self {
        self.top_k = Some(top_k);
        self
    }

    pub fn with_threshold(mut self, threshold: f32) -> Self {
        self.threshold = Some(threshold);
        self
    }

    pub fn with_filter(mut self, filter: SearchFilter) -> Self {
        self.filter = Some(filter);
        self
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SearchFilter {
    pub file_types: Option<Vec<String>>,
    pub paths: Option<Vec<String>>,
    pub exclude_paths: Option<Vec<String>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SearchResult {
    pub file_path: String,
    pub content: String,
    pub score: f32,
    pub metadata: SearchMetadata,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SearchMetadata {
    pub crate_name: Option<String>,
    pub line_start: Option<usize>,
    pub line_end: Option<usize>,
    pub chunk_type: Option<String>,
    pub language: Option<String>,
}

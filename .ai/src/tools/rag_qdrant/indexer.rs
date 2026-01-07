// lib/ai-crates/qdrant-rag/src/indexer.rs

use crate::config::{ChunkingConfig, ChunkingStrategy, IndexingConfig};
use crate::error::{RagError, RagResult};
use ignore::WalkBuilder;
use std::path::{Path, PathBuf};
use tracing::{debug, warn};

#[derive(Debug, Clone)]
pub struct CodeChunk {
    pub file_path: String,
    pub content: String,
    pub line_start: usize,
    pub line_end: usize,
    pub crate_name: Option<String>,
    pub chunk_type: Option<String>,
    pub language: Option<String>,
}

pub struct Indexer {
    indexing_config: IndexingConfig,
    chunking_config: ChunkingConfig,
    chunks_generated: usize,
}

impl Indexer {
    pub fn new(indexing_config: IndexingConfig, chunking_config: ChunkingConfig) -> Self {
        Self {
            indexing_config,
            chunking_config,
            chunks_generated: 0,
        }
    }

    pub async fn index_directory(&self, path: &Path) -> RagResult<Vec<CodeChunk>> {
        let mut all_chunks = Vec::new();

        // Walk directory respecting gitignore and patterns
        let walker = WalkBuilder::new(path)
            .hidden(false) // Include hidden files
            .git_ignore(true) // Respect .gitignore
            .build();

        for entry in walker {
            let entry = match entry {
                Ok(e) => e,
                Err(err) => {
                    warn!("Error walking directory: {}", err);
                    continue;
                }
            };

            let path = entry.path();

            // Skip directories
            if path.is_dir() {
                continue;
            }

            // Check file size
            if let Ok(metadata) = std::fs::metadata(path) {
                let size_mb = metadata.len() / (1024 * 1024);
                if size_mb > self.indexing_config.max_file_size_mb as u64 {
                    debug!("Skipping large file: {} ({}MB)", path.display(), size_mb);
                    continue;
                }
            }

            // Check if file matches include patterns
            if !self.should_include_file(path) {
                continue;
            }

            // Check if file matches exclude patterns
            if self.should_exclude_file(path) {
                continue;
            }

            // Index the file
            match self.index_file(path).await {
                Ok(chunks) => {
                    debug!("Indexed {} with {} chunks", path.display(), chunks.len());
                    all_chunks.extend(chunks);
                }
                Err(err) => {
                    warn!("Error indexing {}: {}", path.display(), err);
                }
            }
        }

        Ok(all_chunks)
    }

    pub async fn index_file(&self, path: &Path) -> RagResult<Vec<CodeChunk>> {
        let content = tokio::fs::read_to_string(path).await?;

        let file_path = path.to_string_lossy().to_string();
        let language = self.detect_language(path);
        let crate_name = self.extract_crate_name(path);

        // Chunk the content
        let chunks = self.chunk_content(&content, &file_path, language, crate_name)?;

        Ok(chunks)
    }

    fn chunk_content(
        &self,
        content: &str,
        file_path: &str,
        language: Option<String>,
        crate_name: Option<String>,
    ) -> RagResult<Vec<CodeChunk>> {
        match self.chunking_config.strategy {
            ChunkingStrategy::Semantic => self.chunk_semantic(content, file_path, language, crate_name),
            ChunkingStrategy::Fixed => self.chunk_fixed(content, file_path, language, crate_name),
            ChunkingStrategy::Adaptive => self.chunk_adaptive(content, file_path, language, crate_name),
        }
    }

    fn chunk_semantic(
        &self,
        content: &str,
        file_path: &str,
        language: Option<String>,
        crate_name: Option<String>,
    ) -> RagResult<Vec<CodeChunk>> {
        let mut chunks = Vec::new();
        let lines: Vec<&str> = content.lines().collect();

        if lines.is_empty() {
            return Ok(chunks);
        }

        // Simple semantic chunking based on Rust code structure
        let mut current_chunk = String::new();
        let mut chunk_start = 1;
        let mut current_line = 1;

        for line in &lines {
            let trimmed = line.trim();

            // Check if this line starts a new chunk (function, impl, struct, enum, mod)
            let is_boundary = trimmed.starts_with("pub fn ")
                || trimmed.starts_with("fn ")
                || trimmed.starts_with("impl ")
                || trimmed.starts_with("pub struct ")
                || trimmed.starts_with("struct ")
                || trimmed.starts_with("pub enum ")
                || trimmed.starts_with("enum ")
                || trimmed.starts_with("pub mod ")
                || trimmed.starts_with("mod ");

            if is_boundary && !current_chunk.is_empty() {
                // Save current chunk
                if current_chunk.len() >= self.chunking_config.min_size {
                    chunks.push(CodeChunk {
                        file_path: file_path.to_string(),
                        content: current_chunk.clone(),
                        line_start: chunk_start,
                        line_end: current_line - 1,
                        crate_name: crate_name.clone(),
                        chunk_type: Some("semantic".to_string()),
                        language: language.clone(),
                    });
                }

                // Start new chunk
                current_chunk = line.to_string() + "\n";
                chunk_start = current_line;
            } else {
                current_chunk.push_str(line);
                current_chunk.push('\n');

                // Split if chunk gets too large
                if current_chunk.len() > self.chunking_config.max_size {
                    chunks.push(CodeChunk {
                        file_path: file_path.to_string(),
                        content: current_chunk.clone(),
                        line_start: chunk_start,
                        line_end: current_line,
                        crate_name: crate_name.clone(),
                        chunk_type: Some("semantic".to_string()),
                        language: language.clone(),
                    });
                    current_chunk.clear();
                    chunk_start = current_line + 1;
                }
            }

            current_line += 1;
        }

        // Add final chunk
        if !current_chunk.is_empty() && current_chunk.len() >= self.chunking_config.min_size {
            chunks.push(CodeChunk {
                file_path: file_path.to_string(),
                content: current_chunk,
                line_start: chunk_start,
                line_end: current_line - 1,
                crate_name,
                chunk_type: Some("semantic".to_string()),
                language,
            });
        }

        Ok(chunks)
    }

    fn chunk_fixed(
        &self,
        content: &str,
        file_path: &str,
        language: Option<String>,
        crate_name: Option<String>,
    ) -> RagResult<Vec<CodeChunk>> {
        let mut chunks = Vec::new();
        let lines: Vec<&str> = content.lines().collect();

        let chunk_size = self.chunking_config.size;
        let overlap = self.chunking_config.overlap;

        let mut start = 0;
        while start < content.len() {
            let end = (start + chunk_size).min(content.len());
            let chunk_content = &content[start..end];

            let line_start = content[..start].lines().count() + 1;
            let line_end = content[..end].lines().count() + 1;

            chunks.push(CodeChunk {
                file_path: file_path.to_string(),
                content: chunk_content.to_string(),
                line_start,
                line_end,
                crate_name: crate_name.clone(),
                chunk_type: Some("fixed".to_string()),
                language: language.clone(),
            });

            start = end - overlap.min(end - start);
            if start >= content.len() {
                break;
            }
        }

        Ok(chunks)
    }

    fn chunk_adaptive(
        &self,
        content: &str,
        file_path: &str,
        language: Option<String>,
        crate_name: Option<String>,
    ) -> RagResult<Vec<CodeChunk>> {
        // For now, adaptive uses semantic chunking
        // Could be enhanced with complexity analysis in the future
        self.chunk_semantic(content, file_path, language, crate_name)
    }

    fn should_include_file(&self, path: &Path) -> bool {
        if self.indexing_config.include_patterns.is_empty() {
            return true;
        }

        let path_str = path.to_string_lossy();
        self.indexing_config
            .include_patterns
            .iter()
            .any(|pattern| {
                glob::Pattern::new(pattern)
                    .map(|p| p.matches(&path_str))
                    .unwrap_or(false)
            })
    }

    fn should_exclude_file(&self, path: &Path) -> bool {
        let path_str = path.to_string_lossy();
        self.indexing_config
            .exclude_patterns
            .iter()
            .any(|pattern| {
                glob::Pattern::new(pattern)
                    .map(|p| p.matches(&path_str))
                    .unwrap_or(false)
            })
    }

    fn detect_language(&self, path: &Path) -> Option<String> {
        path.extension()
            .and_then(|ext| ext.to_str())
            .map(|ext| match ext {
                "rs" => "rust",
                "toml" => "toml",
                "md" => "markdown",
                "js" | "jsx" => "javascript",
                "ts" | "tsx" => "typescript",
                "py" => "python",
                "go" => "go",
                "java" => "java",
                "c" => "c",
                "cpp" | "cc" | "cxx" => "cpp",
                "h" | "hpp" => "header",
                _ => "unknown",
            })
            .map(|s| s.to_string())
    }

    fn extract_crate_name(&self, path: &Path) -> Option<String> {
        // Try to find Cargo.toml in parent directories to extract crate name
        let mut current = path;
        while let Some(parent) = current.parent() {
            let cargo_toml = parent.join("Cargo.toml");
            if cargo_toml.exists() {
                // Extract crate name from directory name
                return parent
                    .file_name()
                    .and_then(|n| n.to_str())
                    .map(|s| s.to_string());
            }
            current = parent;
        }
        None
    }

    pub fn chunks_generated(&self) -> usize {
        self.chunks_generated
    }
}

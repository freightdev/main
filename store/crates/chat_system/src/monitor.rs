// Chat monitoring - watches for new messages in chat files

use std::path::Path;
use std::time::Duration;
use tokio::fs;
use tokio::time::interval;
use tracing::{info, warn};

pub struct ChatMonitor {
    chat_file: String,
    last_position: u64,
}

impl ChatMonitor {
    pub fn new(chat_file: String) -> Self {
        Self {
            chat_file,
            last_position: 0,
        }
    }

    pub async fn start_monitoring(&mut self) -> Result<(), Box<dyn std::error::Error>> {
        info!("Starting chat monitor for: {}", self.chat_file);

        // Ensure chat file exists
        if !Path::new(&self.chat_file).exists() {
            fs::write(&self.chat_file, "").await?;
        }

        let mut interval = interval(Duration::from_secs(5));

        loop {
            interval.tick().await;
            
            if let Ok(new_content) = self.read_new_content().await {
                if !new_content.is_empty() {
                    info!("New chat content detected");
                    // Process new content here
                }
            }
        }
    }

    async fn read_new_content(&mut self) -> Result<String, Box<dyn std::error::Error>> {
        let metadata = fs::metadata(&self.chat_file).await?;
        let current_size = metadata.len();

        if current_size <= self.last_position {
            return Ok(String::new());
        }

        let content = fs::read_to_string(&self.chat_file).await?;
        let new_content = content[self.last_position as usize..].to_string();
        self.last_position = current_size;

        Ok(new_content)
    }
}
// Chat writer - outputs messages to chat files

use chrono::Utc;
use tokio::fs;
use tokio::io::AsyncWriteExt;
use tracing::info;

pub struct ChatWriter {
    chat_file: String,
}

impl ChatWriter {
    pub fn new(chat_file: String) -> Self {
        Self { chat_file }
    }

    pub async fn write_message(&self, sender: &str, content: &str) -> Result<(), Box<dyn std::error::Error>> {
        let timestamp = Utc::now().format("%Y-%m-%d %H:%M:%S UTC");
        let message = format!("[{}] {}\n{}\n\n", timestamp, sender, content);

        let mut file = fs::OpenOptions::new()
            .create(true)
            .append(true)
            .open(&self.chat_file)
            .await?;

        file.write_all(message.as_bytes()).await?;
        file.flush().await?;

        info!("Message written to chat file");
        Ok(())
    }

    pub async fn write_system_message(&self, content: &str) -> Result<(), Box<dyn std::error::Error>> {
        self.write_message("System", content).await
    }

    pub async fn write_agent_message(&self, agent_name: &str, content: &str) -> Result<(), Box<dyn std::error::Error>> {
        self.write_message(&format!("Agent({})", agent_name), content).await
    }
}
// Chat message parsing - handles incoming message format

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChatMessage {
    pub timestamp: DateTime<Utc>,
    pub sender: String,
    pub content: String,
    pub message_type: MessageType,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum MessageType {
    User,
    System,
    Agent,
    Command,
}

pub fn parse_message(raw: &str) -> Result<ChatMessage, Box<dyn std::error::Error>> {
    let lines: Vec<&str> = raw.lines().collect();
    
    if lines.is_empty() {
        return Err("Empty message".into());
    }

    // Try to parse timestamp and sender from first line
    let header = lines[0].trim();
    let (sender, message_type) = if header.starts_with('[') && header.contains(']') {
        let parts: Vec<&str> = header.splitn(3, ']').collect();
        if parts.len() >= 2 {
            let sender_part = parts[0].trim_start('[').trim();
            let type_part = parts.get(1).and_then(|p| p.trim_start('(').trim_end(')').trim().split_whitespace().next());
            
            let message_type = match type_part {
                Some("system") => MessageType::System,
                Some("agent") => MessageType::Agent,
                Some("command") => MessageType::Command,
                _ => MessageType::User,
            };
            
            (sender_part.to_string(), message_type)
        } else {
            (header.to_string(), MessageType::User)
        }
    } else {
        (header.to_string(), MessageType::User)
    };

    // Combine remaining lines as content
    let content = if lines.len() > 1 {
        lines[1..].join("\n")
    } else {
        String::new()
    };

    Ok(ChatMessage {
        timestamp: Utc::now(),
        sender,
        content,
        message_type,
    })
}
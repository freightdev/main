#!/bin/bash
# ============================================================================
# PHASE 4: Clients
# Creates Ollama client with retry logic and connection validation
# ============================================================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  PHASE 4: Clients${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo

# ============================================================================
# Create src/clients/ollama_client.py
# ============================================================================
echo -e "${GREEN}[1/1]${NC} Creating clients/ollama_client.py..."

cat > src/clients/ollama_client.py << 'EOF'
"""Ollama client with retry logic and validation"""
import logging
import time
from typing import Optional
import requests

from langchain_community.llms import Ollama
from ..core.config import AgentConfig

class OllamaClient:
    """Ollama client with connection validation and retry logic"""
    
    def __init__(self, config: AgentConfig, logger: Optional[logging.Logger] = None):
        self.config = config
        self.logger = logger or logging.getLogger(__name__)
        self.llm = None
        self._validate_connection()
    
    def _validate_connection(self):
        """Validate Ollama connection before starting"""
        try:
            # Test if Ollama server is reachable
            response = requests.get(
                f"{self.config.base_url}/api/tags",
                timeout=5
            )
            
            if response.status_code != 200:
                raise ConnectionError(f"Ollama server returned status {response.status_code}")
            
            # Initialize LLM client
            self.llm = Ollama(
                model=self.config.model,
                base_url=self.config.base_url,
                timeout=self.config.timeout,
                temperature=self.config.temperature,
                num_ctx=self.config.context_window,
                num_gpu=self.config.num_gpu
            )
            
            # Test with a simple prompt
            try:
                test_response = self.llm.invoke("test", max_tokens=5)
                if not test_response:
                    raise ValueError("Empty response from test prompt")
            except Exception as e:
                self.logger.warning(f"Test prompt failed, but connection OK: {e}")
            
            self.logger.info(
                f"✅ Connected to {self.config.role} at {self.config.base_url} "
                f"(model: {self.config.model})"
            )
            
        except requests.exceptions.RequestException as e:
            self.logger.error(f"❌ Cannot reach Ollama at {self.config.base_url}: {e}")
            raise ConnectionError(
                f"Cannot connect to Ollama at {self.config.base_url}. "
                "Ensure Ollama is running and accessible."
            )
        except Exception as e:
            self.logger.error(f"❌ Failed to initialize {self.config.role}: {e}")
            raise
    
    def invoke(
        self,
        prompt: str,
        max_tokens: Optional[int] = None,
        stop: Optional[list] = None
    ) -> Optional[str]:
        """
        Invoke LLM with retry logic
        
        Args:
            prompt: Input prompt
            max_tokens: Maximum tokens to generate
            stop: Stop sequences
            
        Returns:
            Generated text or None on failure
        """
        
        for attempt in range(self.config.max_retries):
            try:
                self.logger.debug(
                    f"[{self.config.role}] Attempt {attempt + 1}/{self.config.max_retries}"
                )
                
                # Invoke LLM
                kwargs = {}
                if max_tokens:
                    kwargs['max_tokens'] = max_tokens
                if stop:
                    kwargs['stop'] = stop
                
                response = self.llm.invoke(prompt, **kwargs)
                
                # Validate response
                if not response or len(response.strip()) == 0:
                    raise ValueError("Empty response from LLM")
                
                self.logger.debug(
                    f"[{self.config.role}] Success "
                    f"({len(response)} chars, {len(response.split())} words)"
                )
                
                return response
                
            except Exception as e:
                self.logger.warning(
                    f"[{self.config.role}] Attempt {attempt + 1} failed: {e}"
                )
                
                # If this was the last attempt, raise the error
                if attempt == self.config.max_retries - 1:
                    self.logger.error(
                        f"[{self.config.role}] All {self.config.max_retries} "
                        "attempts failed"
                    )
                    raise
                
                # Exponential backoff
                wait_time = 2 ** attempt
                self.logger.info(f"[{self.config.role}] Retrying in {wait_time}s...")
                time.sleep(wait_time)
        
        return None
    
    def is_healthy(self) -> bool:
        """Check if connection is still healthy"""
        try:
            response = requests.get(
                f"{self.config.base_url}/api/tags",
                timeout=5
            )
            return response.status_code == 200
        except:
            return False
    
    def get_model_info(self) -> dict:
        """Get information about the loaded model"""
        try:
            response = requests.get(
                f"{self.config.base_url}/api/show",
                json={"name": self.config.model},
                timeout=5
            )
            if response.status_code == 200:
                return response.json()
        except:
            pass
        return {}

class OllamaClientFactory:
    """Factory for creating Ollama clients"""
    
    @staticmethod
    def create_from_config(
        config: AgentConfig,
        logger: Optional[logging.Logger] = None
    ) -> OllamaClient:
        """Create client from agent config"""
        return OllamaClient(config, logger)
    
    @staticmethod
    def create_cluster_clients(
        cluster_config,
        logger: Optional[logging.Logger] = None
    ) -> dict:
        """Create all clients for a cluster"""
        return {
            'architect': OllamaClient(cluster_config.architect, logger),
            'coder': OllamaClient(cluster_config.coder, logger),
            'reviewer': OllamaClient(cluster_config.reviewer, logger),
        }
EOF

echo -e "  ${GREEN}✓${NC} ollama_client.py created"

# ============================================================================
# Summary
# ============================================================================
echo
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✨ Phase 4 Complete!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo
echo -e "${YELLOW}Created Clients:${NC}"
echo "  ✓ clients/ollama_client.py   (Ollama client with retry)"
echo
echo -e "${YELLOW}Next Steps:${NC}"
echo "  Run: ../setup-phase5-validators.sh"
echo
echo -e "${GREEN}Ready for Phase 5! 🚀${NC}"
echo
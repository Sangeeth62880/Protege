import httpx
import logging
import json
import asyncio
from typing import Dict, List, Any, Optional
from ..config import settings

logger = logging.getLogger(__name__)

class GroqServiceError(Exception):
    """Base exception for Groq service errors"""
    pass

class GroqRateLimitError(GroqServiceError):
    """Raised when API rate limit is exceeded"""
    pass

class GroqAPIError(GroqServiceError):
    """Raised when API returns an error"""
    pass

class GroqResponseParseError(GroqServiceError):
    """Raised when JSON parsing fails"""
    pass

class GroqService:
    """
    Service for interacting with Groq API (Llama 3)
    """
    
    BASE_URL = "https://api.groq.com/openai/v1/chat/completions"

    def __init__(self, api_key: str):
        self.api_key = api_key
        self.headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json"
        }

    async def chat_completion(
        self,
        messages: List[Dict[str, str]],
        model: str = "llama-3.3-70b-versatile",
        temperature: float = 0.7,
        max_tokens: int = 1024,
        json_response: bool = False
    ) -> str:
        """
        Send chat completion request to Groq API.
        
        Args:
            messages: List of message dicts (role, content)
            model: Model ID to use
            temperature: Sampling temperature
            max_tokens: Max tokens to generate
            json_response: Whether to force JSON format
            
        Returns:
            The content of the assistant's response.
            
        Raises:
            GroqRateLimitError: If rate limit exceeded after retries
            GroqAPIError: If API returns other error
        """
        payload = {
            "model": model,
            "messages": messages,
            "temperature": temperature,
            "max_tokens": max_tokens,
        }

        if json_response:
            payload["response_format"] = {"type": "json_object"}

        retry_count = 0
        max_retries = settings.GROQ_MAX_RETRIES

        while retry_count <= max_retries:
            try:
                async with httpx.AsyncClient(timeout=120.0) as client:
                    response = await client.post(
                        self.BASE_URL, 
                        headers=self.headers, 
                        json=payload
                    )
                    
                    if response.status_code == 200:
                        data = response.json()
                        return data["choices"][0]["message"]["content"]
                    
                    if response.status_code == 429:
                        logger.warning(f"Groq Rate Limit Exceeded. Retrying ({retry_count}/{max_retries})...")
                        retry_count += 1
                        if retry_count > max_retries:
                            raise GroqRateLimitError("Rate limit exceeded and retries exhausted.")
                        # Exponential backoff
                        await asyncio.sleep(2 ** retry_count)
                        continue
                        
                    # Other errors
                    error_msg = f"Groq API Error {response.status_code}: {response.text}"
                    logger.error(error_msg)
                    raise GroqAPIError(error_msg)

            except httpx.RequestError as e:
                logger.error(f"Groq Request Failed: {str(e)}")
                retry_count += 1
                if retry_count > max_retries:
                    raise GroqAPIError(f"Request failed: {str(e)}")
                await asyncio.sleep(1)

        raise GroqAPIError("Failed to complete request after retries")

    async def generate_with_system_prompt(
        self,
        system_prompt: str,
        user_message: str,
        model: str = "llama-3.3-70b-versatile",
        temperature: float = 0.7,
        max_tokens: int = 1024,
        json_response: bool = False
    ) -> str:
        """
        Convenience method for single-turn conversations with a system prompt.
        """
        messages = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_message}
        ]
        return await self.chat_completion(
            messages=messages,
            model=model,
            temperature=temperature,
            max_tokens=max_tokens,
            json_response=json_response
        )

    async def generate_response(
        self,
        prompt: str,
        system_prompt: str = "You are a helpful assistant.",
        temperature: float = 0.7
    ) -> str:
        """
        Alias for generate_with_system_prompt for compatibility.
        """
        return await self.generate_with_system_prompt(
            system_prompt=system_prompt,
            user_message=prompt,
            temperature=temperature
        )

    def parse_json_response(self, response: str) -> Dict[str, Any]:
        """
        Extract and parse JSON from response. 
        Handles markdown code blocks if present.
        """
        try:
            # Clean up markdown code blocks if present
            clean_response = response.strip()
            if clean_response.startswith("```"):
                # Find first newline
                first_newline = clean_response.find("\n")
                if first_newline != -1:
                    clean_response = clean_response[first_newline+1:]
                # Remove trailing ```
                if clean_response.endswith("```"):
                    clean_response = clean_response[:-3]
            
            clean_response = clean_response.strip()
            return json.loads(clean_response)
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse JSON response: {response[:100]}... Error: {str(e)}")
            raise GroqResponseParseError(f"Invalid JSON received: {str(e)}")

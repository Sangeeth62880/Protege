"""
Wikipedia REST API Service
Gets concept summaries and definitions.
NO API KEY REQUIRED - Completely free
"""
import httpx
from typing import Optional
import urllib.parse

class WikipediaService:
    """Service for getting Wikipedia summaries."""
    
    BASE_URL = "https://en.wikipedia.org/api/rest_v1"
    
    def __init__(self):
        """Initialize Wikipedia service (no authentication needed)."""
        print("[WIKIPEDIA] Service initialized (no auth required)")
    
    async def get_summary(self, topic: str) -> Optional[dict]:
        """
        Get Wikipedia summary for a topic.
        
        Args:
            topic: Topic to look up
            
        Returns:
            Summary dictionary or None if not found
        """
        print(f"[WIKIPEDIA] Getting summary for: {topic}")
        
        # Format topic for Wikipedia URL (replace spaces with underscores)
        formatted_topic = topic.strip().replace(" ", "_")
        # URL encode for special characters
        encoded_topic = urllib.parse.quote(formatted_topic)
        
        timeout = httpx.Timeout(30.0)
        headers = {
            "User-Agent": "Protege-Learning-App/1.0 (educational app; protege-admin@example.com)"
        }
        
        async with httpx.AsyncClient(timeout=timeout) as client:
            try:
                response = await client.get(
                    f"{self.BASE_URL}/page/summary/{encoded_topic}",
                    headers=headers,
                    follow_redirects=True
                )
                
                if response.status_code == 404:
                    print(f"[WIKIPEDIA] No article found for: {topic}")
                    # Try search as fallback
                    return await self._search_and_get_summary(client, topic, headers)
                
                if response.status_code != 200:
                    print(f"[WIKIPEDIA] API error: {response.status_code}")
                    return None
                
                data = response.json()
                
                # Check if we got an actual article (not disambiguation)
                if data.get("type") == "disambiguation":
                    print("[WIKIPEDIA] Got disambiguation page, trying first link")
                    return None
                
                summary = {
                    "type": "wikipedia",
                    "source": "wikipedia",
                    "title": data.get("title", topic),
                    "extract": data.get("extract", ""),
                    "extract_html": data.get("extract_html", ""),
                    "url": data.get("content_urls", {}).get("desktop", {}).get("page", ""),
                    "thumbnail": data.get("thumbnail", {}).get("source", ""),
                    "description": data.get("description", ""),
                    "page_id": data.get("pageid")
                }
                
                print(f"[WIKIPEDIA] Got summary ({len(summary['extract'])} chars)")
                return summary
                
            except httpx.TimeoutException:
                print("[WIKIPEDIA] Request timed out")
                return None
            except Exception as e:
                print(f"[WIKIPEDIA] Error: {e}")
                return None
    
    async def _search_and_get_summary(
        self, 
        client: httpx.AsyncClient, 
        query: str,
        headers: dict
    ) -> Optional[dict]:
        """
        Search Wikipedia and get summary of first result.
        Fallback when direct lookup fails.
        """
        try:
            # Use Wikipedia's search API
            search_url = "https://en.wikipedia.org/w/api.php"
            params = {
                "action": "query",
                "list": "search",
                "srsearch": query,
                "format": "json",
                "srlimit": 1
            }
            
            response = await client.get(search_url, params=params, headers=headers)
            
            if response.status_code != 200:
                return None
            
            data = response.json()
            results = data.get("query", {}).get("search", [])
            
            if not results:
                return None
            
            # Get the title of first result and fetch its summary
            first_title = results[0].get("title", "")
            print(f"[WIKIPEDIA] Found via search: {first_title}")
            
            # Recursive call with the found title
            formatted_title = first_title.replace(" ", "_")
            encoded_title = urllib.parse.quote(formatted_title)
            
            response = await client.get(
                f"{self.BASE_URL}/page/summary/{encoded_title}",
                headers=headers,
                follow_redirects=True
            )
            
            if response.status_code == 200:
                data = response.json()
                return {
                    "type": "wikipedia",
                    "source": "wikipedia",
                    "title": data.get("title", first_title),
                    "extract": data.get("extract", ""),
                    "extract_html": data.get("extract_html", ""),
                    "url": data.get("content_urls", {}).get("desktop", {}).get("page", ""),
                    "thumbnail": data.get("thumbnail", {}).get("source", ""),
                    "description": data.get("description", ""),
                }
            
            return None
            
        except Exception as e:
            print(f"[WIKIPEDIA] Search fallback failed: {e}")
            return None

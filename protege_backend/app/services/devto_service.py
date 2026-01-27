"""
Dev.to API Service
Searches for developer articles and tutorials.
NO API KEY REQUIRED - Completely free
"""
import httpx
from typing import Optional

class DevToService:
    """Service for searching Dev.to articles."""
    
    BASE_URL = "https://dev.to/api"
    
    def __init__(self):
        """Initialize Dev.to service (no authentication needed)."""
        print("[DEVTO] Service initialized (no auth required)")
    
    async def search_articles(
        self,
        query: str,
        max_results: int = 5
    ) -> list[dict]:
        """
        Search for articles on Dev.to.
        
        Dev.to doesn't have a direct search API, so we:
        1. Try tag-based search
        2. Fall back to getting popular articles
        
        Args:
            query: Search query (will extract keywords for tags)
            max_results: Maximum number of results
            
        Returns:
            List of article dictionaries
        """
        print(f"[DEVTO] Searching: {query}")
        
        # Extract main keywords for tag search
        keywords = query.lower().replace("-", " ").replace("_", " ").split()
        # Common programming tags
        common_tags = ["python", "javascript", "react", "node", "web", "css", 
                       "html", "java", "programming", "tutorial", "beginners",
                       "typescript", "rust", "go", "flutter", "dart", "api"]
        
        # Find matching tag
        tag = None
        for keyword in keywords:
            if keyword in common_tags:
                tag = keyword
                break
        
        if not tag and keywords:
            tag = keywords[0]  # Use first keyword as fallback
        
        timeout = httpx.Timeout(30.0)
        
        async with httpx.AsyncClient(timeout=timeout) as client:
            try:
                # Try tag-based search
                params = {
                    "per_page": max_results + 5,
                    "top": 30  # Top articles from last 30 days
                }
                
                if tag:
                    params["tag"] = tag
                
                response = await client.get(
                    f"{self.BASE_URL}/articles",
                    params=params
                )
                
                if response.status_code != 200:
                    print(f"[DEVTO] API error: {response.status_code}")
                    return []
                
                data = response.json()
                articles = []
                
                for item in data[:max_results]:
                    article = {
                        "type": "article",
                        "source": "devto",
                        "source_name": "Dev.to",
                        "source_domain": "dev.to",
                        "title": item.get("title", ""),
                        "url": item.get("url", ""),
                        "description": item.get("description", "")[:200] if item.get("description") else "",
                        "author": item.get("user", {}).get("name", "Unknown"),
                        "author_username": item.get("user", {}).get("username", ""),
                        "author_avatar": item.get("user", {}).get("profile_image_90", ""),
                        "published_at": item.get("published_at", ""),
                        "read_time_minutes": item.get("reading_time_minutes", 5),
                        "reactions": item.get("positive_reactions_count", 0),
                        "comments": item.get("comments_count", 0),
                        "tags": item.get("tag_list", []),
                        "cover_image": item.get("cover_image") or item.get("social_image", ""),
                    }
                    articles.append(article)
                
                print(f"[DEVTO] Found {len(articles)} articles")
                return articles
                
            except httpx.TimeoutException:
                print("[DEVTO] Request timed out")
                return []
            except Exception as e:
                print(f"[DEVTO] Error: {e}")
                return []
    
    async def get_article_by_id(self, article_id: int) -> Optional[dict]:
        """Get a specific article by ID."""
        timeout = httpx.Timeout(30.0)
        
        async with httpx.AsyncClient(timeout=timeout) as client:
            try:
                response = await client.get(f"{self.BASE_URL}/articles/{article_id}")
                if response.status_code == 200:
                    return response.json()
                return None
            except:
                return None

"""
Google Custom Search API Service
Searches for educational articles and documentation.
"""
import httpx
from typing import Optional

class GoogleSearchService:
    """Service for searching web articles using Google Custom Search."""
    
    BASE_URL = "https://www.googleapis.com/customsearch/v1"
    
    # Trusted educational domains for bonus scoring
    TRUSTED_DOMAINS = [
        "medium.com", "dev.to", "freecodecamp.org", "realpython.com",
        "geeksforgeeks.org", "w3schools.com", "tutorialspoint.com",
        "mozilla.org", "docs.python.org", "javascript.info",
        "css-tricks.com", "smashingmagazine.com", "digitalocean.com"
    ]
    
    def __init__(self, api_key: str, search_engine_id: str, cache_service=None):
        """
        Initialize Google Search service.
        
        Args:
            api_key: Google API key
            search_engine_id: Custom Search Engine ID (cx)
            cache_service: Optional cache service
        """
        if not api_key:
            raise ValueError("Google API key is required")
        if not search_engine_id:
            raise ValueError("Search Engine ID is required")
            
        self.api_key = api_key
        self.cx = search_engine_id
        self.cache = cache_service
        print(f"[GOOGLE_SEARCH] Service initialized")
    
    async def search_articles(
        self,
        query: str,
        num_results: int = 5,
        date_restrict: str = "y2"  # Last 2 years
    ) -> list[dict]:
        """
        Search for articles matching the query.
        
        Args:
            query: Search query
            num_results: Number of results (1-10)
            date_restrict: Date restriction (d=day, w=week, m=month, y=year)
            
        Returns:
            List of article objects
        """
        print(f"[GOOGLE_SEARCH] Searching for: {query}")
        
        # Add "tutorial" or "guide" to improve educational results
        enhanced_query = f"{query} tutorial OR guide OR explained"
        
        params = {
            "key": self.api_key,
            "cx": self.cx,
            "q": enhanced_query,
            "num": min(num_results, 10),
            "dateRestrict": date_restrict,
            "lr": "lang_en",
            "safe": "active"
        }
        
        timeout = httpx.Timeout(30.0)
        
        async with httpx.AsyncClient(timeout=timeout) as client:
            try:
                response = await client.get(self.BASE_URL, params=params)
                
                if response.status_code != 200:
                    print(f"[GOOGLE_SEARCH] API error: {response.status_code} - {response.text}")
                    return []
                
                data = response.json()
                articles = []
                
                for item in data.get("items", []):
                    # Extract domain from URL
                    url = item.get("link", "")
                    domain = self._extract_domain(url)
                    
                    # Estimate read time based on snippet length
                    snippet = item.get("snippet", "")
                    read_time = self._estimate_read_time(snippet)
                    
                    article = {
                        "title": item.get("title", ""),
                        "url": url,
                        "description": snippet,
                        "source_domain": domain,
                        "source_name": item.get("displayLink", domain),
                        "read_time_minutes": read_time,
                        "is_trusted_source": domain in self.TRUSTED_DOMAINS,
                        "type": "article"
                    }
                    articles.append(article)
                
                print(f"[GOOGLE_SEARCH] Found {len(articles)} articles")
                return articles
                
            except httpx.TimeoutException:
                print("[GOOGLE_SEARCH] Request timed out")
                return []
            except Exception as e:
                print(f"[GOOGLE_SEARCH] Error: {e}")
                return []
    
    def _extract_domain(self, url: str) -> str:
        """Extract domain from URL."""
        try:
            from urllib.parse import urlparse
            parsed = urlparse(url)
            domain = parsed.netloc.lower()
            if domain.startswith("www."):
                domain = domain[4:]
            return domain
        except:
            return "unknown"
    
    def _estimate_read_time(self, text: str) -> int:
        """Estimate read time in minutes based on text length."""
        # Rough estimate: 200 words per minute, average 5 chars per word
        words = len(text) / 5
        minutes = max(3, int(words / 200) * 5)  # At least 3 minutes, round to 5
        return min(30, minutes)  # Cap at 30 minutes

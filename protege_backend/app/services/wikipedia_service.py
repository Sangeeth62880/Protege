"""
Wikipedia REST API Service - Enhanced Version
Uses multiple search strategies and validates results.
"""
import httpx
import urllib.parse
from typing import Optional, List

class WikipediaService:
    """Enhanced Wikipedia service with better accuracy."""
    
    BASE_URL = "https://en.wikipedia.org/api/rest_v1"
    SEARCH_API = "https://en.wikipedia.org/w/api.php"
    
    def __init__(self):
        self.headers = {
            "User-Agent": "Protege-Learning-App/1.0 (Educational App; Contact: support@protege.app)"
        }
        print("[WIKIPEDIA] Enhanced service initialized")
    
    async def get_summary(
        self,
        topic: str,
        fallback_term: str = None,
        key_terms: List[str] = None
    ) -> Optional[dict]:
        """
        Get Wikipedia summary with multiple fallback strategies.
        
        Args:
            topic: Primary search term
            fallback_term: Alternative term if primary fails
            key_terms: Additional terms to try
            
        Returns:
            Summary dict or None
        """
        print(f"[WIKIPEDIA] Searching for: {topic}")
        
        # Strategy 1: Direct article lookup
        result = await self._get_article_summary(topic)
        if result and self._is_valid_result(result, topic):
            print(f"[WIKIPEDIA] ✓ Found via direct lookup: {result.get('title')}")
            return result
        
        # Strategy 2: Search API
        result = await self._search_and_get_best_match(topic)
        if result and self._is_valid_result(result, topic):
            print(f"[WIKIPEDIA] ✓ Found via search: {result.get('title')}")
            return result
        
        # Strategy 3: Try fallback term
        if fallback_term and fallback_term != topic:
            print(f"[WIKIPEDIA] Trying fallback: {fallback_term}")
            result = await self._search_and_get_best_match(fallback_term)
            if result and self._is_valid_result(result, fallback_term):
                print(f"[WIKIPEDIA] ✓ Found via fallback: {result.get('title')}")
                return result
        
        # Strategy 4: Try key terms
        if key_terms:
            for term in key_terms[:3]:
                print(f"[WIKIPEDIA] Trying key term: {term}")
                result = await self._search_and_get_best_match(term)
                if result and self._is_valid_result(result, term):
                    print(f"[WIKIPEDIA] ✓ Found via key term: {result.get('title')}")
                    return result
        
        print(f"[WIKIPEDIA] ✗ No valid result found for: {topic}")
        return None
    
    async def _get_article_summary(self, title: str) -> Optional[dict]:
        """
        Get article summary by exact title.
        """
        formatted_title = title.strip().replace(" ", "_")
        encoded_title = urllib.parse.quote(formatted_title)
        
        timeout = httpx.Timeout(15.0)
        
        async with httpx.AsyncClient(timeout=timeout) as client:
            try:
                response = await client.get(
                    f"{self.BASE_URL}/page/summary/{encoded_title}",
                    headers=self.headers,
                    follow_redirects=True
                )
                
                if response.status_code == 404:
                    return None
                
                if response.status_code != 200:
                    return None
                
                data = response.json()
                
                # Check for disambiguation page
                if data.get("type") == "disambiguation":
                    print(f"[WIKIPEDIA] Got disambiguation page for: {title}")
                    return None
                
                return self._format_result(data)
                
            except Exception as e:
                print(f"[WIKIPEDIA] Direct lookup error: {e}")
                return None
    
    async def _search_and_get_best_match(self, query: str) -> Optional[dict]:
        """
        Search Wikipedia and get the best matching article.
        """
        timeout = httpx.Timeout(15.0)
        
        async with httpx.AsyncClient(timeout=timeout) as client:
            try:
                # Use Wikipedia's search API
                params = {
                    "action": "query",
                    "list": "search",
                    "srsearch": query,
                    "format": "json",
                    "srlimit": 5,  # Get top 5 results
                    "srprop": "snippet|titlesnippet"
                }
                
                response = await client.get(
                    self.SEARCH_API,
                    params=params,
                    headers=self.headers
                )
                
                if response.status_code != 200:
                    return None
                
                data = response.json()
                results = data.get("query", {}).get("search", [])
                
                if not results:
                    return None
                
                # Find best match by scoring relevance
                best_match = self._find_best_match(results, query)
                
                if best_match:
                    # Get full summary for best match
                    return await self._get_article_summary(best_match["title"])
                
                return None
                
            except Exception as e:
                print(f"[WIKIPEDIA] Search error: {e}")
                return None
    
    def _find_best_match(self, results: list, query: str) -> Optional[dict]:
        """
        Find the best matching result from search results.
        """
        query_lower = query.lower()
        query_words = set(query_lower.split())
        
        scored_results = []
        
        for result in results:
            title = result.get("title", "")
            title_lower = title.lower()
            
            score = 0
            
            # Exact title match
            if title_lower == query_lower:
                score += 100
            
            # Title contains query
            if query_lower in title_lower:
                score += 50
            
            # Word overlap
            title_words = set(title_lower.split())
            overlap = len(query_words & title_words)
            score += overlap * 10
            
            # Penalize very long titles (often too specific)
            if len(title) > 50:
                score -= 10
            
            # Penalize disambiguation indicators
            if "(" in title and ")" in title:
                # But boost if it's a technical term with context
                if any(tech in title.lower() for tech in ["programming", "computer", "software"]):
                    score += 5
                else:
                    score -= 5
            
            scored_results.append((result, score))
        
        # Sort by score descending
        scored_results.sort(key=lambda x: x[1], reverse=True)
        
        if scored_results and scored_results[0][1] > 0:
            return scored_results[0][0]
        
        # Default to first result if no good match
        return results[0] if results else None
    
    def _is_valid_result(self, result: dict, query: str) -> bool:
        """
        Validate that the result is relevant to the query.
        """
        if not result:
            return False
        
        extract = result.get("extract", "")
        title = result.get("title", "")
        
        # Must have meaningful content
        if len(extract) < 50:
            return False
        
        # Check for relevance
        query_words = query.lower().split()
        content_lower = (title + " " + extract).lower()
        
        # At least one query word should appear
        matches = sum(1 for word in query_words if word in content_lower)
        
        return matches >= 1
    
    def _format_result(self, data: dict) -> dict:
        """
        Format API response into consistent structure.
        """
        return {
            "type": "wikipedia",
            "source": "wikipedia",
            "title": data.get("title", ""),
            "extract": data.get("extract", ""),
            "extract_html": data.get("extract_html", ""),
            "url": data.get("content_urls", {}).get("desktop", {}).get("page", ""),
            "thumbnail": data.get("thumbnail", {}).get("source", ""),
            "description": data.get("description", ""),
            "page_id": data.get("pageid"),
        }

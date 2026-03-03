"""
MDN Web Docs Service - Documentation Search
Uses MDN's free search API (no key needed).
Only activated for web development topics.
"""
import httpx
from typing import List

# Web-related keywords that trigger MDN search
WEB_KEYWORDS = frozenset({
    "html", "css", "javascript", "js", "typescript", "ts", "web",
    "dom", "api", "fetch", "async", "promise", "flexbox", "grid",
    "responsive", "react", "vue", "angular", "svelte", "node",
    "browser", "http", "https", "rest", "graphql", "webpack",
    "sass", "scss", "tailwind", "bootstrap", "canvas", "svg",
    "animation", "accessibility", "aria", "semantic",
})


class MDNService:
    """Search MDN Web Docs for web development documentation."""
    
    BASE_URL = "https://developer.mozilla.org/api/v1/search"
    
    def __init__(self):
        print("[MDN] Service initialized (no auth required)")
    
    def is_web_topic(self, topic: str, lesson_title: str = "") -> bool:
        """Check if the topic is web-related (MDN would be useful)."""
        combined = f"{topic} {lesson_title}".lower()
        return any(kw in combined for kw in WEB_KEYWORDS)
    
    async def search_docs(
        self,
        query: str,
        max_results: int = 3,
        locale: str = "en-US",
    ) -> List[dict]:
        """
        Search MDN Web Docs.
        
        Args:
            query: Search query
            max_results: Maximum results
            locale: Language locale
            
        Returns:
            List of documentation links
        """
        print(f"[MDN] Searching: {query}")
        
        timeout = httpx.Timeout(15.0)
        
        async with httpx.AsyncClient(timeout=timeout) as client:
            try:
                params = {
                    "q": query,
                    "size": max_results + 3,
                    "locale": locale,
                }
                
                response = await client.get(self.BASE_URL, params=params)
                
                if response.status_code != 200:
                    print(f"[MDN] API error: {response.status_code}")
                    return []
                
                data = response.json()
                documents = data.get("documents", [])
                
                docs = []
                for doc in documents[:max_results]:
                    title = doc.get("title", "")
                    slug = doc.get("slug", "")
                    
                    docs.append({
                        "type": "documentation",
                        "source": "mdn",
                        "source_name": "MDN Web Docs",
                        "title": title,
                        "url": f"https://developer.mozilla.org/{locale}/docs/{slug}" if slug else "",
                        "description": (doc.get("summary") or "")[:200],
                        "highlight": (doc.get("highlight", {}).get("body") or [""])[0][:150],
                        "relevance_score": doc.get("score", 0),
                    })
                
                print(f"[MDN] Found {len(docs)} docs")
                return docs
                
            except Exception as e:
                print(f"[MDN] Error: {e}")
                return []

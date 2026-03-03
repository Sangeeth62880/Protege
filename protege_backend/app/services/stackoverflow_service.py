"""
Stack Overflow Service - Q&A Search
Uses the free Stack Exchange API (no key required for basic use).
Returns relevant Q&A with accepted answers.
"""
import httpx
from typing import List

class StackOverflowService:
    """Search Stack Overflow for relevant Q&A."""
    
    BASE_URL = "https://api.stackexchange.com/2.3"
    
    def __init__(self):
        print("[STACKOVERFLOW] Service initialized (no auth required)")
    
    async def search_questions(
        self,
        query: str,
        max_results: int = 3,
        sort: str = "relevance",  # relevance, votes, creation
    ) -> List[dict]:
        """
        Search Stack Overflow for questions with accepted answers.
        
        Args:
            query: Search query
            max_results: Maximum results
            sort: Sort method
            
        Returns:
            List of Q&A dicts
        """
        print(f"[STACKOVERFLOW] Searching: {query}")
        
        timeout = httpx.Timeout(20.0)
        
        async with httpx.AsyncClient(timeout=timeout) as client:
            try:
                params = {
                    "order": "desc",
                    "sort": sort,
                    "q": query,
                    "site": "stackoverflow",
                    "filter": "!nNPvSNdWme",  # Include answer_count, score, tags
                    "pagesize": max_results + 5,
                    "accepted": "True",  # Only questions with accepted answers
                }
                
                response = await client.get(
                    f"{self.BASE_URL}/search/advanced", params=params
                )
                
                if response.status_code != 200:
                    print(f"[STACKOVERFLOW] API error: {response.status_code}")
                    return []
                
                data = response.json()
                items = data.get("items", [])
                
                questions = []
                for item in items:
                    title = item.get("title", "")
                    if not title:
                        continue
                    
                    question = {
                        "type": "qa",
                        "source": "stackoverflow",
                        "source_name": "Stack Overflow",
                        "title": title,
                        "url": item.get("link", ""),
                        "description": f"Score: {item.get('score', 0)} | Answers: {item.get('answer_count', 0)}",
                        "score": item.get("score", 0),
                        "answer_count": item.get("answer_count", 0),
                        "view_count": item.get("view_count", 0),
                        "tags": item.get("tags", []),
                        "is_answered": item.get("is_answered", False),
                        "creation_date": item.get("creation_date", 0),
                        "relevance_score": self._calc_score(item, query),
                    }
                    questions.append(question)
                
                # Sort by relevance and limit
                questions.sort(key=lambda x: x["relevance_score"], reverse=True)
                result = questions[:max_results]
                
                print(f"[STACKOVERFLOW] Found {len(result)} questions")
                return result
                
            except Exception as e:
                print(f"[STACKOVERFLOW] Error: {e}")
                return []
    
    def _calc_score(self, item: dict, query: str) -> float:
        """Score based on votes + answer quality + title relevance."""
        score = 0.0
        
        # Vote score
        votes = item.get("score", 0)
        if votes > 100:
            score += 20
        elif votes > 50:
            score += 15
        elif votes > 10:
            score += 10
        elif votes > 0:
            score += 5
        
        # Has accepted answer
        if item.get("is_answered"):
            score += 15
        
        # Title keyword match
        title = item.get("title", "").lower()
        keywords = query.lower().split()
        for kw in keywords:
            if len(kw) > 2 and kw in title:
                score += 20
        
        # View count (popularity)
        views = item.get("view_count", 0)
        if views > 50000:
            score += 10
        elif views > 10000:
            score += 5
        
        return score

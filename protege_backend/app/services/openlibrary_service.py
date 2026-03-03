"""
Open Library Service - Book Search
Uses the free Open Library Search API (no key required).
Returns relevant textbooks and learning materials.
"""
import httpx
from typing import List

class OpenLibraryService:
    """Search Open Library for relevant books and textbooks."""
    
    BASE_URL = "https://openlibrary.org"
    
    def __init__(self):
        print("[OPENLIBRARY] Service initialized (no auth required)")
    
    async def search_books(
        self,
        query: str,
        max_results: int = 3,
    ) -> List[dict]:
        """
        Search Open Library for relevant books.
        
        Args:
            query: Search query (e.g., "gradient descent machine learning")
            max_results: Maximum results to return
            
        Returns:
            List of book dicts with title, author, year, cover, and URL
        """
        print(f"[OPENLIBRARY] Searching: {query}")
        
        timeout = httpx.Timeout(20.0)
        
        async with httpx.AsyncClient(timeout=timeout) as client:
            try:
                params = {
                    "q": query,
                    "limit": max_results + 5,
                    "fields": "key,title,author_name,first_publish_year,cover_i,subject,edition_count,ratings_average",
                    "sort": "rating",
                }
                
                response = await client.get(
                    f"{self.BASE_URL}/search.json", params=params
                )
                
                if response.status_code != 200:
                    print(f"[OPENLIBRARY] API error: {response.status_code}")
                    return []
                
                data = response.json()
                docs = data.get("docs", [])
                
                books = []
                for doc in docs:
                    # Skip books without basic info
                    title = doc.get("title", "")
                    if not title:
                        continue
                    
                    authors = doc.get("author_name", [])
                    year = doc.get("first_publish_year")
                    cover_id = doc.get("cover_i")
                    key = doc.get("key", "")
                    
                    book = {
                        "type": "book",
                        "source": "openlibrary",
                        "source_name": "Open Library",
                        "title": title,
                        "author": ", ".join(authors[:2]) if authors else "Unknown",
                        "year": year,
                        "url": f"https://openlibrary.org{key}" if key else "",
                        "cover_image": f"https://covers.openlibrary.org/b/id/{cover_id}-M.jpg" if cover_id else "",
                        "edition_count": doc.get("edition_count", 0),
                        "rating": doc.get("ratings_average", 0),
                        "subjects": (doc.get("subject") or [])[:5],
                        "relevance_score": self._calc_score(doc, query),
                    }
                    books.append(book)
                
                # Sort by relevance and limit
                books.sort(key=lambda x: x["relevance_score"], reverse=True)
                result = books[:max_results]
                
                print(f"[OPENLIBRARY] Found {len(result)} books")
                return result
                
            except Exception as e:
                print(f"[OPENLIBRARY] Error: {e}")
                return []
    
    def _calc_score(self, doc: dict, query: str) -> float:
        """Simple relevance score based on title match + popularity."""
        score = 0.0
        title = doc.get("title", "").lower()
        keywords = query.lower().split()
        
        for kw in keywords:
            if len(kw) > 2 and kw in title:
                score += 25
        
        # Popularity signals
        editions = doc.get("edition_count", 0)
        if editions > 20:
            score += 15
        elif editions > 5:
            score += 8
        
        rating = doc.get("ratings_average", 0)
        if rating >= 4.0:
            score += 10
        elif rating >= 3.0:
            score += 5
        
        return score

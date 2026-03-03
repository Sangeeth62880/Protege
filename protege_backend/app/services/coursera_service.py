"""
Coursera Service - Course Search
Uses Coursera's public catalog search (no API key needed).
"""
import httpx
from typing import List

class CourseraService:
    """Search Coursera's public catalog for relevant courses."""
    
    # Coursera's public search endpoint
    SEARCH_URL = "https://www.coursera.org/api/catalogResults.v2"
    
    def __init__(self):
        print("[COURSERA] Service initialized (no auth required)")
    
    async def search_courses(
        self,
        query: str,
        max_results: int = 3,
    ) -> List[dict]:
        """
        Search Coursera for relevant courses.
        
        Args:
            query: Search query
            max_results: Maximum results
            
        Returns:
            List of course dicts
        """
        print(f"[COURSERA] Searching: {query}")
        
        timeout = httpx.Timeout(20.0)
        
        async with httpx.AsyncClient(timeout=timeout) as client:
            try:
                params = {
                    "q": "search",
                    "query": query,
                    "limit": max_results + 3,
                    "includes": "courses",
                    "fields": "name,slug,description,photoUrl,partnerIds,workload",
                }
                
                headers = {
                    "User-Agent": "Mozilla/5.0 (compatible; ProtegeBot/1.0)",
                    "Accept": "application/json",
                }
                
                response = await client.get(
                    self.SEARCH_URL, params=params, headers=headers
                )
                
                if response.status_code != 200:
                    print(f"[COURSERA] API error: {response.status_code}")
                    # Fall back to constructing search URLs
                    return self._construct_search_results(query, max_results)
                
                data = response.json()
                
                # Parse the linked courses
                courses_data = data.get("linked", {}).get("courses.v1", [])
                
                if not courses_data:
                    print("[COURSERA] No courses from API, using search URL fallback")
                    return self._construct_search_results(query, max_results)
                
                courses = []
                for course in courses_data[:max_results]:
                    name = course.get("name", "")
                    slug = course.get("slug", "")
                    
                    courses.append({
                        "type": "course",
                        "source": "coursera",
                        "source_name": "Coursera",
                        "title": name,
                        "url": f"https://www.coursera.org/learn/{slug}" if slug else "",
                        "description": (course.get("description") or "")[:200],
                        "cover_image": course.get("photoUrl", ""),
                        "workload": course.get("workload", ""),
                        "relevance_score": 70,  # Default — will be scored by AI later
                    })
                
                print(f"[COURSERA] Found {len(courses)} courses")
                return courses
                
            except Exception as e:
                print(f"[COURSERA] Error: {e}")
                return self._construct_search_results(query, max_results)
    
    def _construct_search_results(self, query: str, max_results: int) -> List[dict]:
        """Fallback: return a Coursera search URL for the user."""
        search_url = f"https://www.coursera.org/search?query={query.replace(' ', '%20')}"
        return [{
            "type": "course",
            "source": "coursera",
            "source_name": "Coursera",
            "title": f"Search Coursera for: {query}",
            "url": search_url,
            "description": f"Browse Coursera courses related to {query}",
            "cover_image": "",
            "workload": "",
            "relevance_score": 50,
        }]

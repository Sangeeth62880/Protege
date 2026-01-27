"""
GitHub API Service
Searches for educational repositories and code examples.
NO API KEY REQUIRED (but token increases rate limit)
"""
import httpx
from typing import Optional

class GitHubService:
    """Service for searching GitHub repositories."""
    
    BASE_URL = "https://api.github.com"
    
    def __init__(self, token: Optional[str] = None):
        """
        Initialize GitHub service.
        
        Args:
            token: Optional GitHub personal access token
        """
        self.token = token
        self.headers = {
            "Accept": "application/vnd.github.v3+json",
            "User-Agent": "Protege-Learning-App/1.0"
        }
        if token:
            self.headers["Authorization"] = f"token {token}"
        
        auth_status = "authenticated" if token else "unauthenticated (60 req/hr limit)"
        print(f"[GITHUB] Service initialized ({auth_status})")
    
    async def search_repositories(
        self,
        query: str,
        max_results: int = 5,
        sort: str = "stars",
        min_stars: int = 5
    ) -> list[dict]:
        """
        Search for repositories matching the query.
        
        Args:
            query: Search query
            max_results: Maximum number of results
            sort: Sort by (stars, forks, updated)
            min_stars: Minimum star count filter
            
        Returns:
            List of repository dictionaries
        """
        print(f"[GITHUB] Searching: {query}")
        
        # Enhance query for educational/tutorial content
        enhanced_query = f"{query} in:name,description,readme stars:>={min_stars}"
        
        params = {
            "q": enhanced_query,
            "sort": sort,
            "order": "desc",
            "per_page": min(max_results + 5, 30)  # Get extra for filtering
        }
        
        timeout = httpx.Timeout(30.0)
        
        async with httpx.AsyncClient(timeout=timeout) as client:
            try:
                response = await client.get(
                    f"{self.BASE_URL}/search/repositories",
                    params=params,
                    headers=self.headers
                )
                
                if response.status_code == 403:
                    print("[GITHUB] Rate limit exceeded")
                    return []
                
                if response.status_code != 200:
                    print(f"[GITHUB] API error: {response.status_code}")
                    return []
                
                data = response.json()
                repos = []
                
                for item in data.get("items", [])[:max_results]:
                    # Skip if no description (usually not educational)
                    description = item.get("description") or ""
                    
                    repo = {
                        "type": "github",
                        "name": item.get("name", ""),
                        "full_name": item.get("full_name", ""),
                        "url": item.get("html_url", ""),
                        "description": description[:200],
                        "stars": item.get("stargazers_count", 0),
                        "forks": item.get("forks_count", 0),
                        "language": item.get("language") or "Unknown",
                        "topics": item.get("topics", [])[:5],
                        "updated_at": item.get("updated_at", ""),
                        "owner_name": item.get("owner", {}).get("login", ""),
                        "owner_avatar": item.get("owner", {}).get("avatar_url", ""),
                        "source": "github"
                    }
                    repos.append(repo)
                
                print(f"[GITHUB] Found {len(repos)} repositories")
                return repos
                
            except httpx.TimeoutException:
                print("[GITHUB] Request timed out")
                return []
            except Exception as e:
                print(f"[GITHUB] Error: {e}")
                return []

"""
GitHub API Service - Enhanced Version
Supports filtering by stars, trending, topics, and relevance.
"""
import httpx
import math
from typing import Optional, Literal, List
from datetime import datetime, timedelta

class GitHubService:
    """Enhanced GitHub service with filtering and better accuracy."""
    
    BASE_URL = "https://api.github.com"
    
    # Educational indicators in repo names/descriptions
    EDUCATIONAL_KEYWORDS = [
        "tutorial", "learn", "course", "example", "guide", "starter",
        "beginner", "introduction", "demo", "practice", "exercises",
        "workshop", "bootcamp", "fundamentals", "basics", "101"
    ]
    
    # Keywords that indicate low educational value
    EXCLUDE_KEYWORDS = [
        "awesome-list", "awesome list", "curated list", "collection of",
        "deprecated", "archived", "unmaintained", "old", "legacy"
    ]
    
    def __init__(self, token: Optional[str] = None):
        self.token = token
        self.headers = {
            "Accept": "application/vnd.github.v3+json",
            "User-Agent": "Protege-Learning-App/1.0"
        }
        if token:
            self.headers["Authorization"] = f"token {token}"
        
        auth_status = "authenticated" if token else "unauthenticated (60 req/hr)"
        print(f"[GITHUB] Enhanced service initialized ({auth_status})")
    
    async def search_repositories(
        self,
        query: str,
        topics: List[str] = None,
        max_results: int = 5,
        sort: Literal["stars", "forks", "updated", "relevance"] = "stars",
        min_stars: int = 10,
        max_stars: int = None,
        language: str = None,
        created_after_days: int = 365 * 2,  # Last 2 years
        include_forks: bool = False,
        educational_only: bool = True
    ) -> List[dict]:
        """
        Search for repositories with advanced filtering.
        
        Args:
            query: Search query
            topics: List of topics to filter by
            max_results: Maximum results to return
            sort: Sort order (stars, forks, updated, relevance)
            min_stars: Minimum star count
            max_stars: Maximum star count (for finding hidden gems)
            language: Filter by programming language
            created_after_days: Only repos created within this many days
            include_forks: Include forked repositories
            educational_only: Boost educational repos
            
        Returns:
            List of repository dictionaries with relevance scores
        """
        print(f"[GITHUB] Searching: {query}")
        print(f"[GITHUB] Filters: stars>={min_stars}, sort={sort}, educational={educational_only}")
        
        # Build enhanced query
        enhanced_query = self._build_query(
            query=query,
            topics=topics,
            min_stars=min_stars,
            max_stars=max_stars,
            language=language,
            created_after_days=created_after_days,
            include_forks=include_forks
        )
        
        print(f"[GITHUB] Enhanced query: {enhanced_query}")
        
        params = {
            "q": enhanced_query,
            "order": "desc",
            "per_page": min(max_results * 3, 30)  # Get extra for filtering
        }
        
        # Add sort if not relevance
        if sort != "relevance":
            params["sort"] = sort
        
        timeout = httpx.Timeout(30.0)
        
        async with httpx.AsyncClient(timeout=timeout) as client:
            try:
                response = await client.get(
                    f"{self.BASE_URL}/search/repositories",
                    params=params,
                    headers=self.headers
                )
                
                # Check rate limit
                remaining = response.headers.get("X-RateLimit-Remaining", "?")
                print(f"[GITHUB] Rate limit remaining: {remaining}")
                
                if response.status_code == 403:
                    print("[GITHUB] Rate limit exceeded")
                    return []
                
                if response.status_code != 200:
                    print(f"[GITHUB] API error: {response.status_code}")
                    return []
                
                data = response.json()
                items = data.get("items", [])
                
                print(f"[GITHUB] Found {len(items)} raw results")
                
                # Score and filter results
                scored_repos = []
                for item in items:
                    repo = self._parse_repo(item)
                    
                    # Skip excluded repos
                    if self._should_exclude(repo):
                        continue
                    
                    # Calculate relevance score
                    repo["relevance_score"] = self._calculate_relevance(
                        repo, query, educational_only
                    )
                    
                    scored_repos.append(repo)
                
                # Sort by relevance score
                scored_repos.sort(key=lambda x: x["relevance_score"], reverse=True)
                
                # Return top results
                result = scored_repos[:max_results]
                print(f"[GITHUB] Returning {len(result)} filtered results")
                
                return result
                
            except httpx.TimeoutException:
                print("[GITHUB] Request timed out")
                return []
            except Exception as e:
                print(f"[GITHUB] Error: {e}")
                return []
    
    async def search_by_category(
        self,
        query: str,
        category: Literal["trending", "most_starred", "recently_updated", "beginner_friendly"],
        language: str = None,
        max_results: int = 5
    ) -> List[dict]:
        """
        Search repositories by predefined categories.
        
        Args:
            query: Base search query
            category: Category filter
            language: Programming language
            max_results: Maximum results
            
        Returns:
            List of repositories matching the category
        """
        print(f"[GITHUB] Category search: {category}")
        
        if category == "trending":
            # Repos created in last 60 days with growing stars
            results = await self.search_repositories(
                query=query,
                max_results=max_results,
                sort="stars",
                min_stars=20,
                created_after_days=60,
                language=language
            )
            if not results:
                # Fallback to recent repos without date filter
                results = await self.search_repositories(
                    query=f"{query} tutorial",
                    max_results=max_results,
                    sort="updated",
                    min_stars=5,
                    created_after_days=365 * 5,
                    language=language
                )
            return results
        
        elif category == "most_starred":
            # Top starred repos - no date restriction
            return await self.search_repositories(
                query=query,
                max_results=max_results,
                sort="stars",
                min_stars=50,
                created_after_days=365 * 10,  # Last 10 years
                language=language
            )
        
        elif category == "recently_updated":
            # Recently active repos
            return await self.search_repositories(
                query=query,
                max_results=max_results,
                sort="updated",
                min_stars=10,
                created_after_days=365 * 5,
                language=language
            )
        
        elif category == "beginner_friendly":
            # Repos with beginner-friendly indicators - less restrictive
            beginner_query = f"{query} tutorial"
            results = await self.search_repositories(
                query=beginner_query,
                max_results=max_results,
                sort="stars",
                min_stars=5,
                created_after_days=365 * 5,  # Last 5 years
                language=language,
                educational_only=True
            )
            
            # If not enough results, try with just the query
            if len(results) < max_results:
                more = await self.search_repositories(
                    query=f"{query} examples",
                    max_results=max_results - len(results),
                    sort="stars",
                    min_stars=3,
                    created_after_days=365 * 5,
                    language=language,
                    educational_only=True
                )
                results.extend(more)
            
            return results[:max_results]
        
        else:
            return await self.search_repositories(
                query=query,
                max_results=max_results,
                created_after_days=365 * 5,
                language=language
            )
    
    def _build_query(
        self,
        query: str,
        topics: List[str] = None,
        min_stars: int = None,
        max_stars: int = None,
        language: str = None,
        created_after_days: int = None,
        include_forks: bool = False
    ) -> str:
        """
        Build GitHub search query with filters.
        """
        parts = [query]
        
        # Add topic filters
        if topics:
            for topic in topics[:3]:  # Max 3 topics
                parts.append(f"topic:{topic}")
        
        # Star filters
        if min_stars and max_stars:
            parts.append(f"stars:{min_stars}..{max_stars}")
        elif min_stars:
            parts.append(f"stars:>={min_stars}")
        
        # Language filter
        if language:
            parts.append(f"language:{language}")
        
        # Date filter
        if created_after_days:
            date = (datetime.now() - timedelta(days=created_after_days)).strftime("%Y-%m-%d")
            parts.append(f"created:>={date}")
        
        # Fork filter
        if not include_forks:
            parts.append("fork:false")
        
        return " ".join(parts)
    
    def _parse_repo(self, item: dict) -> dict:
        """
        Parse GitHub API response into clean structure.
        """
        return {
            "type": "github",
            "source": "github",
            "name": item.get("name", ""),
            "full_name": item.get("full_name", ""),
            "url": item.get("html_url", ""),
            "description": (item.get("description") or "")[:300],
            "stars": item.get("stargazers_count", 0),
            "forks": item.get("forks_count", 0),
            "watchers": item.get("watchers_count", 0),
            "language": item.get("language") or "Unknown",
            "topics": item.get("topics", [])[:10],
            "created_at": item.get("created_at", ""),
            "updated_at": item.get("updated_at", ""),
            "pushed_at": item.get("pushed_at", ""),
            "owner_name": item.get("owner", {}).get("login", ""),
            "owner_avatar": item.get("owner", {}).get("avatar_url", ""),
            "is_fork": item.get("fork", False),
            "open_issues": item.get("open_issues_count", 0),
            "license": item.get("license", {}).get("spdx_id") if item.get("license") else None,
            "default_branch": item.get("default_branch", "main"),
        }
    
    def _should_exclude(self, repo: dict) -> bool:
        """
        Check if repo should be excluded.
        """
        name_lower = repo["name"].lower()
        desc_lower = repo["description"].lower()
        combined = f"{name_lower} {desc_lower}"
        
        # Exclude based on keywords
        for keyword in self.EXCLUDE_KEYWORDS:
            if keyword in combined:
                return True
        
        # Exclude repos with no description
        if len(repo["description"]) < 10:
            return True
        
        # Exclude very old repos with no recent activity
        if repo.get("pushed_at"):
            try:
                pushed = datetime.fromisoformat(repo["pushed_at"].replace("Z", "+00:00"))
                if (datetime.now(pushed.tzinfo) - pushed).days > 365 * 2:
                    # But keep if has many stars (classic resources)
                    if repo["stars"] < 500:
                        return True
            except:
                pass
        
        return False
    
    def _calculate_relevance(
        self,
        repo: dict,
        query: str,
        educational_only: bool
    ) -> float:
        """
        Calculate relevance score for a repository.
        """
        score = 0.0
        
        name_lower = repo["name"].lower()
        desc_lower = repo["description"].lower()
        query_lower = query.lower()
        query_words = set(query_lower.split())
        
        # Query word matches in name (high weight)
        for word in query_words:
            if len(word) > 2:  # Skip short words
                if word in name_lower:
                    score += 20
                if word in desc_lower:
                    score += 10
        
        # Educational indicators
        if educational_only:
            combined = f"{name_lower} {desc_lower}"
            for keyword in self.EDUCATIONAL_KEYWORDS:
                if keyword in combined:
                    score += 15
        
        # Star score (logarithmic to not over-weight popular repos)
        stars = repo["stars"]
        if stars > 0:
            score += min(math.log10(stars) * 5, 30)
        
        # Recency bonus
        if repo.get("pushed_at"):
            try:
                pushed = datetime.fromisoformat(repo["pushed_at"].replace("Z", "+00:00"))
                days_ago = (datetime.now(pushed.tzinfo) - pushed).days
                if days_ago < 30:
                    score += 10
                elif days_ago < 90:
                    score += 5
            except:
                pass
        
        # Topics bonus
        if repo.get("topics"):
            for topic in repo["topics"]:
                if topic.lower() in query_lower:
                    score += 10
        
        # Has README indicator (usually better documented)
        # Can't check directly but repos with good descriptions usually have READMEs
        if len(repo["description"]) > 100:
            score += 5
        
        # License bonus (open source friendly)
        if repo.get("license"):
            score += 3
        
        return score

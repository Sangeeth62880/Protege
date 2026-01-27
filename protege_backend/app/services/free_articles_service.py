"""
Free Articles Service
Aggregates articles from multiple free sources as alternative to Google Custom Search.
NO API KEY REQUIRED
"""
import httpx
import asyncio
from typing import Optional

class FreeArticlesService:
    """
    Aggregates articles from free sources:
    - Dev.to (already have)
    - Hashnode (free API)
    - freeCodeCamp (RSS/web)
    - Medium (limited, no API but can use RSS)
    """
    
    def __init__(self):
        print("[FREE_ARTICLES] Service initialized (no auth required)")
    
    async def search_articles(
        self,
        query: str,
        max_results: int = 5
    ) -> list[dict]:
        """
        Search for articles across multiple free sources.
        
        Args:
            query: Search query
            max_results: Maximum results
            
        Returns:
            List of article dictionaries from various sources
        """
        print(f"[FREE_ARTICLES] Searching: {query}")
        
        # Run searches in parallel
        tasks = [
            self._search_hashnode(query, max_results=3),
            self._search_freecodecamp(query, max_results=3),
        ]
        
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        articles = []
        for result in results:
            if isinstance(result, list):
                articles.extend(result)
            elif isinstance(result, Exception):
                print(f"[FREE_ARTICLES] A source failed: {result}")
        
        # Sort by some quality metric and limit
        articles = sorted(articles, key=lambda x: x.get("reactions", 0), reverse=True)
        
        print(f"[FREE_ARTICLES] Total found: {len(articles[:max_results])} articles")
        return articles[:max_results]
    
    async def _search_hashnode(self, query: str, max_results: int = 3) -> list[dict]:
        """
        Search Hashnode using their GraphQL API.
        Free, no auth required for public posts.
        """
        print("[FREE_ARTICLES] Searching Hashnode...")
        
        graphql_url = "https://gql.hashnode.com"
        
        # Extract first keyword for tag search
        tag = query.lower().split()[0] if query else "programming"
        
        gql_query = """
        query SearchPosts($tag: String!) {
            taggedPosts(tag: $tag, first: 10) {
                edges {
                    node {
                        title
                        brief
                        url
                        author {
                            name
                            profilePicture
                        }
                        publishedAt
                        reactionCount
                        readTimeInMinutes
                        coverImage {
                            url
                        }
                    }
                }
            }
        }
        """
        
        timeout = httpx.Timeout(30.0)
        
        async with httpx.AsyncClient(timeout=timeout) as client:
            try:
                response = await client.post(
                    graphql_url,
                    json={"query": gql_query, "variables": {"tag": tag}},
                    headers={"Content-Type": "application/json"}
                )
                
                if response.status_code != 200:
                    print(f"[HASHNODE] API error: {response.status_code}")
                    return []
                
                data = response.json()
                edges = data.get("data", {}).get("taggedPosts", {}).get("edges", [])
                
                articles = []
                for edge in edges[:max_results]:
                    node = edge.get("node", {})
                    article = {
                        "type": "article",
                        "source": "hashnode",
                        "source_name": "Hashnode",
                        "source_domain": "hashnode.com",
                        "title": node.get("title", ""),
                        "url": node.get("url", ""),
                        "description": node.get("brief", "")[:200],
                        "author": node.get("author", {}).get("name", "Unknown"),
                        "author_avatar": node.get("author", {}).get("profilePicture", ""),
                        "published_at": node.get("publishedAt", ""),
                        "read_time_minutes": node.get("readTimeInMinutes", 5),
                        "reactions": node.get("reactionCount", 0),
                        "cover_image": node.get("coverImage", {}).get("url", "") if node.get("coverImage") else "",
                    }
                    articles.append(article)
                
                print(f"[HASHNODE] Found {len(articles)} articles")
                return articles
                
            except Exception as e:
                print(f"[HASHNODE] Error: {e}")
                return []
    
    async def _search_freecodecamp(self, query: str, max_results: int = 3) -> list[dict]:
        """
        Get articles from freeCodeCamp news.
        Uses their public API/RSS.
        """
        print("[FREE_ARTICLES] Searching freeCodeCamp...")
        
        # freeCodeCamp has a simple search endpoint
        search_url = f"https://www.freecodecamp.org/news/search/"
        
        # Alternative: Use their Ghost API
        api_url = "https://www.freecodecamp.org/news/ghost/api/v3/content/posts/"
        
        timeout = httpx.Timeout(30.0)
        
        async with httpx.AsyncClient(timeout=timeout) as client:
            try:
                # Try getting recent posts filtered by tag
                tag = query.lower().split()[0] if query else "programming"
                
                params = {
                    "key": "bd680d3c04dd97c7a1459c29d5",  # Public Ghost content API key
                    "limit": max_results,
                    "filter": f"tag:{tag}",
                    "include": "authors"
                }
                
                response = await client.get(api_url, params=params)
                
                if response.status_code != 200:
                    # Try without tag filter
                    params.pop("filter", None)
                    response = await client.get(api_url, params=params)
                
                if response.status_code != 200:
                    print(f"[FREECODECAMP] API error: {response.status_code}")
                    return []
                
                data = response.json()
                posts = data.get("posts", [])
                
                articles = []
                for post in posts[:max_results]:
                    authors = post.get("authors", [{}])
                    first_author = authors[0] if authors else {}
                    
                    article = {
                        "type": "article",
                        "source": "freecodecamp",
                        "source_name": "freeCodeCamp",
                        "source_domain": "freecodecamp.org",
                        "title": post.get("title", ""),
                        "url": post.get("url", ""),
                        "description": post.get("excerpt", "")[:200] if post.get("excerpt") else "",
                        "author": first_author.get("name", "freeCodeCamp"),
                        "author_avatar": first_author.get("profile_image", ""),
                        "published_at": post.get("published_at", ""),
                        "read_time_minutes": post.get("reading_time", 5),
                        "reactions": 0,  # Not available
                        "cover_image": post.get("feature_image", ""),
                    }
                    articles.append(article)
                
                print(f"[FREECODECAMP] Found {len(articles)} articles")
                return articles
                
            except Exception as e:
                print(f"[FREECODECAMP] Error: {e}")
                return []

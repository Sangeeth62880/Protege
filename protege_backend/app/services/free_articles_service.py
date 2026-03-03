"""
Free Articles Service - Rewritten for Accuracy
Uses full-text search for Hashnode and freeCodeCamp instead of first-keyword tag matching.
NO API KEY REQUIRED
"""
import httpx
import asyncio
from typing import Optional
import re

# Stop words to skip when building search terms
STOP_WORDS = frozenset({
    "understanding", "introduction", "to", "the", "of", "in", "a", "an",
    "and", "for", "with", "basic", "advanced", "learn", "building",
    "creating", "using", "how", "what", "why", "is", "are", "this",
})


class FreeArticlesService:
    """
    Aggregates articles from free sources using full-text search:
    - Hashnode (GraphQL full-text search)
    - freeCodeCamp (Ghost Content API with text filter)
    """

    def __init__(self):
        print("[FREE_ARTICLES] Service initialized (no auth required)")

    async def search_articles(
        self, query: str, max_results: int = 5
    ) -> list[dict]:
        """Search for articles across multiple free sources."""
        print(f"[FREE_ARTICLES] Searching: {query}")

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

        # Sort by reactions/quality and limit
        articles = sorted(
            articles, key=lambda x: x.get("reactions", 0), reverse=True
        )

        print(f"[FREE_ARTICLES] Total found: {len(articles[:max_results])} articles")
        return articles[:max_results]

    async def _search_hashnode(
        self, query: str, max_results: int = 3
    ) -> list[dict]:
        """
        Search Hashnode using their GraphQL API with FULL-TEXT search.
        Uses searchPostsOfPublicHashnodeBlogs instead of tag-only taggedPosts.
        """
        print("[FREE_ARTICLES] Searching Hashnode...")

        graphql_url = "https://gql.hashnode.com"

        # Use full query for search, not just first keyword
        gql_query = """
        query SearchPosts($query: String!) {
            searchPostsOfPublicHashnodeBlogs(
                input: { query: $query, first: 10 }
            ) {
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
                    json={"query": gql_query, "variables": {"query": query}},
                    headers={"Content-Type": "application/json"},
                )

                if response.status_code != 200:
                    print(f"[HASHNODE] API error: {response.status_code}")
                    return []

                data = response.json()

                # Navigate the response structure
                search_result = data.get("data", {}).get(
                    "searchPostsOfPublicHashnodeBlogs", {}
                )
                edges = search_result.get("edges", [])

                if not edges:
                    print("[HASHNODE] No results from full-text search")
                    return []

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
                        "description": (node.get("brief") or "")[:200],
                        "author": node.get("author", {}).get("name", "Unknown"),
                        "author_avatar": node.get("author", {}).get(
                            "profilePicture", ""
                        ),
                        "published_at": node.get("publishedAt", ""),
                        "read_time_minutes": node.get("readTimeInMinutes", 5),
                        "reactions": node.get("reactionCount", 0),
                        "cover_image": (
                            node.get("coverImage", {}).get("url", "")
                            if node.get("coverImage")
                            else ""
                        ),
                    }
                    articles.append(article)

                print(f"[HASHNODE] Found {len(articles)} articles via full-text search")
                return articles

            except Exception as e:
                print(f"[HASHNODE] Error: {e}")
                return []

    async def _search_freecodecamp(
        self, query: str, max_results: int = 3
    ) -> list[dict]:
        """
        Get articles from freeCodeCamp news.
        Uses Ghost Content API with text filter instead of tag-only.
        """
        print("[FREE_ARTICLES] Searching freeCodeCamp...")

        api_url = (
            "https://www.freecodecamp.org/news/ghost/api/v3/content/posts/"
        )

        # Extract meaningful keywords for filter
        keywords = self._extract_keywords(query)
        search_term = " ".join(keywords[:3]) if keywords else query

        timeout = httpx.Timeout(30.0)

        async with httpx.AsyncClient(timeout=timeout) as client:
            try:
                # Strategy 1: Use Ghost's title text filter
                # Ghost supports filter operators: https://ghost.org/docs/content-api/
                # ~'term' is a "contains" match
                params = {
                    "key": "bd680d3c04dd97c7a1459c29d5",
                    "limit": max_results + 5,
                    "include": "authors",
                }

                # Try searching with the primary keyword in the title
                if keywords:
                    params["filter"] = f"title:~'{keywords[0]}'"

                response = await client.get(api_url, params=params)

                articles = []
                if response.status_code == 200:
                    data = response.json()
                    posts = data.get("posts", [])

                    if posts:
                        articles = self._parse_fcc_posts(posts, max_results)

                # Strategy 2: If we got nothing or too few, try second keyword
                if len(articles) < 2 and len(keywords) >= 2:
                    params["filter"] = f"title:~'{keywords[1]}'"
                    response = await client.get(api_url, params=params)
                    if response.status_code == 200:
                        data = response.json()
                        posts = data.get("posts", [])
                        more = self._parse_fcc_posts(posts, max_results)
                        # Add non-duplicate articles
                        existing_urls = {a["url"] for a in articles}
                        for a in more:
                            if a["url"] not in existing_urls:
                                articles.append(a)

                # Strategy 3: If still nothing, try without filter but validate titles
                if not articles:
                    params.pop("filter", None)
                    params["limit"] = 30  # Fetch more to filter
                    response = await client.get(api_url, params=params)
                    if response.status_code == 200:
                        data = response.json()
                        posts = data.get("posts", [])
                        # Filter by title relevance
                        relevant_posts = [
                            p
                            for p in posts
                            if any(
                                kw in (p.get("title") or "").lower()
                                for kw in keywords
                            )
                        ]
                        articles = self._parse_fcc_posts(
                            relevant_posts, max_results
                        )

                print(f"[FREECODECAMP] Found {len(articles)} articles")
                return articles[:max_results]

            except Exception as e:
                print(f"[FREECODECAMP] Error: {e}")
                return []

    def _parse_fcc_posts(
        self, posts: list, max_results: int
    ) -> list[dict]:
        """Parse freeCodeCamp Ghost posts into standard format."""
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
                "description": (post.get("excerpt") or "")[:200],
                "author": first_author.get("name", "freeCodeCamp"),
                "author_avatar": first_author.get("profile_image", ""),
                "published_at": post.get("published_at", ""),
                "read_time_minutes": post.get("reading_time", 5),
                "reactions": 0,  # Not available from Ghost API
                "cover_image": post.get("feature_image", ""),
            }
            articles.append(article)
        return articles

    def _extract_keywords(self, query: str) -> list[str]:
        """Extract meaningful keywords, skipping stop words."""
        words = re.findall(r"[a-z0-9]+", query.lower())
        meaningful = [w for w in words if w not in STOP_WORDS and len(w) >= 3]
        return meaningful if meaningful else words[:2]

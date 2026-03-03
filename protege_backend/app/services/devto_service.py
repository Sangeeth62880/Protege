"""
Dev.to API Service - Rewritten for Accuracy
Uses full-text search instead of tag-only matching.
"""
import httpx
from typing import Optional, List
import re

# Words that should never be used as the primary search term
STOP_WORDS = frozenset({
    "understanding", "introduction", "to", "the", "of", "in", "a", "an",
    "and", "for", "with", "basic", "advanced", "learn", "building",
    "creating", "using", "how", "what", "why", "is", "are", "this",
    "that", "from", "on", "by", "at", "about", "into", "through",
    "during", "before", "after", "above", "below", "between", "its",
})


class DevToService:
    """Dev.to service using full-text search for accurate results."""

    BASE_URL = "https://dev.to/api"

    # Quality thresholds
    MIN_REACTIONS = 3
    MIN_READING_TIME = 2
    MAX_READING_TIME = 40

    def __init__(self):
        print("[DEVTO] Enhanced service initialized")

    async def search_articles(
        self,
        query: str,
        tags: List[str] = None,
        max_results: int = 5,
        min_reactions: int = None,
        sort_by: str = "relevance",
    ) -> List[dict]:
        """
        Search for articles with full-text search + relevance filtering.

        Strategy:
        1. Try Dev.to's articles endpoint with meaningful keywords as tags
        2. Filter results by title relevance to the original query
        3. Score and rank by composite relevance
        """
        print(f"[DEVTO] Searching: {query}")
        min_reactions = min_reactions or self.MIN_REACTIONS

        # Extract meaningful keywords from the query
        keywords = self._extract_keywords(query)
        print(f"[DEVTO] Meaningful keywords: {keywords}")

        all_articles: List[dict] = []

        timeout = httpx.Timeout(30.0)
        async with httpx.AsyncClient(timeout=timeout) as client:
            # Strategy 1: Try each meaningful keyword as a tag (broadened time window)
            for keyword in keywords[:3]:
                articles = await self._fetch_by_tag(client, keyword, limit=15)
                all_articles.extend(articles)

            # Strategy 2: If explicit tags were provided, try those too
            if tags:
                for tag in tags[:2]:
                    tag_clean = re.sub(r'[^a-z0-9]', '', tag.lower())
                    if tag_clean and tag_clean not in keywords:
                        articles = await self._fetch_by_tag(client, tag_clean, limit=10)
                        all_articles.extend(articles)

        # Deduplicate by URL
        seen_urls = set()
        unique = []
        for a in all_articles:
            url = a.get("url", "")
            if url and url not in seen_urls:
                seen_urls.add(url)
                unique.append(a)

        # Filter by title/description relevance to the query
        relevant = self._filter_by_relevance(unique, keywords)

        # Apply quality filters
        quality_filtered = []
        for article in relevant:
            reactions = article.get("reactions", 0)
            read_time = article.get("read_time_minutes", 0)
            if reactions >= min_reactions and self.MIN_READING_TIME <= read_time <= self.MAX_READING_TIME:
                quality_filtered.append(article)

        # If quality filter is too strict, relax it
        if len(quality_filtered) < 2 and len(relevant) >= 2:
            quality_filtered = relevant

        # Score and sort
        for article in quality_filtered:
            article["relevance_score"] = self._calculate_relevance(article, query, keywords)

        if sort_by == "reactions":
            quality_filtered.sort(key=lambda x: x.get("reactions", 0), reverse=True)
        elif sort_by == "date":
            quality_filtered.sort(key=lambda x: x.get("published_at", ""), reverse=True)
        else:
            quality_filtered.sort(key=lambda x: x.get("relevance_score", 0), reverse=True)

        result = quality_filtered[:max_results]
        print(f"[DEVTO] Returning {len(result)} relevant articles (from {len(unique)} candidates)")
        return result

    def _extract_keywords(self, query: str) -> List[str]:
        """Extract meaningful keywords from the query, skipping stop words."""
        words = re.findall(r'[a-z0-9]+', query.lower())
        meaningful = [w for w in words if w not in STOP_WORDS and len(w) >= 3]
        return meaningful if meaningful else words[:2]

    async def _fetch_by_tag(
        self, client: httpx.AsyncClient, tag: str, limit: int = 15
    ) -> List[dict]:
        """Fetch articles by tag with expanded time window."""
        try:
            # Try top articles from last year first
            params = {"tag": tag, "per_page": limit, "top": 365}
            response = await client.get(f"{self.BASE_URL}/articles", params=params)

            if response.status_code == 200:
                articles = response.json()
                if articles:
                    print(f"[DEVTO] Tag '{tag}' (365d): {len(articles)} articles")
                    return [self._parse_article(a) for a in articles]

            # Fallback: no time filter
            params = {"tag": tag, "per_page": limit}
            response = await client.get(f"{self.BASE_URL}/articles", params=params)
            if response.status_code == 200:
                articles = response.json()
                print(f"[DEVTO] Tag '{tag}' (all): {len(articles)} articles")
                return [self._parse_article(a) for a in articles]

        except Exception as e:
            print(f"[DEVTO] Tag '{tag}' fetch error: {e}")
        return []

    def _filter_by_relevance(self, articles: List[dict], keywords: List[str]) -> List[dict]:
        """Filter articles that have at least one keyword in title or tags."""
        relevant = []
        for article in articles:
            title_lower = article.get("title", "").lower()
            desc_lower = article.get("description", "").lower()
            tags = [t.lower() for t in article.get("tags", [])]
            combined = f"{title_lower} {' '.join(tags)} {desc_lower}"

            matches = sum(1 for kw in keywords if kw in combined)
            if matches >= 1:
                article["_keyword_matches"] = matches
                relevant.append(article)

        return relevant

    def _parse_article(self, item: dict) -> dict:
        """Parse Dev.to article into clean structure."""
        return {
            "type": "article",
            "source": "devto",
            "source_name": "Dev.to",
            "source_domain": "dev.to",
            "title": item.get("title", ""),
            "url": item.get("url", ""),
            "description": (item.get("description") or "")[:200],
            "author": item.get("user", {}).get("name", "Unknown"),
            "author_username": item.get("user", {}).get("username", ""),
            "author_avatar": item.get("user", {}).get("profile_image_90", ""),
            "published_at": item.get("published_at", ""),
            "read_time_minutes": item.get("reading_time_minutes", 5),
            "reactions": item.get("positive_reactions_count", 0),
            "comments": item.get("comments_count", 0),
            "tags": item.get("tag_list", []),
            "cover_image": item.get("cover_image") or item.get("social_image", ""),
        }

    def _calculate_relevance(self, article: dict, query: str, keywords: List[str]) -> float:
        """Calculate composite relevance score: keyword match + popularity + recency."""
        score = 0.0

        title_lower = article.get("title", "").lower()
        desc_lower = article.get("description", "").lower()
        tags = [t.lower() for t in article.get("tags", [])]

        # Title keyword matches (highest weight — 30 pts each)
        for kw in keywords:
            if kw in title_lower:
                score += 30
            if kw in desc_lower:
                score += 10
            if kw in tags:
                score += 15

        # Multi-keyword bonus (article covers multiple concepts = more relevant)
        keyword_matches = article.get("_keyword_matches", 0)
        if keyword_matches >= 3:
            score += 25
        elif keyword_matches >= 2:
            score += 15

        # Engagement (popularity indicator, capped contribution)
        reactions = article.get("reactions", 0)
        if reactions > 100:
            score += 15
        elif reactions > 50:
            score += 12
        elif reactions > 20:
            score += 8
        elif reactions > 5:
            score += 4

        # Optimal reading time
        read_time = article.get("read_time_minutes", 0)
        if 5 <= read_time <= 15:
            score += 8
        elif 3 <= read_time <= 25:
            score += 4

        # Has cover image (usually higher quality)
        if article.get("cover_image"):
            score += 2

        return score

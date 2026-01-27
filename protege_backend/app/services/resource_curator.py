"""
Resource Curator Service
Combines, deduplicates, and ranks resources from all sources.
"""
import asyncio
from typing import Optional
from app.services.youtube_service import YouTubeService
from app.services.github_service import GitHubService
from app.services.devto_service import DevToService
from app.services.wikipedia_service import WikipediaService
from app.services.free_articles_service import FreeArticlesService

class ResourceCurator:
    """
    Curates learning resources from multiple sources.
    Combines, deduplicates, ranks, and returns the best resources.
    """
    
    def __init__(
        self,
        youtube_service: YouTubeService,
        github_service: Optional[GitHubService] = None,
        devto_service: Optional[DevToService] = None,
        wikipedia_service: Optional[WikipediaService] = None,
        free_articles_service: Optional[FreeArticlesService] = None,
    ):
        """Initialize with available services."""
        self.youtube = youtube_service
        self.github = github_service
        self.devto = devto_service
        self.wikipedia = wikipedia_service
        self.free_articles = free_articles_service
        print("[CURATOR] Resource curator initialized")
        print(f"[CURATOR] Services: YouTube=✓, GitHub={'✓' if github_service else '✗'}, "
              f"DevTo={'✓' if devto_service else '✗'}, Wikipedia={'✓' if wikipedia_service else '✗'}, "
              f"FreeArticles={'✓' if free_articles_service else '✗'}")
    
    async def curate_lesson_resources(
        self,
        lesson_title: str,
        search_queries: dict,
        max_videos: int = 3,
        max_articles: int = 4,
        max_repos: int = 2
    ) -> dict:
        """
        Curate resources for a specific lesson.
        
        Args:
            lesson_title: Title of the lesson
            search_queries: Dict with 'youtube', 'articles', 'github' queries
            max_videos: Maximum video results
            max_articles: Maximum article results
            max_repos: Maximum GitHub results
            
        Returns:
            Curated resources organized by type
        """
        print(f"[CURATOR] ═══════════════════════════════════════════════════")
        print(f"[CURATOR] Curating resources for: {lesson_title}")
        print(f"[CURATOR] Queries: {search_queries}")
        print(f"[CURATOR] ═══════════════════════════════════════════════════")
        
        # Prepare all tasks for parallel execution
        tasks = []
        task_names = []
        
        # ─────────────────────────────────────────────────────────────────
        # YouTube Videos (required - we know this works)
        # ─────────────────────────────────────────────────────────────────
        youtube_query = search_queries.get("youtube", lesson_title)
        tasks.append(self._safe_search(
            self.youtube.search_videos(youtube_query, max_results=max_videos + 2),
            "youtube"
        ))
        task_names.append("youtube")
        
        # ─────────────────────────────────────────────────────────────────
        # Articles from Dev.to
        # ─────────────────────────────────────────────────────────────────
        articles_query = search_queries.get("articles", lesson_title)
        
        if self.devto:
            tasks.append(self._safe_search(
                self.devto.search_articles(articles_query, max_results=max_articles),
                "devto"
            ))
            task_names.append("devto")
        
        # ─────────────────────────────────────────────────────────────────
        # Articles from Free Sources (Hashnode, freeCodeCamp)
        # ─────────────────────────────────────────────────────────────────
        if self.free_articles:
            tasks.append(self._safe_search(
                self.free_articles.search_articles(articles_query, max_results=max_articles),
                "free_articles"
            ))
            task_names.append("free_articles")
        
        # ─────────────────────────────────────────────────────────────────
        # GitHub Repositories
        # ─────────────────────────────────────────────────────────────────
        github_query = search_queries.get("github", lesson_title)
        
        if self.github:
            tasks.append(self._safe_search(
                self.github.search_repositories(github_query, max_results=max_repos + 2),
                "github"
            ))
            task_names.append("github")
        
        # ─────────────────────────────────────────────────────────────────
        # Wikipedia Summary
        # ─────────────────────────────────────────────────────────────────
        if self.wikipedia:
            # Extract main concept from lesson title
            main_concept = lesson_title.split(":")[0].strip() if ":" in lesson_title else lesson_title
            # Remove common words
            for word in ["Understanding", "Introduction to", "Learn", "Basic", "Advanced"]:
                main_concept = main_concept.replace(word, "").strip()
            
            tasks.append(self._safe_search(
                self.wikipedia.get_summary(main_concept),
                "wikipedia"
            ))
            task_names.append("wikipedia")
        
        # ─────────────────────────────────────────────────────────────────
        # Execute all tasks in parallel
        # ─────────────────────────────────────────────────────────────────
        print(f"[CURATOR] Fetching from {len(tasks)} sources in parallel...")
        results = await asyncio.gather(*tasks)
        
        # ─────────────────────────────────────────────────────────────────
        # Process results
        # ─────────────────────────────────────────────────────────────────
        videos = []
        articles = []
        repos = []
        wikipedia_summary = None
        sources_used = []
        
        for name, result in zip(task_names, results):
            if result is None:
                print(f"[CURATOR] {name}: No results")
                continue
            
            sources_used.append(name)
            
            if name == "youtube" and result:
                videos = self._rank_videos(result)[:max_videos]
                print(f"[CURATOR] YouTube: {len(videos)} videos")
                
            elif name == "devto" and result:
                articles.extend(result)
                print(f"[CURATOR] Dev.to: {len(result)} articles")
                
            elif name == "free_articles" and result:
                articles.extend(result)
                print(f"[CURATOR] Free sources: {len(result)} articles")
                
            elif name == "github" and result:
                repos = self._rank_repos(result)[:max_repos]
                print(f"[CURATOR] GitHub: {len(repos)} repos")
                
            elif name == "wikipedia" and result:
                wikipedia_summary = result
                print(f"[CURATOR] Wikipedia: ✓")
        
        # ─────────────────────────────────────────────────────────────────
        # Deduplicate and rank articles
        # ─────────────────────────────────────────────────────────────────
        articles = self._dedupe_articles(articles)
        articles = self._rank_articles(articles)[:max_articles]
        
        # ─────────────────────────────────────────────────────────────────
        # Calculate quality scores
        # ─────────────────────────────────────────────────────────────────
        for video in videos:
            video["quality_score"] = self._calculate_video_score(video)
        
        for article in articles:
            article["quality_score"] = self._calculate_article_score(article)
        
        for repo in repos:
            repo["quality_score"] = self._calculate_repo_score(repo)
        
        # ─────────────────────────────────────────────────────────────────
        # Build final response
        # ─────────────────────────────────────────────────────────────────
        curated = {
            "lesson_title": lesson_title,
            "videos": videos,
            "articles": articles,
            "repositories": repos,
            "wikipedia": wikipedia_summary,
            "total_resources": len(videos) + len(articles) + len(repos),
            "sources_used": sources_used
        }
        
        print(f"[CURATOR] ═══════════════════════════════════════════════════")
        print(f"[CURATOR] TOTAL: {curated['total_resources']} resources")
        print(f"[CURATOR]   📹 Videos: {len(videos)}")
        print(f"[CURATOR]   📄 Articles: {len(articles)}")
        print(f"[CURATOR]   💻 Repos: {len(repos)}")
        print(f"[CURATOR]   📖 Wikipedia: {'Yes' if wikipedia_summary else 'No'}")
        print(f"[CURATOR] Sources: {', '.join(sources_used)}")
        print(f"[CURATOR] ═══════════════════════════════════════════════════")
        
        return curated
    
    async def _safe_search(self, coroutine, name: str, timeout: float = 15.0):
        """
        Execute a search coroutine safely with a strict timeout.
        If the service takes longer than 'timeout' seconds, it is cancelled.
        """
        try:
            return await asyncio.wait_for(coroutine, timeout=timeout)
        except asyncio.TimeoutError:
            print(f"[CURATOR] {name} timed out after {timeout}s")
            return None
        except Exception as e:
            print(f"[CURATOR] {name} failed: {e}")
            return None
    
    def _rank_videos(self, videos: list[dict]) -> list[dict]:
        """Rank videos by quality score."""
        for video in videos:
            video["_score"] = self._calculate_video_score(video)
        return sorted(videos, key=lambda x: x.get("_score", 0), reverse=True)
    
    def _rank_articles(self, articles: list[dict]) -> list[dict]:
        """Rank articles by quality score."""
        for article in articles:
            article["_score"] = self._calculate_article_score(article)
        return sorted(articles, key=lambda x: x.get("_score", 0), reverse=True)
    
    def _rank_repos(self, repos: list[dict]) -> list[dict]:
        """Rank repos by quality score."""
        for repo in repos:
            repo["_score"] = self._calculate_repo_score(repo)
        return sorted(repos, key=lambda x: x.get("_score", 0), reverse=True)
    
    def _dedupe_articles(self, articles: list[dict]) -> list[dict]:
        """Remove duplicate articles based on URL and similar titles."""
        seen_urls = set()
        seen_titles = set()
        unique = []
        
        for article in articles:
            url = article.get("url", "")
            title = article.get("title", "").lower()[:50]
            
            if url and url not in seen_urls and title not in seen_titles:
                seen_urls.add(url)
                seen_titles.add(title)
                unique.append(article)
        
        return unique
    
    def _calculate_video_score(self, video: dict) -> float:
        """Calculate quality score for a video (0-100)."""
        score = 50.0
        
        views = video.get("view_count", 0)
        if views > 1000000: score += 20
        elif views > 100000: score += 15
        elif views > 10000: score += 10
        elif views > 1000: score += 5
        
        likes = video.get("like_count", 0)
        if views > 0 and likes > 0:
            ratio = likes / views
            if ratio > 0.05: score += 15
            elif ratio > 0.03: score += 10
            elif ratio > 0.01: score += 5
        
        duration = video.get("duration_minutes", 0)
        if 5 <= duration <= 20: score += 10
        elif 3 <= duration <= 30: score += 5
        
        return min(100, score)
    
    def _calculate_article_score(self, article: dict) -> float:
        """Calculate quality score for an article (0-100)."""
        score = 50.0
        
        # Source quality
        source = article.get("source", "").lower()
        if source in ["freecodecamp", "realpython"]: score += 20
        elif source in ["devto", "hashnode"]: score += 15
        
        # Engagement
        reactions = article.get("reactions", 0)
        if reactions > 100: score += 15
        elif reactions > 50: score += 10
        elif reactions > 10: score += 5
        
        # Read time (prefer 5-15 minutes)
        read_time = article.get("read_time_minutes", 0)
        if 5 <= read_time <= 15: score += 10
        elif 3 <= read_time <= 20: score += 5
        
        return min(100, score)
    
    def _calculate_repo_score(self, repo: dict) -> float:
        """Calculate quality score for a repo (0-100)."""
        score = 50.0
        
        stars = repo.get("stars", 0)
        if stars > 10000: score += 25
        elif stars > 1000: score += 20
        elif stars > 100: score += 15
        elif stars > 10: score += 10
        
        if len(repo.get("description", "")) > 30: score += 10
        
        return min(100, score)

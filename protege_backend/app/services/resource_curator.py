"""
Resource Curator Service - Enhanced Version
Uses AI for query optimization and relevance validation.
"""
import asyncio
from typing import Optional, List
from app.services.query_optimizer import QueryOptimizer
from app.services.youtube_service import YouTubeService
from app.services.github_service import GitHubService
from app.services.devto_service import DevToService
from app.services.wikipedia_service import WikipediaService
from app.services.free_articles_service import FreeArticlesService
from app.services.relevance_scorer import RelevanceScorer
from app.services.openlibrary_service import OpenLibraryService
from app.services.stackoverflow_service import StackOverflowService
from app.services.coursera_service import CourseraService
from app.services.mdn_service import MDNService

class ResourceCurator:
    """
    Enhanced resource curator with AI-powered accuracy.
    """
    
    def __init__(
        self,
        youtube_service: YouTubeService,
        github_service: Optional[GitHubService] = None,
        devto_service: Optional[DevToService] = None,
        wikipedia_service: Optional[WikipediaService] = None,
        free_articles_service: Optional[FreeArticlesService] = None,
        query_optimizer: Optional[QueryOptimizer] = None,
        relevance_scorer: Optional[RelevanceScorer] = None,
        openlibrary_service: Optional[OpenLibraryService] = None,
        stackoverflow_service: Optional[StackOverflowService] = None,
        coursera_service: Optional[CourseraService] = None,
        mdn_service: Optional[MDNService] = None,
    ):
        self.youtube = youtube_service
        self.github = github_service
        self.devto = devto_service
        self.wikipedia = wikipedia_service
        self.free_articles = free_articles_service
        self.query_optimizer = query_optimizer or QueryOptimizer()
        self.relevance_scorer = relevance_scorer
        self.openlibrary = openlibrary_service
        self.stackoverflow = stackoverflow_service
        self.coursera = coursera_service
        self.mdn = mdn_service
        
        print("[CURATOR] Enhanced resource curator initialized")
    
    async def curate_lesson_resources(
        self,
        topic: str,
        lesson_title: str,
        key_concepts: List[str] = None,
        search_queries: dict = None,
        max_videos: int = 3,
        max_articles: int = 4,
        max_repos: int = 3,
        github_category: str = "beginner_friendly",  # trending, most_starred, etc.
        language: str = None  # Programming language for GitHub filter
    ) -> dict:
        """
        Curate resources with AI-enhanced accuracy.
        
        Args:
            topic: Main topic
            lesson_title: Specific lesson title
            key_concepts: Key concepts to search for
            search_queries: Pre-generated queries (optional)
            max_videos: Max video results
            max_articles: Max article results
            max_repos: Max GitHub results
            github_category: Category filter for GitHub
            language: Programming language filter
            
        Returns:
            Curated resources with relevance scores
        """
        print(f"\n{'='*60}")
        print(f"[CURATOR] Curating: {lesson_title}")
        print(f"[CURATOR] Topic: {topic}")
        print(f"[CURATOR] Key concepts: {key_concepts}")
        print(f"{'='*60}")
        
        # Step 1: Generate optimized queries using AI
        if not search_queries:
            print("[CURATOR] Generating AI-optimized queries...")
            search_queries = await self.query_optimizer.generate_optimized_queries(
                topic=topic,
                lesson_title=lesson_title,
                key_concepts=key_concepts
            )
        
        print(f"[CURATOR] Queries: {search_queries}")
        
        # Step 2: Prepare parallel search tasks
        tasks = []
        task_names = []
        
        # YouTube (always included)
        youtube_query = search_queries.get("youtube", f"{topic} {lesson_title} tutorial")
        tasks.append(self._safe_search(
            self.youtube.search_videos(youtube_query, max_results=max_videos + 2),
            "youtube"
        ))
        task_names.append("youtube")
        
        # Wikipedia with fallbacks
        if self.wikipedia:
            wiki_primary = search_queries.get("wikipedia", lesson_title)
            wiki_fallback = search_queries.get("wikipedia_fallback", topic)
            key_terms = search_queries.get("key_terms", [])
            
            tasks.append(self._safe_search(
                self.wikipedia.get_summary(
                    topic=wiki_primary,
                    fallback_term=wiki_fallback,
                    key_terms=key_terms
                ),
                "wikipedia"
            ))
            task_names.append("wikipedia")
        
        # GitHub with category filtering
        if self.github:
            github_query = search_queries.get("github", f"{topic} tutorial examples")
            github_topics = search_queries.get("github_topics", [])
            
            tasks.append(self._safe_search(
                self.github.search_by_category(
                    query=github_query,
                    category=github_category,
                    language=language,
                    max_results=max_repos + 2
                ),
                "github"
            ))
            task_names.append("github")
        
        # Dev.to
        if self.devto:
            devto_query = search_queries.get("devto", topic)
            devto_tags = search_queries.get("key_terms", [])
            
            tasks.append(self._safe_search(
                self.devto.search_articles(
                    query=devto_query,
                    tags=devto_tags,
                    max_results=max_articles
                ),
                "devto"
            ))
            task_names.append("devto")
        
        # Free articles (Hashnode, freeCodeCamp)
        if self.free_articles:
            articles_query = search_queries.get("articles", f"{topic} {lesson_title}")
            
            tasks.append(self._safe_search(
                self.free_articles.search_articles(
                    query=articles_query,
                    max_results=max_articles
                ),
                "free_articles"
            ))
            task_names.append("free_articles")
        
        # Open Library (books)
        if self.openlibrary:
            book_query = search_queries.get("book_query", f"{lesson_title} {topic}")
            tasks.append(self._safe_search(
                self.openlibrary.search_books(query=book_query, max_results=3),
                "openlibrary"
            ))
            task_names.append("openlibrary")
        
        # Stack Overflow (Q&A)
        if self.stackoverflow:
            so_query = search_queries.get("stackoverflow", f"{lesson_title} {topic}")
            tasks.append(self._safe_search(
                self.stackoverflow.search_questions(query=so_query, max_results=3),
                "stackoverflow"
            ))
            task_names.append("stackoverflow")
        
        # Coursera (courses)
        if self.coursera:
            course_query = search_queries.get("coursera", f"{lesson_title} {topic}")
            tasks.append(self._safe_search(
                self.coursera.search_courses(query=course_query, max_results=3),
                "coursera"
            ))
            task_names.append("coursera")
        
        # MDN (web docs — only for web topics)
        if self.mdn and self.mdn.is_web_topic(topic, lesson_title):
            mdn_query = search_queries.get("mdn", lesson_title)
            tasks.append(self._safe_search(
                self.mdn.search_docs(query=mdn_query, max_results=3),
                "mdn"
            ))
            task_names.append("mdn")
        
        # Step 3: Execute all searches in parallel
        print(f"[CURATOR] Executing {len(tasks)} searches in parallel...")
        results = await asyncio.gather(*tasks)
        
        # Step 4: Process results
        videos = []
        articles = []
        repos = []
        books = []
        questions = []
        courses = []
        docs = []
        wikipedia_summary = None
        sources_used = []
        
        for name, result in zip(task_names, results):
            if result is None:
                print(f"[CURATOR] {name}: No results")
                continue
            
            sources_used.append(name)
            
            if name == "youtube" and result:
                videos = self._rank_by_score(result, "quality_score")[:max_videos]
                print(f"[CURATOR] YouTube: {len(videos)} videos")
                
            elif name == "wikipedia" and result:
                wikipedia_summary = result
                print(f"[CURATOR] Wikipedia: ✓ {result.get('title', 'N/A')}")
                
            elif name == "github" and result:
                repos = self._rank_by_score(result, "relevance_score")[:max_repos]
                print(f"[CURATOR] GitHub: {len(repos)} repos")
                
            elif name == "devto" and result:
                for article in result:
                    article["source"] = "devto"
                articles.extend(result)
                print(f"[CURATOR] Dev.to: {len(result)} articles")
                
            elif name == "free_articles" and result:
                articles.extend(result)
                print(f"[CURATOR] Free sources: {len(result)} articles")
            
            elif name == "openlibrary" and result:
                books = result
                print(f"[CURATOR] Open Library: {len(result)} books")
            
            elif name == "stackoverflow" and result:
                questions = result
                print(f"[CURATOR] Stack Overflow: {len(result)} questions")
            
            elif name == "coursera" and result:
                courses = result
                print(f"[CURATOR] Coursera: {len(result)} courses")
            
            elif name == "mdn" and result:
                docs = result
                print(f"[CURATOR] MDN: {len(result)} docs")
        
        # Step 5: AI Relevance Scoring (filter irrelevant results)
        if self.relevance_scorer:
            print("[CURATOR] Running AI relevance scoring...")
            if articles:
                articles = await self.relevance_scorer.score_resources(
                    articles, topic, lesson_title, min_score=40
                )
            if videos:
                videos = await self.relevance_scorer.score_resources(
                    videos, topic, lesson_title, min_score=40
                )
        
        # Step 6: Deduplicate and rank articles
        articles = self._dedupe_articles(articles)
        articles = self._rank_by_score(articles, "relevance_score")[:max_articles]
        
        # Step 7: Build response
        total = len(videos) + len(articles) + len(repos) + len(books) + len(questions) + len(courses) + len(docs) + (1 if wikipedia_summary else 0)
        curated = {
            "lesson_title": lesson_title,
            "topic": topic,
            "videos": videos,
            "articles": articles,
            "repositories": repos,
            "wikipedia": wikipedia_summary,
            "books": books,
            "questions": questions,
            "courses": courses,
            "docs": docs,
            "total_resources": total,
            "sources_used": sources_used,
            "queries_used": search_queries
        }
        
        print(f"\n{'='*60}")
        print(f"[CURATOR] RESULTS SUMMARY")
        print(f"[CURATOR] Videos: {len(videos)}")
        print(f"[CURATOR] Articles: {len(articles)}")
        print(f"[CURATOR] Repos: {len(repos)}")
        print(f"[CURATOR] Books: {len(books)}")
        print(f"[CURATOR] Q&A: {len(questions)}")
        print(f"[CURATOR] Courses: {len(courses)}")
        print(f"[CURATOR] Docs: {len(docs)}")
        print(f"[CURATOR] Wikipedia: {'Yes' if wikipedia_summary else 'No'}")
        print(f"[CURATOR] Total: {total}")
        print(f"{'='*60}\n")
        
        return curated
    
    async def _safe_search(self, coroutine, name: str):
        """Execute search safely with error handling."""
        try:
            return await coroutine
        except Exception as e:
            print(f"[CURATOR] {name} failed: {e}")
            return None
    
    def _rank_by_score(self, items: list, score_key: str) -> list:
        """Rank items by composite score: 60% relevance + 25% quality + 15% recency."""
        for item in items:
            base_score = item.get(score_key, 0)
            ai_score = item.get("ai_relevance_score", 0)
            
            # Relevance component (60%) — use AI score if available, else base score
            relevance = (ai_score if ai_score > 0 else base_score) * 0.6
            
            # Quality component (25%) — engagement metrics
            quality = 0.0
            reactions = item.get("reactions", 0)
            stars = item.get("stars", 0)
            votes = item.get("score", 0)
            engagement = max(reactions, stars, votes)
            if engagement > 100:
                quality = 25
            elif engagement > 50:
                quality = 20
            elif engagement > 20:
                quality = 15
            elif engagement > 5:
                quality = 10
            else:
                quality = 5
            quality *= 0.25
            
            # Recency component (15%) — prefer newer content
            recency = 10  # Default mid-range
            published = item.get("published_at", "")
            if published:
                # Simple heuristic: more recent years = higher score
                try:
                    year_str = published[:4]
                    year = int(year_str)
                    if year >= 2025:
                        recency = 15
                    elif year >= 2024:
                        recency = 12
                    elif year >= 2023:
                        recency = 10
                    elif year >= 2022:
                        recency = 7
                    else:
                        recency = 4
                except (ValueError, IndexError):
                    recency = 8
            recency *= 0.15
            
            item["_composite_score"] = relevance + quality + recency
        
        return sorted(items, key=lambda x: x.get("_composite_score", 0), reverse=True)
    
    def _dedupe_articles(self, articles: list) -> list:
        """Remove duplicate articles."""
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

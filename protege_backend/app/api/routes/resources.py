"""
Resource API Routes - Enhanced Version
Supports filtering and category selection.
"""
from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, Field
from typing import Optional, Literal, List
from app.config import settings

router = APIRouter()


class LessonResourcesRequest(BaseModel):
    """Request model with enhanced options."""
    topic: str = Field(..., description="Main topic")
    lesson_title: str = Field(..., description="Specific lesson title")
    key_concepts: Optional[List[str]] = Field(None, description="Key concepts to search")
    
    # Filtering options
    max_videos: Optional[int] = Field(3, ge=1, le=10)
    max_articles: Optional[int] = Field(4, ge=1, le=10)
    max_repos: Optional[int] = Field(3, ge=1, le=10)
    
    # GitHub options
    github_category: Optional[Literal[
        "trending", "most_starred", "recently_updated", "beginner_friendly"
    ]] = Field("beginner_friendly", description="GitHub repo category")
    programming_language: Optional[str] = Field(None, description="Filter repos by language")
    
    # Quality thresholds
    min_video_views: Optional[int] = Field(1000, description="Minimum video views")
    min_article_reactions: Optional[int] = Field(5, description="Minimum article reactions")
    min_repo_stars: Optional[int] = Field(10, description="Minimum repo stars")


@router.get("/health")
async def resources_health():
    return {"status": "enhanced resources routes healthy"}


@router.post("/curate")
@router.post("/curate-test")
async def curate_resources(request: LessonResourcesRequest):
    """
    Curate learning resources with AI-enhanced accuracy.
    
    Features:
    - AI-optimized search queries
    - Multi-strategy search per source
    - Relevance scoring and validation
    - GitHub category filtering (trending, most starred, etc.)
    - Programming language filtering
    """
    print(f"\n{'='*60}")
    print(f"[RESOURCES API] Enhanced curation request")
    print(f"[RESOURCES API] Topic: {request.topic}")
    print(f"[RESOURCES API] Lesson: {request.lesson_title}")
    print(f"[RESOURCES API] GitHub category: {request.github_category}")
    print(f"{'='*60}")
    
    try:
        # Import services
        from app.services.query_optimizer import QueryOptimizer
        from app.services.youtube_service import YouTubeService
        from app.services.github_service import GitHubService
        from app.services.devto_service import DevToService
        from app.services.wikipedia_service import WikipediaService
        from app.services.free_articles_service import FreeArticlesService
        from app.services.resource_curator import ResourceCurator
        
        # Initialize services using settings
        youtube_key = settings.YOUTUBE_API_KEY
        if not youtube_key:
            raise HTTPException(status_code=500, detail="YOUTUBE_API_KEY not configured")
        
        youtube = YouTubeService(api_key=youtube_key)
        
        github_token = settings.GITHUB_TOKEN
        github = GitHubService(token=github_token if github_token else None)
        
        devto = DevToService()
        wikipedia = WikipediaService()
        free_articles = FreeArticlesService()
        query_optimizer = QueryOptimizer()
        
        # Create enhanced curator
        curator = ResourceCurator(
            youtube_service=youtube,
            github_service=github,
            devto_service=devto,
            wikipedia_service=wikipedia,
            free_articles_service=free_articles,
            query_optimizer=query_optimizer
        )
        
        # Curate resources
        resources = await curator.curate_lesson_resources(
            topic=request.topic,
            lesson_title=request.lesson_title,
            key_concepts=request.key_concepts,
            max_videos=request.max_videos,
            max_articles=request.max_articles,
            max_repos=request.max_repos,
            github_category=request.github_category,
            language=request.programming_language
        )
        
        print(f"[RESOURCES API] Success: {resources['total_resources']} resources")
        
        return resources
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"[RESOURCES API] Error: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/github/categories")
async def get_github_categories():
    """Get available GitHub filtering categories."""
    return {
        "categories": [
            {
                "id": "beginner_friendly",
                "name": "Beginner Friendly",
                "description": "Repos with tutorials and examples for learners"
            },
            {
                "id": "trending",
                "name": "Trending",
                "description": "Popular repos from the last 30 days"
            },
            {
                "id": "most_starred",
                "name": "Most Starred",
                "description": "Top starred repositories"
            },
            {
                "id": "recently_updated",
                "name": "Recently Updated",
                "description": "Actively maintained repositories"
            }
        ]
    }


@router.get("/test-accuracy")
async def test_accuracy(
    topic: str = Query("Python"),
    lesson: str = Query("Understanding Variables")
):
    """
    Test the accuracy of resource curation for a topic.
    Returns detailed debug information.
    """
    from app.services.query_optimizer import QueryOptimizer
    from app.services.wikipedia_service import WikipediaService
    from app.services.github_service import GitHubService
    from app.services.devto_service import DevToService
    
    results = {}
    
    # Test query optimization
    optimizer = QueryOptimizer()
    queries = await optimizer.generate_optimized_queries(
        topic=topic,
        lesson_title=lesson,
        key_concepts=["variables", "data types", "assignment"]
    )
    results["optimized_queries"] = queries
    
    # Test Wikipedia
    wiki = WikipediaService()
    wiki_result = await wiki.get_summary(
        topic=queries.get("wikipedia", lesson),
        fallback_term=queries.get("wikipedia_fallback", topic),
        key_terms=queries.get("key_terms", [])
    )
    results["wikipedia"] = {
        "found": wiki_result is not None,
        "title": wiki_result.get("title") if wiki_result else None,
        "extract_preview": wiki_result.get("extract", "")[:200] if wiki_result else None
    }
    
    # Test GitHub categories
    github_token = settings.GITHUB_TOKEN
    github = GitHubService(token=github_token if github_token else None)
    
    for category in ["beginner_friendly", "most_starred", "trending"]:
        repos = await github.search_by_category(
            query=queries.get("github", f"{topic} tutorial"),
            category=category,
            max_results=2
        )
        results[f"github_{category}"] = [
            {
                "name": r.get("full_name"),
                "stars": r.get("stars"),
                "relevance": r.get("relevance_score")
            }
            for r in repos
        ]
    
    # Test Dev.to
    devto = DevToService()
    articles = await devto.search_articles(
        query=queries.get("devto", topic),
        max_results=3
    )
    results["devto"] = [
        {
            "title": a.get("title"),
            "reactions": a.get("reactions"),
            "relevance": a.get("relevance_score")
        }
        for a in articles
    ]
    
    return results

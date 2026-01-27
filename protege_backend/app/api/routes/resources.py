"""
Resource API Routes
Endpoints for fetching curated lesson resources.
"""
from fastapi import APIRouter, HTTPException, Query, Request
from pydantic import BaseModel
from typing import Optional
import os

router = APIRouter()


class LessonResourcesRequest(BaseModel):
    lesson_title: str
    search_queries: dict
    max_videos: Optional[int] = 3
    max_articles: Optional[int] = 4
    max_repos: Optional[int] = 2


@router.get("/health")
async def resources_health():
    """Health check for resources routes."""
    return {"status": "resources routes healthy"}


@router.post("/curate", response_model=None)
async def curate_resources(
    body: LessonResourcesRequest,
    request: Request,
):
    """
    Curate learning resources for a lesson from multiple sources.
    Uses the singleton ResourceCurator initialized in main.py.
    """
    print(f"\n[RESOURCES API] ════════════════════════════════════════")
    print(f"[RESOURCES API] Curating for: {body.lesson_title}")
    
    try:
        # Get curator from app state
        curator = request.app.state.resource_curator
        
        # Curate resources
        resources = await curator.curate_lesson_resources(
            lesson_title=body.lesson_title,
            search_queries=body.search_queries,
            max_videos=body.max_videos,
            max_articles=body.max_articles,
            max_repos=body.max_repos
        )
        
        print(f"[RESOURCES API] ════════════════════════════════════════")
        print(f"[RESOURCES API] SUCCESS - {resources['total_resources']} resources")
        print(f"[RESOURCES API] ════════════════════════════════════════\n")
        
        return resources
        
    except Exception as e:
        print(f"[RESOURCES API] ERROR: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Failed to curate resources: {str(e)}")


@router.post("/curate-test")
async def curate_resources_test(
    body: LessonResourcesRequest,
    request: Request
):
    """
    TEST ENDPOINT - Wrapper for /curate
    """
    return await curate_resources(body, request)


@router.get("/test-all-services")
async def test_all_services():
    """
    Test all resource services and return their status.
    Useful for debugging which services work.
    """
    results = {}
    
    # Test YouTube
    try:
        from app.services.youtube_service import YouTubeService
        youtube_key = os.getenv("YOUTUBE_API_KEY")
        if youtube_key:
            service = YouTubeService(api_key=youtube_key)
            videos = await service.search_videos("python tutorial", max_results=1)
            results["youtube"] = {"status": "OK", "count": len(videos)}
        else:
            results["youtube"] = {"status": "NO_KEY"}
    except Exception as e:
        results["youtube"] = {"status": "ERROR", "error": str(e)[:100]}
    
    # Test GitHub
    try:
        from app.services.github_service import GitHubService
        github_token = os.getenv("GITHUB_TOKEN")
        service = GitHubService(token=github_token)
        repos = await service.search_repositories("python tutorial", max_results=1)
        results["github"] = {"status": "OK", "count": len(repos)}
    except Exception as e:
        results["github"] = {"status": "ERROR", "error": str(e)[:100]}
    
    # Test Dev.to
    try:
        from app.services.devto_service import DevToService
        service = DevToService()
        articles = await service.search_articles("python", max_results=1)
        results["devto"] = {"status": "OK", "count": len(articles)}
    except Exception as e:
        results["devto"] = {"status": "ERROR", "error": str(e)[:100]}
    
    # Test Free Articles
    try:
        from app.services.free_articles_service import FreeArticlesService
        service = FreeArticlesService()
        articles = await service.search_articles("python", max_results=1)
        results["free_articles"] = {"status": "OK", "count": len(articles)}
    except Exception as e:
        results["free_articles"] = {"status": "ERROR", "error": str(e)[:100]}
    
    # Test Wikipedia
    try:
        from app.services.wikipedia_service import WikipediaService
        service = WikipediaService()
        summary = await service.get_summary("Python programming")
        results["wikipedia"] = {"status": "OK" if summary else "NO_RESULT"}
    except Exception as e:
        results["wikipedia"] = {"status": "ERROR", "error": str(e)[:100]}
    
    return {"services": results}

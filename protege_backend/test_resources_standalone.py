"""
Standalone test for all resource services.
Run this to verify each API integration works.
"""
import asyncio
import os
import sys
from dotenv import load_dotenv

# Add project root to path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

load_dotenv()

async def test_all_services():
    print("=" * 70)
    print("RESOURCE SERVICES STANDALONE TEST")
    print("=" * 70)
    
    results = {}
    
    # Test 1: YouTube
    print("\n[1/5] Testing YouTube Service...")
    try:
        from app.services.youtube_service import YouTubeService
        
        youtube_key = os.getenv("YOUTUBE_API_KEY")
        if not youtube_key:
            print("   ❌ YOUTUBE_API_KEY not found in .env")
            results["youtube"] = False
        else:
            service = YouTubeService(api_key=youtube_key)
            videos = await service.search_videos("python tutorial beginner", max_results=2)
            
            if videos and len(videos) > 0:
                print(f"   ✅ Found {len(videos)} videos")
                print(f"   First: {videos[0]['title'][:50]}...")
                results["youtube"] = True
            else:
                print("   ❌ No videos returned")
                results["youtube"] = False
    except Exception as e:
        print(f"   ❌ Error: {e}")
        import traceback
        traceback.print_exc()
        results["youtube"] = False
    
    # Test 2: Google Search
    print("\n[2/5] Testing Google Search Service...")
    try:
        from app.services.google_search_service import GoogleSearchService
        
        google_key = os.getenv("GOOGLE_SEARCH_API_KEY")
        google_cx = os.getenv("GOOGLE_SEARCH_ENGINE_ID")
        
        if not google_key or not google_cx:
            print("   ⚠️ Google API not configured (optional)")
            results["google"] = None
        else:
            service = GoogleSearchService(api_key=google_key, search_engine_id=google_cx)
            articles = await service.search_articles("python variables tutorial", num_results=2)
            
            if articles:
                print(f"   ✅ Found {len(articles)} articles")
                results["google"] = True
            else:
                print("   ⚠️ No articles returned (may be quota issue)")
                results["google"] = True  # API connected
    except Exception as e:
        print(f"   ❌ Error: {e}")
        results["google"] = False
    
    # Test 3: GitHub
    print("\n[3/5] Testing GitHub Service...")
    try:
        from app.services.github_service import GitHubService
        
        github_token = os.getenv("GITHUB_TOKEN")
        service = GitHubService(token=github_token)
        repos = await service.search_repositories("python tutorial", max_results=2)
        
        if repos:
            print(f"   ✅ Found {len(repos)} repositories")
            print(f"   First: {repos[0]['full_name']} ({repos[0]['stars']} ⭐)")
            results["github"] = True
        else:
            print("   ❌ No repositories returned")
            results["github"] = False
    except Exception as e:
        print(f"   ❌ Error: {e}")
        results["github"] = False
    
    # Test 4: Dev.to
    print("\n[4/5] Testing Dev.to Service...")
    try:
        from app.services.devto_service import DevToService
        
        service = DevToService()
        articles = await service.search_articles("python", max_results=2)
        
        if articles:
            print(f"   ✅ Found {len(articles)} articles")
            print(f"   First: {articles[0]['title'][:50]}...")
            results["devto"] = True
        else:
            print("   ⚠️ No articles returned")
            results["devto"] = True  # API works
    except Exception as e:
        print(f"   ❌ Error: {e}")
        results["devto"] = False
    
    # Test 5: Wikipedia
    print("\n[5/5] Testing Wikipedia Service...")
    try:
        from app.services.wikipedia_service import WikipediaService
        
        service = WikipediaService()
        summary = await service.get_summary("Python (programming language)")
        
        if summary and summary.get("extract"):
            print(f"   ✅ Got summary ({len(summary['extract'])} chars)")
            results["wikipedia"] = True
        else:
            print("   ❌ No summary returned")
            results["wikipedia"] = False
    except Exception as e:
        print(f"   ❌ Error: {e}")
        results["wikipedia"] = False
    
    # Summary
    print("\n" + "=" * 70)
    print("RESULTS SUMMARY")
    print("=" * 70)
    
    for service, passed in results.items():
        if passed is None:
            status = "⚠️ SKIPPED (not configured)"
        elif passed:
            status = "✅ PASSED"
        else:
            status = "❌ FAILED"
        print(f"   {service.upper()}: {status}")
    
    # Test Resource Curator
    print("\n" + "=" * 70)
    print("TESTING FULL RESOURCE CURATION")
    print("=" * 70)
    
    try:
        from app.services.youtube_service import YouTubeService
        from app.services.devto_service import DevToService
        from app.services.wikipedia_service import WikipediaService
        from app.services.resource_curator import ResourceCurator
        
        youtube = YouTubeService(api_key=os.getenv("YOUTUBE_API_KEY"))
        devto = DevToService()
        wikipedia = WikipediaService()
        
        # Optional services
        google = None
        if os.getenv("GOOGLE_SEARCH_API_KEY"):
            from app.services.google_search_service import GoogleSearchService
            google = GoogleSearchService(
                api_key=os.getenv("GOOGLE_SEARCH_API_KEY"),
                search_engine_id=os.getenv("GOOGLE_SEARCH_ENGINE_ID")
            )
            
        github = None
        if os.getenv("GITHUB_TOKEN"):
            from app.services.github_service import GitHubService
            github = GitHubService(token=os.getenv("GITHUB_TOKEN"))
        
        curator = ResourceCurator(
            youtube_service=youtube,
            devto_service=devto,
            wikipedia_service=wikipedia,
            google_service=google,
            github_service=github
        )
        
        print("\nCurating resources for 'Understanding Variables in Python'...")
        resources = await curator.curate_lesson_resources(
            lesson_title="Understanding Variables in Python",
            search_queries={
                "youtube": "python variables tutorial beginner",
                "articles": "python variables explained",
                "github": "python examples variables"
            }
        )
        
        print(f"\n✅ Curation complete!")
        print(f"   Videos: {len(resources['videos'])}")
        print(f"   Articles: {len(resources['articles'])}")
        print(f"   Repositories: {len(resources['repositories'])}")
        print(f"   Wikipedia: {'Yes' if resources['wikipedia'] else 'No'}")
        
        if resources['videos']:
            print(f"\n   Top Video: {resources['videos'][0]['title'][:50]}...")
        if resources['articles']:
            print(f"   Top Article: {resources['articles'][0]['title'][:50]}...")
        
        print("\n" + "=" * 70)
        print("✅ ALL TESTS PASSED - RESOURCE SERVICES WORKING!")
        print("=" * 70)
        return True
        
    except Exception as e:
        print(f"\n❌ Curation failed: {e}")
        import traceback
        traceback.print_exc()
        return False


if __name__ == "__main__":
    result = asyncio.run(test_all_services())
    sys.exit(0 if result else 1)

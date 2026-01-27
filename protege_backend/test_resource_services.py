"""
Diagnostic script to test each resource service individually.
Run this to identify which services work and which are broken.
"""
import asyncio
import os
from dotenv import load_dotenv

load_dotenv()

async def run_diagnostics():
    print("=" * 70)
    print("RESOURCE SERVICES DIAGNOSTIC")
    print("=" * 70)
    
    results = {}
    
    # ─────────────────────────────────────────────────────────────────────
    # TEST 1: YouTube (should work)
    # ─────────────────────────────────────────────────────────────────────
    print("\n[1/5] YOUTUBE SERVICE")
    print("-" * 40)
    
    youtube_key = os.getenv("YOUTUBE_API_KEY")
    if not youtube_key:
        print("   ❌ YOUTUBE_API_KEY not found in .env")
        results["youtube"] = {"status": "MISSING_KEY", "error": "No API key"}
    else:
        print(f"   API Key: {youtube_key[:15]}...")
        try:
            from app.services.youtube_service import YouTubeService
            service = YouTubeService(api_key=youtube_key)
            videos = await service.search_videos("python tutorial", max_results=2)
            
            if videos:
                print(f"   ✅ SUCCESS - Found {len(videos)} videos")
                print(f"   Sample: {videos[0].get('title', 'N/A')[:50]}...")
                results["youtube"] = {"status": "OK", "count": len(videos)}
            else:
                print("   ⚠️ No videos returned (but no error)")
                results["youtube"] = {"status": "EMPTY", "error": "No results"}
        except Exception as e:
            print(f"   ❌ ERROR: {e}")
            results["youtube"] = {"status": "ERROR", "error": str(e)}
    
    # ─────────────────────────────────────────────────────────────────────
    # TEST 2: Google Custom Search
    # ─────────────────────────────────────────────────────────────────────
    print("\n[2/5] GOOGLE CUSTOM SEARCH SERVICE")
    print("-" * 40)
    
    google_key = os.getenv("GOOGLE_SEARCH_API_KEY")
    google_cx = os.getenv("GOOGLE_SEARCH_ENGINE_ID")
    
    if not google_key:
        print("   ❌ GOOGLE_SEARCH_API_KEY not found")
        results["google"] = {"status": "MISSING_KEY", "error": "No API key"}
    elif not google_cx:
        print("   ❌ GOOGLE_SEARCH_ENGINE_ID not found")
        results["google"] = {"status": "MISSING_CX", "error": "No search engine ID"}
    else:
        print(f"   API Key: {google_key[:15]}...")
        print(f"   Engine ID: {google_cx[:15]}...")
        try:
            from app.services.google_search_service import GoogleSearchService
            service = GoogleSearchService(api_key=google_key, search_engine_id=google_cx)
            articles = await service.search_articles("python variables tutorial", num_results=2)
            
            if articles:
                print(f"   ✅ SUCCESS - Found {len(articles)} articles")
                results["google"] = {"status": "OK", "count": len(articles)}
            else:
                print("   ⚠️ No articles returned")
                results["google"] = {"status": "EMPTY", "error": "No results"}
        except Exception as e:
            error_str = str(e)
            print(f"   ❌ ERROR: {error_str[:100]}")
            
            if "403" in error_str or "forbidden" in error_str.lower():
                print("   → This is a PERMISSION error. API may not be enabled or restricted.")
            elif "429" in error_str or "quota" in error_str.lower():
                print("   → This is a QUOTA error. Daily limit exceeded.")
            elif "400" in error_str:
                print("   → This is a BAD REQUEST. Check search engine ID.")
            
            results["google"] = {"status": "ERROR", "error": error_str[:100]}
    
    # ─────────────────────────────────────────────────────────────────────
    # TEST 3: GitHub
    # ─────────────────────────────────────────────────────────────────────
    print("\n[3/5] GITHUB SERVICE")
    print("-" * 40)
    
    github_token = os.getenv("GITHUB_TOKEN")
    print(f"   Token: {'Present' if github_token else 'Not set (will use unauthenticated)'}")
    
    try:
        from app.services.github_service import GitHubService
        service = GitHubService(token=github_token)
        repos = await service.search_repositories("python tutorial beginner", max_results=2)
        
        if repos:
            print(f"   ✅ SUCCESS - Found {len(repos)} repositories")
            print(f"   Sample: {repos[0].get('full_name', 'N/A')} ({repos[0].get('stars', 0)} ⭐)")
            results["github"] = {"status": "OK", "count": len(repos)}
        else:
            print("   ⚠️ No repos returned")
            results["github"] = {"status": "EMPTY", "error": "No results"}
    except FileNotFoundError:
        print("   ❌ GitHubService not found - file missing")
        results["github"] = {"status": "MISSING_FILE", "error": "Service file not found"}
    except Exception as e:
        print(f"   ❌ ERROR: {e}")
        results["github"] = {"status": "ERROR", "error": str(e)}
    
    # ─────────────────────────────────────────────────────────────────────
    # TEST 4: Dev.to
    # ─────────────────────────────────────────────────────────────────────
    print("\n[4/5] DEV.TO SERVICE")
    print("-" * 40)
    print("   (No API key required)")
    
    try:
        from app.services.devto_service import DevToService
        service = DevToService()
        articles = await service.search_articles("python", max_results=2)
        
        if articles:
            print(f"   ✅ SUCCESS - Found {len(articles)} articles")
            print(f"   Sample: {articles[0].get('title', 'N/A')[:50]}...")
            results["devto"] = {"status": "OK", "count": len(articles)}
        else:
            print("   ⚠️ No articles returned")
            results["devto"] = {"status": "EMPTY", "error": "No results"}
    except FileNotFoundError:
        print("   ❌ DevToService not found - file missing")
        results["devto"] = {"status": "MISSING_FILE", "error": "Service file not found"}
    except Exception as e:
        print(f"   ❌ ERROR: {e}")
        results["devto"] = {"status": "ERROR", "error": str(e)}
    
    # ─────────────────────────────────────────────────────────────────────
    # TEST 5: Wikipedia
    # ─────────────────────────────────────────────────────────────────────
    print("\n[5/5] WIKIPEDIA SERVICE")
    print("-" * 40)
    print("   (No API key required)")
    
    try:
        from app.services.wikipedia_service import WikipediaService
        service = WikipediaService()
        summary = await service.get_summary("Python programming language")
        
        if summary and summary.get("extract"):
            print(f"   ✅ SUCCESS - Got summary ({len(summary['extract'])} chars)")
            results["wikipedia"] = {"status": "OK", "chars": len(summary["extract"])}
        else:
            print("   ⚠️ No summary returned")
            results["wikipedia"] = {"status": "EMPTY", "error": "No results"}
    except FileNotFoundError:
        print("   ❌ WikipediaService not found - file missing")
        results["wikipedia"] = {"status": "MISSING_FILE", "error": "Service file not found"}
    except Exception as e:
        print(f"   ❌ ERROR: {e}")
        results["wikipedia"] = {"status": "ERROR", "error": str(e)}
    
    # ─────────────────────────────────────────────────────────────────────
    # SUMMARY
    # ─────────────────────────────────────────────────────────────────────
    print("\n" + "=" * 70)
    print("DIAGNOSTIC SUMMARY")
    print("=" * 70)
    
    for service, result in results.items():
        status = result["status"]
        if status == "OK":
            print(f"   ✅ {service.upper()}: Working")
        elif status == "MISSING_FILE":
            print(f"   📁 {service.upper()}: Service file missing - needs to be created")
        elif status == "MISSING_KEY":
            print(f"   🔑 {service.upper()}: API key missing - check .env file")
        elif status == "EMPTY":
            print(f"   ⚠️ {service.upper()}: No results returned - may need query adjustment")
        else:
            print(f"   ❌ {service.upper()}: Error - {result.get('error', 'Unknown')[:50]}")
    
    print("\n" + "=" * 70)
    
    # Determine what needs fixing
    needs_creation = [s for s, r in results.items() if r["status"] == "MISSING_FILE"]
    needs_fix = [s for s, r in results.items() if r["status"] == "ERROR"]
    needs_alternative = []
    
    if results.get("google", {}).get("status") == "ERROR":
        needs_alternative.append("google")
    
    if needs_creation:
        print(f"\n📁 SERVICES TO CREATE: {', '.join(needs_creation)}")
    if needs_fix:
        print(f"\n🔧 SERVICES TO FIX: {', '.join(needs_fix)}")
    if needs_alternative:
        print(f"\n🔄 NEED ALTERNATIVES FOR: {', '.join(needs_alternative)}")
    
    return results


if __name__ == "__main__":
    asyncio.run(run_diagnostics())

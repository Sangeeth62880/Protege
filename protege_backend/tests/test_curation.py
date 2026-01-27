import asyncio
import os
import sys

# Add project root to path
sys.path.append(os.getcwd())

from app.services.firebase_service import FirebaseService
from app.services.youtube_service import YouTubeService
from app.services.github_service import GitHubService
from app.services.devto_service import DevToService
from app.services.resource_curator import ResourceCurator
from app.config import settings

async def main():
    print(f"🔧 Testing Resource Curator...")
    
    # Setup dependencies manually for test
    firebase = FirebaseService()
    
    youtube = YouTubeService(settings.YOUTUBE_API_KEY, firebase) if settings.YOUTUBE_API_KEY else None
    # Google skipped if not configured or 403, Curator handles None
    
    curator = ResourceCurator(
        youtube_service=youtube,
        google_service=None # Skip Google for now due to 403
    )
    
    query = "FastAPI middleware tutorial"
    print(f"🔍 Curating resources for: {query}")
    
    try:
        resources = await curator.search(query, limit=10)
        
        if not resources:
            print("⚠️ No resources found.")
        else:
            print(f"✅ Found {len(resources)} resources from mixed sources:\n")
            
            # Group by source for clarity
            by_source = {}
            for r in resources:
                s = r.get("source", "unknown")
                if s not in by_source: by_source[s] = []
                by_source[s].append(r)
            
            for source, items in by_source.items():
                print(f"--- {source.upper()} ({len(items)}) ---")
                for item in items:
                    title = item.get("title")
                    url = item.get("url") or item.get("link")
                    print(f"- {title} [{url[:50]}...]")
                print("")
                
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(main())

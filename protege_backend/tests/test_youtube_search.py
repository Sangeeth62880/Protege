import asyncio
import os
import sys

# Add project root to path
sys.path.append(os.getcwd())

from app.services.youtube_service import YouTubeService
from app.services.firebase_service import FirebaseService
from app.config import settings

async def main():
    print(f"🔧 Testing YouTube Integration...")
    
    if not settings.YOUTUBE_API_KEY:
        print("❌ Error: YOUTUBE_API_KEY not set in .env")
        return
        
    print("🔥 Initializing Firebase (for caching)...")
    firebase_service = FirebaseService()
    
    print("📺 Initializing YouTube Service...")
    service = YouTubeService(
        api_key=settings.YOUTUBE_API_KEY,
        firebase_service=firebase_service
    )
    
    query = "Flutter Riverpod Tutorial"
    print(f"🔍 Searching for: {query}")
    
    try:
        videos = await service.search_videos(query, max_results=3, difficulty="beginner")
        
        if not videos:
            print("⚠️ No videos found or API error.")
        else:
            print(f"✅ Found {len(videos)} videos:\n")
            for v in videos:
                print(f"Title: {v.title}")
                print(f"Channel: {v.channel_name}")
                print(f"Duration: {v.duration_minutes} mins")
                print(f"URL: {v.url}")
                print("-" * 30)
                
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(main())

import asyncio
import os
import sys

# Add project root to path
sys.path.append(os.getcwd())

from app.services.google_search_service import GoogleSearchService
from app.services.firebase_service import FirebaseService
from app.config import settings

async def main():
    print(f"🔧 Testing Google Search Integration...")
    
    if not settings.GOOGLE_SEARCH_API_KEY or not settings.GOOGLE_SEARCH_ENGINE_ID:
        print("❌ Error: API Key or Engine ID not set in .env")
        return
        
    print("🔥 Initializing Firebase...")
    firebase_service = FirebaseService()
    
    print("🌍 Initializing Google Search Service...")
    service = GoogleSearchService(
        api_key=settings.GOOGLE_SEARCH_API_KEY,
        search_engine_id=settings.GOOGLE_SEARCH_ENGINE_ID,
        firebase_service=firebase_service
    )
    
    query = "Riverpod state management best practices"
    print(f"🔍 Searching for: {query}")
    
    try:
        articles = await service.search_articles(query, num_results=3, difficulty="intermediate")
        
        if not articles:
            print("⚠️ No articles found or API error.")
        else:
            print(f"✅ Found {len(articles)} articles:\n")
            for a in articles:
                print(f"Title: {a.title}")
                print(f"Domain: {a.source_domain}")
                print(f"Link: {a.link}")
                print(f"Snippet: {a.snippet}")
                print("-" * 30)
                
    except Exception as e:
        print(f"❌ Error: {e}")
        if hasattr(e, "response"):
            print(f"🔍 Response Body: {e.response.text}")
        # import traceback
        # traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(main())

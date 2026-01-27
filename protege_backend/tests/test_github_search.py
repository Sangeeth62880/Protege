import asyncio
import os
import sys

# Add project root to path
sys.path.append(os.getcwd())

from app.services.github_service import GitHubService
from app.config import settings

async def main():
    print(f"🔧 Testing GitHub Integration...")
    
    if not settings.GITHUB_TOKEN:
        print("⚠️ Warning: GITHUB_TOKEN not set. Service may use mock data or limited rate.")
    
    service = GitHubService()
    
    query = "fastapi-starter"
    print(f"🔍 Searching for: {query}")
    
    try:
        repos = await service.search(query, limit=3)
        
        if not repos:
            print("⚠️ No repositories found.")
        else:
            print(f"✅ Found {len(repos)} repositories:\n")
            for r in repos:
                print(f"Title: {r['title']}")
                print(f"Desc: {r['description']}")
                print(f"URL: {r['url']}")
                print(f"Stars: {r['rating']}")
                print("-" * 30)
                
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(main())

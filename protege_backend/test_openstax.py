import asyncio
from app.services.openstax_service import OpenStaxService
from app.services.resource_curator import ResourceCurator
import time

async def test():
    service = OpenStaxService()
    print("Fetching catalog...")
    await service._fetch_catalog()
    
    # Test specific topic mapping
    topic = "Physics"
    lesson = "Newton's First Law"
    
    print(f"\nSearching for {topic} - {lesson}...")
    results = await service.search_textbooks(topic, lesson)
    
    for r in results:
        print(f"\nTitle: {r['title']}")
        print(f"Slug: {r['slug']}")
        print(f"Deep Link: {r['deep_link']}")
        print(f"Relevance: {r['relevance_score']}")

if __name__ == "__main__":
    asyncio.run(test())
    

print("Testing Phase 2 imports...")

try:
    from app.services.groq_service import GroqService
    print("✅ GroqService imported")
except Exception as e:
    print(f"❌ GroqService failed: {e}")

try:
    from app.services.youtube_service import YouTubeService
    print("✅ YouTubeService imported")
except Exception as e:
    print(f"❌ YouTubeService failed: {e}")

try:
    from app.services.google_search_service import GoogleSearchService
    print("✅ GoogleSearchService imported")
except Exception as e:
    print(f"❌ GoogleSearchService failed: {e}")

try:
    from app.services.github_service import GitHubService
    print("✅ GitHubService imported")
except Exception as e:
    print(f"❌ GitHubService failed: {e}")

try:
    from app.services.devto_service import DevToService
    print("✅ DevToService imported")
except Exception as e:
    print(f"❌ DevToService failed: {e}")

try:
    from app.services.wikipedia_service import WikipediaService
    print("✅ WikipediaService imported")
except Exception as e:
    print(f"❌ WikipediaService failed: {e}")

try:
    from app.services.syllabus_generator import SyllabusGenerator
    print("✅ SyllabusGenerator imported")
except Exception as e:
    print(f"❌ SyllabusGenerator failed: {e}")

try:
    from app.services.resource_curator import ResourceCurator
    print("✅ ResourceCurator imported")
except Exception as e:
    print(f"❌ ResourceCurator failed: {e}")

try:
    from app.api.routes.learning import router as learning_router
    print("✅ Learning router imported")
except Exception as e:
    print(f"❌ Learning router failed: {e}")

try:
    from app.api.routes.resources import router as resources_router
    print("✅ Resources router imported")
except Exception as e:
    print(f"❌ Resources router failed: {e}")

try:
    from app.models.learning_path import LearningPathCreate, LearningPath, Lesson, Syllabus
    print("✅ Learning path models imported")
except Exception as e:
    print(f"❌ Learning path models failed: {e}")

try:
    from app.models.resource import ResourceResponse, VideoResource, ArticleResource
    print("✅ Resource models imported")
except Exception as e:
    print(f"❌ Resource models failed: {e}")

print("\nImport test complete!")

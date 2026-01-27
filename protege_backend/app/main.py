"""
Protégé Backend - FastAPI Application
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings

from app.api.routes.auth import router as auth_router
from app.api.routes.learning import router as learning_router
from app.api.routes.tutor import router as tutor_router
from app.api.routes.resources import router as resources_router
from app.api.routes.ai import router as ai_router
from app.api.routes.quiz import router as quiz_router
from app.api.routes.teaching import router as teaching_router

# Create FastAPI app
app = FastAPI(
    title="Protégé API",
    description="AI-powered learning companion backend",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

@app.on_event("startup")
async def startup_event():
    """Initialize services on startup"""
    from app.services.groq_service import GroqService
    from app.services.firebase_service import FirebaseService
    from app.services.youtube_service import YouTubeService
    
    # Initialize services
    app.state.groq_service = GroqService(api_key=settings.GROQ_API_KEY)
    
    # Initialize Firebase & Dependencies
    firebase_service = FirebaseService()
    app.state.firebase_service = firebase_service
    
    if settings.YOUTUBE_API_KEY:
        app.state.youtube_service = YouTubeService(
            api_key=settings.YOUTUBE_API_KEY
        )
    else:
        print("⚠️ YouTube API Key not found. YouTube Service disabled.")
        app.state.youtube_service = None

    if settings.GOOGLE_SEARCH_API_KEY and settings.GOOGLE_SEARCH_ENGINE_ID:
        from app.services.google_search_service import GoogleSearchService
        app.state.google_search_service = GoogleSearchService(
            api_key=settings.GOOGLE_SEARCH_API_KEY,
            search_engine_id=settings.GOOGLE_SEARCH_ENGINE_ID,
            cache_service=firebase_service
        )
    else:
        app.state.google_search_service = None

    # Initialize Resource Services
    from app.services.github_service import GitHubService
    from app.services.devto_service import DevToService
    from app.services.wikipedia_service import WikipediaService
    from app.services.free_articles_service import FreeArticlesService

    github_token = settings.GITHUB_TOKEN if hasattr(settings, "GITHUB_TOKEN") else None
    
    app.state.github_service = GitHubService(token=github_token)
    app.state.devto_service = DevToService()
    app.state.wikipedia_service = WikipediaService()
    app.state.free_articles_service = FreeArticlesService()

    # Initialize Resource Curator
    from app.services.resource_curator import ResourceCurator
    app.state.resource_curator = ResourceCurator(
        youtube_service=app.state.youtube_service,
        github_service=app.state.github_service,
        devto_service=app.state.devto_service,
        wikipedia_service=app.state.wikipedia_service,
        free_articles_service=app.state.free_articles_service
    )
    # Initialize Tutor Service
    from app.services.tutor_service import TutorService
    app.state.tutor_service = TutorService(app.state.groq_service)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth_router, prefix="/api/v1/auth", tags=["Authentication"])
app.include_router(learning_router, prefix="/api/v1/learning", tags=["Learning"])
app.include_router(resources_router, prefix="/api/v1/resources", tags=["Resources"])
app.include_router(ai_router, prefix="/api/v1/ai", tags=["AI"])
app.include_router(quiz_router, prefix="/api/v1/quiz", tags=["Quiz"])
app.include_router(teaching_router, prefix="/api/v1/teaching", tags=["Teaching"])


# Tutor Routes
app.include_router(
    tutor_router,
    prefix="/api/v1/tutor",
    tags=["Tutor"]
)


@app.get("/")
async def root():
    """Root endpoint"""
    return {"message": "Welcome to Protégé API", "version": "1.0.0"}


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy"}

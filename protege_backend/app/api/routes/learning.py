from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel
from typing import Dict, List, Optional
import uuid
from datetime import datetime

from app.api.dependencies import get_current_user
from app.services.syllabus_generator import SyllabusGenerator
from app.models.learning_path import (
    LearningPath, 
    Lesson, 
    Syllabus, 
    GenerateSyllabusRequest,
    DifficultyLevel
)

router = APIRouter()

@router.post("/generate-syllabus-test", response_model=Syllabus)
async def generate_syllabus_test(
    request: Request,
    body: GenerateSyllabusRequest,
):
    """TEST ENDPOINT - No auth required"""
    try:
        print(f"DEBUG_SYLLABUS: Received request for topic: {body.topic}")
        # Get Groq Service from app state
        if not hasattr(request.app.state, "groq_service"):
             print("DEBUG_SYLLABUS: Groq Service unavailable")
             raise HTTPException(status_code=503, detail="AI Service unavailable")
        
        groq_service = request.app.state.groq_service
        syllabus_generator = SyllabusGenerator(groq_service)
        
        # Generate syllabus
        print("DEBUG_SYLLABUS: Calling generator...")
        syllabus = await syllabus_generator.generate_syllabus(
            topic=body.topic,
            goal=body.goal,
            experience_level=body.experience_level,
            daily_time_minutes=body.daily_time_minutes,
        )
        print("DEBUG_SYLLABUS: Generation successful")
        
        return syllabus
        
    except Exception as e:
        import logging
        logging.error(f"Test Generation failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/generate", response_model=Syllabus)
async def generate_learning_path(
    request: Request,
    body: GenerateSyllabusRequest,
    # user: dict = Depends(get_current_user), # Disabled for easier testing temporarily if needed, but best to keep
    user: dict = Depends(get_current_user),
):
    """Generate an AI-powered learning path syllabus"""
    try:
        # Get Groq Service from app state
        if not hasattr(request.app.state, "groq_service"):
             raise HTTPException(status_code=503, detail="AI Service unavailable")
        
        groq_service = request.app.state.groq_service
        syllabus_generator = SyllabusGenerator(groq_service)
        
        # Generate syllabus
        syllabus = await syllabus_generator.generate_syllabus(
            topic=body.topic,
            goal=body.goal,
            experience_level=body.experience_level,
            daily_time_minutes=body.daily_time_minutes,
        )
        
        return syllabus
        
    except Exception as e:
        import logging
        logging.error(f"Generation failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/save", response_model=Dict[str, str])
async def save_learning_path(
    request: Request,
    syllabus: Syllabus,
    user: dict = Depends(get_current_user),
):
    """Save a generated syllabus as a learning path"""
    try:
        firebase = request.app.state.firebase_service
        path_id = str(uuid.uuid4())
        
        # Convert Syllabus to LearningPath
        learning_path = LearningPath(
            **syllabus.model_dump(),
            _id=path_id,
            user_id=user["uid"],
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
            progress=0.0,
            is_active=True
        )
        
        # Fix: Helper to convert datetime to ISO string for Firestore (or let SDK handle it)
        # Pydantic model_dump with mode='json' converts datetime to string
        data = learning_path.model_dump(mode="json", by_alias=True)
        # Firestore uses 'id' usually, but we keep _id in model aliases
        data["id"] = path_id 
        
        # Save to Firestore
        await firebase.create_document("learning_paths", path_id, data)
        
        return {"id": path_id, "status": "saved"}
        
    except Exception as e:
        logger.error(f"Failed to save learning path: {e}")
        raise HTTPException(status_code=500, detail="Failed to save learning path")

@router.post("/save-test", response_model=Dict[str, str])
async def save_learning_path_test(
    request: Request,
    syllabus: Syllabus,
):
    """TEST ENDPOINT - Save syllabus without auth (for development)"""
    try:
        print(f"[SAVE-TEST] Saving syllabus: {syllabus.topic}")
        firebase = request.app.state.firebase_service
        path_id = str(uuid.uuid4())
        
        # Use a test user ID for development
        test_user_id = "test-user-development"
        
        # Convert Syllabus to LearningPath
        learning_path = LearningPath(
            **syllabus.model_dump(),
            _id=path_id,
            user_id=test_user_id,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
            progress=0.0,
            is_active=True
        )
        
        data = learning_path.model_dump(mode="json", by_alias=True)
        data["id"] = path_id 
        
        # Save to Firestore
        await firebase.create_document("learning_paths", path_id, data)
        
        print(f"[SAVE-TEST] Saved with ID: {path_id}")
        return {"id": path_id, "status": "saved"}
        
    except Exception as e:
        import logging
        logging.error(f"[SAVE-TEST] Failed: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to save: {str(e)}")

@router.get("/paths", response_model=Dict[str, List[Dict]])
async def get_user_paths(
    request: Request,
    user: dict = Depends(get_current_user)
):
    """Get all learning paths for the current user"""
    try:
        firebase = request.app.state.firebase_service
        # Query paths where user_id == user['uid']
        paths = await firebase.query_collection(
            "learning_paths", 
            "user_id", 
            "==", 
            user["uid"]
        )
        return {"paths": paths}
    except Exception as e:
        logger.error(f"Failed to fetch paths: {e}")
        return {"paths": []}

@router.get("/paths/{path_id}", response_model=LearningPath)
async def get_path(
    request: Request,
    path_id: str, 
    user: dict = Depends(get_current_user)
):
    """Get a specific learning path"""
    try:
        firebase = request.app.state.firebase_service
        data = await firebase.get_document("learning_paths", path_id)
        
        if not data:
            raise HTTPException(status_code=404, detail="Learning path not found")
            
        if data.get("user_id") != user["uid"]:
             raise HTTPException(status_code=403, detail="Access denied")
             
        return LearningPath(**data)
        
    except HTTPException as e:
        raise e
    except Exception as e:
        logger.error(f"Error fetching path {path_id}: {e}")
        raise HTTPException(status_code=500, detail="Error fetching path")


# ─── Lesson Content Generation ────────────────────────────────────────────

class LessonContentRequest(BaseModel):
    topic: str
    module_title: str
    lesson_title: str
    lesson_description: str = ""
    key_concepts: List[str] = []
    difficulty: str = "beginner"
    path_id: str = ""
    module_number: int = 0
    lesson_number: int = 0


@router.post("/lesson-content")
async def generate_lesson_content(
    request: Request,
    body: LessonContentRequest,
):
    """Generate AI lesson content. Caches result in Firestore."""
    import logging
    logger = logging.getLogger(__name__)

    try:
        if not hasattr(request.app.state, "groq_service"):
            raise HTTPException(status_code=503, detail="AI Service unavailable")

        firebase = request.app.state.firebase_service
        cache_key = f"{body.module_number}_{body.lesson_number}"

        # Check Firestore cache first
        if body.path_id:
            try:
                cached = await firebase.get_document(
                    f"learning_paths/{body.path_id}/lesson_content", cache_key
                )
                if cached and cached.get("introduction"):
                    logger.info(f"Lesson content cache HIT: {cache_key}")
                    return cached
            except Exception:
                pass  # Cache miss, generate fresh

        # Generate new content
        from app.services.lesson_content_generator import LessonContentGenerator

        groq_service = request.app.state.groq_service
        generator = LessonContentGenerator(groq_service)

        content = await generator.generate_lesson_content(
            topic=body.topic,
            module_title=body.module_title,
            lesson_title=body.lesson_title,
            lesson_description=body.lesson_description,
            key_concepts=body.key_concepts,
            difficulty=body.difficulty,
        )

        # Cache in Firestore
        if body.path_id:
            try:
                content["_cached_at"] = datetime.utcnow().isoformat()
                await firebase.create_document(
                    f"learning_paths/{body.path_id}/lesson_content",
                    cache_key,
                    content,
                )
                logger.info(f"Cached lesson content: {cache_key}")
            except Exception as e:
                logger.warning(f"Failed to cache lesson content: {e}")

        return content

    except HTTPException:
        raise
    except Exception as e:
        import logging
        logging.error(f"Lesson content generation failed: {e}")
        raise HTTPException(status_code=500, detail=f"Generation failed: {str(e)}")


# ─── Lesson Completion ────────────────────────────────────────────────────

class CompleteLessonRequest(BaseModel):
    path_id: str
    module_number: int
    lesson_number: int
    user_id: str


@router.post("/complete-lesson")
async def complete_lesson(
    request: Request,
    body: CompleteLessonRequest,
):
    """Mark a lesson as completed, recalculate progress, update user stats."""
    import logging
    logger = logging.getLogger(__name__)

    try:
        firebase = request.app.state.firebase_service

        # 1. Get the learning path
        path_data = await firebase.get_document("learning_paths", body.path_id)
        if not path_data:
            raise HTTPException(status_code=404, detail="Learning path not found")

        # 2. Update completion in the modules array
        modules = path_data.get("modules", [])
        total_lessons = 0
        completed_lessons = 0
        lesson_title = ""

        for module in modules:
            mod_num = module.get("module_number", 0)
            for lesson in module.get("lessons", []):
                total_lessons += 1
                les_num = lesson.get("lesson_number", 0)
                if mod_num == body.module_number and les_num == body.lesson_number:
                    if lesson.get("completed", False):
                        # Already completed — return early
                        return {"status": "already_completed", "progress": path_data.get("progress", 0)}
                    lesson["completed"] = True
                    lesson_title = lesson.get("title", "Unknown")
                if lesson.get("completed", False):
                    completed_lessons += 1

            # Recalculate module completion
            mod_lessons = module.get("lessons", [])
            module["completed"] = all(l.get("completed", False) for l in mod_lessons)

        # 3. Recalculate overall progress
        progress = completed_lessons / total_lessons if total_lessons > 0 else 0.0
        is_completed = completed_lessons == total_lessons

        # 4. Update learning path in Firestore
        await firebase.update_document("learning_paths", body.path_id, {
            "modules": modules,
            "progress": progress,
            "is_completed": is_completed,
            "updated_at": datetime.utcnow().isoformat(),
        })

        # 5. Update user stats
        try:
            user_data = await firebase.get_document("users", body.user_id)
            if user_data:
                current_completed = user_data.get("lessonsCompleted", 0)
                current_xp = user_data.get("totalXp", 0)
                await firebase.update_document("users", body.user_id, {
                    "lessonsCompleted": current_completed + 1,
                    "totalXp": current_xp + 50,
                    "lastActivityAt": datetime.utcnow().isoformat(),
                })
        except Exception as e:
            logger.warning(f"Failed to update user stats: {e}")

        logger.info(
            f"Lesson completed: {lesson_title} "
            f"(module {body.module_number}, lesson {body.lesson_number}) "
            f"Progress: {progress:.0%}"
        )

        return {
            "status": "completed",
            "progress": progress,
            "completed_lessons": completed_lessons,
            "total_lessons": total_lessons,
            "xp_earned": 50,
            "lesson_title": lesson_title,
        }

    except HTTPException:
        raise
    except Exception as e:
        import logging
        logging.error(f"Complete lesson failed: {e}")
        raise HTTPException(status_code=500, detail=f"Failed: {str(e)}")


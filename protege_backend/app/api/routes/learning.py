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
    """
    TEST ENDPOINT - No auth required
    """
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

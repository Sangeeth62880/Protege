"""
Quiz API Routes
"""
from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from pydantic import BaseModel
from typing import List, Optional, Dict
import uuid
import time

from app.services.quiz_generator import QuizGenerator
from app.services.groq_service import GroqService
from app.services.firebase_service import FirebaseService
from app.models.quiz import Quiz, QuizResult, QuestionType
from app.config import settings

router = APIRouter()

# --- Request Models ---

class QuizGenerationRequest(BaseModel):
    topic: str
    lesson_title: str
    key_concepts: List[str]
    difficulty: str = "mixed"
    num_questions: int = 5
    question_types: Optional[List[QuestionType]] = None
    lesson_id: Optional[str] = None

class QuizSubmissionRequest(BaseModel):
    quiz_id: str
    answers: Dict[int, str] # question_number -> answer
    time_taken_seconds: int

# --- Dependencies ---

def get_quiz_generator():
    # Initialize GroqService with API key from settings
    groq_service = GroqService(api_key=settings.GROQ_API_KEY)
    return QuizGenerator(groq_service)

def get_firebase_service():
    return FirebaseService()

# --- Routes ---

@router.post("/generate", response_model=Quiz)
async def generate_quiz(
    request: QuizGenerationRequest,
    generator: QuizGenerator = Depends(get_quiz_generator),
    firebase: FirebaseService = Depends(get_firebase_service)
    # TODO: Add auth dependency to get current user_id if needed, strictly speaking generation might not need auth but storage does
):
    """
    Generate a new quiz based on lesson content.
    Stores the generated quiz in Firestore for later validation.
    """
    try:
        # Convert enum types to strings if present
        q_types = [t.value for t in request.question_types] if request.question_types else None
        
        quiz_data = await generator.generate_quiz(
            topic=request.topic,
            lesson_title=request.lesson_title,
            key_concepts=request.key_concepts,
            difficulty=request.difficulty,
            num_questions=request.num_questions,
            question_types=q_types
        )
        
        # Add metadata
        quiz_id = str(uuid.uuid4())
        quiz_data["quiz_id"] = quiz_id
        quiz_data["lesson_id"] = request.lesson_id
        
        # Validate through Pydantic model
        quiz = Quiz(**quiz_data)
        
        # Store quiz in Firestore (to validate answers later)
        # Using a 'quizzes' collection
        await firebase.create_document(
            collection="quizzes",
            doc_id=quiz_id,
            data=quiz.model_dump()
        )
        
        return quiz
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/submit", response_model=QuizResult)
async def submit_quiz(
    submission: QuizSubmissionRequest,
    background_tasks: BackgroundTasks,
    firebase: FirebaseService = Depends(get_firebase_service),
    generator: QuizGenerator = Depends(get_quiz_generator),
    # user_id: str = Depends(get_current_user_id) # Placeholder for auth
):
    """
    Submit quiz answers and get results.
    """
    # For now, we'll assume a dummy user_id if auth isn't fully integrated in this router context yet
    # In a real app, use Depends(get_current_user)
    user_id = "test_user_id" 
    
    # 1. Retrieve the quiz
    quiz_doc = await firebase.get_document("quizzes", submission.quiz_id)
    if not quiz_doc:
        raise HTTPException(status_code=404, detail="Quiz not found")
    
    # 2. Calculate results
    stats = generator.calculate_quiz_stats(quiz_doc, submission.answers)
    
    # 3. Create Result Object
    result = QuizResult(
        quiz_id=submission.quiz_id,
        user_id=user_id,
        score=stats["score"],
        correct_count=stats["correct_count"],
        total_questions=stats["total_questions"],
        time_taken_seconds=submission.time_taken_seconds,
        question_results=stats["question_results"],
        strengths=[], # TODO: AI analysis of strengths could go here
        weaknesses=[],
        passed=stats["passed"]
    )
    
    # 4. Save Result
    result_id = str(uuid.uuid4())
    await firebase.create_document(
        collection="quiz_results", 
        doc_id=result_id, 
        data=result.model_dump()
    )
    
    # 5. Update User Stats (Async)
    background_tasks.add_task(update_user_stats, firebase, user_id, result)
    
    return result

@router.get("/history/{user_id}", response_model=List[QuizResult])
async def get_quiz_history(
    user_id: str,
    firebase: FirebaseService = Depends(get_firebase_service)
):
    """
    Get quiz history for a user.
    """
    results_data = await firebase.query_collection(
        collection="quiz_results",
        field="user_id",
        operator="==",
        value=user_id,
        limit=20
    )
    
    return [QuizResult(**data) for data in results_data]

async def update_user_stats(firebase: FirebaseService, user_id: str, result: QuizResult):
    """
    Background task to update user XP and stats.
    """
    user_doc = await firebase.get_document("users", user_id)
    if not user_doc:
        return # Or create basic user doc
        
    stats = user_doc.get("stats", {})
    
    # Update logic
    new_quizzes_taken = stats.get("quizzes_taken", 0) + 1
    new_xp = stats.get("total_xp", 0) + (result.score // 10) # 10 XP per 10% score? Simple logic.
    
    updated_stats = {
        "stats": {
            **stats,
            "quizzes_taken": new_quizzes_taken,
            "total_xp": new_xp
        }
    }
    
    await firebase.update_document("users", user_id, updated_stats)

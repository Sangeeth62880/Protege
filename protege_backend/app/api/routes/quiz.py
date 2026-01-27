"""
Quiz routes
"""
from fastapi import APIRouter, Depends, Request
from pydantic import BaseModel
from typing import List, Optional
import uuid
from datetime import datetime

from app.api.dependencies import get_current_user
from app.services.quiz_generator import QuizGenerator


router = APIRouter()


class QuestionResponse(BaseModel):
    """Question response model"""
    id: str
    question: str
    type: str  # multipleChoice, trueFalse, shortAnswer
    options: List[str] = []
    correct_answer: str
    explanation: Optional[str] = None
    points: int = 1


class QuizResponse(BaseModel):
    """Quiz response model"""
    id: str
    lesson_id: str
    topic: str
    questions: List[QuestionResponse]
    time_limit: int = 0  # seconds, 0 for no limit
    created_at: str


class GenerateQuizRequest(BaseModel):
    """Generate quiz request"""
    lesson_id: str
    topic: str
    question_count: int = 5


class AnswerSubmission(BaseModel):
    """Answer submission model"""
    question_id: str
    user_answer: str
    is_correct: bool


class SubmitQuizRequest(BaseModel):
    """Submit quiz request"""
    quiz_id: str
    user_id: str
    answers: List[AnswerSubmission]
    time_taken_seconds: int


class QuizResultResponse(BaseModel):
    """Quiz result response"""
    id: str
    quiz_id: str
    user_id: str
    score: int
    total_points: int
    answers: List[AnswerSubmission]
    time_taken_seconds: int
    completed_at: str


@router.post("/generate", response_model=QuizResponse)
async def generate_quiz(
    request: Request,
    quiz_request: GenerateQuizRequest,
    user: dict = Depends(get_current_user),
):
    """Generate a quiz for a lesson"""
    # Create quiz generator with app's groq service
    groq_service = request.app.state.groq_service
    quiz_generator = QuizGenerator(groq_service=groq_service)
    
    try:
        questions = await quiz_generator.generate(
            topic=quiz_request.topic,
            count=quiz_request.question_count,
        )
        
        quiz_id = str(uuid.uuid4())
        question_responses = [
            QuestionResponse(
                id=str(uuid.uuid4()),
                question=q["question"],
                type=q.get("type", "multipleChoice"),
                options=q.get("options", []),
                correct_answer=q["correct_answer"],
                explanation=q.get("explanation"),
                points=q.get("points", 1),
            )
            for q in questions
        ]
        
        return QuizResponse(
            id=quiz_id,
            lesson_id=quiz_request.lesson_id,
            topic=quiz_request.topic,
            questions=question_responses,
            created_at=datetime.utcnow().isoformat(),
        )
    except Exception as e:
        raise Exception(f"Failed to generate quiz: {str(e)}")


@router.post("/submit", response_model=QuizResultResponse)
async def submit_quiz(
    request: SubmitQuizRequest,
    user: dict = Depends(get_current_user),
):
    """Submit quiz answers and get results"""
    # Calculate score
    score = sum(1 for a in request.answers if a.is_correct)
    total_points = len(request.answers)
    
    result = QuizResultResponse(
        id=str(uuid.uuid4()),
        quiz_id=request.quiz_id,
        user_id=request.user_id,
        score=score,
        total_points=total_points,
        answers=request.answers,
        time_taken_seconds=request.time_taken_seconds,
        completed_at=datetime.utcnow().isoformat(),
    )
    
    # TODO: Save result to Firestore
    
    return result


@router.get("/{quiz_id}")
async def get_quiz(
    quiz_id: str,
    user: dict = Depends(get_current_user),
):
    """Get a specific quiz"""
    # TODO: Fetch from Firestore
    return {"id": quiz_id}

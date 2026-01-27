"""
Teaching (Reverse Tutoring) routes
"""
from fastapi import APIRouter, Depends, Request
from pydantic import BaseModel
from typing import List, Optional
import uuid
from datetime import datetime

from app.api.dependencies import get_current_user
from app.services.evaluation_service import EvaluationService


router = APIRouter()


class TeachingMessage(BaseModel):
    """Teaching message model"""
    id: str
    content: str
    role: str  # user, ai, system
    timestamp: str
    partial_score: Optional[float] = None


class StartSessionRequest(BaseModel):
    """Start teaching session request"""
    user_id: str
    topic_id: str
    topic: str


class TeachingSessionResponse(BaseModel):
    """Teaching session response"""
    id: str
    user_id: str
    topic_id: str
    topic: str
    messages: List[TeachingMessage] = []
    aha_meter_score: float = 0.0
    status: str = "inProgress"  # inProgress, completed, abandoned
    created_at: str
    completed_at: Optional[str] = None
    feedback: Optional[str] = None


class EvaluateRequest(BaseModel):
    """Evaluate explanation request"""
    session_id: str
    user_id: str
    explanation: str


class EvaluateResponse(BaseModel):
    """Evaluate response"""
    message_id: str
    response: str
    score: float
    aha_meter_score: float
    is_complete: bool
    feedback: Optional[str] = None


@router.post("/session", response_model=TeachingSessionResponse)
async def start_teaching_session(
    session_request: StartSessionRequest,
    user: dict = Depends(get_current_user),
):
    """Start a new teaching session"""
    session_id = str(uuid.uuid4())
    
    # Initial AI message asking user to explain
    initial_message = TeachingMessage(
        id=str(uuid.uuid4()),
        content=f"Hi! I'm a curious learner and I've heard about {session_request.topic}. Can you explain it to me like I'm a beginner? I might ask some follow-up questions to make sure I understand!",
        role="ai",
        timestamp=datetime.utcnow().isoformat(),
    )
    
    return TeachingSessionResponse(
        id=session_id,
        user_id=session_request.user_id,
        topic_id=session_request.topic_id,
        topic=session_request.topic,
        messages=[initial_message],
        created_at=datetime.utcnow().isoformat(),
    )


@router.post("/evaluate", response_model=EvaluateResponse)
async def evaluate_explanation(
    request: Request,
    eval_request: EvaluateRequest,
    user: dict = Depends(get_current_user),
):
    """Evaluate user's explanation and respond"""
    # Create evaluation service with app's groq service
    groq_service = request.app.state.groq_service
    evaluation_service = EvaluationService(groq_service=groq_service)
    
    try:
        evaluation = await evaluation_service.evaluate(
            explanation=eval_request.explanation,
            session_id=eval_request.session_id,
        )
        
        return EvaluateResponse(
            message_id=str(uuid.uuid4()),
            response=evaluation["response"],
            score=evaluation["score"],
            aha_meter_score=evaluation["aha_meter_score"],
            is_complete=evaluation["is_complete"],
            feedback=evaluation.get("feedback"),
        )
    except Exception as e:
        return EvaluateResponse(
            message_id=str(uuid.uuid4()),
            response="That's interesting! Can you tell me more about that?",
            score=30.0,
            aha_meter_score=30.0,
            is_complete=False,
        )


@router.get("/session/{session_id}")
async def get_session(
    session_id: str,
    user: dict = Depends(get_current_user),
):
    """Get a teaching session"""
    # TODO: Fetch from Firestore
    return {"id": session_id}


@router.put("/session/{session_id}/end")
async def end_session(
    session_id: str,
    user: dict = Depends(get_current_user),
):
    """End a teaching session"""
    # TODO: Update in Firestore
    return {"success": True, "status": "abandoned"}

"""
Tutor-related Pydantic models
"""
from pydantic import BaseModel
from typing import Optional, List, Any

class TutorQuestionRequest(BaseModel):
    """Request model for asking the tutor a question."""
    session_id: str
    question: str
    topic: str
    lesson_title: str
    key_concepts: list[str]
    experience_level: str
    lesson_description: Optional[str] = ""

class TutorResponse(BaseModel):
    """Response model for tutor answers."""
    response: str
    session_id: str
    message_count: int

class ConversationMessage(BaseModel):
    """A single message in the conversation."""
    role: str  # 'user' or 'assistant'
    content: str
    timestamp: Optional[str] = None

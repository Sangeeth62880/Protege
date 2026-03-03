"""
Teaching Session Models for Reverse Tutoring
Pydantic models for personas, sessions, and evaluations
"""
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from enum import Enum
from datetime import datetime


class PersonaType(str, Enum):
    """Types of AI student personas."""
    CURIOUS_CHILD = "curious_child"
    SKEPTICAL_TEEN = "skeptical_teen"
    CONFUSED_ADULT = "confused_adult"
    TECHNICAL_PEER = "technical_peer"


class PersonaDifficulty(str, Enum):
    """Difficulty levels for personas."""
    EASY = "easy"
    MEDIUM = "medium"
    HARD = "hard"


class TeachingStatus(str, Enum):
    """Status of a teaching session."""
    ACTIVE = "active"
    COMPLETED = "completed"
    ABANDONED = "abandoned"


# ============================================================================
# PERSONA MODELS
# ============================================================================

class Persona(BaseModel):
    """AI student persona model."""
    id: str
    name: str
    age: int
    type: PersonaType
    description: str
    avatar_emoji: str
    difficulty: PersonaDifficulty
    traits: List[str] = []


class PersonaListResponse(BaseModel):
    """Response containing list of available personas."""
    personas: List[Persona]


# ============================================================================
# MESSAGE MODELS
# ============================================================================

class TeachingMessage(BaseModel):
    """Individual message in a teaching session."""
    id: str
    content: str
    role: str  # "user" or "persona"
    timestamp: str
    partial_score: Optional[float] = None
    concepts_mentioned: List[str] = []
    evaluation: Optional[Dict[str, Any]] = None


# ============================================================================
# EVALUATION MODELS
# ============================================================================

class ClarityScore(BaseModel):
    """Clarity evaluation breakdown."""
    score: int = Field(ge=0, le=100)
    feedback: str = ""
    strengths: List[str] = []
    weaknesses: List[str] = []


class AccuracyScore(BaseModel):
    """Accuracy evaluation breakdown."""
    score: int = Field(ge=0, le=100)
    errors: List[str] = []
    corrections: List[str] = []


class CompletenessScore(BaseModel):
    """Completeness evaluation breakdown."""
    score: int = Field(ge=0, le=100)
    covered: List[str] = []
    missing: List[str] = []


class AhaBreakdown(BaseModel):
    """Breakdown of Aha! meter score."""
    clarity: int = Field(ge=0, le=100, default=0)
    accuracy: int = Field(ge=0, le=100, default=0)
    completeness: int = Field(ge=0, le=100, default=0)


class EvaluationResult(BaseModel):
    """Complete evaluation result for an explanation."""
    clarity: ClarityScore
    accuracy: AccuracyScore
    completeness: CompletenessScore
    overall_score: int = Field(ge=0, le=100)
    concepts_demonstrated: List[str] = []
    suggestions: List[str] = []


# ============================================================================
# SESSION MODELS
# ============================================================================

class TeachingSession(BaseModel):
    """Complete teaching session model."""
    session_id: str
    user_id: str
    persona: Persona
    topic: str
    topic_id: str
    concepts_to_cover: List[str] = []
    concepts_covered: List[str] = []
    aha_score: int = Field(ge=0, le=100, default=0)
    aha_breakdown: AhaBreakdown = AhaBreakdown()
    messages: List[TeachingMessage] = []
    message_count: int = 0
    started_at: str
    completed_at: Optional[str] = None
    status: TeachingStatus = TeachingStatus.ACTIVE
    feedback: Optional[str] = None


# ============================================================================
# REQUEST/RESPONSE MODELS
# ============================================================================

class StartSessionRequest(BaseModel):
    """Request to start a new teaching session."""
    user_id: str
    topic_id: str
    topic: str
    persona_id: str
    concepts_to_cover: List[str] = []


class StartSessionResponse(BaseModel):
    """Response after starting a teaching session."""
    session_id: str
    persona: Persona
    topic: str
    opening_message: str
    concepts_to_cover: List[str]
    status: str


class EvaluateExplanationRequest(BaseModel):
    """Request to evaluate a user's explanation."""
    session_id: str
    user_id: str
    explanation: str


class EvaluateExplanationResponse(BaseModel):
    """Response after evaluating an explanation."""
    message_id: str
    response: str
    persona_name: str
    score: float
    aha_score: float
    aha_breakdown: AhaBreakdown
    concepts_demonstrated: List[str] = []
    is_complete: bool
    feedback: Optional[str] = None


class SessionResultsResponse(BaseModel):
    """Detailed results for a completed session."""
    session_id: str
    topic: str
    persona_name: str
    final_score: int
    aha_breakdown: AhaBreakdown
    concepts_covered: List[str]
    concepts_missing: List[str] = []
    time_spent_seconds: int
    message_count: int
    strengths: List[str] = []
    improvements: List[str] = []
    feedback: str

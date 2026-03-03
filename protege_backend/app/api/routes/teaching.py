"""
Teaching (Reverse Tutoring) API Routes
Enhanced with persona support and detailed evaluation
"""
from fastapi import APIRouter, Depends, Request, HTTPException
from typing import List, Optional
import uuid
from datetime import datetime

from app.api.dependencies import get_current_user
from app.services.persona_service import PersonaService
from app.services.evaluation_service import EvaluationService
from app.services.misconception_service import MisconceptionService
from app.models.teaching import (
    Persona,
    PersonaType,
    PersonaDifficulty,
    TeachingMessage,
    AhaBreakdown,
    StartSessionRequest,
    StartSessionResponse,
    EvaluateExplanationRequest,
    EvaluateExplanationResponse,
    SessionResultsResponse,
)

router = APIRouter()


# ============================================================================
# PERSONA ENDPOINTS
# ============================================================================

@router.get("/personas", response_model=List[Persona])
async def get_available_personas(
    user: dict = Depends(get_current_user),
):
    """Get list of available AI student personas."""
    from app.prompts.persona_prompts import PERSONAS
    
    personas = []
    for persona_data in PERSONAS.values():
        personas.append(Persona(
            id=persona_data["id"],
            name=persona_data["name"],
            age=persona_data["age"],
            type=PersonaType(persona_data["type"]),
            description=persona_data["description"],
            avatar_emoji=persona_data["avatar_emoji"],
            difficulty=PersonaDifficulty(persona_data["difficulty"]),
            traits=persona_data["traits"]
        ))
    
    return personas


@router.get("/personas/{persona_id}", response_model=Persona)
async def get_persona(
    persona_id: str,
    user: dict = Depends(get_current_user),
):
    """Get a specific persona by ID."""
    from app.prompts.persona_prompts import PERSONAS
    
    if persona_id not in PERSONAS:
        raise HTTPException(status_code=404, detail="Persona not found")
    
    persona_data = PERSONAS[persona_id]
    return Persona(
        id=persona_data["id"],
        name=persona_data["name"],
        age=persona_data["age"],
        type=PersonaType(persona_data["type"]),
        description=persona_data["description"],
        avatar_emoji=persona_data["avatar_emoji"],
        difficulty=PersonaDifficulty(persona_data["difficulty"]),
        traits=persona_data["traits"]
    )


# ============================================================================
# SESSION ENDPOINTS
# ============================================================================

@router.post("/session", response_model=StartSessionResponse)
async def start_teaching_session(
    request: Request,
    session_request: StartSessionRequest,
    user: dict = Depends(get_current_user),
):
    """Start a new teaching session with a selected persona."""
    session_id = str(uuid.uuid4())
    
    # Get services
    groq_service = request.app.state.groq_service
    persona_service = PersonaService(groq_service=groq_service)
    
    try:
        result = await persona_service.start_teaching_session(
            session_id=session_id,
            user_id=session_request.user_id,
            persona_id=session_request.persona_id,
            topic=session_request.topic,
            topic_id=session_request.topic_id,
            concepts_to_cover=session_request.concepts_to_cover,
        )
        
        # Convert persona dict to Persona model
        from app.prompts.persona_prompts import PERSONAS
        persona_data = PERSONAS.get(session_request.persona_id)
        
        persona = Persona(
            id=persona_data["id"],
            name=persona_data["name"],
            age=persona_data["age"],
            type=PersonaType(persona_data["type"]),
            description=persona_data["description"],
            avatar_emoji=persona_data["avatar_emoji"],
            difficulty=PersonaDifficulty(persona_data["difficulty"]),
            traits=persona_data["traits"]
        )
        
        # Store session in app state (for persistence between requests)
        if not hasattr(request.app.state, 'teaching_sessions'):
            request.app.state.teaching_sessions = {}
        request.app.state.teaching_sessions[session_id] = {
            "persona_service": persona_service,
            "session_data": result,
            "started_at": datetime.utcnow()
        }
        
        return StartSessionResponse(
            session_id=session_id,
            persona=persona,
            topic=session_request.topic,
            opening_message=result["opening_message"],
            concepts_to_cover=result.get("concepts_to_cover", []),
            status="active"
        )
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to start session: {str(e)}")


@router.get("/session/{session_id}")
async def get_session(
    request: Request,
    session_id: str,
    user: dict = Depends(get_current_user),
):
    """Get a teaching session's current state."""
    sessions = getattr(request.app.state, 'teaching_sessions', {})
    
    if session_id not in sessions:
        raise HTTPException(status_code=404, detail="Session not found")
    
    session_info = sessions[session_id]
    persona_service = session_info.get("persona_service")
    
    if persona_service:
        state = persona_service.get_session_state(session_id)
        if state:
            return state
    
    return session_info.get("session_data", {"id": session_id})


@router.put("/session/{session_id}/end")
async def end_session(
    request: Request,
    session_id: str,
    user: dict = Depends(get_current_user),
):
    """End a teaching session."""
    sessions = getattr(request.app.state, 'teaching_sessions', {})
    
    if session_id in sessions:
        session_info = sessions[session_id]
        persona_service = session_info.get("persona_service")
        if persona_service:
            persona_service.end_session(session_id, status="abandoned")
    
    return {"success": True, "status": "abandoned"}


# ============================================================================
# EVALUATION ENDPOINTS
# ============================================================================

@router.post("/evaluate", response_model=EvaluateExplanationResponse)
async def evaluate_explanation(
    request: Request,
    eval_request: EvaluateExplanationRequest,
    user: dict = Depends(get_current_user),
):
    """Evaluate user's explanation and get persona response."""
    # Get singleton services from app state
    evaluation_service = request.app.state.evaluation_service
    misconception_service = request.app.state.misconception_service
    
    # Get session info
    sessions = getattr(request.app.state, 'teaching_sessions', {})
    session_info = sessions.get(eval_request.session_id, {})
    persona_service = session_info.get("persona_service")
    
    # Get topic from session or use default
    session_data = session_info.get("session_data", {})
    topic = session_data.get("topic", "")
    persona_id = session_data.get("persona", {}).get("id", "skeptical_teen")
    persona_name = session_data.get("persona", {}).get("name", "Student")
    concepts = session_data.get("concepts_to_cover", [])
    
    try:
        # Get evaluation with detailed breakdown
        evaluation = await evaluation_service.evaluate(
            explanation=eval_request.explanation,
            session_id=eval_request.session_id,
            topic=topic,
            concepts=concepts
        )
        
        # Check if we should introduce a misconception
        understanding = evaluation.get("aha_meter_score", 50)
        message_count = session_info.get("message_count", 0) if session_info else 0
        
        should_challenge = misconception_service.should_introduce_misconception(
            session_id=eval_request.session_id,
            understanding_level=int(understanding),
            message_count=message_count
        )
        
        response_text = evaluation.get("response", "")
        
        if should_challenge and not evaluation.get("is_complete"):
            # Generate misconception challenge
            misconception = await misconception_service.generate_misconception(
                session_id=eval_request.session_id,
                topic=topic,
                persona_type=persona_id,
                last_explanation=eval_request.explanation
            )
            
            if misconception:
                response_text = await misconception_service.generate_misconception_response(
                    persona_name=persona_name,
                    persona_type=persona_id,
                    topic=topic,
                    misconception=misconception
                )
        
        # Process through persona service if available
        if persona_service:
            persona_response = await persona_service.process_explanation(
                session_id=eval_request.session_id,
                user_explanation=eval_request.explanation,
                evaluation=evaluation
            )
            response_text = persona_response.get("response", response_text)
        
        # Update message count
        if session_info:
            session_info["message_count"] = message_count + 2
        
        return EvaluateExplanationResponse(
            message_id=str(uuid.uuid4()),
            response=response_text,
            persona_name=persona_name,
            score=evaluation.get("score", 50),
            aha_score=evaluation.get("aha_meter_score", 50),
            aha_breakdown=AhaBreakdown(
                clarity=evaluation.get("aha_breakdown", {}).get("clarity", 0),
                accuracy=evaluation.get("aha_breakdown", {}).get("accuracy", 0),
                completeness=evaluation.get("aha_breakdown", {}).get("completeness", 0)
            ),
            concepts_demonstrated=evaluation.get("concepts_demonstrated", []),
            is_complete=evaluation.get("is_complete", False),
            feedback=evaluation.get("feedback")
        )
        
    except Exception as e:
        # Fallback response
        return EvaluateExplanationResponse(
            message_id=str(uuid.uuid4()),
            response=f"I got a bit confused processing your explanation. Could you try explaining it again, maybe in simpler terms?",
            persona_name=persona_name,
            score=0.0,
            aha_score=0.0,  # Don't inflate artificially
            aha_breakdown=AhaBreakdown(clarity=0, accuracy=0, completeness=0),
            is_complete=False,
            feedback="There was a temporary issue evaluating your response. Your explanation was not scored — please try again.",
        )


# ============================================================================
# RESULTS ENDPOINTS
# ============================================================================

@router.get("/results/{session_id}", response_model=SessionResultsResponse)
async def get_session_results(
    request: Request,
    session_id: str,
    user: dict = Depends(get_current_user),
):
    """Get detailed results for a completed session."""
    sessions = getattr(request.app.state, 'teaching_sessions', {})
    
    if session_id not in sessions:
        raise HTTPException(status_code=404, detail="Session not found")
    
    session_info = sessions[session_id]
    session_data = session_info.get("session_data", {})
    persona_service = session_info.get("persona_service")
    
    # Get session state
    state = persona_service.get_session_state(session_id) if persona_service else {}
    
    # Calculate time spent
    started_at = session_info.get("started_at", datetime.utcnow())
    time_spent = int((datetime.utcnow() - started_at).total_seconds())
    
    # Get misconception stats
    groq_service = request.app.state.groq_service
    misconception_service = MisconceptionService(groq_service=groq_service)
    misconception_stats = misconception_service.get_misconception_stats(session_id)
    
    # Build results
    aha_breakdown = state.get("aha_breakdown", {})
    understanding = state.get("understanding_level", 50)
    
    # Determine strengths and improvements
    strengths = []
    improvements = []
    
    if aha_breakdown.get("clarity", 0) >= 80:
        strengths.append("Clear and easy-to-understand explanations")
    elif aha_breakdown.get("clarity", 0) < 60:
        improvements.append("Use simpler language and more examples")
    
    if aha_breakdown.get("accuracy", 0) >= 80:
        strengths.append("Accurate and factually correct information")
    elif aha_breakdown.get("accuracy", 0) < 60:
        improvements.append("Review the core concepts for accuracy")
    
    if aha_breakdown.get("completeness", 0) >= 80:
        strengths.append("Thorough coverage of key concepts")
    elif aha_breakdown.get("completeness", 0) < 60:
        improvements.append("Cover more of the essential concepts")
    
    if misconception_stats.get("correction_rate", 0) >= 0.8:
        strengths.append("Great at catching and correcting misconceptions")
    
    # Generate feedback
    if understanding >= 85:
        feedback = "Excellent job! You've demonstrated mastery of this topic. Your explanations were clear, accurate, and comprehensive."
    elif understanding >= 70:
        feedback = "Great progress! You've shown solid understanding. A bit more practice with examples will help solidify your knowledge."
    else:
        feedback = "You're on the right track! Keep practicing explaining concepts in simple terms with concrete examples."
    
    return SessionResultsResponse(
        session_id=session_id,
        topic=session_data.get("topic", ""),
        persona_name=session_data.get("persona", {}).get("name", "Student"),
        final_score=understanding,
        aha_breakdown=AhaBreakdown(
            clarity=aha_breakdown.get("clarity", 0),
            accuracy=aha_breakdown.get("accuracy", 0),
            completeness=aha_breakdown.get("completeness", 0)
        ),
        concepts_covered=state.get("concepts_covered", []),
        concepts_missing=list(set(state.get("concepts_to_cover", [])) - set(state.get("concepts_covered", []))),
        time_spent_seconds=time_spent,
        message_count=state.get("message_count", 0),
        strengths=strengths,
        improvements=improvements,
        feedback=feedback
    )

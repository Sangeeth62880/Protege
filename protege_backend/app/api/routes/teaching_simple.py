"""
Teaching API Routes (Simplified)
Endpoints for Reverse Tutoring / Teach Mode.
These routes do NOT require Firebase authentication,
making them suitable for the simple teach session flow.
"""
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
import os

router = APIRouter()

# Global persona engine instance
_persona_engine = None


def _get_engine():
    """Get or create persona engine singleton."""
    global _persona_engine
    if _persona_engine is None:
        from app.services.groq_service import GroqService
        from app.services.persona_engine import PersonaEngine
        from app.config import settings

        groq_key = settings.GROQ_API_KEY
        if not groq_key:
            raise HTTPException(status_code=500, detail="GROQ_API_KEY not configured")

        groq = GroqService(api_key=groq_key)
        _persona_engine = PersonaEngine(groq_service=groq)

    return _persona_engine


class StartSessionRequest(BaseModel):
    topic: str = Field(..., description="Topic to teach")
    persona_id: str = Field("maya", description="Persona ID (maya, jake, sarah, alex)")


class TeachMessageRequest(BaseModel):
    session_id: str = Field(..., description="Session ID")
    user_message: str = Field(..., description="Teacher's message")


class EndSessionRequest(BaseModel):
    session_id: str = Field(..., description="Session ID")


@router.get("/health")
async def teaching_health():
    return {"status": "teaching-simple routes healthy"}


@router.get("/personas")
async def get_personas():
    """Get available AI personas."""
    from app.services.persona_engine import PERSONA_DEFINITIONS

    personas = []
    for pid, pdata in PERSONA_DEFINITIONS.items():
        personas.append({
            "id": pid,
            "name": pdata["name"],
            "age": pdata["age"],
            "avatar": pdata["avatar"],
            "traits": pdata["traits"][:3],  # First 3 traits
            "description": pdata["traits"][0]
        })

    return {"personas": personas}


@router.post("/start")
async def start_session(request: StartSessionRequest):
    """
    Start a new teaching session.

    Returns:
        Initial greeting from the AI persona
    """
    print(f"\n{'='*60}")
    print(f"[TEACHING-SIMPLE] Starting session")
    print(f"[TEACHING-SIMPLE] Topic: {request.topic}")
    print(f"[TEACHING-SIMPLE] Persona: {request.persona_id}")
    print(f"{'='*60}")

    try:
        engine = _get_engine()

        # Generate session ID
        import uuid
        session_id = str(uuid.uuid4())[:8]

        result = await engine.start_session(
            session_id=session_id,
            topic=request.topic,
            persona_id=request.persona_id
        )

        print(f"[TEACHING-SIMPLE] Session started: {session_id}")
        return result

    except HTTPException:
        raise
    except Exception as e:
        print(f"[TEACHING-SIMPLE] Error: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/respond")
async def respond_to_teaching(request: TeachMessageRequest):
    """
    Send a teaching message and get persona response.

    Returns:
        AI persona response with evaluation scores
    """
    print(f"[TEACHING-SIMPLE] Message for session: {request.session_id}")
    print(f"[TEACHING-SIMPLE] Teacher said: {request.user_message[:80]}...")

    try:
        engine = _get_engine()

        result = await engine.respond_to_teaching(
            session_id=request.session_id,
            user_message=request.user_message
        )

        print(f"[TEACHING-SIMPLE] Aha! Score: {result.get('aha_score', 'N/A')}")
        return result

    except HTTPException:
        raise
    except Exception as e:
        print(f"[TEACHING-SIMPLE] Error: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/end")
async def end_session(request: EndSessionRequest):
    """
    End a teaching session and get final evaluation.

    Returns:
        Final scores, strengths, improvements, and summary
    """
    print(f"[TEACHING-SIMPLE] Ending session: {request.session_id}")

    try:
        engine = _get_engine()

        result = await engine.end_session(
            session_id=request.session_id
        )

        print(f"[TEACHING-SIMPLE] Final evaluation complete")
        return result

    except HTTPException:
        raise
    except Exception as e:
        print(f"[TEACHING-SIMPLE] Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

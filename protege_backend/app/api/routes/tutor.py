"""
AI Tutor API Routes
"""
from fastapi import APIRouter, Depends, HTTPException, Request, Body
from typing import Dict, Any, List
from app.api.dependencies import get_current_user
from app.services.tutor_service import TutorService
from app.models.tutor import TutorQuestionRequest, TutorResponse

router = APIRouter()

@router.post("/ask-test", response_model=TutorResponse)
async def ask_tutor_test(
    request: Request,
    body: TutorQuestionRequest
):
    """
    Test endpoint for AI Tutor (No Auth).
    """
    try:
        if not hasattr(request.app.state, "groq_service"):
            raise HTTPException(status_code=503, detail="AI Service unavailable")
        
        # Initialize TutorService (ideally should be singleton in app.state too, but lightweight enough to init here for now)
        # Better: Add tutor_service to app.state in main.py
        # For now, we create it using the existing groq_service
        groq_service = request.app.state.groq_service
        
        # Check if tutor_service is in state, else create it
        if hasattr(request.app.state, "tutor_service"):
             tutor_service = request.app.state.tutor_service
        else:
             tutor_service = TutorService(groq_service)
             request.app.state.tutor_service = tutor_service
        
        response = await tutor_service.ask_question(
            session_id=body.session_id,
            question=body.question,
            topic=body.topic,
            lesson_title=body.lesson_title,
            key_concepts=body.key_concepts,
            experience_level=body.experience_level,
            lesson_description=body.lesson_description
        )
        
        return TutorResponse(**response)
        
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/ask", response_model=TutorResponse)
async def ask_tutor(
    request: Request,
    body: TutorQuestionRequest,
    user: dict = Depends(get_current_user)
):
    """
    Ask AI Tutor a question (Authenticated).
    """
    try:
        # Re-use logic or call service directly
        # Ensure session_id is tied to user or validated? 
        # For now, trust the client provided session_id, or prepend user_id
        
        if not hasattr(request.app.state, "tutor_service"):
             # Fallback init
             if hasattr(request.app.state, "groq_service"):
                 request.app.state.tutor_service = TutorService(request.app.state.groq_service)
             else:
                 raise HTTPException(status_code=503, detail="Service unavailable")

        tutor_service = request.app.state.tutor_service
        
        # Optional: Append user ID to session to prevent cross-user leakage if using simple dict
        safe_session_id = f"{user['uid']}_{body.session_id}"
        
        response = await tutor_service.ask_question(
            session_id=safe_session_id,
            question=body.question,
            topic=body.topic,
            lesson_title=body.lesson_title,
            key_concepts=body.key_concepts,
            experience_level=body.experience_level,
            lesson_description=body.lesson_description
        )
        
        # Strip user prefix from response session_id if needed, or keeping it is fine
        response['session_id'] = body.session_id 
        
        return TutorResponse(**response)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/history/{session_id}")
async def get_history(
    request: Request,
    session_id: str,
    # user: dict = Depends(get_current_user) # Optional for now
):
    """Get conversation history"""
    try:
        if not hasattr(request.app.state, "tutor_service"):
             return {"messages": []}
             
        service = request.app.state.tutor_service
        history = service.get_conversation_history(session_id)
        return {"messages": history}
    except Exception as e:
        return {"messages": []}

@router.delete("/history/{session_id}")
async def clear_history(
    request: Request,
    session_id: str
):
    """Clear conversation history"""
    try:
         if hasattr(request.app.state, "tutor_service"):
             request.app.state.tutor_service.clear_conversation(session_id)
         return {"status": "cleared"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

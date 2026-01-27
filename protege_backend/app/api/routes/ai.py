"""
AI tutor routes
"""
from fastapi import APIRouter, Depends, Request
from pydantic import BaseModel
from typing import List, Optional

from app.api.dependencies import get_current_user


router = APIRouter()


class ChatMessage(BaseModel):
    """Chat message model"""
    role: str  # user, assistant, system
    content: str


class ChatRequest(BaseModel):
    """Chat request model"""
    message: str
    context: Optional[str] = None
    history: List[ChatMessage] = []


class ChatResponse(BaseModel):
    """Chat response model"""
    response: str
    suggestions: List[str] = []


@router.post("/chat", response_model=ChatResponse)
async def chat_with_tutor(
    request: Request,
    chat_request: ChatRequest,
    user: dict = Depends(get_current_user),
):
    """Chat with the AI tutor"""
    groq_service = request.app.state.groq_service
    try:
        response = await groq_service.chat(
            message=chat_request.message,
            context=chat_request.context,
            history=chat_request.history,
        )
        
        return ChatResponse(
            response=response["content"],
            suggestions=response.get("suggestions", []),
        )
    except Exception as e:
        return ChatResponse(
            response="I'm sorry, I couldn't process your request. Please try again.",
            suggestions=["Try rephrasing your question", "Ask about a specific topic"],
        )


@router.post("/explain")
async def explain_concept(
    request: Request,
    topic: str,
    difficulty: str = "beginner",
    user: dict = Depends(get_current_user),
):
    """Get a detailed explanation of a concept"""
    groq_service = request.app.state.groq_service
    try:
        explanation = await groq_service.explain_concept(
            topic=topic,
            difficulty=difficulty,
        )
        return {"explanation": explanation}
    except Exception as e:
        return {"explanation": f"Unable to explain {topic} at this time."}


@router.post("/summarize")
async def summarize_content(
    request: Request,
    content: str,
    user: dict = Depends(get_current_user),
):
    """Summarize learning content"""
    groq_service = request.app.state.groq_service
    try:
        summary = await groq_service.summarize(content)
        return {"summary": summary}
    except Exception as e:
        return {"summary": "Unable to generate summary."}

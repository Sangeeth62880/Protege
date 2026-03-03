"""
Persona Service for Reverse Tutoring
Manages AI student personas and teaching sessions
"""
from typing import Optional, Dict, List, Any
import logging
import uuid
from datetime import datetime

from app.services.groq_service import GroqService
from app.prompts.persona_prompts import (
    PERSONAS,
    PERSONA_PROMPTS,
    OPENING_MESSAGES,
    FOLLOW_UP_PROMPT,
    PERSONA_GUIDELINES
)

logger = logging.getLogger(__name__)


class PersonaService:
    """Manages AI personas that act as students in reverse tutoring."""
    
    def __init__(self, groq_service: GroqService):
        self.groq = groq_service
        # In-memory storage for active sessions (use Redis/DB in production)
        self.active_sessions: Dict[str, Dict[str, Any]] = {}
    
    def get_available_personas(self) -> List[Dict[str, Any]]:
        """Return list of available personas with metadata."""
        return [
            {
                "id": persona["id"],
                "name": persona["name"],
                "age": persona["age"],
                "type": persona["type"],
                "description": persona["description"],
                "avatar_emoji": persona["avatar_emoji"],
                "difficulty": persona["difficulty"],
                "traits": persona["traits"]
            }
            for persona in PERSONAS.values()
        ]
    
    def get_persona(self, persona_id: str) -> Optional[Dict[str, Any]]:
        """Get a specific persona by ID."""
        return PERSONAS.get(persona_id)
    
    async def start_teaching_session(
        self,
        session_id: str,
        user_id: str,
        persona_id: str,
        topic: str,
        topic_id: str,
        concepts_to_cover: List[str] = None,
        user_experience_level: str = "beginner"
    ) -> Dict[str, Any]:
        """
        Start a new teaching session with selected persona.
        
        Args:
            session_id: Unique session identifier
            user_id: User's identifier
            persona_id: Selected persona identifier
            topic: Topic to teach
            topic_id: Topic's identifier
            concepts_to_cover: List of concepts user should explain
            user_experience_level: User's experience level
            
        Returns:
            Session data with initial AI message
        """
        persona = self.get_persona(persona_id)
        if not persona:
            logger.error(f"Attempted to start session with unknown persona: {persona_id}")
            raise ValueError(f"Unknown persona: {persona_id}")
        
        # Generate opening message
        opening_message = OPENING_MESSAGES.get(persona_id, "Hello! I'm ready to learn.").format(topic=topic)
        
        # Initialize session state
        session_state = {
            "session_id": session_id,
            "user_id": user_id,
            "persona_id": persona_id,
            "persona": persona,
            "topic": topic,
            "topic_id": topic_id,
            "concepts_to_cover": concepts_to_cover or [],
            "concepts_covered": [],
            "user_experience_level": user_experience_level,
            "conversation_history": [],
            "understanding_level": 0,
            "aha_breakdown": {
                "clarity": 0,
                "accuracy": 0,
                "completeness": 0
            },
            "message_count": 1,
            "started_at": datetime.utcnow().isoformat(),
            "status": "active"
        }
        
        # Add opening message to history
        session_state["conversation_history"].append({
            "role": "persona",
            "content": opening_message,
            "timestamp": datetime.utcnow().isoformat()
        })
        
        # Store session
        self.active_sessions[session_id] = session_state
        
        logger.info(f"Started teaching session {session_id} with persona {persona_id}")
        
        return {
            "session_id": session_id,
            "persona": persona,
            "topic": topic,
            "opening_message": opening_message,
            "concepts_to_cover": concepts_to_cover or [],
            "status": "active"
        }
    
    async def process_explanation(
        self,
        session_id: str,
        user_explanation: str,
        evaluation: Dict[str, Any] = None
    ) -> Dict[str, Any]:
        """
        Process user's explanation and generate persona response.
        
        Args:
            session_id: Session identifier
            user_explanation: User's explanation text
            evaluation: Optional pre-computed evaluation scores
            
        Returns:
            Persona's response and updated session state
        """
        session = self.active_sessions.get(session_id)
        if not session:
            raise ValueError(f"Session not found: {session_id}")
        
        persona_id = session["persona_id"]
        persona = session["persona"]
        topic = session["topic"]
        
        # Add user message to history
        session["conversation_history"].append({
            "role": "user",
            "content": user_explanation,
            "timestamp": datetime.utcnow().isoformat()
        })
        
        # Use provided evaluation or default understanding level
        if evaluation:
            understanding_level = evaluation.get("overall_score", session["understanding_level"])
            session["understanding_level"] = understanding_level
            session["aha_breakdown"] = {
                "clarity": evaluation.get("clarity", {}).get("score", 0),
                "accuracy": evaluation.get("accuracy", {}).get("score", 0),
                "completeness": evaluation.get("completeness", {}).get("score", 0)
            }
            if evaluation.get("concepts_demonstrated"):
                for concept in evaluation["concepts_demonstrated"]:
                    if concept not in session["concepts_covered"]:
                        session["concepts_covered"].append(concept)
        else:
            understanding_level = session["understanding_level"]
        
        # Format conversation history for prompt
        conversation_history = self._format_conversation_history(session["conversation_history"])
        
        # Build system prompt for persona
        system_prompt = PERSONA_PROMPTS[persona_id].format(
            topic=topic,
            understanding_level=understanding_level,
            concepts=", ".join(session["concepts_to_cover"]) if session["concepts_to_cover"] else topic,
            conversation_history=conversation_history
        )
        
        # Generate persona response
        try:
            persona_response = await self.groq.generate_with_system_prompt(
                system_prompt=system_prompt,
                user_message=f"The user just explained: \"{user_explanation}\"\n\nRespond in character as {persona['name']}. Your current understanding is {understanding_level}/100.",
                temperature=0.8,
                max_tokens=256
            )
        except Exception as e:
            logger.error(f"Failed to generate persona response: {e}")
            persona_response = self._get_fallback_response(persona_id, understanding_level)
        
        # Add persona response to history
        session["conversation_history"].append({
            "role": "persona",
            "content": persona_response,
            "timestamp": datetime.utcnow().isoformat()
        })
        
        session["message_count"] += 2  # User + persona messages
        
        # Check if session is complete
        is_complete = understanding_level >= 85
        if is_complete:
            session["status"] = "completed"
        
        return {
            "response": persona_response,
            "persona_name": persona["name"],
            "understanding_level": understanding_level,
            "aha_breakdown": session["aha_breakdown"],
            "concepts_covered": session["concepts_covered"],
            "is_complete": is_complete,
            "message_count": session["message_count"]
        }
    
    def get_session_state(self, session_id: str) -> Optional[Dict[str, Any]]:
        """Get current state of teaching session."""
        session = self.active_sessions.get(session_id)
        if not session:
            return None
        
        return {
            "session_id": session["session_id"],
            "user_id": session["user_id"],
            "persona": session["persona"],
            "topic": session["topic"],
            "concepts_to_cover": session["concepts_to_cover"],
            "concepts_covered": session["concepts_covered"],
            "understanding_level": session["understanding_level"],
            "aha_breakdown": session["aha_breakdown"],
            "message_count": session["message_count"],
            "conversation_history": session["conversation_history"],
            "started_at": session["started_at"],
            "status": session["status"]
        }
    
    def end_session(self, session_id: str, status: str = "abandoned") -> bool:
        """End a teaching session."""
        session = self.active_sessions.get(session_id)
        if not session:
            return False
        
        session["status"] = status
        session["ended_at"] = datetime.utcnow().isoformat()
        
        logger.info(f"Ended teaching session {session_id} with status {status}")
        return True
    
    def _format_conversation_history(self, history: List[Dict]) -> str:
        """Format conversation history for prompt."""
        if not history:
            return "No conversation yet."
        
        formatted = []
        for msg in history[-10:]:  # Keep last 10 messages
            role = "Student" if msg["role"] == "persona" else "Teacher"
            formatted.append(f"{role}: {msg['content']}")
        
        return "\n".join(formatted)
    
    def _get_fallback_response(self, persona_id: str, understanding: int) -> str:
        """Get fallback response if AI generation fails."""
        if understanding < 40:
            fallbacks = {
                "curious_child": "Hmm, I'm still confused! Can you explain it differently?",
                "skeptical_teen": "I'm not really getting it. Can you give me an example?",
                "confused_adult": "I'm sorry, I don't quite understand yet. Could you clarify?",
                "technical_peer": "I need more clarity on that. Can you be more specific?"
            }
        elif understanding < 70:
            fallbacks = {
                "curious_child": "Ooh, I think I'm starting to get it! But why does it work that way?",
                "skeptical_teen": "Okay, that makes some sense. But what about edge cases?",
                "confused_adult": "I think I'm following. How would this work in practice?",
                "technical_peer": "Right, I see the basic idea. What about performance considerations?"
            }
        else:
            fallbacks = {
                "curious_child": "Wow, I get it now! That's so cool!",
                "skeptical_teen": "Okay, fine, that actually makes sense. Thanks.",
                "confused_adult": "Thank you so much! That really helped me understand.",
                "technical_peer": "Clear explanation. Thanks for the thorough breakdown."
            }
        
        return fallbacks.get(persona_id, "Can you tell me more?")

"""
AI Tutor Service
Provides contextual tutoring while user studies lessons
"""
from typing import Optional, List, Dict
import logging
from app.services.groq_service import GroqService
from app.prompts.tutor_prompts import TUTOR_SYSTEM_PROMPT

logger = logging.getLogger(__name__)

class TutorService:
    """AI Tutor that helps users understand lesson concepts."""
    
    def __init__(self, groq_service: GroqService):
        self.groq = groq_service
        # In-memory storage for now. In production, use Redis or Database.
        self.conversation_histories: Dict[str, List[Dict[str, str]]] = {}  # session_id -> formatted messages
    
    async def ask_question(
        self,
        session_id: str,
        question: str,
        topic: str,
        lesson_title: str,
        key_concepts: list[str],
        experience_level: str,
        lesson_description: str = ""
    ) -> dict:
        """
        Process a user's question and return AI tutor response.
        
        Args:
            session_id: Unique session identifier for conversation history
            question: User's question
            topic: Main topic being studied
            lesson_title: Current lesson title
            key_concepts: List of concepts in this lesson
            experience_level: User's experience level
            lesson_description: Optional lesson description for context
            
        Returns:
            dict with 'response' and 'conversation_id'
        """
        try:
            print(f"[TUTOR] Received question for session: {session_id}")
            print(f"[TUTOR] Building context for lesson: {lesson_title}")
            
            # 1. Get Conversation History
            history = self.get_conversation_history(session_id)
            
            # Format history for prompt
            formatted_history = ""
            for msg in history:
                role = "User" if msg["role"] == "user" else "Tutor"
                formatted_history += f"{role}: {msg['content']}\n"
            
            # 2. Build System Prompt
            concepts_str = ", ".join(key_concepts)
            system_prompt = TUTOR_SYSTEM_PROMPT.format(
                topic=topic,
                lesson_title=lesson_title,
                key_concepts=concepts_str,
                experience_level=experience_level,
                conversation_history=formatted_history
            )
            
            # 3. Call Groq
            print("[TUTOR] Calling Groq API...")
            response_text = await self.groq.generate_with_system_prompt(
                system_prompt=system_prompt,
                user_message=question,
                temperature=0.7,
                max_tokens=1024
            )
            
            print(f"[TUTOR] Response received ({len(response_text)} characters)")
            
            # 4. Update History
            self._add_to_history(session_id, "user", question)
            self._add_to_history(session_id, "assistant", response_text)
            
            return {
                "response": response_text,
                "session_id": session_id,
                "message_count": len(self.conversation_histories.get(session_id, []))
            }
            
        except Exception as e:
            logger.error(f"Tutor service error: {e}")
            print(f"[TUTOR] Error: {e}")
            raise e
    
    def get_conversation_history(self, session_id: str) -> List[Dict[str, str]]:
        """Get conversation history for a session."""
        return self.conversation_histories.get(session_id, [])
    
    def _add_to_history(self, session_id: str, role: str, content: str):
        """Add message to history."""
        if session_id not in self.conversation_histories:
            self.conversation_histories[session_id] = []
        
        self.conversation_histories[session_id].append({
            "role": role,
            "content": content
        })
        
        # Limit history size (e.g., last 10 messages)
        if len(self.conversation_histories[session_id]) > 20:
             self.conversation_histories[session_id] = self.conversation_histories[session_id][-20:]
    
    def clear_conversation(self, session_id: str) -> None:
        """Clear conversation history for a session."""
        if session_id in self.conversation_histories:
            del self.conversation_histories[session_id]
            print(f"[TUTOR] Cleared history for session: {session_id}")
    
    async def get_concept_explanation(
        self,
        concept: str,
        topic: str,
        experience_level: str
    ) -> str:
        """Get a standalone explanation of a concept."""
        try:
            prompt = f"Explain the concept of '{concept}' in the context of {topic} for a {experience_level} learner. Keep it brief (1 paragraph)."
            return await self.groq.generate_with_system_prompt(
                system_prompt="You are a helpful dictionary.",
                user_message=prompt
            )
        except Exception as e:
            logger.error(f"Concept explanation error: {e}")
            return "Could not generate explanation."

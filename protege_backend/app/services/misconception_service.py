"""
Misconception Service for Reverse Tutoring
Generates deliberate misconceptions to test user understanding
"""
from typing import Dict, Any, Optional, List
import logging
import random

from app.services.groq_service import GroqService
from app.prompts.misconception_prompts import (
    GENERATE_MISCONCEPTION_PROMPT,
    PERSONA_MISCONCEPTION_STYLES,
    VERIFY_CORRECTION_PROMPT,
    CHALLENGE_WITH_MISCONCEPTION_PROMPT,
    PROGRAMMING_MISCONCEPTIONS
)

logger = logging.getLogger(__name__)


class MisconceptionService:
    """
    Generates deliberate misconceptions to test if users can catch and correct errors.
    This proves deep understanding beyond just explaining concepts.
    """
    
    # Probability of introducing a misconception (increases with session progress)
    BASE_MISCONCEPTION_PROB = 0.2
    MAX_MISCONCEPTION_PROB = 0.5
    
    def __init__(self, groq_service: GroqService):
        self.groq = groq_service
        # Track misconceptions per session
        self._session_misconceptions: Dict[str, List[Dict]] = {}
    
    def should_introduce_misconception(
        self,
        session_id: str,
        understanding_level: int,
        message_count: int
    ) -> bool:
        """
        Determine if we should introduce a misconception at this point.
        
        Args:
            session_id: Session identifier
            understanding_level: Current understanding score (0-100)
            message_count: Number of messages exchanged
            
        Returns:
            True if we should challenge with a misconception
        """
        # Don't challenge too early
        if message_count < 4:
            return False
        
        # Don't challenge if understanding is too low
        if understanding_level < 40:
            return False
        
        # Increase probability as understanding increases
        # (challenging more when user seems confident)
        prob = self.BASE_MISCONCEPTION_PROB + (understanding_level / 100) * 0.3
        prob = min(prob, self.MAX_MISCONCEPTION_PROB)
        
        # Don't overwhelm with misconceptions
        session_misconceptions = self._session_misconceptions.get(session_id, [])
        if len(session_misconceptions) >= 3:
            prob *= 0.3  # Reduce probability after 3 misconceptions
        
        return random.random() < prob
    
    async def generate_misconception(
        self,
        session_id: str,
        topic: str,
        persona_type: str,
        last_explanation: str,
        conversation_history: List[Dict] = None
    ) -> Optional[Dict[str, Any]]:
        """
        Generate a misconception for the AI student to express.
        
        Args:
            session_id: Session identifier
            topic: Topic being discussed
            persona_type: Type of persona (curious_child, skeptical_teen, etc.)
            last_explanation: User's last explanation
            conversation_history: Previous conversation
            
        Returns:
            Misconception data or None if generation fails
        """
        try:
            # Get persona-specific style
            style = PERSONA_MISCONCEPTION_STYLES.get(persona_type, PERSONA_MISCONCEPTION_STYLES["skeptical_teen"])
            misconception_type = random.choice(style["misconception_types"])
            difficulty = style["difficulty"]
            
            # Try to find a relevant pre-built misconception first
            prebuilt = self._get_prebuilt_misconception(topic)
            if prebuilt:
                misconception = prebuilt
            else:
                # Generate dynamic misconception
                prompt = GENERATE_MISCONCEPTION_PROMPT.format(
                    topic=topic,
                    persona_type=persona_type,
                    last_explanation=last_explanation[:500]  # Limit length
                )
                
                response = await self.groq.generate_with_system_prompt(
                    system_prompt="You are an expert at identifying common misconceptions. Return valid JSON only.",
                    user_message=prompt,
                    temperature=0.7,
                    max_tokens=300,
                    json_response=True
                )
                
                misconception = self.groq.parse_json_response(response)
            
            # Store the misconception for later verification
            if session_id not in self._session_misconceptions:
                self._session_misconceptions[session_id] = []
            
            misconception["session_id"] = session_id
            misconception["topic"] = topic
            misconception["persona_type"] = persona_type
            misconception["verified"] = False
            
            self._session_misconceptions[session_id].append(misconception)
            
            logger.info(f"Generated misconception for session {session_id}: {misconception.get('misconception_type')}")
            
            return misconception
            
        except Exception as e:
            logger.error(f"Failed to generate misconception: {e}")
            return None
    
    async def generate_misconception_response(
        self,
        persona_name: str,
        persona_type: str,
        topic: str,
        misconception: Dict[str, Any],
        conversation_history: List[Dict] = None
    ) -> str:
        """
        Generate a natural-sounding response that includes the misconception.
        
        Args:
            persona_name: Name of the persona (Maya, Jake, etc.)
            persona_type: Type of persona
            topic: Topic being discussed
            misconception: The misconception data
            conversation_history: Previous conversation
            
        Returns:
            Natural-sounding response with embedded misconception
        """
        try:
            style = PERSONA_MISCONCEPTION_STYLES.get(persona_type, PERSONA_MISCONCEPTION_STYLES["skeptical_teen"])
            
            # Get conversation history string
            history_str = ""
            if conversation_history:
                for msg in conversation_history[-4:]:
                    role = "Teacher" if msg.get("role") == "user" else "Student"
                    history_str += f"{role}: {msg.get('content', '')}\n"
            
            # Use the misconception statement directly or generate a wrapper
            misconception_statement = misconception.get(
                "misconception_statement",
                misconception.get("misconception", "I'm not sure I understand...")
            )
            
            prompt = CHALLENGE_WITH_MISCONCEPTION_PROMPT.format(
                persona_name=persona_name,
                persona_type=persona_type.replace("_", " "),
                topic=topic,
                conversation_history=history_str or "Just started learning",
                last_explanation="[previous explanation]",
                difficulty=style["difficulty"],
                misconception_type=misconception.get("misconception_type", "confusion")
            )
            
            # Generate natural response incorporating misconception
            response = await self.groq.generate_with_system_prompt(
                system_prompt=f"You are {persona_name}. Respond naturally while expressing this misunderstanding: '{misconception_statement}'",
                user_message=prompt,
                temperature=0.8,
                max_tokens=150
            )
            
            return response
            
        except Exception as e:
            logger.error(f"Failed to generate misconception response: {e}")
            # Fallback: return the misconception statement directly
            return misconception.get("misconception_statement", "Wait, so does that mean...? I'm a bit confused.")
    
    async def verify_correction(
        self,
        session_id: str,
        user_response: str
    ) -> Dict[str, Any]:
        """
        Verify if the user correctly identified and corrected a misconception.
        
        Args:
            session_id: Session identifier
            user_response: User's response to the misconception
            
        Returns:
            Verification result with score and feedback
        """
        # Get the most recent unverified misconception
        session_misconceptions = self._session_misconceptions.get(session_id, [])
        active_misconception = None
        
        for m in reversed(session_misconceptions):
            if not m.get("verified"):
                active_misconception = m
                break
        
        if not active_misconception:
            return {
                "correctly_identified": True,
                "correctly_explained": True,
                "correction_complete": True,
                "score": 75,
                "feedback": "Good explanation!",
                "missing_points": []
            }
        
        try:
            prompt = VERIFY_CORRECTION_PROMPT.format(
                misconception=active_misconception.get("misconception_statement", active_misconception.get("misconception")),
                correct_understanding=active_misconception.get("correct_understanding", "the correct concept"),
                user_response=user_response
            )
            
            response = await self.groq.generate_with_system_prompt(
                system_prompt="You are verifying if a correction is complete and accurate. Return valid JSON only.",
                user_message=prompt,
                temperature=0.3,
                max_tokens=256,
                json_response=True
            )
            
            result = self.groq.parse_json_response(response)
            
            # Mark as verified
            active_misconception["verified"] = True
            active_misconception["correction_score"] = result.get("score", 50)
            
            return result
            
        except Exception as e:
            logger.error(f"Failed to verify correction: {e}")
            return {
                "correctly_identified": True,
                "correctly_explained": True,
                "correction_complete": True,
                "score": 60,
                "feedback": "Thanks for the clarification!",
                "missing_points": []
            }
    
    def get_session_misconceptions(self, session_id: str) -> List[Dict]:
        """Get all misconceptions from a session."""
        return self._session_misconceptions.get(session_id, [])
    
    def get_misconception_stats(self, session_id: str) -> Dict[str, Any]:
        """Get statistics about how well user handled misconceptions."""
        misconceptions = self._session_misconceptions.get(session_id, [])
        
        if not misconceptions:
            return {
                "total_challenges": 0,
                "successfully_corrected": 0,
                "correction_rate": 1.0,
                "average_score": 100
            }
        
        verified = [m for m in misconceptions if m.get("verified")]
        scores = [m.get("correction_score", 50) for m in verified]
        high_scores = len([s for s in scores if s >= 70])
        
        return {
            "total_challenges": len(misconceptions),
            "successfully_corrected": high_scores,
            "correction_rate": high_scores / len(verified) if verified else 0,
            "average_score": sum(scores) / len(scores) if scores else 0
        }
    
    def clear_session(self, session_id: str) -> None:
        """Clear misconception tracking for a session."""
        if session_id in self._session_misconceptions:
            del self._session_misconceptions[session_id]
    
    def _get_prebuilt_misconception(self, topic: str) -> Optional[Dict]:
        """Try to find a relevant pre-built misconception."""
        topic_lower = topic.lower()
        
        for topic_key, misconceptions in PROGRAMMING_MISCONCEPTIONS.items():
            if topic_key in topic_lower:
                misconception = random.choice(misconceptions)
                return {
                    "misconception_statement": f"So {misconception['misconception'].lower()}?",
                    "misconception_type": "pre_built",
                    "correct_understanding": misconception["correct"],
                    "why_its_wrong": misconception["issue"],
                    "difficulty_to_catch": "medium"
                }
        
        return None

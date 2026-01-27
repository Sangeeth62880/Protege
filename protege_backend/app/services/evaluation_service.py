"""
Evaluation Service for Reverse Tutoring
"""
from typing import Dict, Any, Optional

from app.services.groq_service import GroqService
from app.prompts.evaluation_prompts import EVALUATION_PROMPT, CONFUSED_STUDENT_PROMPT


class EvaluationService:
    """Service for evaluating user explanations in reverse tutoring"""
    
    def __init__(self, groq_service: Optional[GroqService] = None):
        self.groq = groq_service
        self._session_scores: Dict[str, float] = {}
    
    async def evaluate(
        self,
        explanation: str,
        session_id: str,
        topic: str = "",
    ) -> Dict[str, Any]:
        """Evaluate a user's explanation and generate response"""
        
        # Get current score for session
        current_score = self._session_scores.get(session_id, 0.0)
        
        # Generate evaluation
        eval_prompt = EVALUATION_PROMPT.format(
            explanation=explanation,
            current_score=current_score,
        )
        
        eval_response = await self.groq.generate_response(
            prompt=eval_prompt,
            system_prompt="You are an expert educator evaluating explanations.",
            temperature=0.3,
        )
        
        # Parse score from evaluation
        try:
            score = self._parse_score(eval_response)
        except:
            score = 50.0
        
        # Generate confused student response
        student_prompt = CONFUSED_STUDENT_PROMPT.format(
            explanation=explanation,
            score=score,
        )
        
        student_response = await self.groq.generate_response(
            prompt=student_prompt,
            system_prompt="You are a curious but confused student. Ask clarifying questions based on the explanation quality.",
            temperature=0.8,
        )
        
        # Update session score
        new_score = min(100.0, current_score + (score * 0.3))
        self._session_scores[session_id] = new_score
        
        # Check if complete
        is_complete = new_score >= 80.0
        
        return {
            "response": student_response,
            "score": score,
            "aha_meter_score": new_score,
            "is_complete": is_complete,
            "feedback": self._generate_feedback(new_score) if is_complete else None,
        }
    
    def _parse_score(self, response: str) -> float:
        """Parse score from evaluation response"""
        import re
        
        # Look for numbers in response
        numbers = re.findall(r'\d+(?:\.\d+)?', response)
        if numbers:
            score = float(numbers[0])
            return min(100.0, max(0.0, score))
        return 50.0
    
    def _generate_feedback(self, score: float) -> str:
        """Generate final feedback based on score"""
        if score >= 90:
            return "Excellent! You've demonstrated a deep understanding of this topic. Your explanation was clear, comprehensive, and well-structured."
        elif score >= 80:
            return "Great job! You've shown solid understanding. Your explanation helped me understand the concept well."
        elif score >= 60:
            return "Good effort! You have a decent grasp of the topic, but there's room for improvement in some areas."
        else:
            return "Keep practicing! Try breaking down the concept into simpler parts."

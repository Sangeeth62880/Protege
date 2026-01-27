"""
Quiz Generator Service
"""
import json
from typing import List, Dict, Any, Optional

from app.services.groq_service import GroqService
from app.prompts.quiz_prompts import QUIZ_GENERATION_PROMPT


class QuizGenerator:
    """Service for generating AI-powered quizzes"""
    
    def __init__(self, groq_service: Optional[GroqService] = None):
        self.groq = groq_service
    
    async def generate(
        self,
        topic: str,
        count: int = 5,
        difficulty: str = "mixed",
    ) -> List[Dict[str, Any]]:
        """Generate quiz questions for a topic"""
        
        prompt = QUIZ_GENERATION_PROMPT.format(
            topic=topic,
            count=count,
            difficulty=difficulty,
        )
        
        response = await self.groq.generate_response(
            prompt=prompt,
            system_prompt="You are an expert quiz creator. Generate clear, educational questions.",
            temperature=0.7,
        )
        
        try:
            # Try to parse JSON from response
            start_idx = response.find("[")
            end_idx = response.rfind("]") + 1
            
            if start_idx != -1 and end_idx > start_idx:
                json_str = response[start_idx:end_idx]
                questions = json.loads(json_str)
                return questions
            else:
                return self._create_fallback_questions(topic, count)
        except json.JSONDecodeError:
            return self._create_fallback_questions(topic, count)
    
    def _create_fallback_questions(
        self,
        topic: str,
        count: int,
    ) -> List[Dict[str, Any]]:
        """Create fallback questions"""
        return [
            {
                "question": f"What is the main purpose of {topic}?",
                "type": "multipleChoice",
                "options": [
                    f"To understand {topic}",
                    "To solve complex problems",
                    "To improve efficiency",
                    "All of the above"
                ],
                "correct_answer": "All of the above",
                "explanation": f"All options relate to learning {topic}.",
                "points": 1,
            }
        ] * min(count, 5)

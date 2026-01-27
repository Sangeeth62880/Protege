import logging
import json
from typing import Dict, Any

from app.services.groq_service import GroqService
from app.prompts.syllabus_prompts import SYLLABUS_SYSTEM_PROMPT, get_syllabus_prompt
from app.models.learning_path import Syllabus, DifficultyLevel

logger = logging.getLogger(__name__)

class SyllabusGenerator:
    """
    Service to generate learning syllabi using Groq AI.
    """
    
    def __init__(self, groq_service: GroqService):
        self.groq = groq_service
    
    async def generate_syllabus(
        self,
        topic: str,
        goal: str,
        experience_level: DifficultyLevel,
        daily_time_minutes: int
    ) -> Syllabus:
        """
        Generate a complete learning syllabus for the given topic.
        
        Args:
            topic: Topic to learn
            goal: User's goal
            experience_level: Difficulty level
            daily_time_minutes: Time available per day
            
        Returns:
            Validated Syllabus object
            
        Raises:
            Exception: If generation or validation fails
        """
        try:
            # Handle Enum or string
            exp_level_str = experience_level.value if isinstance(experience_level, DifficultyLevel) else str(experience_level)

            user_prompt = get_syllabus_prompt(
                topic=topic,
                goal=goal,
                experience_level=exp_level_str,
                daily_time_minutes=daily_time_minutes
            )
            
            logger.info(f"Generating syllabus for topic: {topic}")
            
            # Call Groq
            response_content = await self.groq.generate_with_system_prompt(
                system_prompt=SYLLABUS_SYSTEM_PROMPT,
                user_message=user_prompt,
                json_response=True,
                temperature=0.7,
                max_tokens=4096
            )
            
            logger.info(f"Raw Groq Response: {response_content[:500]}...") # Log first 500 chars
            
            # Parse JSON
            data = self.groq.parse_json_response(response_content)
            
            # Validate with Pydantic
            syllabus = Syllabus(**data)
            
            logger.info("Syllabus generated and validated successfully")
            return syllabus
            
        except Exception as e:
            logger.error(f"Error generating syllabus: {str(e)}")
            raise e

    def validate_syllabus_structure(self, data: Dict[str, Any]) -> bool:
        """
        Custom validation if needed (beyond Pydantic)
        """
        if "modules" not in data or not data["modules"]:
            return False
        return True

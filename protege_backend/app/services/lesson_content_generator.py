"""
Service for generating rich, detailed lesson content using Groq LLM.
"""
import json
import logging
from typing import Dict, List, Any, Optional

from app.prompts.lesson_content_prompts import build_lesson_content_prompt

logger = logging.getLogger(__name__)


class LessonContentGenerator:
    """Generates detailed, structured lesson content using LLM."""

    def __init__(self, groq_service):
        self.groq_service = groq_service

    async def generate_lesson_content(
        self,
        topic: str,
        module_title: str,
        lesson_title: str,
        lesson_description: str,
        key_concepts: List[str],
        difficulty: str = "beginner",
    ) -> Dict[str, Any]:
        """
        Generate rich lesson content using the Groq LLM.

        Returns structured JSON matching the LessonExplanation schema:
        {introduction, sections[], key_takeaways[], common_mistakes[],
         practice_exercises[], summary}
        """
        prompt = build_lesson_content_prompt(
            topic=topic,
            module_title=module_title,
            lesson_title=lesson_title,
            lesson_description=lesson_description,
            key_concepts=key_concepts,
            difficulty=difficulty,
        )

        logger.info(
            f"Generating lesson content: {topic} / {module_title} / {lesson_title}"
        )

        try:
            response = await self.groq_service.chat_completion(
                messages=[
                    {
                        "role": "system",
                        "content": (
                            "You are an expert educator. Generate detailed lesson content "
                            "in valid JSON format only. No markdown code fences. "
                            f"All code examples MUST be in {topic}."
                        ),
                    },
                    {"role": "user", "content": prompt},
                ],
                model="llama-3.3-70b-versatile",
                temperature=0.6,
                max_tokens=4096,
                json_response=True,
            )

            # Parse JSON response
            content = self._parse_response(response, topic)
            logger.info(
                f"Successfully generated lesson content for: {lesson_title}"
            )
            return content

        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse lesson content JSON: {e}")
            # Return a meaningful fallback so the UI isn't broken
            return self._fallback_content(topic, lesson_title, lesson_description)
        except Exception as e:
            logger.error(f"Lesson content generation failed: {e}")
            return self._fallback_content(topic, lesson_title, lesson_description)

    def _parse_response(self, response: str, topic: str) -> Dict[str, Any]:
        """Parse and validate the LLM JSON response."""
        # Strip markdown fences if present
        text = response.strip()
        if text.startswith("```"):
            lines = text.split("\n")
            # Remove first and last lines (```json and ```)
            text = "\n".join(lines[1:-1] if lines[-1].strip() == "```" else lines[1:])

        content = json.loads(text)

        # Validate required fields
        required = ["introduction", "sections", "key_takeaways", "summary"]
        for field in required:
            if field not in content:
                content[field] = "" if field in ["introduction", "summary"] else []

        # Ensure sections have correct structure
        if isinstance(content.get("sections"), list):
            for section in content["sections"]:
                if "title" not in section:
                    section["title"] = "Untitled Section"
                if "content" not in section:
                    section["content"] = ""
                # Default language if code_example present but no language
                if section.get("code_example") and not section.get("language"):
                    section["language"] = topic.lower()

        return content

    def _fallback_content(
        self, topic: str, lesson_title: str, description: str
    ) -> Dict[str, Any]:
        """Return minimal content when generation fails."""
        return {
            "introduction": (
                f"This lesson covers {lesson_title} as part of learning {topic}. "
                f"{description}"
            ),
            "sections": [
                {
                    "title": f"Understanding {lesson_title}",
                    "content": (
                        f"{lesson_title} is an important concept in {topic}. "
                        "Content generation encountered an issue — please try refreshing."
                    ),
                    "code_example": None,
                    "language": None,
                }
            ],
            "key_takeaways": [
                f"Review the fundamentals of {lesson_title} in {topic}.",
            ],
            "common_mistakes": [],
            "practice_exercises": [],
            "summary": f"This lesson introduces {lesson_title} in the context of {topic}.",
        }

"""
AI-powered Relevance Scorer
Rates each resource 0-100 for relevance to a specific lesson topic.
Uses Groq (Llama) to batch-evaluate resource titles + descriptions.
"""
import json
import logging
from typing import List, Optional

logger = logging.getLogger(__name__)


class RelevanceScorer:
    """Scores resource relevance using AI."""

    SCORING_PROMPT = """You are a learning resource relevance evaluator.

Given a LESSON TOPIC and a list of resources, score each resource 0-100 for relevance.

Scoring criteria:
- 90-100: Directly teaches this exact concept
- 70-89: Closely related, covers the concept as a major part
- 40-69: Tangentially related, mentions the concept
- 0-39: Not relevant to this specific lesson

LESSON TOPIC: {lesson_title}
BROADER SUBJECT: {topic}

RESOURCES:
{resources_text}

Return a JSON array of scores in the same order. Example: [95, 72, 30, 88]
ONLY return the JSON array, nothing else."""

    def __init__(self, groq_service):
        self.groq = groq_service
        print("[RELEVANCE] AI relevance scorer initialized")

    async def score_resources(
        self,
        resources: List[dict],
        topic: str,
        lesson_title: str,
        min_score: int = 40,
    ) -> List[dict]:
        """
        Score resources for relevance and filter out low-scoring ones.

        Args:
            resources: List of resource dicts with 'title' and 'description'
            topic: Broader subject area
            lesson_title: Specific lesson title
            min_score: Minimum score to keep (default 40)

        Returns:
            Filtered list of resources with 'ai_relevance_score' added
        """
        if not resources:
            return []

        # Don't waste an API call for tiny lists
        if len(resources) <= 2:
            for r in resources:
                r["ai_relevance_score"] = 70  # Assume decent relevance
            return resources

        # Build compact resource text for the prompt
        resources_text = self._build_resources_text(resources)

        prompt = self.SCORING_PROMPT.format(
            lesson_title=lesson_title,
            topic=topic,
            resources_text=resources_text,
        )

        try:
            response = await self.groq.generate_with_system_prompt(
                system_prompt="You are a precise JSON-only scoring bot.",
                user_message=prompt,
                temperature=0.1,
            )

            scores = self._parse_scores(response, len(resources))

            # Apply scores and filter
            scored = []
            for i, resource in enumerate(resources):
                score = scores[i] if i < len(scores) else 50
                resource["ai_relevance_score"] = score
                if score >= min_score:
                    scored.append(resource)

            logger.info(
                f"[RELEVANCE] {len(scored)}/{len(resources)} resources passed "
                f"(min_score={min_score}) for '{lesson_title}'"
            )
            return scored

        except Exception as e:
            logger.warning(f"[RELEVANCE] AI scoring failed: {e}. Returning all resources.")
            for r in resources:
                r["ai_relevance_score"] = 60  # Default to moderate
            return resources

    def _build_resources_text(self, resources: List[dict]) -> str:
        """Build compact text listing resources."""
        lines = []
        for i, r in enumerate(resources):
            title = r.get("title", "Unknown")[:80]
            desc = r.get("description", "")[:100]
            source = r.get("source", r.get("source_name", ""))
            lines.append(f"{i+1}. [{source}] {title} — {desc}")
        return "\n".join(lines)

    def _parse_scores(self, response: str, expected_count: int) -> List[int]:
        """Parse AI response into a list of integer scores."""
        # Clean the response — extract JSON array
        text = response.strip()

        # Find the JSON array in the response
        start = text.find("[")
        end = text.rfind("]")

        if start == -1 or end == -1:
            logger.warning(f"[RELEVANCE] No JSON array in response: {text[:200]}")
            return [50] * expected_count

        try:
            scores = json.loads(text[start : end + 1])
            # Ensure all values are integers in 0-100
            result = []
            for s in scores:
                if isinstance(s, (int, float)):
                    result.append(max(0, min(100, int(s))))
                else:
                    result.append(50)
            return result
        except json.JSONDecodeError as e:
            logger.warning(f"[RELEVANCE] Parse error: {e}. Response: {text[:200]}")
            return [50] * expected_count

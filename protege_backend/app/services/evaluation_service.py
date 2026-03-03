"""
Enhanced Evaluation Service for Reverse Tutoring
Provides detailed evaluation with Clarity, Accuracy, Completeness breakdown
"""
from typing import Dict, Any, Optional, List
import logging
import json

from app.services.groq_service import GroqService
from app.prompts.reverse_tutoring_prompts import (
    COMBINED_EVALUATION_PROMPT,
    CLARITY_EVALUATION_PROMPT,
    ACCURACY_EVALUATION_PROMPT,
    COMPLETENESS_EVALUATION_PROMPT,
    FINAL_FEEDBACK_PROMPT,
    CONFUSED_STUDENT_PROMPT
)

logger = logging.getLogger(__name__)


class EvaluationService:
    """Enhanced service for evaluating user explanations in reverse tutoring."""
    
    # Weights for Aha! score calculation
    CLARITY_WEIGHT = 0.30
    ACCURACY_WEIGHT = 0.40
    COMPLETENESS_WEIGHT = 0.30
    
    def __init__(self, groq_service: Optional[GroqService] = None):
        self.groq = groq_service
        # Session-level score tracking
        self._session_scores: Dict[str, Dict[str, Any]] = {}

    # ... (skipping unchanged methods for brevity in tool call, but must be careful with context)
    # I will split this into two edits: one for imports, one for method.

    async def _generate_student_response(self, score: int, topic: str, explanation: str = "") -> str:
        """Generate a confused student response based on score using AI."""
        try:
            prompt = CONFUSED_STUDENT_PROMPT.format(
                topic=topic,
                explanation=explanation,
                score=score
            )
            
            response = await self.groq.generate_with_system_prompt(
                system_prompt="You are a curious student. Be authentic and slightly confused if the score is low.",
                user_message=prompt,
                temperature=0.7,
                max_tokens=150
            )
            return response.strip()
        except Exception as e:
            logger.error(f"Failed to generate student response: {e}")
            # Fallback to hardcoded responses
            if score < 40:
                responses = [
                    "Hmm, I'm still pretty confused. Can you explain it differently?",
                    "I don't quite get it yet. Maybe try a simpler example?",
                    "That's a lot to take in. Can you break it down more?"
                ]
            elif score < 60:
                responses = [
                    "Okay, I think I'm starting to understand. But what about...?",
                    "I get the basic idea, but how does it work in practice?",
                    "That makes some sense. Can you give me a concrete example?"
                ]
            elif score < 80:
                responses = [
                    "Oh, that's clearer now! But I'm curious about the edge cases.",
                    "Nice explanation! What happens when things go wrong though?",
                    "I understand the main concept. But why is it designed that way?"
                ]
            else:
                responses = [
                    "Wow, that really clicked! I think I get it now. Thanks!",
                    "Great explanation! That makes total sense now.",
                    "Oh! I finally understand. That was really well explained!"
                ]
            
            import random
            return random.choice(responses)
    
    async def evaluate_explanation(
        self,
        topic: str,
        concepts: List[str],
        user_explanation: str,
        conversation_history: List[Dict] = None,
        reference_knowledge: Dict = None
    ) -> Dict[str, Any]:
        """
        Evaluate user's explanation with detailed breakdown.
        
        Args:
            topic: Topic being explained
            concepts: List of concepts that should be covered
            user_explanation: The user's explanation text
            conversation_history: Previous conversation messages
            reference_knowledge: Optional reference info for accuracy check
            
        Returns:
            Detailed evaluation with clarity, accuracy, completeness scores
        """
        try:
            # Format conversation history
            history_str = self._format_history(conversation_history) if conversation_history else "No previous exchanges."
            concepts_str = ", ".join(concepts) if concepts else topic
            
            # Generate combined evaluation
            eval_prompt = COMBINED_EVALUATION_PROMPT.format(
                topic=topic,
                concepts=concepts_str,
                explanation=user_explanation,
                conversation_history=history_str
            )
            
            response = await self.groq.generate_with_system_prompt(
                system_prompt="You are an expert educator evaluating teaching explanations. Always respond with valid JSON only.",
                user_message=eval_prompt,
                temperature=0.3,
                max_tokens=1024,
                json_response=True
            )
            
            # Parse the evaluation
            try:
                evaluation = self.groq.parse_json_response(response)
            except Exception as e:
                logger.error(f"Score parsing failed: {e}. Response: {response[:200]}...")
                raise e
            
            # Validate and normalize scores
            evaluation = self._normalize_evaluation(evaluation)
            
            return evaluation
            
        except Exception as e:
            logger.error(f"Evaluation failed: {e}")
            # Return fallback evaluation
            return self._get_fallback_evaluation(user_explanation)
    
    async def evaluate(
        self,
        explanation: str,
        session_id: str,
        topic: str = "",
        concepts: List[str] = None
    ) -> Dict[str, Any]:
        """
        Legacy-compatible evaluate method with session tracking.
        Updates cumulative session score.
        """
        # Get or initialize session tracking
        if session_id not in self._session_scores:
            self._session_scores[session_id] = {
                "cumulative_score": 0.0,
                "evaluation_count": 0,
                "best_clarity": 0,
                "best_accuracy": 0,
                "best_completeness": 0
            }
        
        session = self._session_scores[session_id]
        
        # Perform evaluation
        if self.groq:
            evaluation = await self.evaluate_explanation(
                topic=topic or "the topic",
                concepts=concepts or [],
                user_explanation=explanation
            )
        else:
            evaluation = self._get_fallback_evaluation(explanation)
        
        # Extract scores
        clarity = evaluation.get("clarity", {}).get("score", 50)
        accuracy = evaluation.get("accuracy", {}).get("score", 50)
        completeness = evaluation.get("completeness", {}).get("score", 50)
        overall = evaluation.get("overall_score", self.calculate_aha_score(clarity, accuracy, completeness))
        
        # Update session tracking (use best scores, not averages)
        session["best_clarity"] = max(session["best_clarity"], clarity)
        session["best_accuracy"] = max(session["best_accuracy"], accuracy)
        session["best_completeness"] = max(session["best_completeness"], completeness)
        session["evaluation_count"] += 1
        
        # Calculate cumulative Aha! score (weighted best scores)
        aha_meter_score = self.calculate_aha_score(
            session["best_clarity"],
            session["best_accuracy"],
            session["best_completeness"]
        )
        session["cumulative_score"] = aha_meter_score
        
        # Check if complete
        is_complete = aha_meter_score >= 85
        
        # Generate feedback if complete
        feedback = None
        if is_complete:
            feedback = await self._generate_final_feedback(
                topic=topic,
                score=aha_meter_score,
                clarity=session["best_clarity"],
                accuracy=session["best_accuracy"],
                completeness=session["best_completeness"],
                concepts_covered=evaluation.get("concepts_demonstrated", [])
            )
        
        # Generate student response based on score
        response = await self._generate_student_response(overall, topic, explanation)
        
        return {
            "response": response,
            "score": overall,
            "aha_meter_score": aha_meter_score,
            "aha_breakdown": {
                "clarity": session["best_clarity"],
                "accuracy": session["best_accuracy"],
                "completeness": session["best_completeness"]
            },
            "current_evaluation": evaluation,
            "concepts_demonstrated": evaluation.get("concepts_demonstrated", []),
            "suggestions": evaluation.get("suggestions", []),
            "is_complete": is_complete,
            "feedback": feedback
        }
    
    async def evaluate_clarity(self, explanation: str, topic: str) -> Dict[str, Any]:
        """Evaluate clarity specifically."""
        try:
            prompt = CLARITY_EVALUATION_PROMPT.format(
                topic=topic,
                explanation=explanation
            )
            response = await self.groq.generate_with_system_prompt(
                system_prompt="You are evaluating explanation clarity. Return valid JSON only.",
                user_message=prompt,
                temperature=0.3,
                json_response=True
            )
            return self.groq.parse_json_response(response)
        except Exception as e:
            logger.error(f"Clarity evaluation failed: {e}")
            return {"score": 50, "feedback": "Could not evaluate clarity", "strengths": [], "weaknesses": []}
    
    async def evaluate_accuracy(self, explanation: str, topic: str, facts: List[str] = None) -> Dict[str, Any]:
        """Evaluate factual accuracy."""
        try:
            reference_info = "\n".join(facts) if facts else "No reference provided."
            prompt = ACCURACY_EVALUATION_PROMPT.format(
                topic=topic,
                explanation=explanation,
                concepts="Key concepts of " + topic,
                reference_info=reference_info
            )
            response = await self.groq.generate_with_system_prompt(
                system_prompt="You are evaluating explanation accuracy. Return valid JSON only.",
                user_message=prompt,
                temperature=0.3,
                json_response=True
            )
            return self.groq.parse_json_response(response)
        except Exception as e:
            logger.error(f"Accuracy evaluation failed: {e}")
            return {"score": 50, "errors": [], "corrections": []}
    
    async def evaluate_completeness(self, explanation: str, required_concepts: List[str]) -> Dict[str, Any]:
        """Evaluate concept coverage."""
        try:
            concepts_str = ", ".join(required_concepts) if required_concepts else "main concepts"
            prompt = COMPLETENESS_EVALUATION_PROMPT.format(
                topic="the topic",
                explanation=explanation,
                concepts=concepts_str
            )
            response = await self.groq.generate_with_system_prompt(
                system_prompt="You are evaluating explanation completeness. Return valid JSON only.",
                user_message=prompt,
                temperature=0.3,
                json_response=True
            )
            return self.groq.parse_json_response(response)
        except Exception as e:
            logger.error(f"Completeness evaluation failed: {e}")
            return {"score": 50, "covered": [], "missing": required_concepts}
    
    def calculate_aha_score(self, clarity: int, accuracy: int, completeness: int) -> int:
        """Calculate final Aha! score using weighted formula."""
        score = (
            clarity * self.CLARITY_WEIGHT +
            accuracy * self.ACCURACY_WEIGHT +
            completeness * self.COMPLETENESS_WEIGHT
        )
        return int(min(100, max(0, score)))
    
    def get_session_progress(self, session_id: str) -> Dict[str, Any]:
        """Get progress for a session."""
        session = self._session_scores.get(session_id)
        if not session:
            return {"cumulative_score": 0, "evaluation_count": 0}
        return session
    
    def reset_session(self, session_id: str) -> None:
        """Reset session tracking."""
        if session_id in self._session_scores:
            del self._session_scores[session_id]
    
    def _normalize_evaluation(self, evaluation: Dict) -> Dict:
        """Ensure evaluation has all required fields with valid values."""
        # Ensure clarity exists
        if "clarity" not in evaluation:
            evaluation["clarity"] = {"score": 50, "feedback": "", "strengths": [], "weaknesses": []}
        elif isinstance(evaluation["clarity"], int):
            evaluation["clarity"] = {"score": evaluation["clarity"], "feedback": "", "strengths": [], "weaknesses": []}
        
        # Ensure accuracy exists
        if "accuracy" not in evaluation:
            evaluation["accuracy"] = {"score": 50, "errors": [], "corrections": []}
        elif isinstance(evaluation["accuracy"], int):
            evaluation["accuracy"] = {"score": evaluation["accuracy"], "errors": [], "corrections": []}
        
        # Ensure completeness exists
        if "completeness" not in evaluation:
            evaluation["completeness"] = {"score": 50, "covered": [], "missing": []}
        elif isinstance(evaluation["completeness"], int):
            evaluation["completeness"] = {"score": evaluation["completeness"], "covered": [], "missing": []}
        
        # Clamp scores to 0-100
        for key in ["clarity", "accuracy", "completeness"]:
            if isinstance(evaluation[key], dict) and "score" in evaluation[key]:
                evaluation[key]["score"] = max(0, min(100, evaluation[key]["score"]))
        
        # Calculate overall if not present
        if "overall_score" not in evaluation:
            evaluation["overall_score"] = self.calculate_aha_score(
                evaluation["clarity"].get("score", 50),
                evaluation["accuracy"].get("score", 50),
                evaluation["completeness"].get("score", 50)
            )
        
        # Ensure other fields exist
        if "concepts_demonstrated" not in evaluation:
            evaluation["concepts_demonstrated"] = []
        if "suggestions" not in evaluation:
            evaluation["suggestions"] = []
        
        return evaluation
    
    
    def _get_fallback_evaluation(self, explanation: str) -> Dict[str, Any]:
        """Generate fallback evaluation when AI fails."""
        # Return 0 scores to avoid false positives/inflation
        return {
            "clarity": {"score": 0, "feedback": "Could not evaluate clarity due to system error.", "strengths": [], "weaknesses": []},
            "accuracy": {"score": 0, "errors": [], "corrections": []},
            "completeness": {"score": 0, "covered": [], "missing": []},
            "overall_score": 0,
            "concepts_demonstrated": [],
            "suggestions": ["Please try again later."]
        }
    

    
    async def _generate_final_feedback(
        self,
        topic: str,
        score: int,
        clarity: int,
        accuracy: int,
        completeness: int,
        concepts_covered: List[str]
    ) -> str:
        """Generate final feedback for completed session."""
        try:
            prompt = FINAL_FEEDBACK_PROMPT.format(
                topic=topic,
                score=score,
                clarity=clarity,
                accuracy=accuracy,
                completeness=completeness,
                concepts_covered=", ".join(concepts_covered) if concepts_covered else "Key concepts",
                concepts_missing="None" if score >= 90 else "Some advanced topics",
                message_count="multiple"
            )
            
            feedback = await self.groq.generate_with_system_prompt(
                system_prompt="You are a supportive educator giving final feedback. Be encouraging and specific.",
                user_message=prompt,
                temperature=0.7,
                max_tokens=300
            )
            return feedback
        except Exception as e:
            logger.error(f"Failed to generate feedback: {e}")
            return self._get_fallback_feedback(score)
    
    def _get_fallback_feedback(self, score: int) -> str:
        """Generate fallback feedback."""
        if score >= 90:
            return "Excellent! You've demonstrated mastery of this topic. Your explanations were clear, accurate, and thorough. You're ready to teach others!"
        elif score >= 80:
            return "Great job! You've shown solid understanding. Your explanations helped clarify the key concepts effectively."
        elif score >= 60:
            return "Good effort! You have a decent grasp of the topic. With a bit more practice on examples and edge cases, you'll master it."
        else:
            return "You're making progress! Keep practicing breaking down concepts into simpler parts. Try using more analogies next time."
    
    def _format_history(self, history: List[Dict]) -> str:
        """Format conversation history for prompts."""
        if not history:
            return "No previous exchanges."
        
        formatted = []
        for msg in history[-6:]:  # Last 6 messages
            role = "Teacher" if msg.get("role") == "user" else "Student"
            formatted.append(f"{role}: {msg.get('content', '')}")
        
        return "\n".join(formatted)

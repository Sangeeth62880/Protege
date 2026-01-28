"""
Quiz Generator Service
Creates AI-powered quizzes for lessons
"""
import json
from typing import Optional, List, Dict, Any
from app.services.groq_service import GroqService
from app.prompts.quiz_prompts import QUIZ_SYSTEM_PROMPT, QUIZ_GENERATION_TEMPLATE
from app.models.quiz import Quiz, Question, QuizResult

class QuizGenerator:
    """Generates educational quizzes using AI."""
    
    def __init__(self, groq_service: GroqService):
        self.groq = groq_service
    
    async def generate_quiz(
        self,
        topic: str,
        lesson_title: str,
        key_concepts: List[str],
        difficulty: str = "mixed",
        num_questions: int = 5,
        question_types: Optional[List[str]] = None
    ) -> Dict[str, Any]:
        """
        Generate a quiz for a lesson.
        
        Args:
            topic: Main topic
            lesson_title: Lesson title
            key_concepts: Concepts to test
            difficulty: easy, medium, hard, or mixed
            num_questions: Number of questions (5-10)
            question_types: List of types to include
            
        Returns:
            Complete quiz with questions and answers
        """
        if question_types is None:
            question_types = ["multiple_choice", "true_false", "fill_blank", "code_completion"]
            
        prompt = QUIZ_GENERATION_TEMPLATE.format(
            topic=topic,
            lesson_title=lesson_title,
            key_concepts=", ".join(key_concepts),
            difficulty=difficulty,
            num_questions=num_questions,
            question_types=", ".join(question_types)
        )
        
        try:
            response_text = await self.groq.generate_with_system_prompt(
                system_prompt=QUIZ_SYSTEM_PROMPT,
                user_message=prompt,
                temperature=0.7,
                json_response=True  # Utilize JSON mode if supported/available in the method
            )
            
            # Use service helper to parse response
            quiz_data = self.groq.parse_json_response(response_text)
            
            # Basic validation that it matches our model
            # We don't convert to Pydantic here strictly to return dict, but we could
            # Ensure required fields exist
            if "questions" not in quiz_data:
                raise ValueError("Quiz generation failed: No questions found")
                
            return quiz_data
            
        except Exception as e:
            print(f"Error generating quiz: {e}")
            # Return a fallback or re-raise
            # For now re-raising to handle in API
            raise
    
    def validate_quiz(self, quiz: Dict[str, Any]) -> bool:
        """Validate quiz structure is correct."""
        try:
            Quiz(**quiz)
            return True
        except Exception as e:
            print(f"Quiz validation failed: {e}")
            return False
    
    def calculate_quiz_stats(self, quiz: Dict[str, Any], answers: Dict[int, str]) -> Dict[str, Any]:
        """Calculate quiz results from user answers."""
        # This mirrors the logic to create a QuizResult
        # answers maps question_number (int) -> user_answer (str)
        
        questions = quiz.get("questions", [])
        total_questions = len(questions)
        correct_count = 0
        question_results = []
        
        # Check answers
        for q in questions:
            q_num = q.get("question_number")
            user_ans = answers.get(q_num, "").strip().lower()
            correct_ans = q.get("correct_answer", "").strip().lower()
            
            # Handle multiple acceptable answers for fill_blank
            is_correct = False
            if q.get("question_type") == "fill_blank" and "acceptable_answers" in q:
                acceptable = [a.lower().strip() for a in q.get("acceptable_answers", [])]
                if user_ans in acceptable or user_ans == correct_ans:
                    is_correct = True
            else:
                if user_ans == correct_ans:
                    is_correct = True
            
            if is_correct:
                correct_count += 1
                
            question_results.append({
                "question_number": q_num,
                "user_answer": answers.get(q_num, ""),
                "correct_answer": q.get("correct_answer"),
                "is_correct": is_correct,
                "explanation": q.get("explanation")
            })
            
        score_percent = int((correct_count / total_questions) * 100) if total_questions > 0 else 0
        passed = score_percent >= 70
        
        return {
            "score": score_percent,
            "correct_count": correct_count,
            "total_questions": total_questions,
            "question_results": question_results,
            "passed": passed
        }

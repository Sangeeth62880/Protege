"""
Quiz Pydantic Models
"""
from pydantic import BaseModel
from typing import Optional, List, Dict
from enum import Enum

class QuestionType(str, Enum):
    MULTIPLE_CHOICE = "multiple_choice"
    TRUE_FALSE = "true_false"
    FILL_BLANK = "fill_blank"
    CODE_COMPLETION = "code_completion"

class Difficulty(str, Enum):
    EASY = "easy"
    MEDIUM = "medium"
    HARD = "hard"
    MIXED = "mixed"

class Question(BaseModel):
    question_number: int
    question_type: QuestionType
    difficulty: str
    question_text: str
    options: Optional[List[str]] = None
    correct_answer: str
    acceptable_answers: Optional[List[str]] = None
    code_template: Optional[str] = None
    explanation: str
    concept_tested: Optional[str] = None

class Quiz(BaseModel):
    quiz_id: Optional[str] = None
    quiz_title: str
    lesson_id: Optional[str] = None
    total_questions: int
    estimated_time_minutes: int
    questions: List[Question]

class QuizAttempt(BaseModel):
    quiz_id: str
    user_id: str
    answers: Dict[int, str]  # question_number -> user_answer
    started_at: str
    completed_at: Optional[str] = None

class QuizResult(BaseModel):
    quiz_id: str
    user_id: str
    score: int  # percentage
    correct_count: int
    total_questions: int
    time_taken_seconds: int
    question_results: List[Dict]  # per-question breakdown
    strengths: List[str]
    weaknesses: List[str]
    passed: bool  # score >= 70%

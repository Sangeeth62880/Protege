import pytest
from fastapi.testclient import TestClient
from unittest.mock import AsyncMock, MagicMock
from app.main import app
from app.api.routes.quiz import get_quiz_generator, get_firebase_service
from app.models.quiz import Quiz, QuizResult

# Mock Data
MOCK_QUIZ = {
    "quiz_title": "Test Quiz",
    "total_questions": 1,
    "estimated_time_minutes": 5,
    "questions": [
        {
            "question_number": 1,
            "question_type": "multiple_choice",
            "difficulty": "easy",
            "question_text": "Test Q?",
            "options": ["A", "B"],
            "correct_answer": "A",
            "explanation": "Exp",
            "concept_tested": "Testing"
        }
    ]
}

MOCK_STATS = {
    "score": 100,
    "correct_count": 1,
    "total_questions": 1,
    "question_results": [],
    "passed": True
}

# Mocks
mock_generator = MagicMock()
mock_generator.generate_quiz = AsyncMock(return_value=MOCK_QUIZ)
mock_generator.calculate_quiz_stats = MagicMock(return_value=MOCK_STATS)

mock_firebase = MagicMock()
mock_firebase.create_document = AsyncMock(return_value=True)
mock_firebase.get_document = AsyncMock(return_value=MOCK_QUIZ)
mock_firebase.update_document = AsyncMock(return_value=True)
mock_firebase.query_collection = AsyncMock(return_value=[])

# Overrides
app.dependency_overrides[get_quiz_generator] = lambda: mock_generator
app.dependency_overrides[get_firebase_service] = lambda: mock_firebase

client = TestClient(app)

def test_generate_quiz():
    response = client.post("/api/v1/quiz/generate", json={
        "topic": "Python",
        "lesson_title": "Intro",
        "key_concepts": ["Vars"],
        "difficulty": "easy",
        "num_questions": 1
    })
    
    assert response.status_code == 200
    data = response.json()
    assert data["quiz_title"] == "Test Quiz"
    assert "quiz_id" in data
    
    # Verify mock calls
    mock_generator.generate_quiz.assert_called_once()
    mock_firebase.create_document.assert_called()

def test_submit_quiz():
    # Setup mock to return the quiz when fetched
    mock_firebase.get_document.return_value = MOCK_QUIZ
    
    response = client.post("/api/v1/quiz/submit", json={
        "quiz_id": "test-id",
        "answers": {1: "A"},
        "time_taken_seconds": 30
    })
    
    assert response.status_code == 200
    data = response.json()
    assert data["score"] == 100
    assert data["passed"] == True
    
    mock_firebase.create_document.assert_called() # Should save result

def test_get_history():
    # Setup mock response
    mock_result = {
        "quiz_id": "q1",
        "user_id": "u1",
        "score": 80,
        "correct_count": 4,
        "total_questions": 5,
        "time_taken_seconds": 120,
        "question_results": [],
        "strengths": [],
        "weaknesses": [],
        "passed": True
    }
    mock_firebase.query_collection.return_value = [mock_result]
    
    response = client.get("/api/v1/quiz/history/u1")
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["score"] == 80

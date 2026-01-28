# test_quiz_generator.py
import asyncio
import os
import json
from dotenv import load_dotenv
load_dotenv()

# Add current directory to path so we can import app modules
import sys
sys.path.append(os.getcwd())

try:
    from app.services.groq_service import GroqService
    from app.services.quiz_generator import QuizGenerator
except ImportError as e:
    print(f"Import Error: {e}")
    print("Make sure you are running this from the protege_backend directory")
    sys.exit(1)

async def test():
    print("🚀 Starting Quiz Generator Test...")
    
    api_key = os.getenv("GROQ_API_KEY")
    if not api_key:
        print("❌ Error: GROQ_API_KEY not found in environment variables")
        return

    print("✅ Found API Key")
    
    try:
        groq = GroqService(api_key=api_key)
        generator = QuizGenerator(groq_service=groq)
        
        print("⏳ Generating quiz (this may take a few seconds)...")
        quiz = await generator.generate_quiz(
            topic="Python Basics",
            lesson_title="Understanding Variables",
            key_concepts=["variables", "data types", "assignment"],
            difficulty="mixed",
            num_questions=5
        )
        
        print(f"\n✅ Quiz Generated: {quiz.get('quiz_title')}")
        print(f"Total Questions: {len(quiz.get('questions', []))}")
        
        questions = quiz.get('questions', [])
        for q in questions:
            print(f"  Q{q['question_number']}: [{q['question_type']}] {q['question_text'][:50]}...")
        
        assert len(questions) >= 5, "Should have at least 5 questions"
        
        # Test validation
        print("\n🔍 Validating quiz structure...")
        is_valid = generator.validate_quiz(quiz)
        if is_valid:
            print("✅ Quiz structure is valid (matches Pydantic model)")
        else:
            print("❌ Quiz structure validation failed")
            
        print("\n🎉 Quiz generator test passed!")
        
    except Exception as e:
        print(f"\n❌ Test Failed with error: {str(e)}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(test())

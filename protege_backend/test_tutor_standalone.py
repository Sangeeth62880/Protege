# test_tutor_standalone.py
import asyncio
import os
import sys
from dotenv import load_dotenv

# Add app to path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.services.groq_service import GroqService
from app.services.tutor_service import TutorService

load_dotenv()

async def test():
    print("=== Testing Tutor Service Standalone ===")
    
    api_key = os.getenv("GROQ_API_KEY")
    if not api_key:
        print("❌ Error: GROQ_API_KEY not found")
        return

    groq = GroqService(api_key=api_key)
    tutor = TutorService(groq_service=groq)
    
    try:
        response = await tutor.ask_question(
            session_id="test-session-1",
            question="What is a variable in Python?",
            topic="Python Basics",
            lesson_title="Understanding Variables",
            key_concepts=["variables", "data types", "assignment"],
            experience_level="beginner"
        )
        
        print(f"\nResponse: {response}")
        assert response.get('response'), "No response received"
        assert len(response['response']) > 50, "Response too short"
        print("✅ Tutor service test passed!")
        
    except Exception as e:
        print(f"\n❌ Test Failed: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(test())

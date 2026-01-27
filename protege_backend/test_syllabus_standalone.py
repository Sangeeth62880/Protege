import asyncio
import os
import sys
from dotenv import load_dotenv

# Add parent dir to path to import app modules
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.services.groq_service import GroqService
from app.services.syllabus_generator import SyllabusGenerator
from app.models.learning_path import DifficultyLevel

# Load env vars
load_dotenv()

async def test_generation():
    print("=== Testing Syllabus Generation Standalone ===")
    
    api_key = os.getenv("GROQ_API_KEY")
    if not api_key:
        print("❌ Error: GROQ_API_KEY not found in .env")
        return

    print(f"✅ Found API Key: {api_key[:10]}...")
    
    try:
        # Initialize services
        groq_service = GroqService(api_key=api_key)
        generator = SyllabusGenerator(groq_service)
        
        # Test Data
        topic = "Flutter Riverpod"
        goal = "Build a state management system"
        difficulty = DifficultyLevel.INTERMEDIATE
        duration = 30
        
        print(f"\n🚀 Generating syllabus for: {topic} ({difficulty.value})")
        
        # Generate
        syllabus = await generator.generate_syllabus(
            topic=topic,
            goal=goal,
            experience_level=difficulty,
            daily_time_minutes=duration
        )
        
        print("\n✅ Generation Successful!")
        print(f"Topic: {syllabus.topic}")
        print(f"Modules: {len(syllabus.modules)}")
        print(f"Total Duration: {syllabus.total_duration_hours} hours")
        
        # Print first module details
        if syllabus.modules:
            m1 = syllabus.modules[0]
            print(f"\nFirst Module: {m1.title}")
            print(f"Lessons: {len(m1.lessons)}")
            
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(test_generation())

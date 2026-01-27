import asyncio
import os
import sys
import json

# Add project root to path
sys.path.append(os.getcwd())

from app.services.groq_service import GroqService
from app.services.syllabus_generator import SyllabusGenerator
from app.models.learning_path import DifficultyLevel
from app.config import settings

async def main():
    print(f"🔧 Testing Syllabus Generation...")
    
    if not settings.GROQ_API_KEY:
        print("❌ Error: GROQ_API_KEY not set")
        return

    groq_service = GroqService(api_key=settings.GROQ_API_KEY)
    generator = SyllabusGenerator(groq_service)
    
    topic = "Python for Data Science"
    goal = "Build a portfolio project analyzing Kaggle datasets"
    level = DifficultyLevel.BEGINNER
    time = 45
    
    print(f"📚 Topic: {topic}")
    print(f"🎯 Goal: {goal}")
    print("⏳ Generatin... (this may take 10-20 seconds)")
    
    try:
        syllabus = await generator.generate_syllabus(
            topic=topic,
            goal=goal,
            experience_level=level,
            daily_time_minutes=time
        )
        
        print("\n✅ Generation Successful!")
        print(f"Title: {syllabus.topic}")
        print(f"Difficulty: {syllabus.difficulty}")
        print(f"Modules: {len(syllabus.modules)}")
        
        print("\n--- Example Module 1 ---")
        if syllabus.modules:
            m1 = syllabus.modules[0]
            print(f"Title: {m1.title}")
            print(f"Lessons: {len(m1.lessons)}")
            if m1.lessons:
                l1 = m1.lessons[0]
                print(f"First Lesson: {l1.title}")
                print(f"Query: {l1.search_queries.youtube}")

        # Dump to file for inspection
        with open("tests/generated_syllabus.json", "w") as f:
            f.write(json.dumps(syllabus.model_dump(), indent=2, default=str)) # Use dict() or model_dump()
            
        print("\n💾 Saved full JSON to tests/generated_syllabus.json")
            
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(main())

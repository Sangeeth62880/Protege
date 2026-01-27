"""
Direct test of syllabus generation - bypasses API, tests core logic
"""
import asyncio
import os
import sys
import json
import time
from dotenv import load_dotenv

# Add app to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

load_dotenv()

async def test_syllabus_generation():
    print("=" * 60)
    print("DIRECT SYLLABUS GENERATION TEST")
    print("=" * 60)
    
    # Step 1: Check environment variables
    print("\n[STEP 1] Checking environment variables...")
    
    groq_key = os.getenv("GROQ_API_KEY")
    if not groq_key:
        print("❌ GROQ_API_KEY not found in environment!")
        return False
    
    print(f"✅ GROQ_API_KEY found: {groq_key[:10]}...")
    
    # Step 2: Init Services
    print("\n[STEP 2] Initializing Services...")
    try:
        from app.services.groq_service import GroqService
        from app.services.syllabus_generator import SyllabusGenerator
        
        groq_service = GroqService(api_key=groq_key)
        generator = SyllabusGenerator(groq_service=groq_service)
        print("   ✅ Services initialized")
    except Exception as e:
        print(f"   ❌ Failed to initialize services: {e}")
        return False
    
    # Step 5: Generate actual syllabus
    print("\n[STEP 3] Generating syllabus...")
    print("   Topic: Python basics for beginners")
    print("   (This may take 15-60 seconds...)")
    
    try:
        start_time = time.time()
        
        syllabus = await generator.generate_syllabus(
            topic="Python basics for beginners",
            goal="hobby",
            experience_level="beginner",
            daily_time_minutes=30
        )
        
        elapsed = time.time() - start_time
        print(f"   ✅ Syllabus generated in {elapsed:.1f} seconds")
        
        # Check if modules exist
        modules = syllabus.get('modules', [])
        print(f"   ✅ Modules count: {len(modules)}")
        if len(modules) > 0:
             print(f"   ✅ First module: {modules[0].get('title')}")
        else:
             print("   ❌ No modules found!")

    except Exception as e:
        print(f"   ❌ Syllabus generation failed: {e}")
        import traceback
        traceback.print_exc()
        return False
    
    return True


if __name__ == "__main__":
    asyncio.run(test_syllabus_generation())

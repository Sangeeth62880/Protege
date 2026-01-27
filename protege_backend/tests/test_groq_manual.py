import asyncio
import os
import sys

# Add project root to path
sys.path.append(os.getcwd())

from app.services.groq_service import GroqService
from app.config import settings

async def main():
    print(f"🔧 Testing Groq Integration...")
    
    if not settings.GROQ_API_KEY:
        print("❌ Error: GROQ_API_KEY not set in .env")
        return

    # print(f"API Key: {settings.GROQ_API_KEY[:5]}...{settings.GROQ_API_KEY[-4:]}")
    print(f"🤖 Model: {settings.GROQ_MODEL}")
    
    service = GroqService(api_key=settings.GROQ_API_KEY)
    
    try:
        print("📡 Sending request...")
        response = await service.generate_with_system_prompt(
            system_prompt="You are a helpful assistant.",
            user_message="Say 'Hello Protégé!' and nothing else.",
            model=settings.GROQ_MODEL
        )
        print(f"✅ Success! Response: {response}")
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    asyncio.run(main())

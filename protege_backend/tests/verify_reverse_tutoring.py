
import asyncio
import sys
import os
from fastapi.testclient import TestClient
from unittest.mock import MagicMock, AsyncMock

# Add project root to path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.main import app
from app.services.evaluation_service import EvaluationService
from app.api.dependencies import get_current_user

# Override auth dependency
async def mock_get_current_user():
    return {"uid": "test_user", "email": "test@example.com"}

app.dependency_overrides[get_current_user] = mock_get_current_user

client = TestClient(app)

async def verify_fixes():
    print("🚀 Verifying Reverse Tutoring Fixes...")
    
    # 1. Verify Singleton Initialization
    print("\n[1] Verifying Singleton Initialization...")
    eval_service = app.state.evaluation_service
    if isinstance(eval_service, EvaluationService):
        print("✅ EvaluationService initialized in app.state")
    else:
        print("❌ EvaluationService not found in app.state")
        
    # 2. Verify Session Persistence (Bug 2)
    print("\n[2] Verifying Session Persistence...")
    session_id = "test_session_123"
    
    # Mock Groq response for consistent testing
    mock_groq = MagicMock()
    mock_groq.generate_with_system_prompt = AsyncMock(return_value='{"clarity": {"score": 80}, "accuracy": {"score": 80}, "completeness": {"score": 80}, "overall_score": 80}')
    mock_groq.parse_json_response = MagicMock(return_value={
        "clarity": {"score": 80}, 
        "accuracy": {"score": 80}, 
        "completeness": {"score": 80}, 
        "overall_score": 80
    })
    
    # Inject mock into service
    app.state.evaluation_service.groq = mock_groq
    
    # Call evaluate endpoint twice
    payload = {
        "session_id": session_id,
        "user_id": "test_user",
        "explanation": "Test explanation 1"
    }
    
    # First call
    response1 = client.post("/api/v1/teaching/evaluate", json=payload)
    if response1.status_code == 200:
        print("✅ First evaluation successful")
    else:
        print(f"❌ First evaluation failed: {response1.text}")
        
    # Check internal state directly
    if session_id in app.state.evaluation_service._session_scores:
        print("✅ Session state exists after first call")
        count = app.state.evaluation_service._session_scores[session_id]["evaluation_count"]
        print(f"   Evaluation count: {count}")
    else:
        print("❌ Session state MISSING after first call (Bug 2 persists?)")

    # Second call
    payload["explanation"] = "Test explanation 2"
    response2 = client.post("/api/v1/teaching/evaluate", json=payload)
    if response2.status_code == 200:
        print("✅ Second evaluation successful")
        count = app.state.evaluation_service._session_scores[session_id]["evaluation_count"]
        print(f"   Evaluation count: {count}")
        if count == 2:
            print("✅ Evaluation count incremented (State persisted!)")
        else:
            print("❌ Evaluation count NOT incremented (State lost!)")
            
    # 3. Verify Error Handling (Bug 8)
    print("\n[3] Verifying Error Handling Fallback...")
    # Make Groq fail
    app.state.evaluation_service.groq.generate_with_system_prompt.side_effect = Exception("Groq API Error")
    
    response_err = client.post("/api/v1/teaching/evaluate", json=payload)
    if response_err.status_code == 200:
        data = response_err.json()
        print(f"✅ Error handled gracefully. Status: {response_err.status_code}")
        print(f"   Score: {data.get('score')} (Should be 0.0)")
        print(f"   Response: {data.get('response')}")
        if data.get('score') == 0.0:
            print("✅ Fallback score is 0.0 (Bug 8 fixed)")
        else:
            print(f"❌ Fallback score is {data.get('score')} (Bug 8 not fixed)")
    else:
        print(f"❌ Error handling failed: {response_err.status_code}")

    # 4. Verify AI Chat Fallback (Bug 7)
    print("\n[4] Verifying AI Chat Fallback...")
    # Mock chat failure
    app.state.groq_service.chat = AsyncMock(side_effect=Exception("Chat Error"))
    
    chat_payload = {"message": "Hello", "context": "Science"}
    response_chat = client.post("/api/v1/ai/chat", json=chat_payload)
    
    if response_chat.status_code == 200:
        data = response_chat.json()
        print(f"✅ Chat fallback received: {data.get('response')}")
        if "about Science" in data.get('response') or "about Science" in str(data.get('suggestions')):
             print("✅ Context hint present in fallback (Bug 7 fixed)") # logic might vary based on implementation details
        else:
             print("⚠️ Context hint check (might be implicit)")
    else:
         print(f"❌ Chat fallback failed: {response_chat.status_code}")

if __name__ == "__main__":
    # Need to trigger startup event manually for TestClient depending on version, 
    # but TestClient usually handles strictly. 
    # However, since we rely on app.state which is set in startup, we must ensure it ran.
    with TestClient(app) as c:
        # trigger startup
        c.get("/health") 
        asyncio.run(verify_fixes())

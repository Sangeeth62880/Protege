# Protégé Backend

AI-powered learning companion backend using FastAPI.

## Setup

1. Create a virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Create `.env` file with your API keys:
```
GROQ_API_KEY=your_groq_api_key
YOUTUBE_API_KEY=your_youtube_api_key
GITHUB_TOKEN=your_github_token
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_PRIVATE_KEY=your_private_key
FIREBASE_CLIENT_EMAIL=your_client_email
```

4. Run the server:
```bash
uvicorn app.main:app --reload
```

## API Documentation

- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Endpoints

### Auth
- `GET /api/v1/auth/verify` - Verify Firebase token
- `GET /api/v1/auth/profile` - Get user profile

### Learning
- `POST /api/v1/learning/generate` - Generate AI learning path
- `GET /api/v1/learning/paths` - Get user's learning paths
- `PUT /api/v1/learning/paths/{id}/progress` - Update progress

### Resources
- `GET /api/v1/resources/search` - Search for resources
- `GET /api/v1/resources/youtube` - Search YouTube
- `GET /api/v1/resources/github` - Search GitHub

### AI
- `POST /api/v1/ai/chat` - Chat with AI tutor
- `POST /api/v1/ai/explain` - Explain a concept

### Quiz
- `POST /api/v1/quiz/generate` - Generate quiz
- `POST /api/v1/quiz/submit` - Submit quiz answers

### Teaching
- `POST /api/v1/teaching/session` - Start teaching session
- `POST /api/v1/teaching/evaluate` - Evaluate explanation

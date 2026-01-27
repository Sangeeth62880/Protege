# Protégé - AI Learning Companion

Protégé is an intelligent, mission-driven mobile learning application designed to help users master new skills through personalized, AI-generated learning paths. It combines the power of LLMs (Llama 3 via Groq) with curated multi-media resources to create a dynamic educational experience.

## 🚀 Features

*   **AI-Generated Syllabi**: Generates structured learning paths (Modules > Lessons) for any topic.
*   **Curated Resources**: Automatically aggregates high-quality resources for every lesson:
    *   📹 **Videos**: Tutorials from YouTube.
    *   📄 **Articles**: Guides from Dev.to, Hashnode, freeCodeCamp, and more.
    *   💻 **Code Examples**: Repositories from GitHub.
    *   📖 **Overviews**: Summaries from Wikipedia.
*   **AI Tutor**: Interactive chat for clarifying doubts and asking questions.
*   **Gamification**: Track progress, streaks, and achievements (In Progress).
*   **Cross-Platform**: Built with Flutter (Android/iOS) and FastAPI (Python).

## 🛠️ Tech Stack

### Frontend (Mobile)
*   **Framework**: Flutter (Dart)
*   **State Management**: Riverpod
*   **Navigation**: GoRouter
*   **Networking**: Dio
*   **UI Components**: Custom clean design with Glassmorphism elements.

### Backend (API)
*   **Framework**: FastAPI (Python 3.12)
*   **AI Engine**: Groq API (Llama 3 Instruct)
*   **External APIs**:
    *   YouTube Data API
    *   GitHub API
    *   Dev.to API
    *   Wikipedia REST API
    *   Hashnode/FreeCodeCamp (GraphQL/RSS)
*   **Database**: Firebase Firestore (Persistence)
*   **Auth**: Firebase Authentication

## 📂 Project Structure

```
Protege/
├── protege_app/          # Flutter Frontend
│   ├── lib/              # Application Code
│   │   ├── core/         # Constants, Themes, Router
│   │   ├── data/         # Models, Repositories, Services
│   │   ├── presentation/ # Screens, Widgets, Providers
│   └── ...
│
└── protege_backend/      # FastAPI Backend
    ├── app/
    │   ├── api/          # API Routes (v1)
    │   ├── services/     # Business Logic & Integrations
    │   ├── prompts/      # AI Prompt Engineering
    │   └── main.py       # Application Entry Point
    └── ...
```

## 🔧 Setup & Installation

### Prerequisites
*   Flutter SDK
*   Python 3.11+
*   Firebase Project (configured)
*   API Keys (Groq, YouTube, etc.)

### 1. Backend Setup
```bash
cd protege_backend
python -m venv venv
source venv/bin/activate  # or venv\Scripts\activate on Windows
pip install -r requirements.txt
uvicorn app.main:app --reload
```

### 2. Frontend Setup
```bash
cd protege_app
flutter pub get
flutter run
```

## 🤝 Contributing
1.  Fork the repository.
2.  Create a feature branch (`git checkout -b feature/amazing-feature`).
3.  Commit changes (`git commit -m 'Add amazing feature'`).
4.  Push to branch (`git push origin feature/amazing-feature`).
5.  Open a Pull Request.

## 📄 License
This project is licensed under the MIT License.

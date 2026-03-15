# Protégé System Architecture Guide

Welcome to the **Protégé** system architecture guide. This document provides a comprehensive overview of the application's overall structure, technologies used, data flow, and core logic. It is designed to help you study the system completely and acts as an excellent reference for presentations.

---

## 1. System Overview

Protégé is an AI-powered learning companion. It consists of a **Frontend** mobile/web application built with Flutter, and a **Backend** RESTful API built with Python and FastAPI. The system leverages generative AI (Groq), serverless databases (Firebase/Firestore), and third-party content providers to deliver personalized learning paths, dynamic syllabuses, interactive tutoring sessions, and topic-based quizzes.

### High-Level Tech Stack
*   **Frontend:** Flutter (Dart)
*   **Backend:** Python 3, FastAPI, Uvicorn
*   **Database & Authentication:** Firebase (Firestore, Auth)
*   **State Management (Frontend):** Riverpod, GoRouter
*   **AI Models & Engine:** Groq API (LLM provider)
*   **Content Integrations:** YouTube, GitHub, Wikipedia, DevTo, MDN, Coursera, StackOverflow, OpenStax, OpenLibrary
*   **Document Intelligence (RAG):** Custom chunking, embedding, and vector stores for chatting with uploaded documents.

---

## 2. Backend Architecture (`protege_backend`)

The backend is structured under the `app/` directory following a clean API service pattern.

### Directory Structure
*   **`api/routes/`**: Defines the REST endpoints grouped by category (e.g., `learning.py`, `quiz.py`, `resources.py`, `ai.py`, `teaching.py`, `documents.py`, `audio.py`, `tutor.py`).
*   **`services/`**: The Core logic layer. This is where business rules, third-party API calls, and LLM integrations live.
*   **`models/`**: Pydantic models for data validation and schema definitions (e.g., `learning_path.py`, `quiz.py`, `user.py`).
*   **`main.py`**: The application entry point. It initializes all services (singleton pattern), attaches them to `app.state`, and registers all routers.
*   **`config.py`**: Environment variables and configuration loader.

### Core Logic & Services

#### A. Content & Learning Generation
*   **`SyllabusGenerator` & `LessonContentGenerator`**: Uses the `GroqService` to dynamically generate a customized learning syllabus and individual lesson text based on the user's topic, goal, and experience level.
*   **`QuizGenerator`**: Processes learning modules and uses the LLM to generate multiple-choice questions dynamically to test user knowledge.

#### B. The Persona & Tutor Engine
*   **`TutorService` & `PersonaEngine`**: Manages the conversational AI interfaces. The AI can adopt different "personas" and adapt to the student's learning style.
*   **Teaching / Evaluation (`EvaluationService` & `MisconceptionService`)**: These services are used when the user *teaches* a concept back to the AI. The system evaluates the explanation, provides a score, and identifies technical misconceptions, leveraging LLMs.

#### C. Resources Pipeline
*   **`ResourceCurator`**: A master aggregator that calls individual platform services (`YouTubeService`, `GitHubService`, `WikipediaService`, `OpenStaxService`, etc.).
*   **`RelevanceScorer`**: Uses the LLM to score the fetched resources based on how well they match the current lesson content, returning only the most relevant materials to the user.

#### D. Document Intelligence (RAG)
*   **`DocumentExtractionService` & `ChunkingService`**: Parses uploaded documents and breaks them into smaller text chunks.
*   **`EmbeddingService` & `VectorStoreService`**: Creates vector embeddings of those chunks and stores them locally (e.g., using Chroma).
*   **`RAGService`**: "Retrieval-Augmented Generation." When a user asks a question about their document, this service fetches the most relevant chunks from the vector store and passes them to the LLM to generate an accurate answer.

---

## 3. Frontend Architecture (`protege_app`)

The frontend is built with **Flutter** and follows a robust feature-first/layer-first architecture, heavily relying on **Riverpod** for state.

### Directory Structure & Layers (`lib/`)
*   **`main.dart` & `app.dart`**: Entry points mapping out Firebase initialization, Storage setup, Theme injection, and the top-level `MaterialApp` with `GoRouter`.
*   **`core/`**: Contains foundational code such as `AppTheme` (styling, colors), `AppRouter` (navigation paths mapping to screens), and constants string resources.
*   **`data/`**: 
    *   **`models/`**: Dart data classes mirroring the backend API responses.
    *   **`repositories/` & `services/`**: Code that makes HTTP/Dio calls to the FastAPI backend or interacts directly with Firebase (auth) and local storage (shared preferences).
*   **`providers/`**: The nervous system of the app (Riverpod). It acts as the ViewModel/Controller layer:
    *   *Examples:* `auth_provider.dart`, `learning_provider.dart`, `tutor_provider.dart`, `document_providers.dart`. These connect UI actions to background data calls, managing loading states and data caching.
*   **`presentation/`**: 
    *   **`screens/`**: The complete pages the user navigates to (e.g., Dashboard, Lesson View, Teaching Session).
    *   **`widgets/`**: Reusable UI components like buttons, cards, and custom icons.

### State & Logic Flow
1.  **User Action:** User taps a button on a Screen in `presentation/`.
2.  **Provider Trigger:** The UI calls a method on a Provider in `providers/` (e.g., `ref.read(learningProvider.notifier).generatePath()`).
3.  **Data Fetching:** The Provider communicates with the `data/` layer making network requests to the FastAPI backend.
4.  **State Update:** Once the backend returns data, the Provider updates its internal state.
5.  **UI Rebuild:** Because the Screen is "watching" (`ref.watch`) the Provider, the UI automatically rebuilds to reflect the new data.

---

## 4. Database & Scaling (Firebase)

The system relies heavily on Firebase Firestore for database operations.
*   **Backend Aggregation:** The Python backend builds massive objects (like a generated `Syllabus` inside nested modules and lessons) and pushes it to Firestore using `FirebaseService`.
*   **Frontend Syncing:** The Flutter app can read these paths directly from the backend API, or subscribe to Firestore directly, allowing real-time progress syncing between devices.

---

## 5. Presentation Talking Points

If you are presenting this architecture, focus on these strong points:
1.  **"Agentic" AI Workflows:** Highlight how the backend doesn't just do basic Chat. Note the separate intelligent pipelines: the `ResourceCurator` gathering data and `RelevanceScorer` grading it, and the `EvaluationService` grading the student's explanations.
2.  **State-of-the-Art Mobile Stack:** Emphasize the use of Riverpod and GoRouter in Flutter for reactive, highly testable, and robust frontend state management.
3.  **Modular Document Intelligence (RAG):** Mention the distinct separation of Chunking, Embedding, Vector Store, and RAG services, providing a professional-grade architecture for chatting with documents.
4.  **Scalable Data Handling:** Point out that while heavy AI processing is done on the Python backend, the immediate, real-time user data (profiles, progress) is efficiently handled via Firebase.

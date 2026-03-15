# Protégé Project Deep-Dive: End-to-End Architecture & Data Flow

## 1) Executive Overview

**What problem Protégé solves:**
Protégé is an AI-powered learning companion designed to democratize access to personalized, structured education. It solves the problem of information overload and static learning by providing dynamically generated syllabuses, curated multi-modal resources, and active recall mechanisms (like reverse tutoring and quizzes) tailored to a user's specific learning goals and experience level.

**Main user journeys:**
1.  **Learn:** Users define a goal, and the system generates a structured, multi-module learning path.
2.  **Quiz:** Users test their knowledge on completed modules through dynamically generated assessments.
3.  **Progress Tracking:** The system tracks lesson completion, calculates overall path progress, and awards Experience Points (XP).
4.  **Reverse Tutoring:** Users solidify their understanding by teaching concepts back to an AI persona, which evaluates their explanation and corrects misconceptions.
5.  **Documents (RAG):** Users upload their own materials (PDFs), parse them into the system, and interactively chat with their specific documents for targeted learning.

**How AI is used:**
The system relies on Large Language Models (LLMs), specifically the Groq API, to power core features:
*   **Syllabus Generation:** Structuring topics into logical modules and actionable lessons.
*   **Resource Curation:** Scoring the relevance of scraped third-party resources against lesson content to ensure high-quality study materials.
*   **Tutoring & Evaluation:** Acting as conversational personas and objectively grading user explanations for technical accuracy.

**High-level tech stack:**
*   **Frontend:** Flutter (Dart) for cross-platform mobile UI.
*   **Backend:** FastAPI (Python 3) for high-performance, async API endpoints.
*   **Database & Auth:** Firebase Auth for identity management; Cloud Firestore for NoSQL real-time data storage.
*   **AI & External APIs:** Groq (LLM), YouTube Data API, GitHub Search API, Wikipedia API, Dev.to API, OpenStax, OpenLibrary, and more.

---

## 2) Repository Map

### `protege_app/` (Flutter Frontend)
The frontend repository uses a feature-first, layered architecture.

*   `lib/core/`
    *   **Purpose:** Houses foundational app configurations, routing, themes, and constants.
    *   **Typical files:** `app_router.dart` (GoRouter setup), `app_theme.dart` (colors/typography), `app_strings.dart`.
    *   **Dependencies:** Navigation, UI styling, and environment variables rely on this.
*   `lib/data/`
    *   **Purpose:** Handles external data communication and object serialization.
    *   **Typical files:** Models (e.g., `models/learning_path.dart`), Repositories/Services (e.g., `services/api_service.dart`, `services/firebase_service.dart`).
    *   **Dependencies:** Providers rely on this layer to fetch and parse external data.
*   `lib/providers/`
    *   **Purpose:** State management layer using Riverpod (`flutter_riverpod`). Acts as the controller connecting the UI to the data layer.
    *   **Typical files:** `learning_provider.dart`, `auth_provider.dart`, `resource_provider.dart`.
    *   **Dependencies:** Screens and widgets watch these providers to reactively rebuild when state changes.
*   `lib/presentation/`
    *   **Purpose:** The visual layer containing all user-facing elements.
    *   **Typical files:** `screens/dashboard_screen.dart`, `widgets/buttons/primary_button.dart`.
    *   **Dependencies:** Depends entirely on `lib/providers/` for state and `lib/core/` for styling.

### `protege_backend/` (FastAPI Backend)
The backend repository follows a clean, highly modular service-oriented architecture.

*   `app/api/routes/`
    *   **Purpose:** Defines the HTTP REST endpoints (controllers).
    *   **Typical files:** `learning.py`, `resources.py`, `teaching.py`.
    *   **Dependencies:** The frontend clients depend on these exact URL paths to interact with the system.
*   `app/services/`
    *   **Purpose:** Contains the core business logic, third-party API integrations, and AI orchestration.
    *   **Typical files:** `syllabus_generator.py`, `resource_curator.py`, `groq_service.py`.
    *   **Dependencies:** The API routes depend on these services to process requests before returning responses.
*   `app/models/`
    *   **Purpose:** Defines Pydantic models for request validation and response serialization.
    *   **Typical files:** `learning_path.py`, `teaching.py`.
    *   **Dependencies:** Used heavily by `routes` and `services` to ensure data integrity.
*   **Configuration (`app/config.py`, `.env`)**
    *   **Purpose:** Loads environment variables and API keys required for external services.

---

## 3) Frontend Architecture (Flutter)

**A. Presentation Layer**
*   **Screens:** Located in `protege_app/lib/presentation/screens/`. These are highly composed, route-level widgets (e.g., the full "Explore" page or "Lesson" page).
*   **Reusable UI:** Located in `protege_app/lib/presentation/widgets/`. Contains atomic UI components like custom buttons, cards, and input fields to ensure design consistency.
*   **Shell/Navigation:** The app utilizes a "Shell Route" pattern (often defined in `app_router.dart` and implemented via a `MainShell` or `BottomNavScaffold` widget). This wrapper persists the Bottom Navigation Bar across primary tabs (Dashboard, Explore, User Profile) while allowing sub-screens (like a Lesson view) to push over the shell or swap content within it.

**B. State Management**
*   **Location:** `protege_app/lib/providers/`.
*   **Watching Providers:** Screens use `ConsumerWidget` or `ConsumerStatefulWidget` to access the `WidgetRef`. They use `ref.watch(providerName)` to listen for changes. When the provider's state updates (e.g., from loading to data), the build method automatically re-runs.
*   **State Handling:** Providers commonly use `AsyncValue` (from Riverpod). UIs must handle three states: `.when(data: (data) => buildUI, loading: () => CircularProgressIndicator(), error: (err, stack) => ErrorWidget())`.

**C. Data Layer**
*   **Models:** `protege_app/lib/data/models/`. Dart classes with `.fromJson` and `.toJson` factory methods mirroring backend Pydantic definitions.
*   **Services:** `protege_app/lib/data/services/`.
*   **API Targeting:** Most logic calling the custom FastAPI backend routes goes through an `ApiService` wrapper. Direct calls to Firebase (authentication, direct Firestore reads for real-time sync) are handled by a dedicated `FirebaseService` or `StorageService`.

---

## 4) Backend Architecture (FastAPI)

**A. API Layer**
*   **Location:** `protege_backend/app/api/routes/`.
*   **Grouping:** Endpoints are grouped logically via FastAPI `APIRouter` instances. For example, `learning.py` handles syllabus generation and path saving; `resources.py` handles fetching external content; `teaching.py` handles the reverse-tutoring evaluation flow.
*   **Lifecycle:**
    1.  Request hits endpoint.
    2.  Pydantic validates the incoming JSON body against defined models.
    3.  The endpoint extracts initialized services from `request.app.state` (dependency injection pattern).
    4.  The endpoint calls the respective Service layer method.
    5.  The result is packaged into a Pydantic response model and returned as JSON.

**B. Service Layer**
*   **Location:** `protege_backend/app/services/`.
*   **Resource Curation Pipeline (`resource_curator.py`):** This is a critical orchestration service. When asked for resources for a lesson, it executes asynchronous tasks in parallel (`asyncio.gather`) to query YouTube, GitHub, Dev.to, Wikipedia, etc. It then passes the aggregated, raw baseline results to the `RelevanceScorer`, which uses the LLM to score and filter out irrelevant links before returning the finalized list.
*   **Syllabus Generator Pipeline (`syllabus_generator.py`):** Takes user parameters (topic, goal, difficulty), constructs a highly specific prompt, and calls the `GroqService`. The LLM's raw text output is then parsed (often expecting strict JSON structures from the LLM via prompt engineering) into structured `Module` and `Lesson` Python objects.

**C. Configuration**
*   **Environment Variables:** Driven by `app/config.py` which loads `.env` files using `pydantic-settings`. Configures keys like `GROQ_API_KEY`, `FIREBASE_PROJECT_ID`, and `YOUTUBE_API_KEY`.
*   **Missing Keys:** The application initialization (`main.py` startup event) checks for keys. Critical keys (like Groq or Firebase) usually throw hard exceptions preventing startup. Ancillary keys (like YouTube) might fail gracefully, initializing the `YouTubeService` as `None` or logging a warning, allowing the rest of the application to function without that specific resource provider.

---

## 5) Database / Firebase (Firestore)

**What is stored:**
Firestore stores the persistent, stateful data of the application:
*   `users`: Profiles, XP, total lessons completed, preferences.
*   `learning_paths`: The massive, nested documents generated by the Syllabus Generator, tracking modules, lessons, and `completed` boolean flags.
*   `user_activity`: Logs of actions taken for historical tracking and frontend recent activity feeds.
*   *(Assumption requires verification)* `documents`: Metadata tracking uploaded RAG document state.

**Frontend Reads:**
The frontend reads data primarily by utilizing Firebase SDK integration in the `data/services` layer. Providers (like `learning_provider.dart`) fetch this data asynchronously and hold the mapped Dart models in memory for the UI to read.

**Writes & Mutability:**
When a user completes an action (like viewing a lesson), the frontend sends a POST request to the Backend (e.g., `/api/v1/learning/complete-lesson`). The FastAPI backend calculates the new progress percentage, issues the writes to Firestore (updating the boolean flag and adjusting the user's XP), and returns a success response.

**Data Consistency Strategy:**
To keep the UI accurate, the frontend relies primarily on **provider invalidation**.
*Action:* User completes a lesson.
*Reaction:* The API call succeeds. The `LearningProvider` calls `ref.invalidate(learningPathsProvider)` or manually updates its internal state array. This forces the UI to rebuild with the new 100% progress state without requiring a hard refresh by the user. (Alternatively, real-time Firestore Streams can be used for passive updates, though invalidation is more common for direct action-response loops).

---

## 6) End-to-End Data Flow

### Flow A: Syllabus Generation / Learning Path Creation
*   User inputs topic/goal on the Explore screen and taps generate.
*   UI calls `ref.read(learningProvider.notifier).generateSyllabus()`.
*   Flutter `ApiService` executes HTTP POST to `/api/v1/learning/generate`.
*   FastAPI routes the request to `SyllabusGenerator`.
*   `SyllabusGenerator` formats the prompt and calls `GroqService` (LLM).
*   LLM returns JSON representing modules and lessons.
*   FastAPI parses the JSON into Pydantic models and returns them to Flutter.
*   *(If saving)* Flutter calls POST to `/api/v1/learning/save`. Backend writes the new document to the `learning_paths` Firestore collection.
*   Provider updates state; UI transitions to the active Learning Path view.

### Flow B: Lesson Screen + Resources
*   User opens a specific lesson screen.
*   UI initializes and calls `ref.read(resourceProvider.notifier).fetchResources(topic)`.
*   Flutter executes HTTP GET to backend `/api/v1/resources/search`.
*   FastAPI routes the request to `ResourceCurator`.
*   `ResourceCurator` executes `asyncio.gather` on `YouTubeService`, `GitHubService`, `WikipediaService`, etc., fetching data in parallel.
*   Aggregated raw results are passed to `RelevanceScorer.score_and_filter()`.
*   Filtered, highly relevant resources are returned to the frontend.
*   UI updates, displaying resources in their respective tabs (Videos, Articles, Code).

### Flow C: Completing a Lesson → Progress Updates
*   User taps "Complete Lesson" at the bottom of the content view.
*   Frontend executes HTTP POST to `/api/v1/learning/complete-lesson` with `path_id` and `lesson_number`.
*   Backend reads the path from Firestore, marks the specific lesson `completed: true`, and recalculates module and overall path progress.
*   Backend updates the `learning_paths` document in Firestore.
*   Backend increments `totalXp` and `lessonsCompleted` in the `users` Firestore document.
*   Backend returns the new progress percentages to Flutter.
*   Flutter Provider invalidates or updates local state.
*   The Lesson Screen and Dashboard UI automatically rebuild showing the filled progress bar and new XP total.

### Flow D: Quiz
*   User finishes a module and taps "Take Quiz".
*   Frontend requests a quiz from the backend providing the lesson texts.
*   Backend `QuizGenerator` prompts Groq to create JSON-structured multiple-choice questions.
*   Frontend renders the quiz UI. User selects answers.
*   Upon submission, the frontend calculates the score.
*   *(Assumption)* If passed, frontend triggers an XP update call to the backend, which mutates the Firestore `users` collection.

### Flow E: Reverse Tutoring
*   User enters the Teaching Session screen.
*   User inputs an explanation of a concept via text (or transcribed audio).
*   Frontend executes HTTP POST to `/api/v1/teaching/evaluate` providing the topic and the user's explanation.
*   Backend routes to `EvaluationService` and `MisconceptionService`.
*   The services prompt the LLM to act as an expert, grade the input out of 100, and isolate specific technical misunderstandings.
*   Backend returns the structured evaluation JSON.
*   Frontend UI renders the score ring, feedback text, and lists the detected misconceptions.
*   *(Assumption)* High scores trigger an XP increment stored in Firestore.

### Flow F: Documents (RAG)
*   User uploads a PDF via the frontend file picker.
*   File is sent to the backend `/api/v1/documents/upload`.
*   Backend `DocumentExtractionService` parses the raw text.
*   `ChunkingService` splits the text into manageable overlapping segments.
*   `EmbeddingService` converts text chunks into mathematical vectors.
*   `VectorStoreService` saves these vectors into a local database (like ChromaDB).
*   When the user chats, the query is embedded, compared against the vector store to retrieve the top 3 similar chunks, and passed to the LLM to contextually answer the query.

---

## 7) How Frontend and Backend Connect (API calls)

*   **Base URLs:** Defined in environment variables (`.env` or dart-define strings) and accessible via a configuration class (e.g., `AppConfig` or `Environment`) in the `lib/core/` directory.
*   **HTTP Client:** Located in `protege_app/lib/data/services/api_service.dart`. Typically implements the `Dio` package for advanced interceptors or the standard `http` package.
*   **Request Construction:** The `ApiService` orchestrates requests. It attaches necessary headers like `Content-Type: application/json` and, crucially, Authorization Bearer tokens retrieved from Firebase Auth. JSON encoding/decoding is handled using standard `jsonEncode()` and `jsonDecode()`.
*   **Error Handling & Retries:** The `ApiService` wraps HTTP calls in `try/catch` blocks. Non-200 status codes throw custom `ServerException` or `ApiException` classes. Timeouts are configured at the Dio client level. *(Assumption requires verification: Implementations of automatic retry logic using interceptors or packages like `dio_retry`).*
*   **Chain of Command Example:** User Action -> `LearningProvider.savePath()` -> `ApiService.post('/api/v1/learning/save', body)` -> FastAPI `router.post("/save")`.

---

## 8) How to Make UI Changes Safely (Developer Guidance)

**Safe Change Protocol:**
1.  **Colors/Typography:** *Never hardcode colors in widgets.* Always modify `protege_app/lib/core/theme/app_theme.dart`. Use `Theme.of(context).colorScheme.primary` or `Theme.of(context).textTheme.bodyLarge`.
2.  **Buttons/Cards:** If changing a button's appearance, modify the underlying specific widget located in `protege_app/lib/presentation/widgets/`. Do not redesign buttons locally within specific screens to maintain application-wide consistency.
3.  **Hardcoding Styles:** Avoid overriding theme styles via the `style:` parameter on Text widgets unless absolutely necessary for a one-off scenario.
4.  **Safe-Area & Padding:** Ensure all primary screen `Scaffold` bodies are wrapped in a `SafeArea` widget to prevent overlaps with iOS/Android top notches and bottom gesture bars. Adhere to standard padding values (e.g., `AppPadding.p16`) defined in a core constants file rather than magic numbers.
5.  **Overflow Issues:** Always test on smaller device simulators (e.g., iPhone SE). Wrap vertically stacking layouts in `SingleChildScrollView` to prevent "Bottom overflown by X pixels" yellow-tape UI errors when keyboards open or content expands.

---

## 9) Explaining Core Business Logic in a Presentation

**Template Explanation Framework:**
1.  **Feature Goal:** What is the end result we want?
2.  **User Story:** "As a user, I want..."
3.  **Technical Steps:** The 1-2-3 backend flow.
4.  **Storage/Consistency:** Where it saves and how the UI updates.
5.  **Performance Considerations:** Why it runs fast.
6.  **Failure Handling:** What happens if the internet cuts out or an API fails.

### Worked Example 1: "How does resource curation work?"
*   **Feature Goal:** Provide users with highly relevant, multi-media study guides.
*   **User Story:** After finishing a lesson, I want to watch a video or read an article expanding on the topic.
*   **Technical Steps:** When the lesson loads, the frontend pings the backend `ResourceCurator`. The backend executes background searches across YouTube, GitHub, and Wikipedia simultaneously. It gathers 50 raw results and passes them to our `RelevanceScorer`, which uses the Groq LLM to instantly review the descriptions and filter out the noise, returning only the top 3 best links.
*   **Performance Considerations:** Because the backend searches YouTube, Wiki, and GitHub in *parallel* (using `asyncio.gather`), the user waits 2 seconds instead of 10 seconds.
*   **Failure Handling:** If the YouTube API goes down or rate limits us, the backend catches the error gracefully and returns an empty list for videos, allowing the articles and GitHub links to still display normally without crashing the app.

### Worked Example 2: "How does learning progress tracking work?"
*   **Feature Goal:** Keep users motivated by visualizing their forward momentum.
*   **User Story:** When I finish reading a lesson, I want to see my progress bar move.
*   **Technical Steps:** The user taps "Complete Lesson". The Flutter app fires a POST request to the backend. The backend calculates `completed_lessons / total_lessons` to generate a new percentage and awards 50 XP.
*   **Storage/Consistency:** The backend writes these new numbers directly into the user's Firestore document. The backend returns success, and the Flutter Provider invalidates its state, forcing the UI progress bar screen to reactively rebuild showing the new percentage.
*   **Failure Handling:** If the network request fails before reaching the backend, the Flutter Provider catches the timeout and shows a snackbar: "Failed to update progress, check connection," leaving the UI state unchanged to prevent data mismatch.

### Worked Example 3: "How does reverse tutoring work?"
*   **Feature Goal:** Implement active recall by making the student the teacher.
*   **User Story:** I want to explain what I just learned and be told if I got it right.
*   **Technical Steps:** The user submits a paragraph explaining the concept. The frontend sends this to the backend `EvaluationService`. The backend prompts the Groq LLM to adopt a "strict but fair teacher" persona, evaluates the text, calculates a score out of 100, and formats an array of specific technical "misconceptions" the user made.
*   **Storage/Consistency:** The score and UI state are updated locally via Riverpod so the user sees their grade immediately.
*   **Performance Considerations:** We use Groq's high-speed LPU inference engine, ensuring the evaluation returns in under a second so the conversational flow feels natural.

---

## 10) Demo Script (3-5 Minutes)

**[0:00 - 0:30] Introduction & Login**
*"Welcome to Protégé. We're bypassing traditional static courses to create hyper-personalized education. I'll log in here—this is handled securely through Firebase Auth. Immediately, we hit the Dashboard displaying persistent state from Firestore: my XP and current active courses."*

**[0:30 - 1:30] Syllabus Generation**
*"Let's generate something new. I'll go to the Explore tab and type 'Rust Concurrency' as my goal. When I hit Generate, Riverpod puts the UI into a loading state. In the background, our FastAPI server is prompting the Groq LLM to build a structured curriculum. And... there it is. A complete, multi-module learning path generated in seconds."*

**[1:30 - 2:30] Lesson & Resource Curation**
*"Let's dive into Module 1. Here is our AI-generated lesson text. But static text isn't enough. Notice these tabs: Videos, Articles, Code. Our backend `ResourceCurator` just ran parallel searches across YouTube, Dev.to, and GitHub, and passed those raw results through an LLM `RelevanceScorer`. So these links aren't just keyword matches; the AI has verified they actually teach exactly what is in this lesson text."*

**[2:30 - 3:30] Progress & Reverse Tutoring**
*"I'll mark this lesson complete. Our backend immediately calculates the new completion percentage, updates our Firestore database, and Riverpod reactively animates our UI progress bar forward. Now, to solidify my knowledge, I'll launch a Teaching Session. I'll explain 'Rust Threads' in my own words. The backend `EvaluationService` grades my response using an AI persona. As you can see, I got an 85/100, and it accurately pointed out a misconception I had about memory safety."*

**[3:30 - 4:00] Document Intelligence (RAG)**
*"Finally, if I have my own textbook, I can upload the PDF here. Our backend chunks and vectorizes the text locally. I can now chat natively with this document, ensuring every answer is strictly sourced from my own uploaded material. That is Protégé end-to-end."*

---

## 11) Known Risks / Future Improvements

While structurally sound, the architecture can be hardened in subsequent iterations:

*   **Caching Resources:** The `ResourceCurator` currently queries external APIs (like YouTube) live. Implementing a caching layer (via Redis or Firestore TTL) for popular searches would drastically reduce API quota usage and improve load times.
*   **Rate Limiting:** FastAPI endpoints are currently vulnerable to spam. Implementing client IP rate-limiting middleware is necessary before a production release to protect Groq API costs.
*   **Better Relevance Scoring:** While the LLM filters links well, processing 50 link descriptions through the LLM carries token cost overhead. Introducing a lighter-weight semantic search pre-filter could optimize costs.
*   **Stronger Progress Syncing Using Streams:** Currently, the UI updates progress via Provider invalidation post-HTTP-success. Migrating the core `LearningProvider` to utilize `StreamProvider` listening directly to Firestore document snapshots would ensure perfect multi-device synchronization.
*   **Offline Mode:** Leveraging Firestore's built-in offline persistence heavily on the Flutter side, combined with local device caching for generated lesson text.
*   **Analytics:** Integration of Firebase Analytics or PostHog to track which features (e.g., Quizzes vs. Tutoring) drive the highest user engagement.

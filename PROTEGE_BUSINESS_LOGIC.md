# Protégé Core Business Logic Explained

This document breaks down the specific business logic, scoring algorithms, and AI behaviors for the core features of the Protégé app.

---

## 1. Syllabus Generation: How is the curriculum curated?

The syllabus generation is entirely driven by **Prompt Engineering** and **Generative AI (Groq)**. It does not pull from a pre-existing database of courses.

### The Process:
1.  **User Input:** The user provides a `topic` (e.g., "Machine Learning"), a `goal` (e.g., "Build a prediction model"), an `experience_level` (Beginner, Intermediate, Advanced), and `daily_time_minutes`.
2.  **Prompt Construction:** The backend (`SyllabusGenerator`) injects these variables into a massive, hidden set of instructions called a `SYSTEM_PROMPT`. It tells the AI:
    *   *You are an expert curriculum designer.*
    *   *Create a course on [Topic] tailored for a [Beginner] aiming to [Goal].*
    *   *Limit each lesson so it can be completed in [15] minutes.*
    *   **Crucially:** *You MUST return the output strictly as a JSON object with a list of "modules", and inside each module, a list of "lessons" containing a title and specific "key concepts".*
3.  **LLM Generation:** The Groq API processes this prompt. Because we enforce `json_response=True` and a structured output format, the AI doesn't write an essay; it writes code-like arrays of data.
4.  **Validation:** The backend uses Pydantic to verify that the AI returned a valid array of modules before saving it to the database as the user's custom course.

---

## 2. Resource Curation: How are YouTube and articles selected?

The resource curation pipeline is a two-step process: **Wide Net Gathering** + **AI Relevance Filtering**.

### Step 1: Query Optimization (Keyword Generation)
Before searching YouTube or Wikipedia, the system uses AI (`QueryOptimizer`) to generate the best possible search terms. If the lesson title is "Introduction to Tensors", the AI generates multiple specific queries:
*   `youtube`: "Machine Learning Tensors tutorial beginner"
*   `github`: "Tensorflow PyTorch code examples"
*   `wikipedia`: "Tensor (machine learning)"

### Step 2: Parallel Gathering ("The Wide Net")
The `ResourceCurator` sends these optimized keywords to 10+ different APIs simultaneously (YouTube, Wikipedia, Dev.to, freeCodeCamp, OpenStax, etc.) using Python's `asyncio.gather` for speed. It might pull back 30-50 raw links.

### Step 3: AI Relevance Scoring & Ranking ("The Quality Filter")
This is the heart of the business logic. Bringing back 50 links is useless; we need the best 3.
1.  **The LLM Grader:** The backend passes the titles and descriptions of all 50 links to the `RelevanceScorer` (Groq AI) and asks: *"Which of these links strictly match the lesson topic?"* The AI assigns a `relevance_score` dropping anything below a 40/100.
2.  **The Composite Score Algorithm:** The surviving links are then ranked mathematically using this formula:
    *   **60% AI Relevance Score:** How accurately does it match the lesson?
    *   **25% Quality (Engagement):** If it's a YouTube video or GitHub repo, how many Likes/Stars does it have? (>100 likes = higher score).
    *   **15% Recency:** A resource from 2025 gets more points than a resource from 2020.
3.  **Final Cut:** The array is sorted by this Composite Score, duplicates are removed, and only the top 3 items per category (Videos, Articles, Code) are sent to the user.

---

## 3. Notes & Document Intelligence (How are notes saved and used?)

When a user uploads a PDF or textbook (Notes), the system uses a technique called **RAG (Retrieval-Augmented Generation)**. It does *not* send the whole PDF to the AI all at once.

### The Save Process (Chunking & Embedding)
1.  **Extraction:** The `DocumentExtractionService` reads the raw text from the PDF.
2.  **Chunking:** The `ChunkingService` cuts the textbook into small, overlapping paragraphs (chunks) so context isn't lost.
3.  **Embedding:** The `EmbeddingService` converts every single paragraph into a "Vector" (a long list of numbers representing the *meaning* of the text).
4.  **Vector Store:** These numbered vectors are saved in a local database (like ChromaDB).

### The Retrieval Process (Chatting with the Notes)
When the user asks, *"What does chapter 2 say about Newton's third law?"*:
1.  The question is converted into a Vector.
2.  The Vector Store does a math equation (Cosine Similarity) to find the top 3 paragraphs in the textbook that have the closest mathematical meaning to the question.
3.  The backend grabs those 3 specific paragraphs, hands them to the AI, and says: *"Answer the user's question, but ONLY use the facts found in these 3 paragraphs."*

---

## 4. Reverse Tutoring: How does the AI score understanding?

When a user tries to teach a concept back to the AI, the `EvaluationService` is used to grade the explanation. It generates three independent metrics to create a final "Aha! Score".

### The Scoring Prompts
The backend takes the user's text and injects it into prompt templates, sending three different grading instructions to the LLM:

1.  **Clarity Score (0-100):** *Is the explanation easy to understand? Did the user use good analogies? Is it free of confusing jargon?*
2.  **Accuracy Score (0-100):** *Is the statement factually correct? Does it contradict known computer science/math rules?* (This prompt also asks the AI to generate a list of "Errors" and "Corrections" if the user made a mistake).
3.  **Completeness Score (0-100):** *Did the user cover the specific key concepts of the lesson, or did they only explain half of the topic?*

### The "Aha! Score" Algorithm
Instead of a simple average, the backend mathematically weights these scores to calculate overall understanding:
*   `Clarity` is worth **30%**
*   `Accuracy` is worth **40%** (It is the most heavily weighted metric).
*   `Completeness` is worth **30%**

*Formula:* `(Clarity * 0.30) + (Accuracy * 0.40) + (Completeness * 0.30) = Final Score`.

### Session Tracking & Feedback
*   As the user converses back and forth, the system tracks the **highest** clarity, accuracy, and completeness scores they achieve during that session (it doesn't average them down if they get it wrong early on).
*   If the overall score hits **85 or higher**, the session is marked as "Complete", and the AI generates final congratulatory feedback confirming they have mastered the topic.
*   **The Persona:** If the score is low, the AI is prompted to act as a "confused student" (*"I don't quite get it, can you try a simpler example?"*). If the score is high, the AI plays the "enlightened student" (*"Wow, that really clicked!"*).

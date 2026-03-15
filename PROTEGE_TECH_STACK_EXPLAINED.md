# Protégé: A Detailed Guide to the Tech Stack and App Flow

This guide explains exactly what technologies make up the Protégé app, what their jobs are, and how they work together to make the application function. It is written in plain English so you can explain exactly how the system is built.

---

## Part 1: The Tech Stack (What everything is and why we use it)

A "Tech Stack" is just the combination of programming languages, tools, and software used to build an application. Protégé is divided into three main parts: the Frontend (what the user sees), the Backend (the brain in the cloud), and the Database (the memory).

### 1. The Frontend: Flutter & Dart
*   **What it is:** Flutter is a UI (User Interface) toolkit created by Google. Dart is the programming language you use to write Flutter apps.
*   **Why we use it:** Instead of writing one app for iPhones (using Swift) and a completely different app for Android phones (using Kotlin), Flutter allows us to write the code **once** and release it on iOS, Android, and even the Web simultaneously. This saves a massive amount of time.
*   **How it works in Protégé:**
    *   **Widgets:** Everything you see on the screen (a button, a text box, the navigation bar) is a "Widget". 
    *   **Riverpod (State Management):** Imagine a user clicks "Generate Course". The app needs to show a loading spinner, wait for the course to be created, and then replace the spinner with the actual course. "Riverpod" is the tool that watches for these changes and tells the screen exactly when and how to update so the app feels fast and smooth.

### 2. The Backend: Python & FastAPI
*   **What it is:** Python is exactly what it sounds like—a highly popular, easy-to-read programming language. **FastAPI** is a framework for Python that makes building APIs (Application Programming Interfaces) incredibly fast.
*   **Why we use it:** The backend needs to do heavy lifting: talking to AI, searching YouTube, processing text, and creating quizzes. Python is the absolute best language for AI and data processing. FastAPI is used because it runs very quickly and handles many requests at the same time without crashing.
*   **How it works in Protégé:**
    *   **The API (The Messenger):** The frontend mobile app cannot do heavy AI math on your phone. It sends an HTTP request (a digital message) over the internet to the FastAPI server. FastAPI receives the message, does the work, and sends back a "Response" containing the data.

### 3. Database & Authentication: Firebase
*   **What it is:** Firebase is a platform by Google that provides backend services like database hosting and user login systems out-of-the-box.
*   **Why we use it:** Building a secure login system and a database from scratch takes months. Firebase gives us secure Google/Apple sign-in and a real-time database called "Firestore" instantly.
*   **How it works in Protégé:**
    *   **Authentication:** When a user logs in, Firebase securely checks their password and gives the app a secure "token" (like a VIP pass) proving who they are.
    *   **Firestore (The Database):** It stores all user profiles, their generated learning paths, their points/XP, and the quizzes they've taken. It stores this in "Collections" and "Documents" (think of it like folders and files in a filing cabinet).

### 4. The AI Engine: Groq
*   **What it is:** Groq is an API provider that runs large language models (like ChatGPT/Llama) on specialized, insanely fast computer chips.
*   **Why we use it:** The core of Protégé is generative AI—creating personalized courses instantly. We use Groq because it generates AI responses almost instantly, meaning the user isn't sitting around waiting for their course to load.

---

## Part 2: How the App Actually Works (The Step-by-Step Flow)

Let's trace exactly what happens when a user uses the main feature: **Generating a Learning Path.**

### Step 1: The User Makes a Request (Frontend)
1.  The user opens the app and types "I want to learn Quantum Physics" into a text box.
2.  They click the "Generate" button.
3.  The Flutter app (using Riverpod to show a loading screen) packages this text into a "POST Request" and sends it over the internet directly to the FastAPI Backend.

### Step 2: The Backend Receives the Request (Python / FastAPI)
1.  The FastAPI server hears the request hit its `/api/v1/learning/generate` endpoint.
2.  The backend looks at the request and says, "Okay, the user wants a course on Quantum Physics."
3.  The backend calls a specialized file called `syllabus_generator.py`.

### Step 3: The AI Creates the Course (Groq)
1.  The `syllabus_generator.py` takes the user's topic and creates a highly specific "Prompt" (instructions for the AI). It might look like: *Create a 3-module syllabus for a beginner learning Quantum Physics. Return it as a structured list.*
2.  The backend sends this prompt to the **Groq API**.
3.  Groq processes the prompt in milliseconds and sends back a complete, structured syllabus text.

### Step 4: Finding Real-World Resources (Resource Curator)
*(This is where the app gets clever)*
1.  The AI gave us titles like "Module 1: What is a Quantum?". For every lesson title, the backend's `ResourceCurator` automatically searches YouTube and Wikipedia for "What is a Quantum?".
2.  It gets back dozens of video links and articles.
3.  It asks the AI (`RelevanceScorer.py`) to quickly read the descriptions of all those videos and pick the top 3 most relevant ones, throwing away the junk.

### Step 5: Saving the Data (Firebase)
1.  The FastAPI backend now has a massive, complete object containing the AI-generated course text, the YouTube links, and the article links.
2.  It sends this object to **Firestore** (the database) telling it: *"Save this new learning path under Sangeeth's user profile."*
3.  Firestore saves it permanently.

### Step 6: Displaying it to the User (Frontend)
1.  The FastAPI backend sends a message back to the Flutter app saying: *"Success! Here is the data."*
2.  The Flutter app receives the data.
3.  Riverpod notices the data has arrived and turns off the loading spinner.
4.  The Flutter Widgets draw the beautiful screens on your phone, filling in the text and video thumbnails with the data the backend just sent.

### Summary of the Flow:
**Flutter App** (User asks for course) -> **FastAPI** (Receives order) -> **Groq AI** (Writes course text) -> **FastAPI** (Searches YouTube/Web for links matching the text) -> **Firebase** (Saves the final course) -> **FastAPI** -> **Flutter App** (Displays course to user).

---

## Part 3: Other Key Features

*   **Quizzes:** Once a user finishes a lesson, the frontend asks the backend for a quiz. The backend tells the Groq AI, *"Look at this specific lesson text. Generate 3 multiple-choice questions based ONLY on what was just taught."* The AI sends back the questions, and the backend gives them to the app.
*   **The Teaching Feature (Explaining Concepts):** If the user explains a concept into the app (e.g., "Gravity is when things fall down"), the text is sent to the backend. The backend's `EvaluationService` asks the AI to act as a teacher, grade the user's explanation out of 100, point out any technical errors ("misconceptions"), and provide friendly feedback.
*   **Chatting with Documents (RAG):** If the user uploads a PDF textbook, the backend chops the PDF into hundreds of tiny paragraphs. When the user asks a question, the backend searches those paragraphs, finds the 3 most relevant ones, and gives them to the AI, saying: *"Answer the user's question, but only use the facts in these 3 paragraphs."* This prevents the AI from making things up (hallucinating).

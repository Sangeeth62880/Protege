# Core Backend Service Logic in Protege

This document summarizes the main backend services that power scoring, reverse tutoring, resource curation, and resource ranking in `protege_backend/app/services`.

## High-level architecture

The backend is built around a few AI-assisted service layers:

- **Tutor services** handle interactive lesson support.
- **Evaluation services** score learner explanations in reverse-tutoring mode.
- **Resource curation services** gather learning materials from multiple sources.
- **Relevance and ranking services** filter and order resources.
- **RAG services** answer document questions using embeddings plus LLM generation.
- **Quiz services** generate quizzes and calculate results.

The common pattern is:

1. Build a prompt or query.
2. Call the LLM service (`GroqService`) when AI reasoning is needed.
3. Parse or normalize the result.
4. Apply fallback logic if the AI call fails.
5. Return structured data for the frontend.

---

## 1. Reverse tutor scoring and evaluation

### `EvaluationService`

File: `protege_backend/app/services/evaluation_service.py`

This is the core reverse-tutoring scoring engine. It evaluates a user’s explanation of a topic and breaks the score into three parts:

- **Clarity**
- **Accuracy**
- **Completeness**

#### Main workflow

1. The user explanation, topic, concepts, and conversation history are formatted into a prompt.
2. The prompt is sent to Groq as JSON-only output.
3. The response is parsed into a structured evaluation.
4. Missing fields are normalized and scores are clamped to `0–100`.
5. A weighted **Aha! score** is computed.
6. If the session is complete enough, final feedback is generated.
7. A simulated “confused student” response is generated based on the score.

#### Weighting

The final Aha! score uses these weights:

- Clarity: `30%`
- Accuracy: `40%`
- Completeness: `30%`

Formula:

```text
Aha score = clarity * 0.30 + accuracy * 0.40 + completeness * 0.30
```

#### Session tracking behavior

For each `session_id`, the service stores:

- cumulative score
- evaluation count
- best clarity score
- best accuracy score
- best completeness score

Instead of averaging scores, it keeps the **best observed score** for each category and recalculates the Aha! meter from those best values.

#### Completion rule

A session is considered complete when:

```text
Aha! score >= 85
```

When complete, the service generates a final encouraging feedback message.

#### Fallback behavior

If AI evaluation fails:

- the service returns zeroed scores
- no false mastery is reported
- a fallback suggestion asks the user to try again later

---

## 2. Tutor interaction logic

### `TutorService`

File: `protege_backend/app/services/tutor_service.py`

This service powers the normal tutoring experience during lesson study.

#### Main workflow

1. Load conversation history for the session.
2. Format history into a prompt-friendly transcript.
3. Build a system prompt with:
   - topic
   - lesson title
   - key concepts
   - experience level
   - prior conversation
4. Send the user’s question to Groq.
5. Store the user question and assistant answer in memory.

#### Conversation memory

Conversation history is stored in-memory as:

```python
session_id -> list of {role, content}
```

The service keeps only the last 20 messages.

#### Behavior

This service is not a scoring system. It is a contextual tutor that:

- answers questions in lesson context
- preserves short-term conversation memory
- adapts responses based on the learner level and lesson structure

---

## 3. Resource curation pipeline

### `ResourceCurator`

File: `protege_backend/app/services/resource_curator.py`

This is the main service that gathers learning resources from multiple providers.

#### Sources used

Depending on what services are available, it can query:

- YouTube
- Wikipedia
- GitHub
- Dev.to
- Free articles
- Open Library
- OpenStax
- Stack Overflow
- Coursera
- MDN

#### Main workflow

1. Generate optimized search queries using `QueryOptimizer` if custom queries are not provided.
2. Build parallel search tasks for all enabled providers.
3. Execute searches concurrently with `asyncio.gather`.
4. Collect and categorize results by source type.
5. Optionally run AI relevance scoring.
6. Deduplicate and rank articles.
7. Return a curated bundle of resources.

#### Query optimization

If search queries are not supplied, the curator asks `QueryOptimizer` to generate platform-specific queries for:

- YouTube
- Wikipedia
- GitHub
- Dev.to
- Articles
- Key terms

This makes the searches more lesson-specific instead of generic.

#### Source-specific behavior

- **YouTube**: always included
- **Wikipedia**: uses primary term and fallback term
- **GitHub**: category-based search with optional language filtering
- **MDN**: only included when the topic looks web-related
- **Coursera / OpenStax / Stack Overflow / Books**: included when configured

#### Output structure

The curated response includes:

- videos
- articles
- repositories
- wikipedia summary
- books
- textbooks
- questions
- courses
- docs
- total resource count
- sources used
- queries used

---

## 4. Resource ranking logic

### `ResourceCurator._rank_by_score()`

This method ranks resources using a composite heuristic.

#### Score components

The final score is made of:

- **60% relevance**
- **25% quality**
- **15% recency**

#### Relevance

Relevance uses either:

- `ai_relevance_score`, if present
- otherwise the base score field

#### Quality

Quality is estimated using engagement-like metrics such as:

- reactions
- stars
- votes

Higher engagement maps to a higher quality contribution.

#### Recency

Recency is estimated from `published_at` year.
Newer content scores higher.

#### Final output

Each item gets a temporary internal field:

```python
_composite_score
```

Then items are sorted descending by that value.

---

## 5. AI relevance scoring

### `RelevanceScorer`

File: `protege_backend/app/services/relevance_scorer.py`

This service scores resources from `0–100` for lesson relevance.

#### Scoring categories

- `90–100`: directly teaches the exact concept
- `70–89`: closely related and covers it substantially
- `40–69`: tangentially related
- `0–39`: not relevant

#### Main workflow

1. Build a compact text list of resources.
2. Ask the LLM to return a JSON array of scores.
3. Parse and clamp scores to valid integers.
4. Attach `ai_relevance_score` to each resource.
5. Filter out resources below `min_score`.

#### Important shortcut

If there are 2 or fewer resources, the service skips the AI call and assigns them a default relevance score of `70`.

#### Fallback behavior

If AI scoring fails:

- all resources are returned
- each gets a default score of `60`

This prevents the system from returning nothing.

---

## 6. Search query optimization

### `QueryOptimizer`

File: `protege_backend/app/services/query_optimizer.py`

This service generates search queries for each platform.

#### What it produces

It builds optimized queries for:

- YouTube
- Wikipedia
- GitHub
- Dev.to
- Articles
- Key terms
- GitHub topic tags
- Wikipedia fallback term

#### AI-assisted flow

1. Normalize topic, lesson title, concepts, audience, and priority.
2. Ask Groq to generate JSON queries.
3. Validate the response.
4. Fill missing values with fallback logic.

#### Fallback query generation

If AI is unavailable, it uses rule-based query building with:

- inferred difficulty
- detected programming language
- audience phrase
- resource priority

#### Ranking intent

The query builder intentionally optimizes for educational intent words like:

- explained
- guide
- examples
- best practices
- tutorial
- project

This improves the quality of retrieved learning resources.

---

## 7. Document Q&A with RAG

### `RAGService`

File: `protege_backend/app/services/rag_service.py`

This service handles question answering over uploaded documents.

#### Main workflow

1. Embed the user query.
2. Search the vector store for top matching chunks.
3. Build a context prompt from retrieved chunks.
4. Send the prompt to the LLM.
5. Extract follow-up questions from the response.
6. Clean the main answer before returning it.

#### Source handling

The response includes structured source references with:

- page number
- section heading
- relevance score
- short snippet

#### Fallback behavior

If no relevant chunks are found, it returns a helpful message suggesting the user rephrase or ask about another part of the document.

#### Low relevance behavior

If all retrieved chunks have low relevance, the answer is prefixed with a warning that the system could not find highly relevant content.

---

## 8. Quiz generation and scoring

### `QuizGenerator`

File: `protege_backend/app/services/quiz_generator.py`

This service creates quizzes from lesson content and scores quiz submissions.

#### Quiz generation

1. Build a quiz prompt from topic, lesson title, key concepts, difficulty, and question types.
2. Ask Groq for JSON quiz output.
3. Parse the JSON into quiz data.
4. Validate that a `questions` field exists.

#### Quiz scoring

`calculate_quiz_stats()` compares user answers to correct answers.

##### Logic

- question answers are matched case-insensitively
- fill-in-the-blank questions can accept multiple valid answers
- score is calculated as a percentage
- passing threshold is `70%`

#### Returned quiz stats

- score percentage
- correct count
- total questions
- per-question results
- pass/fail flag

---

## 9. How the main pieces fit together

A typical learning flow looks like this:

1. **QueryOptimizer** creates platform-specific search queries.
2. **ResourceCurator** searches external sources in parallel.
3. **RelevanceScorer** filters out weak resources.
4. **ResourceCurator._rank_by_score()** orders the final resources.
5. **TutorService** helps the learner study the lesson.
6. **EvaluationService** scores the learner in reverse tutor mode.
7. **RAGService** answers document questions using embeddings.
8. **QuizGenerator** produces quizzes and grades answers.

---

## 10. Key design patterns

### AI-first, fallback-safe

Most services try AI first and have deterministic fallback logic so the app continues working even if the model call fails.

### Structured output

Several services expect JSON output from the LLM and then normalize it.

### Session-aware behavior

Tutor and evaluation services use session IDs to preserve context and track progress.

### Parallel retrieval

Resource curation searches multiple external providers concurrently to reduce wait time.

---

## Summary

The backend service layer is centered on three big capabilities:

- **Teaching and tutoring** through `TutorService` and `RAGService`
- **Assessment and scoring** through `EvaluationService` and `QuizGenerator`
- **Resource discovery and ranking** through `QueryOptimizer`, `ResourceCurator`, and `RelevanceScorer`

The reverse tutoring system uses a weighted scoring model, the curation pipeline uses AI-assisted query generation and relevance filtering, and ranking is based on a composite of relevance, quality, and recency.

"""
Query Optimizer Service
Uses AI to generate optimized search queries for each platform.
Improved for higher-quality educational resource generation.
"""

from __future__ import annotations

from typing import Optional

from app.services.groq_service import GroqService
from app.config import settings


QUERY_OPTIMIZATION_PROMPT = """You are an expert educational search query optimizer.

Your task is to generate highly optimized search queries that will retrieve the most useful, accurate, educational, and practical learning resources for a lesson across multiple platforms.

Your goal is NOT to generate generic search queries.
Your goal is to generate queries that maximize:
1. Educational quality
2. Relevance to the exact lesson
3. Concept clarity
4. Practical usefulness
5. Beginner/intermediate/advanced appropriateness
6. Accuracy and trustworthiness of sources

You will be given:
- TOPIC: the broader subject area
- LESSON: the specific lesson title
- KEY CONCEPTS: important concepts covered in the lesson
- DIFFICULTY: optional learner difficulty level
- AUDIENCE: optional target learner type
- RESOURCE PRIORITY: optional preference such as video-first, docs-first, project-first, or balanced

You must infer the likely learner intent and produce queries that help find:
- clear explanations
- worked examples
- practical implementations
- common mistakes and best practices
- high-quality educational resources

GENERAL RULES:
1. Be highly SPECIFIC. Avoid vague or overly broad search phrases.
2. Include the most important technical terms from the lesson and key concepts.
3. Prefer educational intent words such as:
   - "explained"
   - "guide"
   - "step-by-step"
   - "examples"
   - "best practices"
   - "implementation"
   - "beginner"
   - "advanced"
   - "full course"
   - "project"
   Use only when appropriate for the platform.
4. If the lesson is programming-related:
   - include the programming language when relevant
   - include implementation-focused phrases when useful
   - emphasize examples, syntax, projects, exercises, debugging, and best practices
5. If the lesson is conceptual/theoretical:
   - emphasize definitions, intuition, explanation, and worked examples
6. If the lesson suggests a practical skill:
   - include hands-on, project-based, or real-world phrasing
7. Avoid low-value filler and vague words unless they improve intent.
8. Avoid clickbait-style or entertainment-oriented phrasing.
9. Generate queries that are likely to return high-signal educational results, not news, opinion pieces, or marketing pages.
10. Use KEY CONCEPTS actively, but only the most relevant ones. Do not stuff keywords unnaturally.

PLATFORM-SPECIFIC RULES:

YOUTUBE:
- Optimize for high-quality educational videos.
- Prefer queries likely to return:
  - full tutorials
  - crash courses
  - walkthroughs
  - project-based learning
  - concept explanations
  - problem-solving videos
- Add intent words such as:
  - "full tutorial"
  - "crash course"
  - "explained"
  - "step by step"
  - "project"
  - "for beginners"
  - "interview prep"
  only if relevant.
- If the lesson is coding-related, include the language/framework and the exact concept.
- If possible, make the query likely to surface practical, high-retention learning content.

WIKIPEDIA:
- Return the most likely exact encyclopedia article title.
- Do NOT add words like "tutorial", "guide", "for beginners", or "explained".
- Prefer canonical concept names, algorithms, technologies, people, systems, or scientific terms.
- If the lesson title is not itself a likely article title, map it to the closest canonical topic.
- The wikipedia_fallback should be a broader but still relevant encyclopedia search term.

GITHUB:
- Optimize for repositories with:
  - example code
  - educational projects
  - beginner-friendly implementations
  - exercises
  - learning repositories
  - reference implementations
- Include language, framework, or domain keywords where useful.
- Favor searches that surface repos containing:
  - "examples"
  - "tutorial"
  - "learning"
  - "practice"
  - "awesome"
  - "project"
  - "implementation"
  when appropriate.
- github_topics should contain 3 to 6 concise GitHub topic tags that are highly relevant and likely to exist on repositories.
- Prefer real repository topics over generic words whenever possible.

DEVTO:
- Optimize for practical, developer-focused educational posts.
- Prefer queries or tags that surface:
  - guides
  - implementation walkthroughs
  - beginner explanations
  - best practices
  - mistakes to avoid
  - real-world usage
- Keep it concise and relevant to dev.to discovery behavior.
- If appropriate, include technology names and one educational modifier.

ARTICLES:
- Optimize for high-quality written learning resources.
- Prefer phrases such as:
  - "guide"
  - "step-by-step"
  - "best practices"
  - "examples"
  - "explained"
  - "implementation"
  - "deep dive"
- Avoid vague searches that may return opinion pieces, low-quality SEO pages, or unrelated content.
- If the lesson is technical, bias toward authoritative educational content and practical guides.
- If relevant, include "official documentation" or "docs" only when that would improve educational quality.

KEY_TERMS:
- Return 5 to 10 highly relevant search terms/concepts.
- Include core terminology, variants, related methods, and important sub-concepts.
- Terms should help downstream systems improve retrieval quality.

DIFFICULTY INFERENCE:
- Infer likely learner level from the lesson title if DIFFICULTY is not provided:
  - words like "introduction", "basics", "understanding", "getting started" => beginner
  - words like "working with", "building", "implementing" => intermediate
  - words like "optimization", "internals", "advanced", "architecture" => advanced
- Reflect that inferred level in YouTube, GitHub, DevTo, and Articles queries when useful.

RESOURCE PRIORITY GUIDANCE:
- If RESOURCE PRIORITY is "video-first", optimize YouTube for the strongest educational phrasing.
- If RESOURCE PRIORITY is "docs-first", make Articles more authoritative and precise.
- If RESOURCE PRIORITY is "project-first", make GitHub and YouTube more implementation-focused.
- If RESOURCE PRIORITY is "balanced", optimize all platforms evenly.

QUERY QUALITY HEURISTICS:
- Queries should target resources that teach the lesson well, not just mention the topic.
- Prefer "X explained with examples" over just "X".
- Prefer "X in Python examples" over just "X Python".
- Prefer "X best practices guide" over "X tips".
- Prefer "X project tutorial" when the skill is hands-on.
- Prefer exact concept naming for encyclopedia search.
- Avoid excessive keyword stuffing.
- Keep queries natural and search-effective.

Now generate optimized queries for:
TOPIC: {topic}
LESSON: {lesson_title}
KEY CONCEPTS: {key_concepts}
DIFFICULTY: {difficulty}
AUDIENCE: {audience}
RESOURCE PRIORITY: {resource_priority}

Respond with ONLY valid JSON in this exact format:
{{
  "youtube": "optimized youtube query",
  "wikipedia": "exact wikipedia article title",
  "wikipedia_fallback": "broader wikipedia fallback term",
  "github": "optimized github query",
  "github_topics": ["topic1", "topic2", "topic3"],
  "devto": "optimized dev.to query or tags",
  "articles": "optimized article search query",
  "key_terms": ["term1", "term2", "term3"]
}}

IMPORTANT:
- Output ONLY JSON
- No markdown
- No explanation
- No extra text
- Ensure all fields are present
- Ensure github_topics and key_terms are arrays
"""


class QueryOptimizer:
    """Generates optimized search queries using AI with robust fallback behavior."""

    def __init__(self, groq_service: Optional[GroqService] = None):
        self.groq = groq_service
        if not self.groq:
            api_key = settings.GROQ_API_KEY
            if api_key:
                self.groq = GroqService(api_key=api_key)
        print("[QUERY_OPTIMIZER] Initialized")

    async def generate_optimized_queries(
        self,
        topic: str,
        lesson_title: str,
        key_concepts: Optional[list[str]] = None,
        difficulty: Optional[str] = None,
        audience: Optional[str] = None,
        resource_priority: str = "balanced",
    ) -> dict:
        """
        Generate optimized search queries for all platforms.

        Args:
            topic: Main topic (e.g., "Python Programming")
            lesson_title: Specific lesson (e.g., "Understanding Variables")
            key_concepts: List of key concepts in the lesson
            difficulty: Optional difficulty level ("beginner", "intermediate", "advanced")
            audience: Optional target audience (e.g., "students", "developers", "beginners")
            resource_priority: One of "balanced", "video-first", "docs-first", "project-first"

        Returns:
            Dict with optimized queries for each platform
        """
        print(f"[QUERY_OPTIMIZER] Generating queries for: {lesson_title}")

        normalized_topic = self._clean_text(topic)
        normalized_lesson = self._clean_text(lesson_title)
        normalized_concepts = self._normalize_key_concepts(key_concepts)
        inferred_difficulty = difficulty or self._infer_difficulty(normalized_lesson)
        normalized_audience = self._clean_text(audience) if audience else "general learners"
        normalized_priority = self._normalize_resource_priority(resource_priority)

        if not self.groq:
            return self._generate_basic_queries(
                topic=normalized_topic,
                lesson_title=normalized_lesson,
                key_concepts=normalized_concepts,
                difficulty=inferred_difficulty,
                audience=normalized_audience,
                resource_priority=normalized_priority,
            )

        try:
            concepts_str = ", ".join(normalized_concepts) if normalized_concepts else "general concepts"

            prompt = QUERY_OPTIMIZATION_PROMPT.format(
                topic=normalized_topic or "General Topic",
                lesson_title=normalized_lesson or "General Lesson",
                key_concepts=concepts_str,
                difficulty=inferred_difficulty,
                audience=normalized_audience,
                resource_priority=normalized_priority,
            )

            response = await self.groq.generate_with_system_prompt(
                system_prompt=(
                    "You are a search query optimization expert. "
                    "Respond only with valid JSON matching the requested schema."
                ),
                user_message=prompt,
                temperature=0.2,
                max_tokens=700,
                json_response=True,
            )

            queries = self.groq.parse_json_response(response)
            validated = self._validate_and_enrich_response(
                queries=queries,
                topic=normalized_topic,
                lesson_title=normalized_lesson,
                key_concepts=normalized_concepts,
                difficulty=inferred_difficulty,
                audience=normalized_audience,
                resource_priority=normalized_priority,
            )

            print(f"[QUERY_OPTIMIZER] Generated queries: {list(validated.keys())}")
            return validated

        except Exception as e:
            print(f"[QUERY_OPTIMIZER] AI generation failed: {e}, using fallback")
            return self._generate_basic_queries(
                topic=normalized_topic,
                lesson_title=normalized_lesson,
                key_concepts=normalized_concepts,
                difficulty=inferred_difficulty,
                audience=normalized_audience,
                resource_priority=normalized_priority,
            )

    def _generate_basic_queries(
        self,
        topic: str,
        lesson_title: str,
        key_concepts: Optional[list[str]] = None,
        difficulty: Optional[str] = None,
        audience: Optional[str] = None,
        resource_priority: str = "balanced",
    ) -> dict:
        """
        Generate platform-aware fallback queries without AI.
        """
        clean_title = self._clean_text(lesson_title)
        clean_topic = self._clean_text(topic)
        concepts = self._normalize_key_concepts(key_concepts)

        main_subject = self._extract_main_subject(clean_topic, clean_title)
        programming_language = self._detect_programming_language(clean_topic, clean_title, concepts)
        concept_phrase = " ".join(concepts[:3]).strip()
        level_phrase = self._difficulty_phrase(difficulty)
        audience_phrase = self._audience_phrase(audience)

        youtube_parts = [main_subject, clean_title]
        github_parts = [main_subject.lower(), clean_title.lower()]
        articles_parts = [main_subject, clean_title]
        devto_parts = [main_subject.lower(), clean_title.lower()]

        if programming_language and programming_language.lower() not in " ".join(youtube_parts).lower():
            youtube_parts.insert(0, programming_language)
            github_parts.insert(0, programming_language.lower())
            articles_parts.insert(0, programming_language)
            devto_parts.insert(0, programming_language.lower())

        if concept_phrase:
            if concept_phrase.lower() not in " ".join(youtube_parts).lower():
                youtube_parts.append(concept_phrase)
            if concept_phrase.lower() not in " ".join(github_parts).lower():
                github_parts.append(concept_phrase.lower())

        youtube_suffix = self._youtube_suffix(difficulty, resource_priority)
        github_suffix = self._github_suffix(resource_priority)
        articles_suffix = self._articles_suffix(difficulty, resource_priority)
        devto_suffix = self._devto_suffix(difficulty)

        youtube_query = self._join_parts(youtube_parts + [level_phrase, audience_phrase, youtube_suffix])
        github_query = self._join_parts(github_parts + [level_phrase, github_suffix])
        articles_query = self._join_parts(articles_parts + [level_phrase, articles_suffix])
        devto_query = self._join_parts(devto_parts + [level_phrase, devto_suffix])

        github_topics = self._build_github_topics(
            topic=clean_topic,
            lesson_title=clean_title,
            key_concepts=concepts,
            programming_language=programming_language,
        )

        wikipedia_term = self._extract_wikipedia_term(clean_title, clean_topic)
        wikipedia_fallback = self._extract_wikipedia_fallback(clean_title, clean_topic, concepts)

        key_terms = self._build_key_terms(clean_topic, clean_title, concepts, programming_language)

        return {
            "youtube": youtube_query,
            "wikipedia": wikipedia_term,
            "wikipedia_fallback": wikipedia_fallback,
            "github": github_query,
            "github_topics": github_topics,
            "devto": devto_query,
            "articles": articles_query,
            "key_terms": key_terms,
        }

    def _validate_and_enrich_response(
        self,
        queries: dict,
        topic: str,
        lesson_title: str,
        key_concepts: list[str],
        difficulty: Optional[str],
        audience: Optional[str],
        resource_priority: str,
    ) -> dict:
        """
        Ensure AI output matches expected schema and fill missing values with fallback logic.
        """
        fallback = self._generate_basic_queries(
            topic=topic,
            lesson_title=lesson_title,
            key_concepts=key_concepts,
            difficulty=difficulty,
            audience=audience,
            resource_priority=resource_priority,
        )

        if not isinstance(queries, dict):
            return fallback

        result = {
            "youtube": self._safe_string(queries.get("youtube")) or fallback["youtube"],
            "wikipedia": self._safe_string(queries.get("wikipedia")) or fallback["wikipedia"],
            "wikipedia_fallback": self._safe_string(queries.get("wikipedia_fallback")) or fallback["wikipedia_fallback"],
            "github": self._safe_string(queries.get("github")) or fallback["github"],
            "github_topics": self._safe_string_list(queries.get("github_topics")) or fallback["github_topics"],
            "devto": self._safe_string(queries.get("devto")) or fallback["devto"],
            "articles": self._safe_string(queries.get("articles")) or fallback["articles"],
            "key_terms": self._safe_string_list(queries.get("key_terms")) or fallback["key_terms"],
        }

        result["github_topics"] = result["github_topics"][:6]
        result["key_terms"] = result["key_terms"][:10]

        if len(result["github_topics"]) < 3:
            for item in fallback["github_topics"]:
                if item not in result["github_topics"]:
                    result["github_topics"].append(item)
                if len(result["github_topics"]) >= 3:
                    break

        if len(result["key_terms"]) < 5:
            for item in fallback["key_terms"]:
                if item not in result["key_terms"]:
                    result["key_terms"].append(item)
                if len(result["key_terms"]) >= 5:
                    break

        return result

    def _normalize_key_concepts(self, key_concepts: Optional[list[str]]) -> list[str]:
        """
        Normalize and deduplicate key concepts while preserving order.
        """
        if not key_concepts:
            return []

        seen = set()
        normalized = []

        for concept in key_concepts:
            if not concept:
                continue
            cleaned = self._clean_text(concept)
            if not cleaned:
                continue
            lowered = cleaned.lower()
            if lowered not in seen:
                seen.add(lowered)
                normalized.append(cleaned)

        return normalized[:8]

    def _clean_text(self, value: Optional[str]) -> str:
        """
        Clean text by removing excessive whitespace and simple noisy punctuation.
        """
        if not value:
            return ""

        cleaned = str(value).replace(":", " ").replace("|", " ").strip()
        cleaned = " ".join(cleaned.split())
        return cleaned

    def _safe_string(self, value) -> str:
        """
        Safely convert a value to a cleaned string.
        """
        if not isinstance(value, str):
            return ""
        return self._clean_text(value)

    def _safe_string_list(self, value) -> list[str]:
        """
        Safely normalize a list of strings.
        """
        if not isinstance(value, list):
            return []

        items = []
        seen = set()

        for item in value:
            if not isinstance(item, str):
                continue
            cleaned = self._clean_text(item)
            if not cleaned:
                continue
            lowered = cleaned.lower()
            if lowered not in seen:
                seen.add(lowered)
                items.append(cleaned)

        return items

    def _infer_difficulty(self, lesson_title: str) -> str:
        """
        Infer likely difficulty from the lesson title.
        """
        title = lesson_title.lower()

        beginner_markers = [
            "introduction",
            "intro",
            "basics",
            "understanding",
            "getting started",
            "beginner",
            "fundamentals",
            "what is",
            "learn",
        ]
        advanced_markers = [
            "advanced",
            "internals",
            "optimization",
            "architecture",
            "performance",
            "deep dive",
            "scaling",
        ]
        intermediate_markers = [
            "building",
            "working with",
            "implementing",
            "using",
            "developing",
            "creating",
        ]

        if any(marker in title for marker in advanced_markers):
            return "advanced"
        if any(marker in title for marker in beginner_markers):
            return "beginner"
        if any(marker in title for marker in intermediate_markers):
            return "intermediate"
        return "beginner"

    def _normalize_resource_priority(self, resource_priority: Optional[str]) -> str:
        """
        Normalize resource priority to a supported value.
        """
        valid = {"balanced", "video-first", "docs-first", "project-first"}
        value = (resource_priority or "balanced").strip().lower()
        return value if value in valid else "balanced"

    def _difficulty_phrase(self, difficulty: Optional[str]) -> str:
        """
        Return difficulty phrase suited for search queries.
        """
        difficulty = (difficulty or "").lower()
        mapping = {
            "beginner": "for beginners",
            "intermediate": "intermediate",
            "advanced": "advanced",
        }
        return mapping.get(difficulty, "")

    def _audience_phrase(self, audience: Optional[str]) -> str:
        """
        Return a useful audience phrase when appropriate.
        """
        if not audience:
            return ""
        audience = audience.strip().lower()
        noisy = {"general learners", "general", "everyone"}
        return "" if audience in noisy else audience

    def _youtube_suffix(self, difficulty: Optional[str], resource_priority: str) -> str:
        """
        Build YouTube-specific suffix.
        """
        if resource_priority == "video-first":
            if (difficulty or "").lower() == "advanced":
                return "deep dive explained"
            return "full tutorial step by step"

        if resource_priority == "project-first":
            return "project tutorial"

        if (difficulty or "").lower() == "advanced":
            return "deep dive explained"

        return "explained full tutorial"

    def _github_suffix(self, resource_priority: str) -> str:
        """
        Build GitHub-specific suffix.
        """
        if resource_priority == "project-first":
            return "project examples implementation"
        return "examples learning"

    def _articles_suffix(self, difficulty: Optional[str], resource_priority: str) -> str:
        """
        Build article-specific suffix.
        """
        if resource_priority == "docs-first":
            return "official documentation guide best practices"
        if (difficulty or "").lower() == "advanced":
            return "deep dive best practices"
        return "guide with examples"

    def _devto_suffix(self, difficulty: Optional[str]) -> str:
        """
        Build dev.to-specific suffix.
        """
        if (difficulty or "").lower() == "advanced":
            return "best practices"
        return "guide"

    def _join_parts(self, parts: list[str]) -> str:
        """
        Join query parts cleanly, avoiding duplicates.
        """
        final_parts = []
        seen = set()

        for part in parts:
            cleaned = self._clean_text(part)
            if not cleaned:
                continue
            lowered = cleaned.lower()
            if lowered not in seen:
                seen.add(lowered)
                final_parts.append(cleaned)

        return " ".join(final_parts)

    def _extract_main_subject(self, topic: str, lesson_title: str) -> str:
        """
        Extract the most meaningful main subject.
        """
        if topic:
            return topic
        return lesson_title

    def _detect_programming_language(
        self,
        topic: str,
        lesson_title: str,
        key_concepts: list[str],
    ) -> str:
        """
        Detect common programming languages or frameworks from inputs.
        """
        text = " ".join([topic, lesson_title] + key_concepts).lower()

        known_terms = [
            "python",
            "javascript",
            "typescript",
            "java",
            "c++",
            "c#",
            "go",
            "golang",
            "rust",
            "ruby",
            "php",
            "swift",
            "kotlin",
            "scala",
            "r",
            "fastapi",
            "django",
            "flask",
            "react",
            "next.js",
            "node.js",
            "nodejs",
            "vue",
            "angular",
            "spring boot",
        ]

        for term in known_terms:
            if term in text:
                if term == "golang":
                    return "Go"
                if term == "nodejs":
                    return "Node.js"
                return term

        return ""

    def _build_github_topics(
        self,
        topic: str,
        lesson_title: str,
        key_concepts: list[str],
        programming_language: str,
    ) -> list[str]:
        """
        Build concise GitHub topic tags.
        """
        candidates = []

        if programming_language:
            candidates.append(programming_language.lower().replace(" ", "-"))

        for source in [topic, lesson_title] + key_concepts:
            lowered = source.lower().strip()
            if not lowered:
                continue
            tokenized = lowered.replace("/", " ").replace("_", " ").split()
            if len(tokenized) == 1:
                candidates.append(tokenized[0])
            else:
                candidates.append("-".join(tokenized[:2]))

        candidates.extend(["learning", "examples"])

        cleaned = []
        seen = set()

        for item in candidates:
            value = item.strip("- ").lower()
            if not value or len(value) < 2:
                continue
            if value not in seen:
                seen.add(value)
                cleaned.append(value)

        return cleaned[:6]

    def _build_key_terms(
        self,
        topic: str,
        lesson_title: str,
        key_concepts: list[str],
        programming_language: str,
    ) -> list[str]:
        """
        Build high-value key terms for downstream search enhancement.
        """
        terms = []

        if programming_language:
            terms.append(programming_language)

        if lesson_title:
            terms.append(lesson_title)

        if topic and topic.lower() != lesson_title.lower():
            terms.append(topic)

        terms.extend(key_concepts)

        # Add shorter concept chunks when useful
        for concept in key_concepts:
            parts = concept.split()
            if len(parts) > 1:
                terms.extend(parts[:2])

        cleaned = []
        seen = set()

        for term in terms:
            value = self._clean_text(term)
            if not value:
                continue
            lowered = value.lower()
            if lowered not in seen:
                seen.add(lowered)
                cleaned.append(value)

        return cleaned[:10]

    def _extract_wikipedia_term(self, lesson_title: str, topic: str) -> str:
        """
        Extract the most likely Wikipedia article title.
        """
        remove_patterns = [
            "Understanding",
            "Introduction to",
            "Introduction",
            "Learn",
            "Getting Started with",
            "Getting Started",
            "Working with",
            "Basics of",
            "Basics",
            "How to",
            "What is",
            "What are",
            "Building",
            "Using",
            "Implementing",
        ]

        term = lesson_title
        for pattern in remove_patterns:
            term = term.replace(pattern, "").strip()

        term = self._clean_text(term)

        if len(term) < 3:
            term = topic

        return term or topic or lesson_title

    def _extract_wikipedia_fallback(
        self,
        lesson_title: str,
        topic: str,
        key_concepts: list[str],
    ) -> str:
        """
        Extract a broader fallback term for Wikipedia search.
        """
        if topic:
            return topic
        if key_concepts:
            return key_concepts[0]
        return lesson_title

"""
Query Optimizer Service
Uses AI to generate optimized search queries for each platform.
"""
from typing import Optional
from app.services.groq_service import GroqService
from app.config import settings

QUERY_OPTIMIZATION_PROMPT = """You are a search query optimization expert. 
Your job is to generate the BEST possible search queries for finding educational content.

Given a lesson topic, generate optimized search queries for different platforms.

RULES:
1. Be SPECIFIC - avoid generic terms
2. Include key technical terms
3. Add context words that indicate educational content
4. For programming topics, include the language name
5. Avoid filler words like "tutorial" for Wikipedia (it's an encyclopedia)
6. For GitHub, focus on finding example code and learning repos

EXAMPLES:
- Lesson: "Understanding Variables in Python"
  - YouTube: "python variables explained beginner tutorial"
  - Wikipedia: "Variable (computer science)"
  - GitHub: "python examples variables beginner learning"
  - DevTo: "python variables beginners guide"
  - Articles: "python variables tutorial explained examples"

- Lesson: "Introduction to Machine Learning"
  - YouTube: "machine learning basics explained simple"
  - Wikipedia: "Machine learning"
  - GitHub: "machine learning tutorial python examples beginner"
  - DevTo: "machine learning introduction beginners"
  - Articles: "machine learning basics tutorial introduction"

Now generate queries for:
TOPIC: {topic}
LESSON: {lesson_title}
KEY CONCEPTS: {key_concepts}

Respond with ONLY valid JSON:
{{
  "youtube": "optimized youtube search query",
  "wikipedia": "exact Wikipedia article title to search",
  "wikipedia_fallback": "alternative Wikipedia search term",
  "github": "optimized github search query",
  "github_topics": ["topic1", "topic2", "topic3"],
  "devto": "optimized dev.to search tags",
  "articles": "optimized general article search query",
  "key_terms": ["term1", "term2", "term3"]
}}
"""


class QueryOptimizer:
    """Generates optimized search queries using AI."""
    
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
        key_concepts: list[str] = None
    ) -> dict:
        """
        Generate optimized search queries for all platforms.
        
        Args:
            topic: Main topic (e.g., "Python Programming")
            lesson_title: Specific lesson (e.g., "Understanding Variables")
            key_concepts: List of key concepts in the lesson
            
        Returns:
            Dict with optimized queries for each platform
        """
        print(f"[QUERY_OPTIMIZER] Generating queries for: {lesson_title}")
        
        if not self.groq:
            # Fallback to basic query generation
            return self._generate_basic_queries(topic, lesson_title, key_concepts)
        
        try:
            concepts_str = ", ".join(key_concepts) if key_concepts else "general concepts"
            
            prompt = QUERY_OPTIMIZATION_PROMPT.format(
                topic=topic,
                lesson_title=lesson_title,
                key_concepts=concepts_str
            )
            
            response = await self.groq.generate_with_system_prompt(
                system_prompt="You are a search query optimization expert. Respond only with valid JSON.",
                user_message=prompt,
                temperature=0.3,  # Lower temperature for more consistent results
                max_tokens=500,
                json_response=True
            )
            
            queries = self.groq.parse_json_response(response)
            print(f"[QUERY_OPTIMIZER] Generated queries: {list(queries.keys())}")
            return queries
            
        except Exception as e:
            print(f"[QUERY_OPTIMIZER] AI generation failed: {e}, using fallback")
            return self._generate_basic_queries(topic, lesson_title, key_concepts)
    
    def _generate_basic_queries(
        self,
        topic: str,
        lesson_title: str,
        key_concepts: list[str] = None
    ) -> dict:
        """
        Generate basic queries without AI (fallback).
        """
        # Clean up the lesson title
        clean_title = lesson_title.replace(":", "").replace("-", " ").strip()
        
        # Extract main subject
        main_subject = topic.split()[0] if topic else ""
        
        # Build concept string
        concepts = " ".join(key_concepts[:3]) if key_concepts else ""
        
        return {
            "youtube": f"{main_subject} {clean_title} tutorial explained",
            "wikipedia": self._extract_wikipedia_term(lesson_title, topic),
            "wikipedia_fallback": topic,
            "github": f"{main_subject.lower()} {clean_title.lower()} examples",
            "github_topics": [main_subject.lower(), "tutorial", "learning"],
            "devto": main_subject.lower(),
            "articles": f"{main_subject} {clean_title} tutorial guide",
            "key_terms": key_concepts[:5] if key_concepts else [main_subject]
        }
    
    def _extract_wikipedia_term(self, lesson_title: str, topic: str) -> str:
        """
        Extract the most likely Wikipedia article title.
        """
        # Common patterns to remove
        remove_patterns = [
            "Understanding", "Introduction to", "Learn", "Getting Started with",
            "Working with", "Basics of", "How to", "What is", "What are"
        ]
        
        term = lesson_title
        for pattern in remove_patterns:
            term = term.replace(pattern, "").strip()
        
        # If the term is too short, use the topic
        if len(term) < 3:
            term = topic
        
        return term

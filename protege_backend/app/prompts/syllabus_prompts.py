from .base_prompts import combine_prompts

SYLLABUS_SYSTEM_PROMPT = """
You are an expert curriculum designer for Protégé, an AI learning platform.
Your job is to create personalized, structured learning paths.

When creating a syllabus:
1. Break the topic into logical modules (4-8 modules typically)
2. Each module has 3-6 lessons
3. Each lesson has specific learning objectives
4. Provide HIGHLY SPECIFIC search queries to find learning resources (see query rules below)
5. Estimate realistic time for each lesson
6. Consider the user's experience level
7. Order content from foundational to advanced

SEARCH QUERY RULES — Follow these exactly:
- YouTube queries MUST include the specific concept + "tutorial" or "explained". Example: "gradient descent algorithm explained" NOT "machine learning".
- Article queries MUST include the concept + context. Example: "understanding gradient descent optimization" NOT "machine learning basics".
- GitHub queries should target learning repos. Example: "gradient descent python implementation example" NOT "machine learning".
- Wikipedia queries should be the exact concept name. Example: "Gradient descent" NOT "machine learning overview".
- NEVER use a generic topic name (like "Python" or "Machine Learning") as the primary search term.
- NEVER duplicate the same search query across different lessons.
- Each query must be specific enough to return content about THAT EXACT lesson, not the broader topic.

Always respond with valid JSON.
"""

SYLLABUS_USER_PROMPT_TEMPLATE = """
Create a learning syllabus for:

TOPIC: {topic}
USER'S GOAL: {goal}
EXPERIENCE LEVEL: {experience_level}
DAILY TIME AVAILABLE: {daily_time_minutes} minutes

Return a JSON object with this structure:
{{
  "topic": "Full topic name",
  "description": "Brief description of what will be learned",
  "total_duration_hours": number,
  "difficulty": "beginner|intermediate|advanced",
  "prerequisites": ["list", "of", "prerequisites"],
  "modules": [
    {{
      "module_number": 1,
      "title": "Module Title",
      "description": "What this module covers",
      "duration_hours": number,
      "lessons": [
        {{
          "lesson_number": 1,
          "title": "Lesson Title",
          "description": "What this lesson teaches",
          "duration_minutes": number,
          "learning_objectives": ["objective 1", "objective 2"],
          "key_concepts": ["concept 1", "concept 2"],
          "search_queries": {{
            "youtube": "specific concept + tutorial/explained (e.g. 'gradient descent algorithm explained')",
            "articles": "specific concept + context (e.g. 'understanding gradient descent optimization')",
            "github": "specific concept + implementation (e.g. 'gradient descent python example')",
            "wikipedia": "exact concept name (e.g. 'Gradient descent')",
            "wikipedia_fallback": "broader fallback concept name",
            "key_terms": ["term1", "term2"]
          }}
        }}
      ]
    }}
  ],
  "capstone_project": {{
    "title": "Project Title",
    "description": "What the user will build",
    "skills_applied": ["skill 1", "skill 2"]
  }}
}}

CRITICAL: Each lesson's search_queries must be SPECIFIC to that lesson's exact topic.
- BAD: "youtube": "Python programming" for a lesson about list comprehensions
- GOOD: "youtube": "Python list comprehensions tutorial beginner"
"""

def get_syllabus_prompt(topic: str, goal: str, experience_level: str, daily_time_minutes: int) -> str:
    return SYLLABUS_USER_PROMPT_TEMPLATE.format(
        topic=topic,
        goal=goal,
        experience_level=experience_level,
        daily_time_minutes=daily_time_minutes
    )

from .base_prompts import combine_prompts

SYLLABUS_SYSTEM_PROMPT = """
You are an expert curriculum designer for Protégé, an AI learning platform.
Your job is to create personalized, structured learning paths.

When creating a syllabus:
1. Break the topic into logical modules (4-8 modules typically)
2. Each module has 3-6 lessons
3. Each lesson has specific learning objectives
4. Provide search queries to find learning resources
5. Estimate realistic time for each lesson
6. Consider the user's experience level
7. Order content from foundational to advanced

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
            "youtube": "specific YouTube search query",
            "articles": "specific article search query",
            "github": "specific GitHub search query (optional)"
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
"""

def get_syllabus_prompt(topic: str, goal: str, experience_level: str, daily_time_minutes: int) -> str:
    return SYLLABUS_USER_PROMPT_TEMPLATE.format(
        topic=topic,
        goal=goal,
        experience_level=experience_level,
        daily_time_minutes=daily_time_minutes
    )

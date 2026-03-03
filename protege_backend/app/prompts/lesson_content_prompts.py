"""
Prompt templates for AI lesson content generation.
Each generates structured, topic-specific educational content.
"""

LESSON_CONTENT_PROMPT = """You are an expert educator creating a detailed, structured lesson for an online learning platform.

## Context
- **Subject/Topic**: {topic}
- **Module**: {module_title}
- **Lesson Title**: {lesson_title}
- **Lesson Description**: {lesson_description}
- **Key Concepts to Cover**: {key_concepts}
- **Difficulty Level**: {difficulty}

## CRITICAL RULES
1. ALL code examples MUST be in **{topic}** programming language. Do NOT use any other language. If the topic is Python, write Python code. If the topic is JavaScript, write JavaScript code. Never default to Dart, Java, or any other language.
2. Content must be SPECIFIC to "{lesson_title}" within the context of "{topic}". Do NOT give generic programming advice.
3. Every explanation must build on the lesson_description and expand it with real depth.
4. Code examples must be WORKING, COMPLETE, and RUNNABLE — no pseudo-code unless explicitly labeled.
5. Key takeaways must be specific to this lesson, NOT generic platitudes like "practice writing clean code".

## Required Output Format (respond ONLY with this JSON structure, no markdown wrapping):
{{
  "introduction": "2-3 paragraphs introducing {lesson_title} in the context of {topic}. Explain WHY this matters and WHAT the learner will gain. 150-250 words.",
  "sections": [
    {{
      "title": "Section title",
      "content": "Detailed markdown-formatted explanation. 200-400 words per section. Use bullet points, bold, and emphasis for readability.",
      "code_example": "Complete, working code example in {topic} (or null if no code needed for this section)",
      "language": "{topic_language}"
    }}
  ],
  "key_takeaways": [
    "Specific, actionable takeaway 1 about {lesson_title}",
    "Specific, actionable takeaway 2",
    "At least 5 takeaways, each unique and meaningful"
  ],
  "common_mistakes": [
    {{
      "mistake": "What beginners commonly get wrong",
      "correction": "The correct approach and why"
    }}
  ],
  "practice_exercises": [
    {{
      "title": "Exercise title",
      "description": "What to build or implement",
      "hint": "A helpful hint if they get stuck"
    }}
  ],
  "summary": "A concise 2-3 sentence summary of the entire lesson, reinforcing the most important point."
}}

## Section Guidelines
- Include 3-5 sections covering the key concepts
- At least 2 sections should have code_example
- The first section should be foundational ("What is X?")
- Later sections should build complexity
- The language field for code examples must be the actual language identifier: "python" for Python, "javascript" for JavaScript, "java" for Java, etc.
- For non-programming topics, omit code_example (set to null) and language (set to null)

## Difficulty Calibration
- **beginner**: Assume no prior knowledge of this specific topic. Explain every term. Short, simple code examples.
- **intermediate**: Assume foundational knowledge. Focus on patterns, best practices, edge cases. Medium complexity code.
- **advanced**: Assume working knowledge. Focus on internals, optimization, advanced patterns. Complex real-world code.

Generate the lesson content now. Remember: ONLY output valid JSON, no markdown code fences.
"""


def build_lesson_content_prompt(
    topic: str,
    module_title: str,
    lesson_title: str,
    lesson_description: str,
    key_concepts: list[str],
    difficulty: str = "beginner",
) -> str:
    """Build the formatted prompt for lesson content generation."""
    # Determine the language identifier for code examples
    topic_lower = topic.lower().strip()
    language_map = {
        "python": "python",
        "javascript": "javascript",
        "typescript": "typescript",
        "java": "java",
        "c++": "cpp",
        "c#": "csharp",
        "ruby": "ruby",
        "go": "go",
        "golang": "go",
        "rust": "rust",
        "swift": "swift",
        "kotlin": "kotlin",
        "dart": "dart",
        "php": "php",
        "r": "r",
        "sql": "sql",
        "html": "html",
        "css": "css",
        "react": "javascript",
        "react native": "javascript",
        "vue": "javascript",
        "angular": "typescript",
        "node.js": "javascript",
        "nodejs": "javascript",
        "django": "python",
        "flask": "python",
        "fastapi": "python",
        "spring": "java",
        "rails": "ruby",
        "ruby on rails": "ruby",
    }

    topic_language = language_map.get(topic_lower, topic_lower)

    return LESSON_CONTENT_PROMPT.format(
        topic=topic,
        module_title=module_title,
        lesson_title=lesson_title,
        lesson_description=lesson_description,
        key_concepts=", ".join(key_concepts) if key_concepts else "general concepts",
        difficulty=difficulty,
        topic_language=topic_language,
    )

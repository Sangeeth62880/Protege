"""
Quiz Generation Prompts
"""

QUIZ_GENERATION_PROMPT = """Generate {count} quiz questions about: "{topic}"

Difficulty: {difficulty}

Return a JSON array with this exact structure:
[
    {{
        "question": "The question text",
        "type": "multipleChoice",
        "options": ["Option A", "Option B", "Option C", "Option D"],
        "correct_answer": "The correct option text",
        "explanation": "Why this is the correct answer",
        "points": 1
    }}
]

Guidelines:
1. Mix question types (mostly multiple choice, some true/false)
2. Make incorrect options plausible
3. Cover different aspects of the topic
4. Provide clear, educational explanations
5. Vary difficulty within the set

For true/false questions, use:
{{
    "question": "Statement to evaluate",
    "type": "trueFalse",
    "options": ["True", "False"],
    "correct_answer": "True" or "False",
    "explanation": "Explanation",
    "points": 1
}}

Return ONLY the JSON array, no additional text."""


QUESTION_EVALUATION_PROMPT = """Evaluate this answer:

Question: {question}
User's Answer: {user_answer}
Correct Answer: {correct_answer}

Is the user's answer correct? Consider:
1. Exact match (definitely correct)
2. Semantically equivalent (likely correct)
3. Partially correct (some points)
4. Incorrect

Respond with JSON:
{{
    "is_correct": true/false,
    "score": 0.0 to 1.0,
    "feedback": "Brief explanation"
}}"""

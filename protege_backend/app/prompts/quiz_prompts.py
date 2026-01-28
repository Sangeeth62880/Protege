"""
Quiz Generation Prompt Templates
"""

QUIZ_SYSTEM_PROMPT = """You are an expert educational quiz creator for Protégé.
Your job is to create engaging, educational quizzes that test understanding.

QUIZ REQUIREMENTS:
1. Questions should test understanding, not just memorization
2. Include a mix of difficulty levels
3. Each question must have a clear correct answer
4. Explanations should teach, not just state the answer
5. For programming topics, include code-based questions

OUTPUT FORMAT:
You must respond with valid JSON only. No additional text.
"""

QUIZ_GENERATION_TEMPLATE = """Create a quiz for:

TOPIC: {topic}
LESSON: {lesson_title}
CONCEPTS TO TEST: {key_concepts}
DIFFICULTY LEVEL: {difficulty}
NUMBER OF QUESTIONS: {num_questions}
QUESTION TYPES: {question_types}

Return JSON with this exact structure:
{{
  "quiz_title": "Quiz: {lesson_title}",
  "total_questions": {num_questions},
  "estimated_time_minutes": <number>,
  "questions": [
    {{
      "question_number": 1,
      "question_type": "multiple_choice",
      "difficulty": "easy|medium|hard",
      "question_text": "The question here?",
      "options": ["A) Option 1", "B) Option 2", "C) Option 3", "D) Option 4"],
      "correct_answer": "A",
      "explanation": "Detailed explanation of why A is correct and why others are wrong.",
      "concept_tested": "variable assignment"
    }},
    {{
      "question_number": 2,
      "question_type": "true_false",
      "difficulty": "easy",
      "question_text": "Statement to evaluate",
      "correct_answer": "true",
      "explanation": "Why this is true/false"
    }},
    {{
      "question_number": 3,
      "question_type": "fill_blank",
      "difficulty": "medium",
      "question_text": "A _____ is used to store data in Python.",
      "correct_answer": "variable",
      "acceptable_answers": ["variable", "var"],
      "explanation": "Explanation here"
    }},
    {{
      "question_number": 4,
      "question_type": "code_completion",
      "difficulty": "hard",
      "question_text": "Complete the code to print 'Hello World':",
      "code_template": "_____(\"Hello World\")",
      "correct_answer": "print",
      "explanation": "The print() function outputs text to the console"
    }}
  ]
}}
"""

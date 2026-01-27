"""
Evaluation Prompts for Reverse Tutoring
"""

EVALUATION_PROMPT = """Evaluate this explanation for teaching quality:

Explanation: "{explanation}"

Current session score: {current_score}/100

Rate the explanation on:
1. Clarity (0-25): Is it easy to understand?
2. Accuracy (0-25): Is the information correct?
3. Completeness (0-25): Does it cover key concepts?
4. Examples (0-25): Are there good examples?

Provide a score from 0-100 and brief feedback.

Format: Score: [number]"""


CONFUSED_STUDENT_PROMPT = """You are a curious learner receiving this explanation:

"{explanation}"

Quality score: {score}/100

Respond as a confused but eager student:
- If score < 40: You're very confused. Ask basic clarifying questions.
- If score 40-60: You somewhat understand but have specific questions.
- If score 60-80: You mostly understand. Ask about edge cases or applications.
- If score > 80: You understand well! Show appreciation and ask an advanced question.

Keep your response to 2-3 sentences. Be encouraging but push for clarity."""


AHA_METER_PROMPT = """Based on the teaching session so far:

Topic: {topic}
Explanations given: {num_explanations}
Current understanding score: {current_score}

Determine if the student (AI) has achieved the "Aha!" moment:
- Score >= 80: Full understanding achieved ✓
- Score 60-79: Good progress, almost there
- Score < 60: More explanation needed

Respond with:
1. Whether to mark as complete (true/false)
2. Encouraging feedback for the teacher
3. Specific areas that were well-explained or need work"""

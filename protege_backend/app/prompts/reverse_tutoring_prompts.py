"""
Reverse Tutoring Prompts
Detailed prompts for evaluating user explanations
"""

# ============================================================================
# CLARITY EVALUATION PROMPT
# ============================================================================

CLARITY_EVALUATION_PROMPT = """Evaluate the CLARITY of this explanation about {topic}.

Explanation to evaluate:
"{explanation}"

Evaluate on these criteria (each out of 25 points):
1. SIMPLICITY (0-25): Is the language easy to understand?
   - Uses simple words vs. unnecessary jargon
   - Sentence structure is clear
   - Avoids overly complex phrasing

2. STRUCTURE (0-25): Is the explanation well-organized?
   - Has a logical flow
   - Ideas build on each other
   - Easy to follow from start to finish

3. EXAMPLES (0-25): Are there helpful examples or analogies?
   - Uses relatable comparisons
   - Examples clarify abstract concepts
   - Analogies are appropriate

4. ENGAGEMENT (0-25): Is it engaging and clear?
   - Not dry or boring
   - Key points stand out
   - Reader stays interested

Provide your evaluation in this exact JSON format:
{{
    "score": <total 0-100>,
    "feedback": "<one sentence overall feedback>",
    "strengths": ["<strength 1>", "<strength 2>"],
    "weaknesses": ["<weakness 1>", "<weakness 2>"],
    "simplicity_score": <0-25>,
    "structure_score": <0-25>,
    "examples_score": <0-25>,
    "engagement_score": <0-25>
}}"""


# ============================================================================
# ACCURACY EVALUATION PROMPT
# ============================================================================

ACCURACY_EVALUATION_PROMPT = """Evaluate the ACCURACY of this explanation about {topic}.

Explanation to evaluate:
"{explanation}"

Key concepts that should be accurate:
{concepts}

Reference information (if available):
{reference_info}

Evaluate:
1. Are there any FACTUAL ERRORS? (major mistakes that are simply wrong)
2. Are there any MISCONCEPTIONS? (common misunderstandings being propagated)
3. Are there any OVERSIMPLIFICATIONS that become inaccurate?
4. Is the technical terminology used correctly?

Provide your evaluation in this exact JSON format:
{{
    "score": <0-100, deduct points for each error>,
    "errors": [
        {{"error": "<describe error>", "correction": "<correct information>", "severity": "<minor|moderate|major>"}}
    ],
    "corrections": ["<correction 1>", "<correction 2>"],
    "terminology_correct": true/false,
    "oversimplifications": ["<oversimplification if any>"]
}}

If the explanation is accurate, return score: 100 with empty errors array."""


# ============================================================================
# COMPLETENESS EVALUATION PROMPT
# ============================================================================

COMPLETENESS_EVALUATION_PROMPT = """Evaluate the COMPLETENESS of this explanation about {topic}.

Explanation to evaluate:
"{explanation}"

Essential concepts that should be covered:
{concepts}

Evaluate:
1. Which essential concepts were COVERED adequately?
2. Which essential concepts are MISSING or barely touched?
3. Is the explanation thorough for the scope?
4. Are there important relationships between concepts explained?

Provide your evaluation in this exact JSON format:
{{
    "score": <0-100, based on coverage percentage>,
    "covered": ["<concept 1 that was explained>", "<concept 2>"],
    "missing": ["<concept not covered>", "<concept barely mentioned>"],
    "coverage_percentage": <what % of concepts were covered>,
    "depth": "<shallow|adequate|thorough>",
    "relationships_explained": true/false
}}"""


# ============================================================================
# COMBINED EVALUATION PROMPT (for single API call)
# ============================================================================

COMBINED_EVALUATION_PROMPT = """You are an expert educator evaluating a teaching explanation.

TOPIC: {topic}
CONCEPTS TO COVER: {concepts}

EXPLANATION TO EVALUATE:
"{explanation}"

CONVERSATION CONTEXT:
{conversation_history}

Evaluate this explanation on THREE dimensions:

## 1. CLARITY (30% weight)
- Is the language simple and accessible?
- Is the explanation well-structured?
- Are there helpful examples or analogies?

## 2. ACCURACY (40% weight)
- Is all information factually correct?
- Are there any misconceptions?
- Is terminology used correctly?

## 3. COMPLETENESS (30% weight)
- Are the key concepts covered?
- Is the explanation thorough?
- What's missing that should be included?

Return your evaluation in this exact JSON format:
{{
    "clarity": {{
        "score": <0-100>,
        "feedback": "<brief feedback>",
        "strengths": ["<strength 1>"],
        "weaknesses": ["<weakness 1>"]
    }},
    "accuracy": {{
        "score": <0-100>,
        "errors": [],
        "corrections": []
    }},
    "completeness": {{
        "score": <0-100>,
        "covered": ["<concepts covered>"],
        "missing": ["<concepts missing>"]
    }},
    "overall_score": <weighted average>,
    "concepts_demonstrated": ["<concepts the user clearly understands>"],
    "suggestions": ["<how to improve the explanation>"]
}}"""


# ============================================================================
# MISCONCEPTION DETECTION PROMPT
# ============================================================================

MISCONCEPTION_DETECTION_PROMPT = """Analyze this explanation for common misconceptions about {topic}.

Explanation:
"{explanation}"

Common misconceptions about this topic include:
{common_misconceptions}

Check if the explanation:
1. Contains any of these common misconceptions
2. Might inadvertently teach incorrect mental models
3. Uses analogies that could lead to misunderstanding
4. Oversimplifies in ways that create wrong impressions

Return in JSON format:
{{
    "misconceptions_found": [
        {{"misconception": "<what's wrong>", "in_explanation": "<quote from explanation>", "correct_understanding": "<what should be said>"}}
    ],
    "risky_analogies": ["<analogy that might mislead>"],
    "safe": true/false
}}"""


# ============================================================================
# AHA! MOMENT DETECTION PROMPT  
# ============================================================================

AHA_MOMENT_PROMPT = """Based on the teaching session progress, determine if the "Aha! moment" has been achieved.

Topic: {topic}
Current Understanding Score: {score}/100
Concepts Covered: {concepts_covered}
Concepts Still Missing: {concepts_missing}
Message Count: {message_count}

The user has been teaching for {messages} exchanges.

Determine:
1. Has the user demonstrated MASTERY (clear, accurate, complete explanations)?
2. Should we celebrate their teaching success?
3. What encouraging feedback should we give?

Return in JSON format:
{{
    "mastery_achieved": true/false,
    "celebration_message": "<exciting congratulations if mastery achieved>",
    "encouragement": "<encouraging message for next steps>",
    "key_strength": "<what they explained best>",
    "growth_area": "<what could improve>"
}}"""


# ============================================================================
# FEEDBACK GENERATION PROMPTS
# ============================================================================

FINAL_FEEDBACK_PROMPT = """Generate final feedback for a completed reverse tutoring session.

Topic: {topic}
Final Score: {score}/100
Clarity: {clarity}/100
Accuracy: {accuracy}/100  
Completeness: {completeness}/100
Concepts Successfully Taught: {concepts_covered}
Concepts That Need Work: {concepts_missing}
Total Exchanges: {message_count}

Generate encouraging, specific feedback that:
1. Celebrates what they did well
2. Notes areas for improvement
3. Suggests next steps for learning
4. Is warm and motivating

Keep it to 2-3 short paragraphs.

Feedback:"""


# ============================================================================
# STUDENT RESPONSE PROMPT
# ============================================================================

CONFUSED_STUDENT_PROMPT = """You are a curious learner trying to understand {topic}.
You received this explanation:

"{explanation}"

Quality score: {score}/100

Respond as a confused but eager student learning about {topic}:
- If score < 40: You're very confused about {topic}. Ask basic clarifying questions specific to {topic}.
- If score 40-60: You somewhat understand but have specific questions about {topic}.
- If score 60-80: You mostly understand {topic}. Ask about edge cases or real-world applications.
- If score > 80: You understand {topic} well! Show appreciation and ask an advanced question.

Keep your response to 2-3 sentences. Be encouraging but push for clarity about {topic}."""

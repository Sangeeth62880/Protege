"""
Misconception Prompts for Reverse Tutoring
Prompts for generating deliberate misconceptions to test user understanding
"""

# ============================================================================
# MISCONCEPTION GENERATION PROMPTS
# ============================================================================

GENERATE_MISCONCEPTION_PROMPT = """Generate a common misconception about {topic} that a confused student might have.

The student persona is: {persona_type}
The user just explained: "{last_explanation}"

Common misconceptions about this topic include things like:
- Confusing similar concepts
- Oversimplifying to the point of being wrong
- Missing key dependencies or prerequisites
- Applying concepts in wrong contexts

Generate a natural-sounding statement that:
1. Contains a SUBTLE misconception (not obviously wrong)
2. Is phrased as the student "checking their understanding"
3. Would require the teacher to gently correct them
4. Is relevant to what was just explained

Return in this exact JSON format:
{{
    "misconception_statement": "<what the confused student says>",
    "misconception_type": "<what type of error: confusion|oversimplification|wrong_context|missing_nuance>",
    "correct_understanding": "<what the correct understanding should be>",
    "why_its_wrong": "<brief explanation of the error>",
    "difficulty_to_catch": "<easy|medium|hard>"
}}"""


# ============================================================================
# PERSONA-SPECIFIC MISCONCEPTION STYLES
# ============================================================================

PERSONA_MISCONCEPTION_STYLES = {
    "curious_child": {
        "intro_phrases": [
            "So it's like {wrong_analogy}?",
            "Oh! So that means {oversimplification}!",
            "But my friend said {common_myth}...",
            "Is it the same as {confused_concept}?"
        ],
        "misconception_types": ["oversimplification", "wrong_analogy", "confusion"],
        "difficulty": "easy"
    },
    "skeptical_teen": {
        "intro_phrases": [
            "Wait, so basically {wrong_conclusion}?",
            "That doesn't make sense because {flawed_logic}...",
            "But if that's true, then {wrong_implication}",
            "I read online that {internet_myth}..."
        ],
        "misconception_types": ["flawed_logic", "wrong_implication", "edge_case_confusion"],
        "difficulty": "medium"
    },
    "confused_adult": {
        "intro_phrases": [
            "Let me make sure I understand - {partial_understanding}?",
            "In my old job we did {wrong_application}, is it similar?",
            "So this is basically the same as {wrong_analogy}?",
            "I think I get it - {incomplete_understanding}?"
        ],
        "misconception_types": ["wrong_application", "incomplete_understanding", "context_confusion"],
        "difficulty": "medium"
    },
    "technical_peer": {
        "intro_phrases": [
            "But wouldn't that mean {edge_case_failure}?",
            "What about {obscure_scenario} - wouldn't that break?",
            "I thought {subtle_technical_error} was the standard approach?",
            "Doesn't that violate {misremembered_principle}?"
        ],
        "misconception_types": ["subtle_technical_error", "edge_case_confusion", "misapplied_principle"],
        "difficulty": "hard"
    }
}


# ============================================================================
# MISCONCEPTION VERIFICATION PROMPT
# ============================================================================

VERIFY_CORRECTION_PROMPT = """Verify if the user correctly identified and corrected the misconception.

The misconception was: "{misconception}"
The correct understanding should be: "{correct_understanding}"
The user's correction: "{user_response}"

Evaluate:
1. Did the user IDENTIFY the error in the misconception?
2. Did the user EXPLAIN why it was wrong?
3. Did the user provide the CORRECT understanding?
4. Was the correction COMPLETE (nothing important missing)?

Return in JSON format:
{{
    "correctly_identified": true/false,
    "correctly_explained": true/false,
    "correction_complete": true/false,
    "score": <0-100>,
    "feedback": "<brief feedback on the correction>",
    "missing_points": ["<anything the user missed>"]
}}"""


# ============================================================================
# TOPIC-SPECIFIC MISCONCEPTION BANKS
# ============================================================================

# These are example misconceptions for common programming topics
# The AI will generate dynamic ones based on context

PROGRAMMING_MISCONCEPTIONS = {
    "variables": [
        {
            "misconception": "Variables are like boxes that store data",
            "issue": "This analogy fails for reference types and mutable data",
            "correct": "Variables are labels/names that point to data in memory"
        },
        {
            "misconception": "Changing a copy always changes the original too",
            "issue": "Confuses pass-by-value with pass-by-reference",
            "correct": "It depends on whether the type is value or reference"
        }
    ],
    "functions": [
        {
            "misconception": "Functions and methods are the same thing",
            "issue": "Methods are functions bound to objects/classes",
            "correct": "Methods are functions associated with objects, functions are standalone"
        },
        {
            "misconception": "Return statements end the program",
            "issue": "Confuses return with exit",
            "correct": "Return ends the function and gives back a value"
        }
    ],
    "loops": [
        {
            "misconception": "For loops and while loops do exactly the same thing",
            "issue": "Overlooks use case differences",
            "correct": "For loops are best when you know iteration count, while loops when you don't"
        },
        {
            "misconception": "You should always use for loops because they're faster",
            "issue": "Premature optimization, ignores readability",
            "correct": "Choose based on clarity and use case, not perceived speed"
        }
    ],
    "arrays": [
        {
            "misconception": "Arrays and lists are always the same",
            "issue": "Ignores language-specific implementations",
            "correct": "Arrays are often fixed-size and type-specific, lists are typically dynamic"
        }
    ],
    "objects": [
        {
            "misconception": "Classes and objects are the same thing",
            "issue": "Confuses blueprint with instance",
            "correct": "A class is a template, an object is an instance created from that template"
        }
    ]
}


# ============================================================================
# MISCONCEPTION CHALLENGE PROMPT
# ============================================================================

CHALLENGE_WITH_MISCONCEPTION_PROMPT = """You are {persona_name}, a {persona_type} student learning {topic}.

You've been listening to the teacher's explanation and you think you understand, but you have a misconception you want to check.

Based on the conversation so far:
{conversation_history}

And the teacher's last explanation:
"{last_explanation}"

Generate a response where you:
1. Show partial understanding of what was explained
2. Express your misconception as if checking your understanding
3. Make it sound natural for your persona
4. The misconception should be {difficulty} to catch

Your misconception type should be: {misconception_type}

Respond in 2-3 sentences, staying in character as {persona_name}."""

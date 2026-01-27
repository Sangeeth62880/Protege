SYSTEM_PROMPT_BASE = """
You are Protégé, an advanced AI learning assistant designed to create personalized application-based learning experiences.
Your goal is to help users learn by doing, providing structured paths, practical exercises, and constructive feedback.
"""

JSON_FORMAT_INSTRUCTIONS = """
You must output strictly valid JSON. 
Do not include any explanation, preamble, or markdown formatting outside the JSON object.
"""

def combine_prompts(system_prompt: str, instructions: str = "") -> str:
    """Helper to combine base prompt with specific instructions"""
    full_prompt = f"{system_prompt}\n\n{JSON_FORMAT_INSTRUCTIONS}" if "JSON" in instructions or "JSON" in system_prompt else system_prompt
    if instructions:
        full_prompt += f"\n\n{instructions}"
    return full_prompt

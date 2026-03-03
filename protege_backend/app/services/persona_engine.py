"""
Persona Engine
Powers the AI personas for Reverse Tutoring.
Each persona has a distinct personality, age-appropriate vocabulary,
and asks topic-relevant questions based on conversation context.
"""
import json
from typing import Optional

PERSONA_DEFINITIONS = {
    "maya": {
        "name": "Curious Maya",
        "age": 8,
        "avatar": "👧",
        "traits": [
            "Extremely curious, asks 'why?' and 'how?' constantly",
            "Uses simple vocabulary appropriate for an 8-year-old",
            "Makes creative analogies to things a child would know (toys, games, school, animals)",
            "Gets excited when something makes sense ('Ooh!', 'Wow!', 'Cool!')",
            "Sometimes misunderstands and needs simpler re-explanation",
            "Relates new concepts to everyday experiences",
            "Has a short attention span - prefers short, clear answers",
            "Uses emojis naturally"
        ],
        "system_prompt": """You are Maya, an enthusiastic and curious 8-year-old girl. 
You are being TAUGHT by a human teacher about a specific topic.

YOUR ROLE: You are the STUDENT. The human is your TEACHER.

YOUR PERSONALITY:
- You are genuinely curious and eager to learn
- You speak like a real 8-year-old child - simple words, short sentences
- You make creative comparisons to things kids know (toys, cartoons, school, playground)
- When you understand something, you get really excited
- When confused, you say so honestly and ask for simpler explanations
- You sometimes make cute mistakes in understanding that help the teacher clarify
- You use emojis naturally (1-2 per message, not excessive)

YOUR BEHAVIOR:
- Ask follow-up questions that are DIRECTLY related to what the teacher just said
- Never pretend to understand if the explanation is unclear
- Build on previous explanations in the conversation
- Sometimes try to summarize what you learned in your own words (getting it partly right)
- Ask "why does it work that way?" or "can you give me an example?" frequently
- Connect new concepts to things you already discussed in this conversation

IMPORTANT:
- You are NOT a teacher. You are a STUDENT learning from the human.
- Your questions should test whether the human truly understands the topic.
- Ask questions that probe DEPTH of understanding, not just surface knowledge.
- Naturally challenge the teacher with "but what about..." scenarios.
- NEVER give correct explanations yourself - you're the student.
- Keep responses to 2-4 sentences maximum.
- Always respond in context of the SPECIFIC TOPIC being taught."""
    },
    
    "jake": {
        "name": "Skeptical Jake",
        "age": 16,
        "avatar": "🧑",
        "traits": [
            "Skeptical and questioning - doesn't accept things at face value",
            "Speaks like a teenager - casual, sometimes uses slang",
            "Asks 'prove it' and 'how do you know?' type questions",
            "Challenges assumptions and looks for edge cases",
            "Respects good explanations but pushes back on vague ones",
            "Compares with things he's seen online or heard from friends",
            "Gets bored with overly basic explanations"
        ],
        "system_prompt": """You are Jake, a skeptical and sharp 16-year-old teenager.
You are being TAUGHT by a human teacher about a specific topic.

YOUR ROLE: You are the STUDENT. The human is your TEACHER.

YOUR PERSONALITY:
- You're smart but skeptical - you don't just accept things without proof
- You speak casually like a real teenager
- You challenge the teacher with "but what about..." and "how do you know..." questions
- You ask about edge cases and real-world applications
- If an explanation is vague, you call it out: "That doesn't really make sense to me..."
- When you get a great explanation, you acknowledge it: "Okay, that actually makes sense"
- You sometimes bring up related things you've heard to test the teacher
- You prefer practical examples over theory

YOUR BEHAVIOR:
- Ask questions that specifically probe whether the teacher REALLY understands
- Challenge with counter-examples or edge cases related to the SPECIFIC TOPIC
- Push for practical, real-world applications
- If the teacher gives a surface-level answer, push deeper
- Sometimes play devil's advocate
- Build on the conversation history - reference what was said before
- Don't be rude, but don't be easy either

IMPORTANT:
- You are NOT a teacher. You are a STUDENT who is hard to impress.
- Your questions should naturally test depth of understanding.
- Focus questions on the SPECIFIC TOPIC being taught.
- Keep responses to 2-4 sentences maximum.
- NEVER give correct explanations yourself."""
    },
    
    "sarah": {
        "name": "Confused Sarah",
        "age": 35,
        "avatar": "👩",
        "traits": [
            "Adult learner changing careers - motivated but anxious",
            "Needs patient, clear explanations",
            "Asks for real-world analogies from everyday life",
            "Sometimes overthinks or overcomplicates things",
            "Appreciative when things finally click",
            "Relates concepts to her work experience (marketing, business)",
            "Worried about making mistakes"
        ],
        "system_prompt": """You are Sarah, a 35-year-old marketing professional trying to learn technical topics for a career change.

YOUR ROLE: You are the STUDENT. The human is your TEACHER.

YOUR PERSONALITY:
- You are motivated but sometimes anxious about learning technical things
- You speak professionally but warmly
- You need clear, real-world analogies to understand technical concepts
- When confused, you explain WHAT specifically confuses you
- When something clicks, you express genuine relief and excitement
- You relate new concepts to your marketing/business background
- You sometimes ask "Is this how it works in real projects?"
- You worry about common pitfalls: "What if I do this wrong?"

YOUR BEHAVIOR:
- Ask clarifying questions about the SPECIFIC parts you don't understand
- Request real-world examples and use cases
- Sometimes try to paraphrase what you learned (sometimes getting it slightly wrong)
- Ask about practical applications in work settings
- Express when the pace is too fast or too slow
- Build on previous conversation points
- Ask "Can you walk me through that step by step?"

IMPORTANT:
- You are NOT a teacher. You are a STUDENT who needs patience.
- Your questions should test whether the teacher can explain clearly to a non-technical person.
- Focus on the SPECIFIC TOPIC being taught.
- Keep responses to 2-4 sentences maximum.
- NEVER give correct explanations yourself."""
    },
    
    "alex": {
        "name": "Technical Alex",
        "age": 28,
        "avatar": "🧔",
        "traits": [
            "Has some technical background - knows basics",
            "Asks about edge cases, performance, best practices",
            "Wants to understand WHY something works, not just HOW",
            "Compares approaches and asks about trade-offs",
            "Interested in advanced topics and deeper understanding",
            "Asks about common patterns and anti-patterns"
        ],
        "system_prompt": """You are Alex, a 28-year-old junior developer who knows some basics but wants deeper understanding.

YOUR ROLE: You are the STUDENT. The human is your TEACHER.

YOUR PERSONALITY:
- You have some basic technical knowledge but want to go deeper
- You speak technically but not arrogantly
- You ask about WHY things work, not just HOW
- You care about best practices and common pitfalls
- You ask about edge cases: "What happens if..."
- You compare approaches: "Is there another way to do this?"
- You want to understand trade-offs and design decisions
- You ask about real-world production scenarios

YOUR BEHAVIOR:
- Ask specific technical follow-up questions related to the TOPIC
- Challenge with edge cases that reveal depth of understanding
- Ask about performance implications and best practices
- Compare the explained approach with alternatives
- Ask about common mistakes developers make
- Build on previous conversation points
- Sometimes introduce slightly advanced related concepts to test breadth

IMPORTANT:
- You are NOT a teacher. You are a STUDENT who asks tough technical questions.
- Your questions should genuinely test deep understanding of the SPECIFIC TOPIC.
- Keep responses to 2-4 sentences maximum.
- NEVER give correct explanations yourself - only ask questions."""
    }
}


class PersonaEngine:
    """
    Powers AI persona responses for Reverse Tutoring.
    """
    
    def __init__(self, groq_service):
        """
        Initialize with Groq service.
        
        Args:
            groq_service: GroqService instance for AI generation
        """
        self.groq = groq_service
        # Store conversation histories by session
        self.conversations = {}
        print("[PERSONA_ENGINE] Initialized")
    
    async def start_session(
        self,
        session_id: str,
        topic: str,
        persona_id: str
    ) -> dict:
        """
        Start a new teaching session.
        
        Args:
            session_id: Unique session identifier
            topic: Topic the user will teach
            persona_id: Selected persona ID
            
        Returns:
            Initial greeting message and session info
        """
        persona = PERSONA_DEFINITIONS.get(persona_id)
        if not persona:
            persona = PERSONA_DEFINITIONS["maya"]
            persona_id = "maya"
        
        print(f"[PERSONA_ENGINE] Starting session {session_id}")
        print(f"[PERSONA_ENGINE] Topic: {topic}")
        print(f"[PERSONA_ENGINE] Persona: {persona['name']}")
        
        # Generate contextual opening message
        opening_prompt = f"""The teacher wants to teach you about: "{topic}"

Generate your FIRST message as {persona['name']} (age {persona['age']}).

Requirements:
- Greet the teacher warmly
- Show genuine interest in learning about "{topic}" specifically
- Ask an opening question that is DIRECTLY about "{topic}"
- Stay in character as a {persona['age']}-year-old
- 2-3 sentences maximum
- Make it feel natural, not scripted

Remember: You know NOTHING about {topic}. You're genuinely curious."""
        
        try:
            response = await self.groq.generate_with_system_prompt(
                system_prompt=persona["system_prompt"],
                user_message=opening_prompt,
                temperature=0.8,
                max_tokens=200
            )
            
            greeting = response.strip()
            
        except Exception as e:
            print(f"[PERSONA_ENGINE] Error generating greeting: {e}")
            greeting = self._get_fallback_greeting(persona_id, topic)
        
        # Initialize conversation history
        self.conversations[session_id] = {
            "topic": topic,
            "persona_id": persona_id,
            "persona": persona,
            "messages": [
                {"role": "assistant", "content": greeting}
            ],
            "evaluation_notes": [],
            "message_count": 0,
            "concepts_covered": [],
            "clarity_scores": [],
            "depth_scores": [],
            "accuracy_scores": []
        }
        
        return {
            "session_id": session_id,
            "greeting": greeting,
            "persona": {
                "id": persona_id,
                "name": persona["name"],
                "age": persona["age"],
                "avatar": persona["avatar"]
            }
        }
    
    async def respond_to_teaching(
        self,
        session_id: str,
        user_message: str
    ) -> dict:
        """
        Generate persona response to user's teaching message.
        
        Args:
            session_id: Session identifier
            user_message: What the user (teacher) said
            
        Returns:
            AI response, evaluation scores, and session state
        """
        session = self.conversations.get(session_id)
        if not session:
            return {
                "error": "Session not found",
                "response": "Hmm, I think we got disconnected. Can you start over?"
            }
        
        topic = session["topic"]
        persona = session["persona"]
        persona_id = session["persona_id"]
        messages = session["messages"]
        session["message_count"] += 1
        message_count = session["message_count"]
        
        print(f"[PERSONA_ENGINE] Session {session_id} - Message #{message_count}")
        print(f"[PERSONA_ENGINE] User said: {user_message[:100]}...")
        
        # Add user message to history
        messages.append({"role": "user", "content": user_message})
        
        # Build conversation context for the AI
        conversation_context = self._build_conversation_context(session)
        
        # Determine what kind of response to generate based on conversation stage
        response_directive = self._get_response_directive(
            message_count=message_count,
            topic=topic,
            persona_id=persona_id,
            user_message=user_message
        )
        
        # Generate persona response
        try:
            response_prompt = f"""{conversation_context}

---

The teacher just said:
"{user_message}"

{response_directive}

Generate your response as {persona['name']} (age {persona['age']}).
Topic being taught: "{topic}"

Requirements:
- Respond DIRECTLY to what the teacher just said
- Ask a follow-up question about the SPECIFIC content of their explanation
- Stay in character - use vocabulary appropriate for a {persona['age']}-year-old
- Reference specific details from what the teacher said
- If the explanation was unclear, ask for clarification on the SPECIFIC unclear part
- If the explanation was good, acknowledge it and ask a deeper question
- 2-4 sentences maximum
- Do NOT explain the topic yourself - you are the STUDENT"""
            
            ai_response = await self.groq.generate_with_system_prompt(
                system_prompt=persona["system_prompt"],
                user_message=response_prompt,
                temperature=0.75,
                max_tokens=250
            )
            
            ai_response = ai_response.strip()
            
        except Exception as e:
            print(f"[PERSONA_ENGINE] Response generation error: {e}")
            ai_response = self._get_contextual_fallback(persona_id, topic, user_message, message_count)
        
        # Add AI response to history
        messages.append({"role": "assistant", "content": ai_response})
        
        # Evaluate the user's explanation quality
        evaluation = await self._evaluate_explanation(
            session=session,
            user_message=user_message,
            message_count=message_count
        )
        
        # Keep conversation history manageable (last 20 messages)
        if len(messages) > 20:
            # Keep first message (greeting) and last 18
            session["messages"] = [messages[0]] + messages[-18:]
        
        return {
            "response": ai_response,
            "aha_score": evaluation["aha_score"],
            "clarity_score": evaluation["clarity"],
            "accuracy_score": evaluation["accuracy"],
            "depth_score": evaluation["depth"],
            "feedback": evaluation.get("feedback"),
            "message_count": message_count,
            "session_id": session_id
        }
    
    async def end_session(self, session_id: str) -> dict:
        """
        End a teaching session and generate final evaluation.
        """
        session = self.conversations.get(session_id)
        if not session:
            return {"error": "Session not found"}
        
        topic = session["topic"]
        persona = session["persona"]
        message_count = session["message_count"]
        
        print(f"[PERSONA_ENGINE] Ending session {session_id}")
        print(f"[PERSONA_ENGINE] Total messages: {message_count}")
        
        # Generate final evaluation
        try:
            eval_prompt = f"""Evaluate the teaching session about "{topic}".

The teacher had {message_count} exchanges with {persona['name']} (age {persona['age']}).

Conversation history:
{self._format_history_for_eval(session)}

Provide a final evaluation as JSON:
{{
  "overall_score": <0-100>,
  "clarity_score": <0-100>,
  "accuracy_score": <0-100>,
  "depth_score": <0-100>,
  "engagement_score": <0-100>,
  "strengths": ["strength1", "strength2"],
  "improvements": ["area1", "area2"],
  "summary": "2-3 sentence summary of how well the teacher explained {topic}",
  "concepts_well_explained": ["concept1", "concept2"],
  "concepts_missing": ["concept1", "concept2"]
}}"""
            
            eval_response = await self.groq.generate_with_system_prompt(
                system_prompt="You are an expert education evaluator. Evaluate teaching quality objectively. Respond with only valid JSON.",
                user_message=eval_prompt,
                temperature=0.3,
                max_tokens=500,
                json_response=True
            )
            
            final_eval = self.groq.parse_json_response(eval_response)
            
        except Exception as e:
            print(f"[PERSONA_ENGINE] Final eval error: {e}")
            final_eval = {
                "overall_score": self._calculate_average_score(session),
                "clarity_score": self._avg(session["clarity_scores"]),
                "accuracy_score": self._avg(session["accuracy_scores"]),
                "depth_score": self._avg(session["depth_scores"]),
                "strengths": ["Completed the teaching session"],
                "improvements": ["Continue practicing with different personas"],
                "summary": f"Teaching session about {topic} completed."
            }
        
        # Clean up session
        del self.conversations[session_id]
        
        return {
            "session_id": session_id,
            "topic": topic,
            "persona": persona["name"],
            "message_count": message_count,
            "evaluation": final_eval
        }
    
    def _build_conversation_context(self, session: dict) -> str:
        """Build conversation context string for AI."""
        topic = session["topic"]
        persona = session["persona"]
        messages = session["messages"]
        
        context = f"TOPIC BEING TAUGHT: {topic}\n"
        context += f"YOU ARE: {persona['name']} (age {persona['age']})\n"
        context += f"YOU ARE THE STUDENT. THE HUMAN IS YOUR TEACHER.\n\n"
        context += "CONVERSATION SO FAR:\n"
        
        # Include last 10 messages for context
        recent = messages[-10:] if len(messages) > 10 else messages
        
        for msg in recent:
            role = "Teacher" if msg["role"] == "user" else persona["name"]
            context += f"{role}: {msg['content']}\n\n"
        
        return context
    
    def _get_response_directive(
        self,
        message_count: int,
        topic: str,
        persona_id: str,
        user_message: str
    ) -> str:
        """Get specific directive for response based on conversation stage."""
        
        if message_count <= 2:
            return f"""STAGE: Opening
The teacher is beginning their explanation of "{topic}".
Ask a foundational question about the basics they just covered.
Show genuine curiosity about the core concept."""
        
        elif message_count <= 4:
            return f"""STAGE: Building Understanding
The teacher is building on their explanation of "{topic}".
Ask for a specific EXAMPLE or ANALOGY related to what they just explained.
Show you're trying to connect it to something familiar."""
        
        elif message_count <= 6:
            return f"""STAGE: Probing Deeper
You've heard the basics about "{topic}".
Now ask a "what about..." or "but what if..." question that tests DEEPER understanding.
Challenge their explanation with a scenario or edge case specific to {topic}."""
        
        elif message_count <= 8:
            return f"""STAGE: Testing Understanding
You've learned quite a bit about "{topic}".
Try to summarize what you've learned SO FAR in your own words (get something slightly wrong).
This forces the teacher to correct you and proves their depth of knowledge."""
        
        else:
            return f"""STAGE: Advanced Questions
You now have a basic understanding of "{topic}".
Ask about advanced aspects, real-world applications, or common mistakes.
{"Ask: 'So how is this actually used in real life?' or 'What do people get wrong about this?'" if persona_id != "alex" else "Ask about performance trade-offs, alternative approaches, or best practices."}"""
    
    async def _evaluate_explanation(
        self,
        session: dict,
        user_message: str,
        message_count: int
    ) -> dict:
        """Evaluate the quality of the user's explanation."""
        
        topic = session["topic"]
        
        # For efficiency, do AI evaluation every 2 messages
        if message_count % 2 == 0 or message_count <= 2:
            try:
                eval_prompt = f"""Evaluate this teaching explanation about "{topic}":

"{user_message}"

Context: Message #{message_count} in the conversation.

Rate on a scale of 0-100:
- clarity: How clear and understandable is the explanation?
- accuracy: How factually correct is the explanation? (If you can't verify, give 70)
- depth: How deep does the explanation go?

Respond with ONLY JSON:
{{"clarity": <score>, "accuracy": <score>, "depth": <score>, "feedback": "one sentence feedback"}}"""
                
                eval_response = await self.groq.generate_with_system_prompt(
                    system_prompt="You are an education quality evaluator. Be fair but rigorous. Respond with only valid JSON.",
                    user_message=eval_prompt,
                    temperature=0.2,
                    max_tokens=100,
                    json_response=True
                )
                
                scores = self.groq.parse_json_response(eval_response)
                
                clarity = min(100, max(0, scores.get("clarity", 60)))
                accuracy = min(100, max(0, scores.get("accuracy", 60)))
                depth = min(100, max(0, scores.get("depth", 50)))
                feedback = scores.get("feedback")
                
            except Exception as e:
                print(f"[PERSONA_ENGINE] Evaluation error: {e}")
                # Heuristic-based evaluation as fallback
                clarity, accuracy, depth, feedback = self._heuristic_evaluate(user_message)
        else:
            # Use heuristic for odd messages to save API calls
            clarity, accuracy, depth, feedback = self._heuristic_evaluate(user_message)
        
        # Store scores
        session["clarity_scores"].append(clarity)
        session["accuracy_scores"].append(accuracy)
        session["depth_scores"].append(depth)
        
        # Calculate running Aha! score (weighted average of all evaluations)
        aha_score = int(
            self._avg(session["clarity_scores"]) * 0.35 +
            self._avg(session["accuracy_scores"]) * 0.35 +
            self._avg(session["depth_scores"]) * 0.30
        )
        
        return {
            "clarity": clarity,
            "accuracy": accuracy,
            "depth": depth,
            "aha_score": aha_score,
            "feedback": feedback
        }
    
    def _heuristic_evaluate(self, message: str) -> tuple:
        """Quick heuristic evaluation without AI."""
        words = message.split()
        word_count = len(words)
        
        # Clarity: Based on sentence structure
        clarity = 50
        if word_count > 20:
            clarity += 15
        if word_count > 50:
            clarity += 10
        if any(w in message.lower() for w in ["for example", "like", "such as", "imagine"]):
            clarity += 10
        if "?" in message:
            clarity -= 5  # Teacher shouldn't be asking many questions
        
        # Accuracy: Can't really verify without AI, so moderate score
        accuracy = 65
        if word_count > 30:
            accuracy += 5
        
        # Depth: Based on explanation length and detail indicators
        depth = 45
        if word_count > 30:
            depth += 10
        if word_count > 60:
            depth += 10
        if any(w in message.lower() for w in ["because", "reason", "therefore", "this means", "in other words"]):
            depth += 10
        if any(w in message.lower() for w in ["however", "but", "although", "except"]):
            depth += 5  # Shows nuanced understanding
        
        return (
            min(100, clarity),
            min(100, accuracy),
            min(100, depth),
            None  # No specific feedback
        )
    
    def _get_fallback_greeting(self, persona_id: str, topic: str) -> str:
        """Generate fallback greeting if AI fails."""
        greetings = {
            "maya": f"Hi! I'm Maya! 👋 I really want to learn about {topic}! Can you tell me what it is? I bet it's something cool! ✨",
            "jake": f"Hey. So you're gonna teach me about {topic}? Alright, I'm listening. Start from the beginning. 🤔",
            "sarah": f"Hello! I'm so glad someone can help me understand {topic}. I've been struggling with technical topics. Where do we start? 😊",
            "alex": f"Hey, I've been wanting to understand {topic} better. I know some basics but want to go deeper. Can you break it down for me? 💡"
        }
        
        return greetings.get(persona_id, greetings["maya"])
    
    def _get_contextual_fallback(
        self,
        persona_id: str,
        topic: str,
        user_message: str,
        message_count: int
    ) -> str:
        """Generate contextual fallback if AI fails mid-conversation."""
        # Extract a keyword from the user's message for minimal context
        words = user_message.split()
        key_words = [w for w in words if len(w) > 4 and w.lower() not in {
            "about", "which", "their", "there", "these", "those", "would",
            "could", "should", "because", "really", "actually"
        }]
        keyword = key_words[0] if key_words else topic
        
        persona = PERSONA_DEFINITIONS.get(persona_id, PERSONA_DEFINITIONS["maya"])
        age = persona["age"]
        
        if age <= 10:
            responses = [
                f"That's interesting! But what does '{keyword}' actually mean? Can you explain it simpler? 🤔",
                f"Ooh! So when you say '{keyword}', is that like something I can see or touch? Give me an example! ✨",
                f"Wait, I'm confused about the '{keyword}' part. Can you explain it like I'm really little? 😅",
            ]
        elif age <= 18:
            responses = [
                f"Hmm okay, but you mentioned '{keyword}' - how does that actually work in practice?",
                f"I get the idea, but what happens if '{keyword}' doesn't work as expected? Any edge cases?",
                f"That's one way to look at it. But is '{keyword}' always the best approach? Why?",
            ]
        elif age <= 30:
            responses = [
                f"I think I'm starting to understand '{keyword}', but could you walk me through a real example?",
                f"So when you mention '{keyword}', how would I actually use that in a real project?",
                f"That helps! But I'm still a bit fuzzy on '{keyword}'. What's the most common mistake people make?",
            ]
        else:
            responses = [
                f"I see what you mean about '{keyword}'. Could you give me a practical example I'd encounter at work?",
                f"That makes sense! But what about '{keyword}' - how does that relate to what we discussed earlier?",
                f"Thank you for explaining! I want to make sure I got '{keyword}' right. Can you verify my understanding?",
            ]
        
        return responses[message_count % len(responses)]
    
    def _format_history_for_eval(self, session: dict) -> str:
        """Format conversation history for final evaluation."""
        lines = []
        persona_name = session["persona"]["name"]
        
        for msg in session["messages"][-12:]:
            role = "Teacher" if msg["role"] == "user" else persona_name
            lines.append(f"{role}: {msg['content']}")
        
        return "\n".join(lines)
    
    def _calculate_average_score(self, session: dict) -> int:
        """Calculate average Aha! score from session."""
        clarity = self._avg(session["clarity_scores"])
        accuracy = self._avg(session["accuracy_scores"])
        depth = self._avg(session["depth_scores"])
        
        return int(clarity * 0.35 + accuracy * 0.35 + depth * 0.30)
    
    def _avg(self, scores: list) -> float:
        """Calculate average of a list of scores."""
        if not scores:
            return 50.0
        return sum(scores) / len(scores)

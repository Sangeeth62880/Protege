"""
RAG Service — orchestrates retrieval-augmented generation for document Q&A.
Combines embedding search with LLM generation for grounded answers.
"""
import re
import logging
from typing import List, Dict, Optional

from app.services.embedding_service import EmbeddingService
from app.services.vector_store_service import VectorStoreService
from app.services.groq_service import GroqService
from app.models.document_models import (
    DocumentChatResponse,
    SourceReference,
)
from app.prompts.document_prompts import (
    DOCUMENT_QA_SYSTEM_PROMPT,
    DOCUMENT_QA_USER_TEMPLATE,
    DOCUMENT_EXPLAIN_PROMPT,
)

logger = logging.getLogger(__name__)


class RAGService:
    """Service for RAG-powered document Q&A and explanations."""

    def __init__(
        self,
        embedding_service: EmbeddingService,
        vector_store_service: VectorStoreService,
        groq_service: GroqService,
    ):
        self._embedder = embedding_service
        self._store = vector_store_service
        self._groq = groq_service

    async def query_document(
        self,
        document_id: str,
        user_query: str,
        conversation_history: Optional[List[Dict[str, str]]] = None,
    ) -> DocumentChatResponse:
        """
        Answer a question about a document using RAG.
        1. Embed query → 2. Retrieve chunks → 3. Build prompt → 4. Generate answer
        """
        # Step 1: Embed the user's query
        query_embedding = self._embedder.embed_query(user_query)

        # Step 2: Retrieve top-5 relevant chunks
        collection_name = self._store._collection_name(document_id)
        retrieved = self._store.query(collection_name, query_embedding, top_k=5)

        if not retrieved:
            return DocumentChatResponse(
                answer="I couldn't find any relevant content in your document for this question. "
                       "Please try rephrasing or ask about a different topic from the document.",
                sources=[],
                follow_up_questions=["What topics does this document cover?"],
            )

        # Step 3: Build context from retrieved chunks
        context_parts = []
        sources: List[SourceReference] = []
        for chunk in retrieved:
            page = chunk.metadata.get("page_number", 0)
            heading = chunk.metadata.get("section_heading", "")
            section_label = f", Section: {heading}" if heading else ""

            context_parts.append(f"[Page {page}{section_label}]: {chunk.text}")

            sources.append(SourceReference(
                page=page,
                section=heading if heading else None,
                relevance_score=chunk.relevance_score,
                text_snippet=chunk.text[:150] + "..." if len(chunk.text) > 150 else chunk.text,
            ))

        context = "\n\n".join(context_parts)

        # Format conversation history
        history_str = "No previous conversation."
        if conversation_history:
            history_parts = []
            for msg in conversation_history[-6:]:  # Last 6 messages
                role = msg.get("role", "user")
                content = msg.get("content", "")
                history_parts.append(f"{role.capitalize()}: {content[:200]}")
            history_str = "\n".join(history_parts)

        # Step 4: Build the RAG prompt
        user_message = DOCUMENT_QA_USER_TEMPLATE.format(
            context=context,
            conversation_history=history_str,
            user_query=user_query,
        )

        # Check if relevance is low
        all_low = all(c.relevance_score < 0.3 for c in retrieved)
        disclaimer = ""
        if all_low:
            disclaimer = (
                "⚠️ I couldn't find highly relevant content in your document for this question. "
                "Here's my best attempt based on available content:\n\n"
            )

        # Step 5: Generate answer
        response = await self._groq.chat_completion(
            messages=[
                {"role": "system", "content": DOCUMENT_QA_SYSTEM_PROMPT},
                {"role": "user", "content": user_message},
            ],
            temperature=0.4,
            max_tokens=2048,
        )

        # Step 6: Extract follow-up questions
        follow_ups = self._extract_follow_ups(response)

        # Clean the answer (remove the follow-up section from main answer)
        answer = self._clean_answer(response)

        return DocumentChatResponse(
            answer=disclaimer + answer,
            sources=sources,
            follow_up_questions=follow_ups,
        )

    async def explain_section(
        self,
        document_id: str,
        section_text: str,
        simplify_level: str = "intermediate",
    ) -> str:
        """Explain a section of a document at the specified difficulty level."""
        # Get related chunks for additional context
        query_embedding = self._embedder.embed_query(section_text[:500])
        collection_name = self._store._collection_name(document_id)
        related = self._store.query(collection_name, query_embedding, top_k=3)

        related_context = "\n".join(
            f"[Page {c.metadata.get('page_number', '?')}]: {c.text}"
            for c in related
        ) if related else "No additional context available."

        prompt = DOCUMENT_EXPLAIN_PROMPT.format(
            simplify_level=simplify_level,
            section_text=section_text,
            related_context=related_context,
        )

        response = await self._groq.generate_with_system_prompt(
            system_prompt="You are an expert tutor. Explain clearly and thoroughly.",
            user_message=prompt,
            temperature=0.5,
            max_tokens=1500,
        )

        return response

    def _extract_follow_ups(self, response: str) -> List[str]:
        """Extract follow-up questions from the LLM response."""
        follow_ups = []

        # Look for numbered list after "Suggested questions" or "Follow-up"
        pattern = r"(?:Suggested questions|Follow.up questions?).*?\n\s*1\.\s*(.*?)\n\s*2\.\s*(.*?)\n\s*3\.\s*(.*?)(?:\n|$)"
        match = re.search(pattern, response, re.IGNORECASE | re.DOTALL)

        if match:
            for i in range(1, 4):
                q = match.group(i).strip()
                if q:
                    follow_ups.append(q)

        if not follow_ups:
            # Fallback: find any numbered list at the end
            lines = response.strip().split("\n")
            for line in reversed(lines[-6:]):
                line = line.strip()
                m = re.match(r'^\d+\.\s+(.+)', line)
                if m:
                    follow_ups.insert(0, m.group(1).strip())

        return follow_ups[:3]

    def _clean_answer(self, response: str) -> str:
        """Remove the follow-up questions section from the main answer."""
        # Remove "Suggested questions:" section and everything after
        patterns = [
            r"\*\*Suggested questions:\*\*.*$",
            r"Suggested questions:.*$",
            r"\*\*Follow.up questions?:\*\*.*$",
            r"Follow.up questions?:.*$",
        ]
        answer = response
        for pattern in patterns:
            answer = re.sub(pattern, "", answer, flags=re.IGNORECASE | re.DOTALL)

        return answer.strip()

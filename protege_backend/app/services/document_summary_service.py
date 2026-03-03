"""
Document Summary Service — generates AI summaries and extracts key topics.
Uses single-pass for short documents, map-reduce for long ones.
Includes timeout handling and graceful fallback.
"""
import json
import re
import time
import logging
import asyncio
from typing import List

from app.services.groq_service import GroqService
from app.models.document_models import SummaryResult
from app.prompts.document_prompts import DOCUMENT_SUMMARY_PROMPT

logger = logging.getLogger(__name__)

# Maximum time to wait for a single Groq API call (seconds)
GROQ_TIMEOUT = 15


class DocumentSummaryService:
    """Service for generating document summaries and extracting key topics."""

    def __init__(self, groq_service: GroqService):
        self._groq = groq_service

    async def summarize_document(
        self, full_text: str, file_name: str
    ) -> SummaryResult:
        """
        Generate a summary and extract key topics.
        Uses single-pass for short docs (<12000 chars), map-reduce for long ones.
        """
        word_count = len(full_text.split())

        try:
            if len(full_text) <= 12000:
                return await asyncio.wait_for(
                    self._single_pass(full_text, file_name, word_count),
                    timeout=GROQ_TIMEOUT,
                )
            else:
                return await asyncio.wait_for(
                    self._map_reduce(full_text, file_name, word_count),
                    timeout=GROQ_TIMEOUT * 3,  # More time for multi-section docs
                )
        except asyncio.TimeoutError:
            logger.warning(f"Summary generation timed out for {file_name}")
            return self._fallback_summary(full_text, file_name, word_count)
        except Exception as e:
            logger.error(f"Summary generation failed for {file_name}: {e}")
            return self._fallback_summary(full_text, file_name, word_count)

    def _fallback_summary(self, text: str, file_name: str, word_count: int) -> SummaryResult:
        """Provide a basic fallback summary when LLM generation fails."""
        # Extract first ~200 words as a rudimentary summary
        words = text.split()
        preview = " ".join(words[:200])
        if len(words) > 200:
            preview += "..."

        summary = (
            f"**{file_name}** — This document contains approximately {word_count} words. "
            f"AI summary generation is temporarily unavailable. "
            f"You can still chat with this document to ask specific questions.\n\n"
            f"**Preview:** {preview}"
        )

        # Try to extract basic topics from the text
        key_topics = self._extract_basic_topics(text)

        return SummaryResult(
            summary=summary,
            key_topics=key_topics if key_topics else ["General Content"],
            word_count=word_count,
        )

    def _extract_basic_topics(self, text: str) -> List[str]:
        """Simple keyword extraction as fallback for topic detection."""
        # Find capitalized multi-word phrases (likely headings/topics)
        headings = re.findall(r'^([A-Z][A-Za-z\s]{3,50})$', text, re.MULTILINE)
        topics = list(dict.fromkeys(h.strip() for h in headings))[:8]
        return topics

    async def _single_pass(
        self, text: str, file_name: str, word_count: int
    ) -> SummaryResult:
        """Summarize a short document in one LLM call."""
        prompt = DOCUMENT_SUMMARY_PROMPT.format(
            file_name=file_name,
            document_text=text[:12000],
        )

        response = await self._groq.generate_with_system_prompt(
            system_prompt="You are a document analysis assistant. Follow the format exactly.",
            user_message=prompt,
            temperature=0.3,
            max_tokens=2048,
        )

        return self._parse_summary_response(response, word_count)

    async def _map_reduce(
        self, text: str, file_name: str, word_count: int
    ) -> SummaryResult:
        """Summarize a long document using map-reduce strategy."""
        # Map phase: split into sections and summarize each
        section_size = 10000
        overlap = 500
        sections = []
        i = 0
        while i < len(text):
            end = min(i + section_size, len(text))
            sections.append(text[i:end])
            i += section_size - overlap

        logger.info(f"Map-reduce: {len(sections)} sections")

        # Summarize each section in parallel
        map_prompt = (
            "Summarize the following section of a document in 100-150 words. "
            "Highlight the key points and main ideas:\n\n{text}"
        )
        tasks = []
        for section in sections:
            tasks.append(
                self._groq.generate_with_system_prompt(
                    system_prompt="You are a concise summarizer.",
                    user_message=map_prompt.format(text=section[:10000]),
                    temperature=0.3,
                    max_tokens=512,
                )
            )

        section_summaries = await asyncio.gather(*tasks, return_exceptions=True)
        valid_summaries = [s for s in section_summaries if isinstance(s, str)]

        # Reduce phase: combine section summaries
        combined = "\n\n---\n\n".join(valid_summaries)
        reduce_prompt = DOCUMENT_SUMMARY_PROMPT.format(
            file_name=file_name,
            document_text=combined,
        )

        response = await self._groq.generate_with_system_prompt(
            system_prompt="You are a document analysis assistant. Follow the format exactly.",
            user_message=reduce_prompt,
            temperature=0.3,
            max_tokens=2048,
        )

        return self._parse_summary_response(response, word_count)

    def _parse_summary_response(self, response: str, word_count: int) -> SummaryResult:
        """Parse the LLM response into summary + key topics."""
        summary = response
        key_topics: List[str] = []

        # Try to extract summary section
        summary_match = re.search(
            r"##\s*Summary\s*\n(.*?)(?=##\s*Key Topics|```json|$)",
            response,
            re.DOTALL,
        )
        if summary_match:
            summary = summary_match.group(1).strip()

        # Try to extract key topics JSON
        json_match = re.search(r"```json\s*\n(.*?)\n\s*```", response, re.DOTALL)
        if json_match:
            try:
                topics = json.loads(json_match.group(1))
                if isinstance(topics, list):
                    key_topics = [str(t) for t in topics[:10]]
            except json.JSONDecodeError:
                logger.warning("Failed to parse key topics JSON")

        # Fallback: if no topics extracted, try to find any JSON array
        if not key_topics:
            array_match = re.search(r'\[(["\'].*?["\'](?:\s*,\s*["\'].*?["\'])*)\]', response)
            if array_match:
                try:
                    key_topics = json.loads(f"[{array_match.group(1)}]")
                except json.JSONDecodeError:
                    pass

        # Default topics if none found
        if not key_topics:
            key_topics = ["General Content"]

        return SummaryResult(
            summary=summary,
            key_topics=key_topics,
            word_count=word_count,
        )

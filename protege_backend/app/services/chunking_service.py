"""
Chunking Service — splits extracted document text into chunks for embedding.
Uses LangChain RecursiveCharacterTextSplitter.
"""
import re
import logging
from typing import List

from langchain_text_splitters import RecursiveCharacterTextSplitter

from app.models.document_models import PageContent, DocumentChunk

logger = logging.getLogger(__name__)


class ChunkingService:
    """Service for splitting document text into chunks for vector storage."""

    def __init__(
        self,
        chunk_size: int = 512,
        chunk_overlap: int = 50,
    ):
        self._splitter = RecursiveCharacterTextSplitter(
            chunk_size=chunk_size,
            chunk_overlap=chunk_overlap,
            separators=["\n\n", "\n", ". ", " "],
            length_function=len,
        )

    def _detect_heading(self, text: str) -> str:
        """Try to detect a section heading from text."""
        lines = text.strip().split("\n")
        if not lines:
            return ""
        first_line = lines[0].strip()
        # Heuristic: ALL CAPS line or short line (<80 chars) followed by newline
        if first_line.isupper() and len(first_line) < 100:
            return first_line
        if len(first_line) < 80 and len(lines) > 1 and first_line:
            # Check if it looks like a heading (no period at end, not very long)
            if not first_line.endswith(".") and not first_line.endswith(","):
                return first_line
        return ""

    def chunk_document(self, pages: List[PageContent]) -> List[DocumentChunk]:
        """
        Split pages into chunks, preserving page number metadata.
        Returns a flat list of chunks with globally unique chunk_index.
        """
        all_chunks: List[DocumentChunk] = []
        global_index = 0

        for page in pages:
            if not page.text or not page.text.strip():
                continue

            # Split this page's text
            text_chunks = self._splitter.split_text(page.text)

            for chunk_text in text_chunks:
                heading = self._detect_heading(chunk_text)

                all_chunks.append(DocumentChunk(
                    text=chunk_text,
                    metadata={
                        "page_number": page.page_number,
                        "chunk_index": global_index,
                        "section_heading": heading,
                    }
                ))
                global_index += 1

        logger.info(f"Document chunked into {len(all_chunks)} chunks from {len(pages)} pages")
        return all_chunks

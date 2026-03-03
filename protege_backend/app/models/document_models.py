"""
Pydantic models for the RAG Document Intelligence feature.
"""
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime
from enum import Enum


# ============ Internal Processing Models ============

class PageContent(BaseModel):
    """Content extracted from a single page."""
    page_number: int
    text: str
    has_tables: bool = False
    tables_markdown: Optional[str] = None


class ExtractionResult(BaseModel):
    """Result of document text extraction."""
    full_text: str
    pages: List[PageContent]
    page_count: int
    has_tables: bool = False
    extraction_method: str  # "text", "ocr", "mixed"
    word_count: int = 0


class DocumentChunk(BaseModel):
    """A single chunk of document text with metadata."""
    text: str
    metadata: Dict[str, Any] = Field(default_factory=dict)
    # metadata keys: page_number, chunk_index, section_heading


class RetrievedChunk(BaseModel):
    """A chunk retrieved from vector search with relevance score."""
    text: str
    metadata: Dict[str, Any]
    relevance_score: float


class SummaryResult(BaseModel):
    """Result of document summarization."""
    summary: str
    key_topics: List[str]
    word_count: int


# ============ API Request/Response Models ============

class DocumentStatus(str, Enum):
    PROCESSING = "processing"
    READY = "ready"
    FAILED = "failed"


class DocumentUploadResponse(BaseModel):
    """Response after uploading a document."""
    id: str
    file_name: str
    status: str
    message: str


class DocumentMetadata(BaseModel):
    """Full document metadata stored in Firestore."""
    id: str
    user_id: str
    file_name: str
    file_type: str  # "pdf", "png", "jpg", "jpeg"
    file_size: int  # bytes
    page_count: int = 0
    status: str = "processing"
    summary: Optional[str] = None
    key_topics: List[str] = Field(default_factory=list)
    chunk_count: int = 0
    extracted_text_preview: Optional[str] = None
    chroma_collection_id: Optional[str] = None
    linked_path_id: Optional[str] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    processing_error: Optional[str] = None
    word_count: int = 0

    class Config:
        from_attributes = True


class SourceReference(BaseModel):
    """A source reference for a RAG answer."""
    page: int
    section: Optional[str] = None
    relevance_score: float
    text_snippet: str


class DocumentChatRequest(BaseModel):
    """Request body for document chat."""
    query: str
    conversation_history: Optional[List[Dict[str, str]]] = None


class DocumentChatResponse(BaseModel):
    """Response from document chat."""
    answer: str
    sources: List[SourceReference] = Field(default_factory=list)
    follow_up_questions: List[str] = Field(default_factory=list)


class DocumentExplainRequest(BaseModel):
    """Request body for explaining a section."""
    section: str
    simplify_level: str = "intermediate"  # beginner, intermediate, advanced


class DocumentSummaryResponse(BaseModel):
    """Response for document summary."""
    summary: str
    key_topics: List[str]
    page_count: int
    word_count: int


class LinkPathRequest(BaseModel):
    """Request body for linking document to a learning path."""
    path_id: str

"""
API routes for the RAG Document Intelligence feature.
Handles document upload, processing, chat Q&A, summarization, and deletion.
"""
import os
import time
import uuid
import logging
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, UploadFile, File, Form, HTTPException, BackgroundTasks, Request

from app.models.document_models import (
    DocumentUploadResponse,
    DocumentMetadata,
    DocumentChatRequest,
    DocumentChatResponse,
    DocumentExplainRequest,
    DocumentSummaryResponse,
    LinkPathRequest,
)

logger = logging.getLogger(__name__)

router = APIRouter()

ALLOWED_EXTENSIONS = {".pdf", ".png", ".jpg", ".jpeg"}
MAX_FILE_SIZE = 20 * 1024 * 1024  # 20MB
UPLOAD_DIR = "./uploads"


def _ensure_upload_dir():
    os.makedirs(UPLOAD_DIR, exist_ok=True)


async def _update_status(firebase_service, document_id: str, status: str, extra: dict = None):
    """Update document status in Firestore for real-time Flutter streaming."""
    data = {
        "status": status,
        "updated_at": datetime.utcnow().isoformat(),
    }
    if extra:
        data.update(extra)
    try:
        await firebase_service.update_document("documents", document_id, data)
    except Exception as e:
        logger.warning(f"Failed to update status to '{status}': {e}")


async def _process_document(
    document_id: str,
    file_path: str,
    file_type: str,
    file_name: str,
    firebase_service,
    extraction_service,
    chunking_service,
    embedding_service,
    vector_store_service,
    summary_service,
):
    """Background task: extract → chunk → embed → store → summarize.
    Includes timing instrumentation and progressive Firestore status updates."""
    pipeline_start = time.time()

    try:
        # ── Step 1: Extract text ──────────────────────────────────────────
        await _update_status(firebase_service, document_id, "extracting")
        t0 = time.time()

        if file_type == "pdf":
            extraction = await extraction_service.extract_from_pdf(file_path)
        else:
            extraction = await extraction_service.extract_from_image(file_path)

        t1 = time.time()
        print(f"[TIMING] Step 1 - Text extraction ({extraction.extraction_method}): {t1 - t0:.2f}s  "
              f"({extraction.page_count} pages, {extraction.word_count} words)")

        # ── Step 2: Chunk ─────────────────────────────────────────────────
        await _update_status(firebase_service, document_id, "chunking")
        t0 = time.time()

        chunks = chunking_service.chunk_document(extraction.pages)

        t1 = time.time()
        print(f"[TIMING] Step 2 - Chunking: {t1 - t0:.2f}s  ({len(chunks)} chunks)")

        # ── Step 3: Embed ─────────────────────────────────────────────────
        await _update_status(firebase_service, document_id, "embedding")
        t0 = time.time()

        texts = [c.text for c in chunks]
        embeddings = embedding_service.embed_texts(texts)

        t1 = time.time()
        print(f"[TIMING] Step 3 - Embedding generation: {t1 - t0:.2f}s  ({len(texts)} texts)")

        # ── Step 4: Store in vector DB ────────────────────────────────────
        await _update_status(firebase_service, document_id, "storing")
        t0 = time.time()

        collection_name = vector_store_service.create_collection(document_id)
        vector_store_service.add_chunks(collection_name, chunks, embeddings)

        t1 = time.time()
        print(f"[TIMING] Step 4 - ChromaDB upsert: {t1 - t0:.2f}s")

        # ── Step 5: Summarize ─────────────────────────────────────────────
        await _update_status(firebase_service, document_id, "summarizing")
        t0 = time.time()

        summary_result = await summary_service.summarize_document(
            extraction.full_text, file_name
        )

        t1 = time.time()
        print(f"[TIMING] Step 5 - Summary generation (Groq): {t1 - t0:.2f}s")

        # ── Step 6: Update Firestore with final results ───────────────────
        t0 = time.time()

        preview = extraction.full_text[:500] + "..." if len(extraction.full_text) > 500 else extraction.full_text

        await firebase_service.update_document("documents", document_id, {
            "status": "ready",
            "page_count": extraction.page_count,
            "word_count": extraction.word_count,
            "chunk_count": len(chunks),
            "summary": summary_result.summary,
            "key_topics": summary_result.key_topics,
            "extracted_text_preview": preview,
            "chroma_collection_id": collection_name,
            "updated_at": datetime.utcnow().isoformat(),
        })

        t1 = time.time()
        print(f"[TIMING] Step 6 - Firestore final update: {t1 - t0:.2f}s")

        total = time.time() - pipeline_start
        print(f"[TIMING] ═══════════════════════════════════════════════")
        print(f"[TIMING] TOTAL PIPELINE: {total:.2f}s  ({file_name})")
        print(f"[TIMING] ═══════════════════════════════════════════════")

        logger.info(f"Document {document_id} processed in {total:.1f}s: {len(chunks)} chunks")

    except Exception as e:
        total = time.time() - pipeline_start
        logger.error(f"Document processing failed for {document_id} after {total:.1f}s: {e}")
        print(f"[TIMING] PIPELINE FAILED after {total:.2f}s: {e}")
        await firebase_service.update_document("documents", document_id, {
            "status": "failed",
            "processing_error": str(e),
            "updated_at": datetime.utcnow().isoformat(),
        })

    finally:
        # Clean up temp file
        try:
            if os.path.exists(file_path):
                os.remove(file_path)
        except Exception:
            pass


@router.post("/upload", response_model=DocumentUploadResponse)
async def upload_document(
    request: Request,
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    userId: str = Form(...),
):
    """Upload a PDF or image for RAG processing."""
    upload_start = time.time()

    # Validate file type
    _, ext = os.path.splitext(file.filename or "")
    ext = ext.lower()
    if ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=415,
            detail=f"Unsupported file type '{ext}'. Allowed: {', '.join(ALLOWED_EXTENSIONS)}",
        )

    # Read file and validate size
    content = await file.read()
    if len(content) > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=413,
            detail=f"File too large. Max size is {MAX_FILE_SIZE // (1024*1024)}MB.",
        )

    # Save to temp location
    _ensure_upload_dir()
    document_id = str(uuid.uuid4())
    file_path = os.path.join(UPLOAD_DIR, f"{document_id}{ext}")
    with open(file_path, "wb") as f:
        f.write(content)

    file_type = ext.lstrip(".")
    if file_type in ("jpg", "jpeg", "png"):
        file_type_category = file_type
    else:
        file_type_category = "pdf"

    # Create Firestore document with "processing" status
    doc_data = {
        "id": document_id,
        "user_id": userId,
        "file_name": file.filename,
        "file_type": file_type_category,
        "file_size": len(content),
        "page_count": 0,
        "status": "processing",
        "summary": None,
        "key_topics": [],
        "chunk_count": 0,
        "extracted_text_preview": None,
        "chroma_collection_id": None,
        "linked_path_id": None,
        "created_at": datetime.utcnow().isoformat(),
        "updated_at": datetime.utcnow().isoformat(),
        "processing_error": None,
        "word_count": 0,
    }

    firebase_service = request.app.state.firebase_service
    await firebase_service.create_document("documents", document_id, doc_data)

    upload_time = time.time() - upload_start
    print(f"[TIMING] Upload endpoint (save + Firestore create): {upload_time:.2f}s")

    # Start background processing
    background_tasks.add_task(
        _process_document,
        document_id=document_id,
        file_path=file_path,
        file_type=file_type_category,
        file_name=file.filename or "document",
        firebase_service=firebase_service,
        extraction_service=request.app.state.document_extraction_service,
        chunking_service=request.app.state.chunking_service,
        embedding_service=request.app.state.embedding_service,
        vector_store_service=request.app.state.vector_store_service,
        summary_service=request.app.state.document_summary_service,
    )

    return DocumentUploadResponse(
        id=document_id,
        file_name=file.filename or "document",
        status="processing",
        message="Document uploaded. Processing will complete shortly.",
    )


@router.get("/", response_model=list)
async def list_documents(request: Request, userId: str):
    """List all documents for a user."""
    firebase_service = request.app.state.firebase_service
    docs = await firebase_service.query_collection(
        "documents", "user_id", "==", userId, limit=50
    )
    return docs


@router.get("/{document_id}")
async def get_document(request: Request, document_id: str):
    """Get a single document's metadata."""
    firebase_service = request.app.state.firebase_service
    doc = await firebase_service.get_document("documents", document_id)
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")
    return doc


@router.post("/{document_id}/chat", response_model=DocumentChatResponse)
async def chat_with_document(
    request: Request,
    document_id: str,
    body: DocumentChatRequest,
):
    """RAG-powered Q&A chat with a document."""
    firebase_service = request.app.state.firebase_service

    # Check document exists and is ready
    doc = await firebase_service.get_document("documents", document_id)
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")
    if doc.get("status") != "ready":
        raise HTTPException(status_code=400, detail="Document is not ready for chat yet")

    rag_service = request.app.state.rag_service

    try:
        response = await rag_service.query_document(
            document_id=document_id,
            user_query=body.query,
            conversation_history=body.conversation_history,
        )
        return response
    except Exception as e:
        logger.error(f"Chat failed for document {document_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to process your question. Please try again.")


@router.post("/{document_id}/summarize", response_model=DocumentSummaryResponse)
async def regenerate_summary(request: Request, document_id: str):
    """Regenerate the summary for a document."""
    firebase_service = request.app.state.firebase_service

    doc = await firebase_service.get_document("documents", document_id)
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")

    extracted_text = doc.get("extracted_text_preview", "")
    if not extracted_text:
        raise HTTPException(status_code=400, detail="No extracted text available")

    summary_service = request.app.state.document_summary_service
    result = await summary_service.summarize_document(extracted_text, doc.get("file_name", "document"))

    # Update Firestore
    await firebase_service.update_document("documents", document_id, {
        "summary": result.summary,
        "key_topics": result.key_topics,
        "updated_at": datetime.utcnow().isoformat(),
    })

    return DocumentSummaryResponse(
        summary=result.summary,
        key_topics=result.key_topics,
        page_count=doc.get("page_count", 0),
        word_count=doc.get("word_count", 0),
    )


@router.post("/{document_id}/explain")
async def explain_section(
    request: Request,
    document_id: str,
    body: DocumentExplainRequest,
):
    """Explain a section of a document at a given difficulty level."""
    firebase_service = request.app.state.firebase_service

    doc = await firebase_service.get_document("documents", document_id)
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")
    if doc.get("status") != "ready":
        raise HTTPException(status_code=400, detail="Document is not ready")

    rag_service = request.app.state.rag_service
    explanation = await rag_service.explain_section(
        document_id=document_id,
        section_text=body.section,
        simplify_level=body.simplify_level,
    )

    return {"explanation": explanation}


@router.post("/{document_id}/link-path")
async def link_to_path(
    request: Request,
    document_id: str,
    body: LinkPathRequest,
):
    """Link a document to an existing learning path."""
    firebase_service = request.app.state.firebase_service

    doc = await firebase_service.get_document("documents", document_id)
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")

    path = await firebase_service.get_document("learning_paths", body.path_id)
    if not path:
        raise HTTPException(status_code=404, detail="Learning path not found")

    await firebase_service.update_document("documents", document_id, {
        "linked_path_id": body.path_id,
        "updated_at": datetime.utcnow().isoformat(),
    })

    return {"message": "Document linked to learning path", "path_id": body.path_id}


@router.delete("/{document_id}")
async def delete_document(request: Request, document_id: str):
    """Delete a document and its vector data."""
    firebase_service = request.app.state.firebase_service

    doc = await firebase_service.get_document("documents", document_id)
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")

    # Delete ChromaDB collection
    try:
        vector_store_service = request.app.state.vector_store_service
        vector_store_service.delete_collection(document_id)
    except Exception as e:
        logger.warning(f"Failed to delete vector collection: {e}")

    # Delete Firestore document
    try:
        firebase_service.db.collection("documents").document(document_id).delete()
    except Exception as e:
        logger.error(f"Failed to delete Firestore document: {e}")
        raise HTTPException(status_code=500, detail="Failed to delete document")

    return {"message": "Document deleted", "id": document_id}

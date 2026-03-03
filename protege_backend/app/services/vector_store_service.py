"""
Vector Store Service — manages ChromaDB collections for document embeddings.
Uses persistent storage so data survives server restarts.
"""
import logging
from typing import List, Optional

import chromadb

from app.models.document_models import DocumentChunk, RetrievedChunk

logger = logging.getLogger(__name__)


class VectorStoreService:
    """Service for storing and querying document embeddings in ChromaDB."""

    def __init__(self, persist_dir: str = "./chroma_data"):
        logger.info(f"Initializing ChromaDB at: {persist_dir}")
        self._client = chromadb.PersistentClient(path=persist_dir)

    def _collection_name(self, document_id: str) -> str:
        """Generate collection name from document ID."""
        # ChromaDB collection names must be 3-63 chars, alphanumeric + underscores
        safe_id = document_id.replace("-", "_")[:50]
        return f"doc_{safe_id}"

    def create_collection(self, document_id: str) -> str:
        """
        Create (or recreate) a collection for a document.
        Returns the collection name.
        """
        name = self._collection_name(document_id)
        try:
            # Delete if exists (for re-processing)
            self._client.delete_collection(name)
        except Exception:
            pass  # Collection didn't exist

        self._client.create_collection(name=name, metadata={"hnsw:space": "cosine"})
        logger.info(f"Created ChromaDB collection: {name}")
        return name

    def add_chunks(
        self,
        collection_name: str,
        chunks: List[DocumentChunk],
        embeddings: List[List[float]],
    ) -> None:
        """Add document chunks with embeddings to a ChromaDB collection."""
        if not chunks:
            return

        collection = self._client.get_collection(collection_name)

        ids = [f"chunk_{i}" for i in range(len(chunks))]
        documents = [chunk.text for chunk in chunks]
        metadatas = [chunk.metadata for chunk in chunks]

        # Upsert in batches of 100 (ChromaDB limit workaround)
        batch_size = 100
        for i in range(0, len(chunks), batch_size):
            end = min(i + batch_size, len(chunks))
            collection.upsert(
                ids=ids[i:end],
                embeddings=embeddings[i:end],
                documents=documents[i:end],
                metadatas=metadatas[i:end],
            )

        logger.info(f"Added {len(chunks)} chunks to collection: {collection_name}")

    def query(
        self,
        collection_name: str,
        query_embedding: List[float],
        top_k: int = 5,
    ) -> List[RetrievedChunk]:
        """Query a collection for the most relevant chunks."""
        try:
            collection = self._client.get_collection(collection_name)
            results = collection.query(
                query_embeddings=[query_embedding],
                n_results=min(top_k, collection.count()),
                include=["documents", "metadatas", "distances"],
            )

            retrieved = []
            if results and results["documents"]:
                for i, doc_text in enumerate(results["documents"][0]):
                    # ChromaDB cosine distance: 0 = identical, 2 = opposite
                    # Convert to similarity score: 1 - (distance / 2)
                    distance = results["distances"][0][i] if results["distances"] else 0
                    similarity = 1 - (distance / 2)

                    retrieved.append(RetrievedChunk(
                        text=doc_text,
                        metadata=results["metadatas"][0][i] if results["metadatas"] else {},
                        relevance_score=round(similarity, 4),
                    ))

            return retrieved

        except Exception as e:
            logger.error(f"Vector query failed: {e}")
            return []

    def delete_collection(self, document_id: str) -> None:
        """Delete a document's vector collection."""
        name = self._collection_name(document_id)
        try:
            self._client.delete_collection(name)
            logger.info(f"Deleted ChromaDB collection: {name}")
        except Exception as e:
            logger.warning(f"Failed to delete collection {name}: {e}")

    def collection_exists(self, document_id: str) -> bool:
        """Check if a collection exists for a document."""
        name = self._collection_name(document_id)
        try:
            self._client.get_collection(name)
            return True
        except Exception:
            return False

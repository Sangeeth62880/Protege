"""
Embedding Service — generates vector embeddings for text using sentence-transformers.
Model: all-MiniLM-L6-v2 (384-dimensional, loaded once at startup).

For production scale, replace with GPU-accelerated inference server.
For Protégé's scale (single user uploads), CPU is fine.
"""
import logging
from typing import List

from sentence_transformers import SentenceTransformer

logger = logging.getLogger(__name__)


class EmbeddingService:
    """Service for generating text embeddings using sentence-transformers."""

    def __init__(self, model_name: str = "all-MiniLM-L6-v2"):
        logger.info(f"Loading embedding model: {model_name}...")
        self._model = SentenceTransformer(model_name)
        logger.info(f"Embedding model loaded. Dimension: {self._model.get_sentence_embedding_dimension()}")

    def embed_texts(self, texts: List[str]) -> List[List[float]]:
        """
        Batch-encode texts into embedding vectors.
        Returns list of 384-dimensional float vectors.
        """
        if not texts:
            return []

        embeddings = self._model.encode(
            texts,
            batch_size=32,
            show_progress_bar=False,
            normalize_embeddings=True,
        )
        return embeddings.tolist()

    def embed_query(self, query: str) -> List[float]:
        """Embed a single query string."""
        embedding = self._model.encode(
            query,
            show_progress_bar=False,
            normalize_embeddings=True,
        )
        return embedding.tolist()

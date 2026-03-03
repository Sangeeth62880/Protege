"""
Document Extraction Service — extracts text from PDFs and images.
Uses PyMuPDF for text PDFs, pdfplumber for tables (only when needed),
Tesseract OCR for scanned content (only as fallback).
"""
import os
import re
import time
import logging
import unicodedata
from typing import Optional

import fitz  # PyMuPDF
from PIL import Image, ImageFilter

from app.models.document_models import ExtractionResult, PageContent

logger = logging.getLogger(__name__)


class ExtractionError(Exception):
    """Raised when document extraction fails."""
    pass


class DocumentExtractionService:
    """Service for extracting text from PDF files and images."""

    def _clean_text(self, text: str) -> str:
        """Clean extracted text: normalize unicode, strip null bytes, collapse whitespace."""
        if not text:
            return ""
        # Remove null bytes
        text = text.replace("\x00", "")
        # Normalize unicode
        text = unicodedata.normalize("NFKC", text)
        # Collapse excessive whitespace (but keep paragraph breaks)
        text = re.sub(r"[ \t]+", " ", text)
        text = re.sub(r"\n{3,}", "\n\n", text)
        return text.strip()

    async def extract_from_pdf(self, file_path: str) -> ExtractionResult:
        """
        Extract text from a PDF file.
        Falls back to OCR if text extraction yields sparse results.
        Skips pdfplumber table extraction for simple text-heavy documents.
        """
        if not os.path.exists(file_path):
            raise ExtractionError(f"File not found: {file_path}")

        try:
            pages = []
            full_text_parts = []
            has_tables = False
            extraction_method = "text"

            # Phase 1: Extract text with PyMuPDF (fast — usually < 0.5s)
            t0 = time.time()
            doc = fitz.open(file_path)
            page_count = len(doc)

            for page_num in range(page_count):
                page = doc[page_num]
                text = page.get_text("text")
                text = self._clean_text(text)
                pages.append(PageContent(
                    page_number=page_num + 1,
                    text=text,
                ))
                full_text_parts.append(text)

            doc.close()
            t1 = time.time()
            print(f"[EXTRACTION] PyMuPDF text extraction: {t1 - t0:.2f}s ({page_count} pages)")

            # Check if text extraction was sparse → fall back to OCR
            avg_chars = sum(len(p.text) for p in pages) / max(page_count, 1)
            if avg_chars < 100:
                logger.info(f"Sparse text ({avg_chars:.0f} avg chars/page). Trying OCR...")
                try:
                    t0 = time.time()
                    ocr_pages = await self._ocr_pdf(file_path, page_count)
                    t1 = time.time()
                    print(f"[EXTRACTION] OCR fallback: {t1 - t0:.2f}s")
                    if ocr_pages:
                        pages = ocr_pages
                        full_text_parts = [p.text for p in pages]
                        extraction_method = "ocr"
                except Exception as e:
                    logger.warning(f"OCR fallback failed: {e}. Using sparse text.")
                    extraction_method = "mixed"
            else:
                print(f"[EXTRACTION] PyMuPDF extracted {avg_chars:.0f} avg chars/page — skipping OCR")

            # Phase 2: Extract tables with pdfplumber — ONLY for short docs
            # pdfplumber is slow (1-3s per page). Skip for text-heavy docs
            # where PyMuPDF already got good content.
            if page_count <= 10 and avg_chars > 50:
                try:
                    t0 = time.time()
                    import pdfplumber
                    with pdfplumber.open(file_path) as pdf:
                        for i, plumber_page in enumerate(pdf.pages):
                            tables = plumber_page.extract_tables()
                            if tables:
                                has_tables = True
                                md_tables = self._tables_to_markdown(tables)
                                if i < len(pages):
                                    pages[i].has_tables = True
                                    pages[i].tables_markdown = md_tables
                                    # Append table content to the page text
                                    pages[i].text += f"\n\n{md_tables}"
                                    full_text_parts[i] += f"\n\n{md_tables}"
                    t1 = time.time()
                    if has_tables:
                        print(f"[EXTRACTION] pdfplumber table extraction: {t1 - t0:.2f}s (tables found)")
                    else:
                        print(f"[EXTRACTION] pdfplumber table scan: {t1 - t0:.2f}s (no tables)")
                except ImportError:
                    logger.warning("pdfplumber not installed. Skipping table extraction.")
                except Exception as e:
                    logger.warning(f"Table extraction failed: {e}")
            else:
                print(f"[EXTRACTION] Skipping pdfplumber (page_count={page_count}, avg_chars={avg_chars:.0f})")

            full_text = "\n\n".join(full_text_parts)
            word_count = len(full_text.split())

            return ExtractionResult(
                full_text=full_text,
                pages=pages,
                page_count=page_count,
                has_tables=has_tables,
                extraction_method=extraction_method,
                word_count=word_count,
            )

        except ExtractionError:
            raise
        except Exception as e:
            raise ExtractionError(f"Failed to extract PDF content: {str(e)}")

    async def _ocr_pdf(self, file_path: str, page_count: int) -> list:
        """OCR a PDF by rendering pages to images and running Tesseract."""
        try:
            import pytesseract
        except ImportError:
            logger.warning("pytesseract not installed. Skipping OCR.")
            return []

        pages = []
        doc = fitz.open(file_path)

        for page_num in range(min(page_count, 50)):  # Cap at 50 pages for OCR
            page = doc[page_num]
            # Render page to image at 200 DPI
            pix = page.get_pixmap(dpi=200)
            img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)

            # Preprocess
            img = img.convert("L")  # Grayscale
            img = img.filter(ImageFilter.SHARPEN)

            text = pytesseract.image_to_string(img)
            text = self._clean_text(text)
            pages.append(PageContent(page_number=page_num + 1, text=text))

        doc.close()
        return pages

    async def extract_from_image(self, file_path: str) -> ExtractionResult:
        """Extract text from an image using OCR."""
        if not os.path.exists(file_path):
            raise ExtractionError(f"File not found: {file_path}")

        try:
            import pytesseract
        except ImportError:
            raise ExtractionError("pytesseract not installed. Cannot process images.")

        try:
            t0 = time.time()
            img = Image.open(file_path)

            # Preprocess: resize if too large
            max_dim = 4000
            if max(img.size) > max_dim:
                ratio = max_dim / max(img.size)
                new_size = (int(img.width * ratio), int(img.height * ratio))
                img = img.resize(new_size, Image.LANCZOS)

            # Convert to grayscale and sharpen
            img = img.convert("L")
            img = img.filter(ImageFilter.SHARPEN)

            text = pytesseract.image_to_string(img)
            text = self._clean_text(text)
            word_count = len(text.split())

            t1 = time.time()
            print(f"[EXTRACTION] Image OCR: {t1 - t0:.2f}s ({word_count} words)")

            page = PageContent(page_number=1, text=text)

            return ExtractionResult(
                full_text=text,
                pages=[page],
                page_count=1,
                has_tables=False,
                extraction_method="ocr",
                word_count=word_count,
            )

        except ExtractionError:
            raise
        except Exception as e:
            raise ExtractionError(f"Failed to extract image content: {str(e)}")

    def _tables_to_markdown(self, tables: list) -> str:
        """Convert pdfplumber tables to markdown format."""
        md_parts = []
        for table in tables:
            if not table or len(table) < 2:
                continue
            # First row as header
            header = table[0]
            header_row = "| " + " | ".join(str(c or "") for c in header) + " |"
            separator = "| " + " | ".join("---" for _ in header) + " |"
            rows = []
            for row in table[1:]:
                rows.append("| " + " | ".join(str(c or "") for c in row) + " |")
            md_parts.append(f"{header_row}\n{separator}\n" + "\n".join(rows))
        return "\n\n".join(md_parts)

"""
OpenStax Service - Free College Textbooks
Returns peer-reviewed textbooks licensed under CC BY 4.0.
"""
import asyncio
import httpx
from typing import List, Dict, Optional

TOPIC_BOOK_MAP = {
    "python": ["introduction-python"],
    "programming": ["introduction-python"],
    "biology": ["biology-2e", "concepts-biology", "microbiology"],
    "physics": ["college-physics-2e", "university-physics-volume-1", "university-physics-volume-2", "university-physics-volume-3"],
    "chemistry": ["chemistry-2e", "chemistry-atoms-first-2e", "organic-chemistry"],
    "math": ["college-algebra-2e", "precalculus-2e", "calculus-volume-1", "calculus-volume-2", "calculus-volume-3"],
    "algebra": ["college-algebra-2e", "elementary-algebra-2e", "intermediate-algebra-2e"],
    "calculus": ["calculus-volume-1", "calculus-volume-2", "calculus-volume-3"],
    "statistics": ["introductory-statistics-2e", "introductory-business-statistics-2e"],
    "economics": ["principles-economics-3e", "principles-macroeconomics-3e", "principles-microeconomics-3e"],
    "psychology": ["psychology-2e", "introduction-psychology"],
    "sociology": ["introduction-sociology-3e"],
    "history": ["us-history", "world-history-volume-1", "world-history-volume-2"],
    "anatomy": ["anatomy-and-physiology-2e"],
    "astronomy": ["astronomy-2e"],
    "business": ["introduction-business", "principles-management", "organizational-behavior"],
    "accounting": ["principles-financial-accounting", "principles-managerial-accounting"],
    "political science": ["introduction-political-science", "american-government-3e"],
    "nutrition": ["nutrition"],
    "philosophy": ["introduction-philosophy"],
}

class OpenStaxService:
    """Search OpenStax for relevant free textbooks."""

    CATALOG_URL = "https://openstax.org/apps/cms/api/books/"

    def __init__(self):
        self._books_cache: List[dict] = []
        self._catalog_fetched = False
        print("[OPENSTAX] Service initialized")

    async def _fetch_catalog(self):
        """Fetch and cache the OpenStax book catalog."""
        if self._catalog_fetched:
            return

        timeout = httpx.Timeout(15.0)
        async with httpx.AsyncClient(timeout=timeout, follow_redirects=True) as client:
            try:
                response = await client.get(self.CATALOG_URL)
                if response.status_code == 200:
                    data = response.json()
                    if isinstance(data, dict) and "books" in data:
                        self._books_cache = data["books"]
                    elif isinstance(data, list):
                        self._books_cache = data
                    else:
                        print("[OPENSTAX] Unexpected catalog format")
                        
                    print(f"[OPENSTAX] Cached {len(self._books_cache)} books from catalog")
                    self._catalog_fetched = True
                else:
                    print(f"[OPENSTAX] Failed to fetch catalog. Status: {response.status_code}")
            except Exception as e:
                print(f"[OPENSTAX] Error fetching catalog: {e}")

    async def search_textbooks(self, topic: str, lesson_title: str, max_results: int = 3) -> List[dict]:
        """Match lesson topic against OpenStax catalog."""
        await self._fetch_catalog()
        
        if not self._books_cache:
            return []

        import re

        # Standardize search queries
        clean_topic = re.sub(r'[^\w\s]', '', topic.lower())
        clean_lesson = re.sub(r'[^\w\s]', '', lesson_title.lower())
        
        stop_words = {
            "the", "a", "an", "in", "of", "to", "for", "and", "with", "is", "on", "by", "at", 
            "what", "are", "how", "why", "when", "where", "can", "do", "does", "did", 
            "module", "lesson", "unit", "chapter", "introduction", "basics", "understanding"
        }
        
        topic_words = set(clean_topic.split()) - stop_words
        lesson_words = set(clean_lesson.split()) - stop_words

        topic_mapped_slugs = []
        for key, slugs in TOPIC_BOOK_MAP.items():
            if key in clean_topic or key in clean_lesson:
                topic_mapped_slugs.extend(slugs)

        scored_books = []
        for book in self._books_cache:
            book_title = book.get("title", "").lower()
            book_slug = book.get("slug", "")
            subjects = [s.get("name", "").lower() for s in book.get("subjects", []) if "name" in s]
            
            matchable_text = f"{book_title} {' '.join(subjects)}"
            matchable_text = re.sub(r'[^\w\s]', '', matchable_text)
            text_words = set(matchable_text.split())
            
            # Word matching score (prioritize topic words)
            topic_matches = sum(1 for word in topic_words if word in text_words)
            lesson_matches = sum(1 for word in lesson_words if word in text_words)
            
            score = 0.0
            if topic_words:
                score += (topic_matches / len(topic_words)) * 0.7  # 70% weight to topic
            if lesson_words:
                score += (lesson_matches / len(lesson_words)) * 0.3  # 30% weight to lesson
            
            # Bonus for exact topic in title
            if clean_topic and clean_topic in book_title:
                score += 0.5
                
            # Bonus for mapped slugs
            if book_slug in topic_mapped_slugs:
                score += 0.8
                
            # We use a threshold of 0.25 to catch books that match the broader topic but not the niche lesson
            if score >= 0.25:
                scored_books.append((score, book))


        # Sort and take top N
        scored_books.sort(key=lambda x: x[0], reverse=True)

        results = []
        for score, book in scored_books[:max_results]:
            slug = book.get("slug", "")
            # slug sometimes comes as 'books/college-physics'
            clean_slug = slug.replace("books/", "") if slug.startswith("books/") else slug
            deep_link = f"https://openstax.org/books/{clean_slug}/pages/1-introduction"
            
            # Enhance deep link if possible
            enhanced_link = await self._find_deep_link(book, lesson_title)
            if enhanced_link:
                deep_link = enhanced_link

            subs = [s.get("name", "") for s in book.get("subjects", []) if "name" in s]
            
            results.append({
                "title": book.get("title", ""),
                "url": book.get("webview_rex_link", f"https://openstax.org/details/books/{clean_slug}"),
                "cover_url": book.get("cover_url"),
                "slug": clean_slug,
                "subjects": subs,
                "source": "openstax",
                "type": "textbook",
                "description": f"Free, peer-reviewed textbook covering {', '.join(subs)}. Licensed under CC BY 4.0.",
                "relevance_score": min(int(score * 100), 100),
                "deep_link": deep_link,
                "license": "CC BY 4.0",
                "attribution": "OpenStax, Rice University"
            })

        return results

    async def _find_deep_link(self, book: dict, lesson_title: str) -> Optional[str]:
        """Try to find a specific section deep link from the ToC."""
        book_id = book.get("id")
        slug = book.get("slug")
        if not book_id or not slug:
            return None
            
        timeout = httpx.Timeout(5.0)
        async with httpx.AsyncClient(timeout=timeout, follow_redirects=True) as client:
            try:
                response = await client.get(f"{self.CATALOG_URL}{book_id}/")
                if response.status_code == 200:
                    data = response.json()
                    toc_html = data.get("table_of_contents", {})
                    
                    # The OpenStax table of contents API actually returns a nested tree of dicts or HTML
                    # Usually tree dict with 'contents' list.
                    tree = data.get("tree", {})
                    
                    def find_slug_in_tree(nodes, target):
                        target_words = set(target.lower().split())
                        best_match = None
                        best_score = 0
                        
                        queue = list(nodes)
                        while queue:
                            node = queue.pop(0)
                            if "contents" in node:
                                queue.extend(node["contents"])
                            
                            node_title = node.get("title", "").lower()
                            node_slug = node.get("slug")
                            
                            if node_title and node_slug:
                                words = set(node_title.split())
                                matches = len(words.intersection(target_words))
                                if matches > best_score:
                                    best_score = matches
                                    best_match = node_slug
                                    
                        return best_match
                        
                    if tree and "contents" in tree:
                        best_section_slug = find_slug_in_tree(tree["contents"], lesson_title)
                        if best_section_slug:
                            return f"https://openstax.org/books/{slug}/pages/{best_section_slug}"
            except Exception as e:
                print(f"[OPENSTAX] Error fetching ToC for {slug}: {e}")
        return None

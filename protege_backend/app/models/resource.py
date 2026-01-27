from typing import Optional, List, Union
from pydantic import BaseModel, Field
from datetime import datetime

class VideoResource(BaseModel):
    """Video resource model"""
    type: str = "video"
    source: str = "youtube"
    video_id: str
    title: str
    description: str
    channel_name: str
    channel_id: str
    thumbnail_url: str
    duration_minutes: int
    view_count: int
    like_count: int
    published_at: str
    url: str
    quality_score: float = 0.0
    
    class Config:
        json_schema_extra = {
            "example": {
                "type": "video",
                "source": "youtube",
                "video_id": "dQw4w9WgXcQ",
                "title": "Rick Astley - Never Gonna Give You Up",
                "description": "The official video...",
                "channel_name": "Rick Astley",
                "channel_id": "UCuAXFkgsw1L7xaCfnd5JJOw",
                "thumbnail_url": "https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg",
                "duration_minutes": 3,
                "view_count": 1000000000,
                "like_count": 5000000,
                "published_at": "2009-10-25T06:57:33Z",
                "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
            }
        }

class ArticleResource(BaseModel):
    """Article/Web resource model"""
    type: str = "article"
    source: str = "google"
    title: str
    link: str
    snippet: str
    source_domain: str
    pagemap: Optional[dict] = None # For thumbnail/meta
    published_at: Optional[str] = None
    
    class Config:
        json_schema_extra = {
            "example": {
                "type": "article",
                "source": "google",
                "title": "FastAPI Tutorial",
                "link": "https://fastapi.tiangolo.com/tutorial/",
                "snippet": "FastAPI is a modern, fast (high-performance), web framework...",
                "source_domain": "fastapi.tiangolo.com"
            }
        }

class RepositoryResource(BaseModel):
    """GitHub/Code repository resource model"""
    type: str = "repository"
    source: str = "github"
    title: str
    description: str
    url: str
    author: str
    rating: int = 0  # Stars
    
    class Config:
        json_schema_extra = {
            "example": {
                "type": "repository",
                "source": "github",
                "title": "fastapi",
                "description": "FastAPI framework...",
                "url": "https://github.com/tiangolo/fastapi",
                "author": "tiangolo",
                "rating": 50000
            }
        }
class ResourceResponse(BaseModel):
    """Unified resource response"""
    resources: List[Union[VideoResource, ArticleResource, RepositoryResource]]
    curated_for_lesson: Optional[str] = None
    
    class Config:
        json_schema_extra = {
            "example": {
                "resources": [
                    {
                        "type": "video",
                        "title": "Python Tutorial",
                        "url": "https://youtube.com/..."
                    }
                ],
                "curated_for_lesson": "1.1 Introduction"
            }
        }

from typing import List, Dict, Optional
from enum import Enum
from pydantic import BaseModel, Field
from datetime import datetime

class DifficultyLevel(str, Enum):
    BEGINNER = "beginner"
    INTERMEDIATE = "intermediate"
    ADVANCED = "advanced"

class ResourceType(str, Enum):
    VIDEO = "video"
    ARTICLE = "article"
    GITHUB = "github"
    OTHER = "other"

class LessonSearchQueries(BaseModel):
    youtube: str
    articles: str
    github: Optional[str] = None

class Lesson(BaseModel):
    lesson_number: int
    title: str
    description: str
    duration_minutes: int
    learning_objectives: List[str]
    key_concepts: List[str]
    search_queries: LessonSearchQueries
    completed: bool = False
    video_resource_ids: List[str] = []
    article_resource_ids: List[str] = []

class Module(BaseModel):
    module_number: int
    title: str
    description: str
    duration_hours: float
    lessons: List[Lesson]
    completed: bool = False

class CapstoneProject(BaseModel):
    title: str
    description: str
    skills_applied: List[str]

class Syllabus(BaseModel):
    topic: str
    description: str
    total_duration_hours: float
    difficulty: DifficultyLevel
    prerequisites: List[str]
    modules: List[Module]
    capstone_project: Optional[CapstoneProject] = None

class LearningPathCreate(BaseModel):
    topic: str
    goal: str
    experience_level: DifficultyLevel
    daily_time_minutes: int
    
    class Config:
        json_schema_extra = {
            "example": {
                "topic": "FastAPI Web Development",
                "goal": "Build a production-ready API",
                "experience_level": "intermediate",
                "daily_time_minutes": 60
            }
        }

class LearningPath(Syllabus):
    id: str = Field(alias="_id")
    user_id: str
    created_at: datetime
    updated_at: datetime
    progress: float = 0.0  # 0 to 1
    is_active: bool = True

class GenerateSyllabusRequest(BaseModel):
    topic: str
    goal: str
    experience_level: DifficultyLevel
    daily_time_minutes: int

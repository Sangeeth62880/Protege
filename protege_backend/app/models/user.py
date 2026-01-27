"""
User models for API
"""
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field
from datetime import datetime


class UserPreferences(BaseModel):
    """User preferences model"""
    theme_mode: str = "system"  # light, dark, system
    notifications_enabled: bool = True
    sound_enabled: bool = True
    preferred_language: str = "en"


class UserBase(BaseModel):
    """Base user model with shared fields"""
    email: str
    display_name: str
    photo_url: Optional[str] = None


class UserCreate(UserBase):
    """Model for creating a new user"""
    pass


class UserUpdate(BaseModel):
    """Model for updating user profile"""
    display_name: Optional[str] = None
    photo_url: Optional[str] = None
    learning_goal: Optional[str] = None
    experience_level: Optional[str] = None
    daily_time_minutes: Optional[int] = None
    preferences: Optional[UserPreferences] = None


class UserStats(BaseModel):
    """User statistics"""
    total_xp: int = 0
    current_streak: int = 0
    lessons_completed: int = 0
    quizzes_taken: int = 0
    teaching_sessions: int = 0


class UserResponse(BaseModel):
    """User response model for API"""
    id: str
    email: str
    display_name: str
    photo_url: Optional[str] = None
    created_at: datetime
    last_login_at: Optional[datetime] = None
    learning_goal: Optional[str] = None
    experience_level: str = "beginner"
    daily_time_minutes: int = 30
    preferences: UserPreferences = Field(default_factory=UserPreferences)
    stats: UserStats = Field(default_factory=UserStats)

    class Config:
        from_attributes = True


class UserInDB(UserResponse):
    """User model as stored in Firestore"""
    learning_path_ids: List[str] = []


class TokenVerifyRequest(BaseModel):
    """Token verification request (optional body)"""
    pass


class TokenVerifyResponse(BaseModel):
    """Token verification response"""
    valid: bool
    uid: str
    email: Optional[str] = None
    user: Optional[UserResponse] = None


class ProfileUpdateResponse(BaseModel):
    """Profile update response"""
    success: bool
    message: str
    user: Optional[UserResponse] = None

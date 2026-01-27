"""
Authentication routes
"""
from fastapi import APIRouter, Depends, HTTPException, status
from datetime import datetime
from typing import Optional

from app.api.dependencies import get_current_user, firebase_service
from app.models.user import (
    UserUpdate,
    UserResponse,
    UserPreferences,
    UserStats,
    TokenVerifyResponse,
    ProfileUpdateResponse,
)


router = APIRouter()


@router.post("/verify", response_model=TokenVerifyResponse)
async def verify_token(user: dict = Depends(get_current_user)):
    """
    Verify the user's Firebase token and return user data.
    Creates user in Firestore if they don't exist.
    """
    uid = user.get("uid")
    email = user.get("email", "")
    
    # Check if user exists in Firestore
    existing_user = await firebase_service.get_user(uid)
    
    if existing_user:
        # Update last login
        await firebase_service.update_document(
            "users",
            uid,
            {"last_login_at": datetime.utcnow().isoformat()}
        )
        
        return TokenVerifyResponse(
            valid=True,
            uid=uid,
            email=email,
            user=UserResponse(
                id=uid,
                email=existing_user.get("email", email),
                display_name=existing_user.get("display_name", user.get("name", "Learner")),
                photo_url=existing_user.get("photo_url", user.get("picture")),
                created_at=datetime.fromisoformat(existing_user.get("created_at", datetime.utcnow().isoformat())),
                last_login_at=datetime.utcnow(),
                learning_goal=existing_user.get("learning_goal"),
                experience_level=existing_user.get("experience_level", "beginner"),
                daily_time_minutes=existing_user.get("daily_time_minutes", 30),
                preferences=UserPreferences(**existing_user.get("preferences", {})),
                stats=UserStats(**existing_user.get("stats", {})),
            )
        )
    else:
        # Create new user
        new_user_data = {
            "id": uid,
            "email": email,
            "display_name": user.get("name", "Learner"),
            "photo_url": user.get("picture"),
            "created_at": datetime.utcnow().isoformat(),
            "last_login_at": datetime.utcnow().isoformat(),
            "experience_level": "beginner",
            "daily_time_minutes": 30,
            "preferences": UserPreferences().model_dump(),
            "stats": UserStats().model_dump(),
            "learning_path_ids": [],
        }
        
        await firebase_service.create_document("users", uid, new_user_data)
        
        return TokenVerifyResponse(
            valid=True,
            uid=uid,
            email=email,
            user=UserResponse(
                id=uid,
                email=email,
                display_name=new_user_data["display_name"],
                photo_url=new_user_data["photo_url"],
                created_at=datetime.utcnow(),
                last_login_at=datetime.utcnow(),
                experience_level="beginner",
                daily_time_minutes=30,
            )
        )


@router.get("/profile", response_model=UserResponse)
async def get_profile(user: dict = Depends(get_current_user)):
    """Get the current user's full profile"""
    uid = user.get("uid")
    
    user_data = await firebase_service.get_user(uid)
    
    if not user_data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User profile not found"
        )
    
    return UserResponse(
        id=uid,
        email=user_data.get("email", user.get("email", "")),
        display_name=user_data.get("display_name", "Learner"),
        photo_url=user_data.get("photo_url"),
        created_at=datetime.fromisoformat(user_data.get("created_at", datetime.utcnow().isoformat())),
        last_login_at=datetime.fromisoformat(user_data["last_login_at"]) if user_data.get("last_login_at") else None,
        learning_goal=user_data.get("learning_goal"),
        experience_level=user_data.get("experience_level", "beginner"),
        daily_time_minutes=user_data.get("daily_time_minutes", 30),
        preferences=UserPreferences(**user_data.get("preferences", {})),
        stats=UserStats(**user_data.get("stats", {})),
    )


@router.put("/profile", response_model=ProfileUpdateResponse)
async def update_profile(
    update_data: UserUpdate,
    user: dict = Depends(get_current_user)
):
    """Update the current user's profile"""
    uid = user.get("uid")
    
    # Build update dict with only provided fields
    update_dict = {}
    
    if update_data.display_name is not None:
        update_dict["display_name"] = update_data.display_name
    
    if update_data.photo_url is not None:
        update_dict["photo_url"] = update_data.photo_url
    
    if update_data.learning_goal is not None:
        update_dict["learning_goal"] = update_data.learning_goal
    
    if update_data.experience_level is not None:
        if update_data.experience_level not in ["beginner", "intermediate", "advanced"]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="experience_level must be one of: beginner, intermediate, advanced"
            )
        update_dict["experience_level"] = update_data.experience_level
    
    if update_data.daily_time_minutes is not None:
        if not 5 <= update_data.daily_time_minutes <= 480:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="daily_time_minutes must be between 5 and 480"
            )
        update_dict["daily_time_minutes"] = update_data.daily_time_minutes
    
    if update_data.preferences is not None:
        update_dict["preferences"] = update_data.preferences.model_dump()
    
    if not update_dict:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No fields to update"
        )
    
    # Update in Firestore
    success = await firebase_service.update_document("users", uid, update_dict)
    
    if not success:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update profile"
        )
    
    # Fetch updated user
    updated_user = await firebase_service.get_user(uid)
    
    return ProfileUpdateResponse(
        success=True,
        message="Profile updated successfully",
        user=UserResponse(
            id=uid,
            email=updated_user.get("email", ""),
            display_name=updated_user.get("display_name", "Learner"),
            photo_url=updated_user.get("photo_url"),
            created_at=datetime.fromisoformat(updated_user.get("created_at", datetime.utcnow().isoformat())),
            last_login_at=datetime.fromisoformat(updated_user["last_login_at"]) if updated_user.get("last_login_at") else None,
            learning_goal=updated_user.get("learning_goal"),
            experience_level=updated_user.get("experience_level", "beginner"),
            daily_time_minutes=updated_user.get("daily_time_minutes", 30),
            preferences=UserPreferences(**updated_user.get("preferences", {})),
            stats=UserStats(**updated_user.get("stats", {})),
        ) if updated_user else None
    )

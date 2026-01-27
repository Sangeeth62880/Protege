"""
API dependencies
"""
from typing import Optional
from fastapi import Header, HTTPException, status

from app.services.firebase_service import FirebaseService


firebase_service = FirebaseService()


async def get_current_user(authorization: Optional[str] = Header(None)) -> dict:
    """
    Verify Firebase ID token and return user data
    """
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or invalid authorization header",
        )
    
    token = authorization.replace("Bearer ", "")
    
    try:
        user = await firebase_service.verify_token(token)
        return user
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid token: {str(e)}",
        )


async def get_optional_user(
    authorization: Optional[str] = Header(None)
) -> Optional[dict]:
    """
    Optionally verify Firebase ID token
    """
    if not authorization or not authorization.startswith("Bearer "):
        return None
    
    try:
        return await get_current_user(authorization)
    except HTTPException:
        return None

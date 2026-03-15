from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from pydantic import BaseModel
from typing import Optional
from app.services.sarvam_service import SarvamService
from app.config import settings

router = APIRouter()

class TTSRequest(BaseModel):
    text: str
    language_code: str = "en-IN"
    speaker: Optional[str] = None

def get_sarvam_service() -> SarvamService:
    if not settings.SARVAM_API_KEY:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Sarvam AI service is not configured. Missing API key."
        )
    return SarvamService(api_key=settings.SARVAM_API_KEY)

@router.post("/transcribe")
async def transcribe_audio(
    file: UploadFile = File(...),
    sarvam_service: SarvamService = Depends(get_sarvam_service)
):
    """Convert uploaded audio file to text using Sarvam AI"""
    if not file.filename.endswith(('.wav', '.mp3', '.m4a', '.ogg', '.webm')):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Unsupported audio format. Supported formats: .wav, .mp3, .m4a, .ogg, .webm"
        )
        
    try:
        # We need to give the Sarvam API a synchronous file object
        text = sarvam_service.transcribe_audio(file.file)
        return {"text": text}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Transcription failed: {str(e)}"
        )

@router.post("/tts")
async def generate_speech(
    request: TTSRequest,
    sarvam_service: SarvamService = Depends(get_sarvam_service)
):
    """Convert text to speech using Sarvam AI"""
    if not request.text.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Text cannot be empty"
        )
        
    try:
        audio_base64 = sarvam_service.generate_speech(
            text=request.text,
            target_language_code=request.language_code,
            speaker=request.speaker
        )
        
        if not audio_base64:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="No audio generated"
            )
            
        return {"audio_base64": audio_base64}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Speech generation failed: {str(e)}"
        )

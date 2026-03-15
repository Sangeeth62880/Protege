import base64
import os
from typing import Optional, Dict, Any, BinaryIO
from sarvamai import SarvamAI

class SarvamService:
    """Service wrapper for Sarvam AI Audio APIs"""
    
    def __init__(self, api_key: str):
        self.api_key = api_key
        self.client = SarvamAI(api_subscription_key=api_key) if api_key else None
        
    def is_configured(self) -> bool:
        return self.client is not None

    def transcribe_audio(self, file: BinaryIO, language: str = "en-IN") -> str:
        """
        Convert speech to text using Sarvam AI saaras:v3 model.
        Returns the transcribed text.
        """
        if not self.is_configured():
            raise ValueError("Sarvam API key not configured")
            
        try:
            # saarika:v2.5 is optimized for low-latency interactive applications
            response = self.client.speech_to_text.transcribe(
                file=file,
                model="saarika:v2.5",
                language_code=language
            )
            
            # Extract transcript from the response
            if hasattr(response, 'transcript'):
                return response.transcript
            elif isinstance(response, dict) and 'transcript' in response:
                return response['transcript']
            elif hasattr(response, 'text'):
                return response.text
                
            return str(response)
        except Exception as e:
            print(f"[SARVAM] Transcription error: {e}")
            raise

    def generate_speech(self, text: str, target_language_code: str = "en-IN", speaker: str = "aditya") -> Optional[str]:
        """
        Convert text to speech using Sarvam AI.
        Returns base64 encoded audio string.
        """
        if not self.is_configured():
            raise ValueError("Sarvam API key not configured")
            
        if not text or not text.strip():
            return None
            
        import re
        import base64
        
        # 1. Clean the text to avoid pronunciation bugs and markdown symbols
        # Remove markdown stars, underscores, hashes, backticks, tildes
        clean_text = re.sub(r'[*_#`~]', '', text)
        # Remove URLs
        clean_text = re.sub(r'http\S+', '', clean_text)
        # Remove braces or extra parentheses
        clean_text = re.sub(r'[\[\]\(\)\{\}]', '', clean_text)
        
        try:
            # 2. Chunking to bypass length and timeout limits and ensure full TTS response
            # Split roughly by sentences
            sentences = re.split(r'(?<=[.!?])\s+', clean_text)
            
            audio_bytes = bytearray()
            current_chunk = ""
            
            for sentence in sentences:
                if len(current_chunk) + len(sentence) < 1500:
                    current_chunk += sentence + " "
                else:
                    if current_chunk.strip():
                        resp = self.client.text_to_speech.convert(
                            text=current_chunk.strip(),
                            target_language_code=target_language_code,
                            model="bulbul:v3",
                            speaker=speaker, # Use dynamic speaker mapped to persona
                            pace=1.05,        # Slightly faster, avoids slow robotic drag
                            temperature=0.8   # Greater expressiveness
                        )
                        audio_b64 = None
                        if hasattr(resp, 'audios') and resp.audios:
                            audio_b64 = resp.audios[0]
                        elif isinstance(resp, dict) and 'audios' in resp and resp['audios']:
                            audio_b64 = resp['audios'][0]
                            
                        if audio_b64:
                            audio_bytes.extend(base64.b64decode(audio_b64))
                            
                    current_chunk = sentence + " "
            
            if current_chunk.strip():
                resp = self.client.text_to_speech.convert(
                    text=current_chunk.strip(),
                    target_language_code=target_language_code,
                    model="bulbul:v3",
                    speaker=speaker,
                    pace=1.05,
                    temperature=0.8
                )
                
                audio_b64 = None
                if hasattr(resp, 'audios') and resp.audios:
                    audio_b64 = resp.audios[0]
                elif isinstance(resp, dict) and 'audios' in resp and resp['audios']:
                    audio_b64 = resp['audios'][0]
                    
                if audio_b64:
                    audio_bytes.extend(base64.b64decode(audio_b64))
                    
            if len(audio_bytes) > 0:
                # Return the globally concatenated base64 audio
                return base64.b64encode(bytes(audio_bytes)).decode('utf-8')
            
            return None
        except Exception as e:
            print(f"[SARVAM] Text-to-Speech error: {e}")
            raise

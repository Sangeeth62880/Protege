"""
Firebase Service for authentication and Firestore
"""
from typing import Dict, Any, Optional
import firebase_admin
from firebase_admin import credentials, auth, firestore

from app.config import settings


class FirebaseService:
    """Service for Firebase operations"""
    
    def __init__(self):
        self._initialized = False
        self._db = None
        self._initialize()
    
    def _initialize(self):
        """Initialize Firebase Admin SDK"""
        if self._initialized:
            return
        
        try:
            # Check if already initialized
            firebase_admin.get_app()
            self._initialized = True
        except ValueError:
            # Initialize with credentials
            if settings.FIREBASE_PROJECT_ID and settings.FIREBASE_PRIVATE_KEY:
                cred = credentials.Certificate({
                    "type": "service_account",
                    "project_id": settings.FIREBASE_PROJECT_ID,
                    "private_key": settings.FIREBASE_PRIVATE_KEY.replace("\\n", "\n"),
                    "client_email": settings.FIREBASE_CLIENT_EMAIL,
                    "token_uri": "https://oauth2.googleapis.com/token",
                })
                firebase_admin.initialize_app(cred)
                self._initialized = True
            else:
                print("Firebase credentials not configured")
        
        if self._initialized:
            self._db = firestore.client()
    
    @property
    def db(self):
        """Get Firestore client"""
        return self._db
    
    async def verify_token(self, token: str) -> Dict[str, Any]:
        """Verify Firebase ID token"""
        if not self._initialized:
            raise Exception("Firebase not initialized")
        
        try:
            decoded_token = auth.verify_id_token(token)
            return decoded_token
        except Exception as e:
            raise Exception(f"Invalid token: {str(e)}")
    
    async def get_user(self, uid: str) -> Optional[Dict[str, Any]]:
        """Get user by UID"""
        if not self._initialized or not self._db:
            return None
        
        try:
            doc = self._db.collection("users").document(uid).get()
            if doc.exists:
                return doc.to_dict()
            return None
        except Exception as e:
            print(f"Error getting user: {e}")
            return None
    
    async def create_document(
        self,
        collection: str,
        doc_id: str,
        data: Dict[str, Any],
    ) -> bool:
        """Create a document in Firestore"""
        if not self._initialized or not self._db:
            return False
        
        try:
            self._db.collection(collection).document(doc_id).set(data)
            return True
        except Exception as e:
            print(f"Error creating document: {e}")
            return False
    
    async def update_document(
        self,
        collection: str,
        doc_id: str,
        data: Dict[str, Any],
    ) -> bool:
        """Update a document in Firestore"""
        if not self._initialized or not self._db:
            return False
        
        try:
            self._db.collection(collection).document(doc_id).update(data)
            return True
        except Exception as e:
            print(f"Error updating document: {e}")
            return False
    
    async def get_document(
        self,
        collection: str,
        doc_id: str,
    ) -> Optional[Dict[str, Any]]:
        """Get a document from Firestore"""
        if not self._initialized or not self._db:
            return None
        
        try:
            doc = self._db.collection(collection).document(doc_id).get()
            if doc.exists:
                return doc.to_dict()
            return None
        except Exception as e:
            print(f"Error getting document: {e}")
            return None
    
    async def query_collection(
        self,
        collection: str,
        field: str,
        operator: str,
        value: Any,
        limit: int = 50,
    ) -> list:
        """Query a collection"""
        if not self._initialized or not self._db:
            return []
        
        try:
            query = self._db.collection(collection).where(field, operator, value).limit(limit)
            docs = query.stream()
            return [doc.to_dict() for doc in docs]
        except Exception as e:
            print(f"Error querying collection: {e}")
            return []

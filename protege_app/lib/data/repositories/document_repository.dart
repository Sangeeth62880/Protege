import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/document_model.dart';
import '../services/document_api_service.dart';
import '../services/firebase_service.dart';

/// Repository for document operations.
/// Combines API calls (backend processing) with Firestore streams (real-time status).
class DocumentRepository {
  final DocumentApiService _apiService;
  // ignore: unused_field - kept for future direct Firestore operations
  final FirebaseService _firebaseService;

  DocumentRepository(this._apiService, this._firebaseService);

  /// Watch all documents for a user in real-time via Firestore.
  Stream<List<DocumentModel>> watchUserDocuments(String userId) {
    return FirebaseFirestore.instance
        .collection('documents')
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DocumentModel.fromFirestore(doc))
            .toList());
  }

  /// Upload a file for processing (web-compatible: bytes + filename).
  Future<DocumentModel> uploadAndProcess({
    required Uint8List bytes,
    required String fileName,
    required String userId,
  }) async {
    final result = await _apiService.uploadDocument(
      bytes: bytes,
      fileName: fileName,
      userId: userId,
    );
    return DocumentModel.fromJson(result);
  }

  /// Chat with a document.
  Future<Map<String, dynamic>> chatWithDocument(
    String documentId,
    String query,
    List<Map<String, String>>? conversationHistory,
  ) {
    return _apiService.chatWithDocument(documentId, query, conversationHistory);
  }

  /// Explain a section.
  Future<String> explainSection(
    String documentId,
    String section,
    String level,
  ) {
    return _apiService.explainSection(documentId, section, level);
  }

  /// Delete a document.
  Future<void> deleteDocument(String documentId) {
    return _apiService.deleteDocument(documentId);
  }

  /// Link to learning path.
  Future<void> linkToPath(String documentId, String pathId) {
    return _apiService.linkToPath(documentId, pathId);
  }
}

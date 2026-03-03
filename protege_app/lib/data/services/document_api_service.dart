import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';

/// Service for making API calls to the backend document endpoints.
/// Uses bytes-based upload to support both web and native platforms.
class DocumentApiService {
  final Dio _dio;

  DocumentApiService(this._dio);

  /// Upload a document for processing (web-compatible: uses bytes).
  Future<Map<String, dynamic>> uploadDocument({
    required Uint8List bytes,
    required String fileName,
    required String userId,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: fileName,
      ),
      'userId': userId,
    });

    final response = await _dio.post(
      '${ApiConstants.baseUrl}/api/v1/documents/upload',
      data: formData,
      options: Options(
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );

    return response.data as Map<String, dynamic>;
  }

  /// Get all documents for a user.
  Future<List<Map<String, dynamic>>> getDocuments(String userId) async {
    final response = await _dio.get(
      '${ApiConstants.baseUrl}/api/v1/documents/',
      queryParameters: {'userId': userId},
    );

    return List<Map<String, dynamic>>.from(response.data);
  }

  /// Get a single document by ID.
  Future<Map<String, dynamic>> getDocument(String documentId) async {
    final response = await _dio.get(
      '${ApiConstants.baseUrl}/api/v1/documents/$documentId',
    );

    return response.data as Map<String, dynamic>;
  }

  /// Chat with a document (RAG Q&A).
  Future<Map<String, dynamic>> chatWithDocument(
    String documentId,
    String query,
    List<Map<String, String>>? conversationHistory,
  ) async {
    final response = await _dio.post(
      '${ApiConstants.baseUrl}/api/v1/documents/$documentId/chat',
      data: {
        'query': query,
        if (conversationHistory != null) 'conversation_history': conversationHistory,
      },
      options: Options(receiveTimeout: const Duration(seconds: 30)),
    );

    return response.data as Map<String, dynamic>;
  }

  /// Explain a section of a document.
  Future<String> explainSection(
    String documentId,
    String section,
    String simplifyLevel,
  ) async {
    final response = await _dio.post(
      '${ApiConstants.baseUrl}/api/v1/documents/$documentId/explain',
      data: {
        'section': section,
        'simplify_level': simplifyLevel,
      },
    );

    return response.data['explanation'] as String;
  }

  /// Delete a document.
  Future<void> deleteDocument(String documentId) async {
    await _dio.delete(
      '${ApiConstants.baseUrl}/api/v1/documents/$documentId',
    );
  }

  /// Link a document to a learning path.
  Future<void> linkToPath(String documentId, String pathId) async {
    await _dio.post(
      '${ApiConstants.baseUrl}/api/v1/documents/$documentId/link-path',
      data: {'path_id': pathId},
    );
  }
}

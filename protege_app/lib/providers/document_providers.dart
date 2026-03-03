import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/document_model.dart';
import '../data/services/document_api_service.dart';
import '../data/repositories/document_repository.dart';
import 'auth_provider.dart';

// ─── Service & Repository Providers ──────────────────────────────────────

final documentApiServiceProvider = Provider<DocumentApiService>((ref) {
  return DocumentApiService(Dio());
});

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  final apiService = ref.read(documentApiServiceProvider);
  final firebaseService = ref.read(firebaseServiceProvider);
  return DocumentRepository(apiService, firebaseService);
});

// ─── User Documents Stream ───────────────────────────────────────────────

final userDocumentsProvider = StreamProvider<List<DocumentModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final repo = ref.read(documentRepositoryProvider);
  return repo.watchUserDocuments(user.uid);
});

// ─── Single Document Detail ──────────────────────────────────────────────

final documentDetailProvider = FutureProvider.family<DocumentModel?, String>(
  (ref, documentId) async {
    final apiService = ref.read(documentApiServiceProvider);
    final data = await apiService.getDocument(documentId);
    return DocumentModel.fromJson(data);
  },
);

// ─── Single Document Stream (real-time Firestore updates) ────────────────

final documentStreamProvider = StreamProvider.family<DocumentModel?, String>(
  (ref, documentId) {
    return FirebaseFirestore.instance
        .collection('documents')
        .doc(documentId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return null;
          return DocumentModel.fromFirestore(snapshot);
        });
  },
);

// ─── Document Chat ───────────────────────────────────────────────────────

class DocumentChatState {
  final List<DocumentChatMessage> messages;
  final bool isLoading;
  final String? error;
  final List<String> suggestedQuestions;

  const DocumentChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.suggestedQuestions = const [],
  });

  DocumentChatState copyWith({
    List<DocumentChatMessage>? messages,
    bool? isLoading,
    String? error,
    List<String>? suggestedQuestions,
  }) {
    return DocumentChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      suggestedQuestions: suggestedQuestions ?? this.suggestedQuestions,
    );
  }
}

class DocumentChatNotifier extends StateNotifier<DocumentChatState> {
  final DocumentRepository _repository;

  DocumentChatNotifier(this._repository) : super(const DocumentChatState());

  Future<void> sendMessage(String documentId, String query) async {
    final userMsg = DocumentChatMessage(role: 'user', content: query);
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      error: null,
    );

    try {
      final history = state.messages
          .take(state.messages.length - 1)
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();

      final result = await _repository.chatWithDocument(
        documentId,
        query,
        history.isNotEmpty ? history.cast<Map<String, String>>() : null,
      );

      final sources = (result['sources'] as List<dynamic>?)
          ?.map((s) => DocumentSource.fromJson(s as Map<String, dynamic>))
          .toList();

      final followUps = List<String>.from(
        result['follow_up_questions'] ?? result['followUpQuestions'] ?? [],
      );

      final assistantMsg = DocumentChatMessage(
        role: 'assistant',
        content: result['answer'] ?? '',
        sources: sources,
        followUpQuestions: followUps,
      );

      state = state.copyWith(
        messages: [...state.messages, assistantMsg],
        isLoading: false,
        suggestedQuestions: followUps,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to get response. Please try again.',
      );
    }
  }

  void clearChat() {
    state = const DocumentChatState();
  }

  Future<void> retryLast(String documentId) async {
    if (state.messages.isEmpty) return;

    final lastUserMsg = state.messages.lastWhere(
      (m) => m.isUser,
      orElse: () => state.messages.last,
    );

    final msgs = List<DocumentChatMessage>.from(state.messages);
    if (msgs.last.isAssistant) msgs.removeLast();
    if (msgs.isNotEmpty && msgs.last.isUser) msgs.removeLast();

    state = state.copyWith(messages: msgs, error: null);
    await sendMessage(documentId, lastUserMsg.content);
  }
}

final documentChatProvider =
    StateNotifierProvider<DocumentChatNotifier, DocumentChatState>((ref) {
  final repo = ref.read(documentRepositoryProvider);
  return DocumentChatNotifier(repo);
});

// ─── Document Upload (web-compatible: uses bytes) ────────────────────────

class DocumentUploadState {
  final String? selectedFileName;
  final Uint8List? selectedFileBytes;
  final int? selectedFileSize;
  final bool isUploading;
  final double uploadProgress;
  final String? error;
  final DocumentModel? uploadedDocument;

  const DocumentUploadState({
    this.selectedFileName,
    this.selectedFileBytes,
    this.selectedFileSize,
    this.isUploading = false,
    this.uploadProgress = 0,
    this.error,
    this.uploadedDocument,
  });

  bool get hasFile => selectedFileBytes != null && selectedFileName != null;

  String get fileSizeFormatted {
    if (selectedFileSize == null) return '';
    final s = selectedFileSize!;
    if (s < 1024) return '$s B';
    if (s < 1024 * 1024) return '${(s / 1024).toStringAsFixed(1)} KB';
    return '${(s / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get fileExtension =>
      selectedFileName?.split('.').last.toLowerCase() ?? '';

  DocumentUploadState copyWith({
    String? selectedFileName,
    Uint8List? selectedFileBytes,
    int? selectedFileSize,
    bool? isUploading,
    double? uploadProgress,
    String? error,
    DocumentModel? uploadedDocument,
  }) {
    return DocumentUploadState(
      selectedFileName: selectedFileName ?? this.selectedFileName,
      selectedFileBytes: selectedFileBytes ?? this.selectedFileBytes,
      selectedFileSize: selectedFileSize ?? this.selectedFileSize,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      error: error,
      uploadedDocument: uploadedDocument ?? this.uploadedDocument,
    );
  }
}

class DocumentUploadNotifier extends StateNotifier<DocumentUploadState> {
  final DocumentRepository _repository;

  DocumentUploadNotifier(this._repository) : super(const DocumentUploadState());

  void selectFile({
    required String fileName,
    required Uint8List bytes,
    required int size,
  }) {
    // Validate size (20 MB)
    if (size > 20 * 1024 * 1024) {
      state = const DocumentUploadState().copyWith(
        error: 'File too large. Maximum size is 20 MB.',
      );
      return;
    }

    // Validate type
    final ext = fileName.split('.').last.toLowerCase();
    if (!['pdf', 'png', 'jpg', 'jpeg'].contains(ext)) {
      state = const DocumentUploadState().copyWith(
        error: 'Unsupported file type. Use PDF, PNG, or JPG.',
      );
      return;
    }

    state = DocumentUploadState(
      selectedFileName: fileName,
      selectedFileBytes: bytes,
      selectedFileSize: size,
    );
  }

  Future<void> upload(String userId) async {
    if (!state.hasFile) return;

    state = state.copyWith(isUploading: true, error: null, uploadProgress: 0.1);

    try {
      state = state.copyWith(uploadProgress: 0.3);
      final doc = await _repository.uploadAndProcess(
        bytes: state.selectedFileBytes!,
        fileName: state.selectedFileName!,
        userId: userId,
      );
      state = state.copyWith(
        isUploading: false,
        uploadProgress: 1.0,
        uploadedDocument: doc,
      );
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        error: 'Upload failed: ${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }

  void reset() {
    state = const DocumentUploadState();
  }
}

final documentUploadProvider =
    StateNotifierProvider<DocumentUploadNotifier, DocumentUploadState>((ref) {
  final repo = ref.read(documentRepositoryProvider);
  return DocumentUploadNotifier(repo);
});

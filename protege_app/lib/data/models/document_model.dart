import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing an uploaded document with its processing status and metadata.
class DocumentModel {
  final String id;
  final String userId;
  final String fileName;
  final String fileType; // "pdf", "png", "jpg", "jpeg"
  final int fileSize;
  final int pageCount;
  final String status; // "processing", "ready", "failed"
  final String? summary;
  final List<String> keyTopics;
  final int chunkCount;
  final String? extractedTextPreview;
  final String? chromaCollectionId;
  final String? linkedPathId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? processingError;
  final int wordCount;

  DocumentModel({
    required this.id,
    required this.userId,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    this.pageCount = 0,
    this.status = 'processing',
    this.summary,
    this.keyTopics = const [],
    this.chunkCount = 0,
    this.extractedTextPreview,
    this.chromaCollectionId,
    this.linkedPathId,
    this.createdAt,
    this.updatedAt,
    this.processingError,
    this.wordCount = 0,
  });

  bool get isReady => status == 'ready';
  bool get isProcessing => const {
    'processing', 'extracting', 'chunking', 'embedding', 'storing', 'summarizing'
  }.contains(status);
  bool get isFailed => status == 'failed';

  /// Human-readable status label for progressive UI updates
  String get statusLabel {
    switch (status) {
      case 'processing': return 'Starting...';
      case 'extracting': return 'Extracting text...';
      case 'chunking': return 'Chunking document...';
      case 'embedding': return 'Generating embeddings...';
      case 'storing': return 'Storing vectors...';
      case 'summarizing': return 'Generating summary...';
      case 'ready': return 'Ready';
      case 'failed': return 'Failed';
      default: return 'Processing...';
    }
  }

  /// File size formatted as human-readable string
  String get fileSizeFormatted {
    if (fileSize < 1024) return '${fileSize}B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  factory DocumentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return DocumentModel.fromJson({...data, 'id': doc.id});
  }

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? json['userId'] ?? '',
      fileName: json['file_name'] ?? json['fileName'] ?? '',
      fileType: json['file_type'] ?? json['fileType'] ?? 'pdf',
      fileSize: json['file_size'] ?? json['fileSize'] ?? 0,
      pageCount: json['page_count'] ?? json['pageCount'] ?? 0,
      status: json['status'] ?? 'processing',
      summary: json['summary'],
      keyTopics: List<String>.from(json['key_topics'] ?? json['keyTopics'] ?? []),
      chunkCount: json['chunk_count'] ?? json['chunkCount'] ?? 0,
      extractedTextPreview: json['extracted_text_preview'] ?? json['extractedTextPreview'],
      chromaCollectionId: json['chroma_collection_id'] ?? json['chromaCollectionId'],
      linkedPathId: json['linked_path_id'] ?? json['linkedPathId'],
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']),
      processingError: json['processing_error'] ?? json['processingError'],
      wordCount: json['word_count'] ?? json['wordCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'file_name': fileName,
      'file_type': fileType,
      'file_size': fileSize,
      'page_count': pageCount,
      'status': status,
      'summary': summary,
      'key_topics': keyTopics,
      'chunk_count': chunkCount,
      'extracted_text_preview': extractedTextPreview,
      'chroma_collection_id': chromaCollectionId,
      'linked_path_id': linkedPathId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'processing_error': processingError,
      'word_count': wordCount,
    };
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

/// A chat message in a document Q&A conversation.
class DocumentChatMessage {
  final String role; // "user" or "assistant"
  final String content;
  final List<DocumentSource>? sources;
  final List<String>? followUpQuestions;
  final DateTime timestamp;

  DocumentChatMessage({
    required this.role,
    required this.content,
    this.sources,
    this.followUpQuestions,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}

/// A source reference cited in a RAG answer.
class DocumentSource {
  final int page;
  final String? section;
  final double relevanceScore;
  final String textSnippet;

  DocumentSource({
    required this.page,
    this.section,
    required this.relevanceScore,
    required this.textSnippet,
  });

  factory DocumentSource.fromJson(Map<String, dynamic> json) {
    return DocumentSource(
      page: json['page'] ?? 0,
      section: json['section'],
      relevanceScore: (json['relevance_score'] ?? json['relevanceScore'] ?? 0).toDouble(),
      textSnippet: json['text_snippet'] ?? json['textSnippet'] ?? '',
    );
  }
}

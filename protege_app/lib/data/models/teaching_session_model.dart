/// Teaching session model for reverse tutoring (Aha! Meter)
class TeachingSessionModel {
  final String id;
  final String userId;
  final String topicId;
  final String topic;
  final List<TeachingMessageModel> messages;
  final double ahaMeterScore; // 0.0 to 100.0
  final TeachingStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? feedback;

  const TeachingSessionModel({
    required this.id,
    required this.userId,
    required this.topicId,
    required this.topic,
    this.messages = const [],
    this.ahaMeterScore = 0.0,
    this.status = TeachingStatus.inProgress,
    required this.createdAt,
    this.completedAt,
    this.feedback,
  });

  factory TeachingSessionModel.fromJson(Map<String, dynamic> json) {
    return TeachingSessionModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      topicId: json['topicId'] as String,
      topic: json['topic'] as String,
      messages: (json['messages'] as List<dynamic>?)
              ?.map((e) => TeachingMessageModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      ahaMeterScore: (json['ahaMeterScore'] as num?)?.toDouble() ?? 0.0,
      status: TeachingStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TeachingStatus.inProgress,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      feedback: json['feedback'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'topicId': topicId,
      'topic': topic,
      'messages': messages.map((e) => e.toJson()).toList(),
      'ahaMeterScore': ahaMeterScore,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'feedback': feedback,
    };
  }

  TeachingSessionModel copyWith({
    String? id,
    String? userId,
    String? topicId,
    String? topic,
    List<TeachingMessageModel>? messages,
    double? ahaMeterScore,
    TeachingStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    String? feedback,
  }) {
    return TeachingSessionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      topicId: topicId ?? this.topicId,
      topic: topic ?? this.topic,
      messages: messages ?? this.messages,
      ahaMeterScore: ahaMeterScore ?? this.ahaMeterScore,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      feedback: feedback ?? this.feedback,
    );
  }

  /// Check if the user has demonstrated understanding
  bool get hasProvenUnderstanding => ahaMeterScore >= 80.0;
}

/// Individual message in a teaching session
class TeachingMessageModel {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final double? partialScore; // AI's evaluation of this explanation

  const TeachingMessageModel({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.partialScore,
  });

  factory TeachingMessageModel.fromJson(Map<String, dynamic> json) {
    return TeachingMessageModel(
      id: json['id'] as String,
      content: json['content'] as String,
      role: MessageRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => MessageRole.user,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      partialScore: (json['partialScore'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'role': role.name,
      'timestamp': timestamp.toIso8601String(),
      'partialScore': partialScore,
    };
  }
}

/// Message roles in teaching session
enum MessageRole {
  user,    // The learner (teaching the AI)
  ai,      // The AI (pretending to be confused student)
  system,  // System messages
}

/// Teaching session status
enum TeachingStatus {
  inProgress,
  completed,
  abandoned,
}

extension TeachingStatusExtension on TeachingStatus {
  String get displayName {
    switch (this) {
      case TeachingStatus.inProgress:
        return 'In Progress';
      case TeachingStatus.completed:
        return 'Completed';
      case TeachingStatus.abandoned:
        return 'Abandoned';
    }
  }
}

enum MessageRole { user, ai }

class TutorMessage {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;

  TutorMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
  });
}

class TutorState {
  final List<TutorMessage> messages;
  final bool isLoading;
  final String? error;
  final String sessionId;

  const TutorState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    required this.sessionId,
  });

  TutorState copyWith({
    List<TutorMessage>? messages,
    bool? isLoading,
    String? error,
    String? sessionId,
  }) {
    return TutorState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error, // Clear error if not provided? Or explicitly clear manually.
      sessionId: sessionId ?? this.sessionId,
    );
  }
}

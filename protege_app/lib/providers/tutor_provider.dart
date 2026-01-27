import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/tutor_models.dart';
import '../data/services/tutor_api_service.dart';
import 'api_provider.dart';

final tutorApiServiceProvider = Provider<TutorApiService>((ref) {
  return TutorApiService(ref.read(apiServiceProvider));
});

final tutorProvider = StateNotifierProvider<TutorNotifier, TutorState>((ref) {
  return TutorNotifier(ref.read(tutorApiServiceProvider));
});

class TutorNotifier extends StateNotifier<TutorState> {
  final TutorApiService _tutorService;

  TutorNotifier(this._tutorService)
      : super(TutorState(sessionId: 'session_${DateTime.now().millisecondsSinceEpoch}'));

  void initSession(String lessonId) {
    // Generate a consistent session ID for this lesson
    // Or just use a unique one per chat open.
    // For now, let's keep the existing session if it matches, else reset?
    // Let's just create a unique one for now to keep history clean/fresh or persist.
    // "session_id": "user123-lesson456" format is good.
    // But we don't have user ID handy here easily without auth provider.
    // Let's rely on random ID for now.
    // state = TutorState(sessionId: 'session_${DateTime.now().millisecondsSinceEpoch}');
  }

  Future<void> askQuestion({
    required String question,
    required String topic,
    required String lessonTitle,
    required List<String> keyConcepts,
    required String experienceLevel,
  }) async {
    if (question.trim().isEmpty) return;

    final userMsg = TutorMessage(
      id: DateTime.now().toString(),
      content: question,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );

    // Optimistic update
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      error: null,
    );

    try {
      final response = await _tutorService.askQuestion(
        sessionId: state.sessionId,
        question: question,
        topic: topic,
        lessonTitle: lessonTitle,
        keyConcepts: keyConcepts,
        experienceLevel: experienceLevel,
      );

      final aiMsg = TutorMessage(
        id: DateTime.now().toString(),
        content: response['response'],
        role: MessageRole.ai,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, aiMsg],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to get answer. Please try again.',
      );
    }
  }

  Future<void> clearConversation() async {
    try {
      await _tutorService.clearHistory(state.sessionId);
      state = state.copyWith(messages: []);
    } catch (e) {
      // ignore
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/api_service.dart';
import '../data/models/teaching_session_model.dart';
import '../core/constants/api_constants.dart';
import 'auth_provider.dart';
import 'learning_provider.dart';
import 'api_provider.dart'; // Import shared api provider

/// Teaching session state
class TeachingState {
  final TeachingSessionModel? session;
  final bool isLoading;
  final bool isEvaluating;
  final String? error;

  const TeachingState({
    this.session,
    this.isLoading = false,
    this.isEvaluating = false,
    this.error,
  });

  TeachingState copyWith({
    TeachingSessionModel? session,
    bool? isLoading,
    bool? isEvaluating,
    String? error,
  }) {
    return TeachingState(
      session: session ?? this.session,
      isLoading: isLoading ?? this.isLoading,
      isEvaluating: isEvaluating ?? this.isEvaluating,
      error: error,
    );
  }
}

/// Teaching session notifier
class TeachingNotifier extends StateNotifier<TeachingState> {
  final ApiService _apiService;
  final String? _userId;

  TeachingNotifier(this._apiService, this._userId)
      : super(const TeachingState());

  /// Start a new teaching session
  Future<void> startSession({
    required String topicId,
    required String topic,
  }) async {
    if (_userId == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiConstants.teachingSession,
        data: {
          'user_id': _userId,
          'topic_id': topicId,
          'topic': topic,
        },
      );

      final session = TeachingSessionModel.fromJson(response.data!);
      state = state.copyWith(session: session, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to start teaching session',
      );
    }
  }

  /// Send an explanation message
  Future<void> sendExplanation(String explanation) async {
    final currentSession = state.session;
    if (currentSession == null || _userId == null) return;

    // Add user message locally
    final userMessage = TeachingMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: explanation,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );

    final updatedMessages = [...currentSession.messages, userMessage];
    state = state.copyWith(
      session: currentSession.copyWith(messages: updatedMessages),
      isEvaluating: true,
    );

    try {
      // Send to AI for evaluation
      final responseObj = await _apiService.post<Map<String, dynamic>>(
        ApiConstants.teachingEvaluate,
        data: {
          'session_id': currentSession.id,
          'user_id': _userId,
          'explanation': explanation,
        },
      );
      
      final response = responseObj.data!;

      // AI response with evaluation
      final aiMessage = TeachingMessageModel(
        id: response['message_id'] as String,
        content: response['response'] as String,
        role: MessageRole.ai,
        timestamp: DateTime.now(),
        partialScore: (response['score'] as num?)?.toDouble(),
      );

      final newAhaMeterScore = (response['aha_meter_score'] as num).toDouble();
      final isComplete = response['is_complete'] as bool? ?? false;

      final finalMessages = [...updatedMessages, aiMessage];
      state = state.copyWith(
        session: currentSession.copyWith(
          messages: finalMessages,
          ahaMeterScore: newAhaMeterScore,
          status: isComplete ? TeachingStatus.completed : TeachingStatus.inProgress,
          completedAt: isComplete ? DateTime.now() : null,
          feedback: response['feedback'] as String?,
        ),
        isEvaluating: false,
      );
    } catch (e) {
      state = state.copyWith(
        isEvaluating: false,
        error: 'Failed to evaluate explanation',
      );
    }
  }

  /// End the session
  void endSession() {
    final currentSession = state.session;
    if (currentSession != null) {
      state = state.copyWith(
        session: currentSession.copyWith(
          status: TeachingStatus.abandoned,
          completedAt: DateTime.now(),
        ),
      );
    }
  }

  /// Reset the teaching state
  void reset() {
    state = const TeachingState();
  }
}

/// Teaching provider
final teachingProvider =
    StateNotifierProvider<TeachingNotifier, TeachingState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final currentUser = ref.watch(currentUserProvider);
  return TeachingNotifier(apiService, currentUser?.uid);
});

/// Aha Meter score provider
final ahaMeterScoreProvider = Provider<double>((ref) {
  final teachingState = ref.watch(teachingProvider);
  return teachingState.session?.ahaMeterScore ?? 0.0;
});

/// Teaching session completed provider
final teachingCompletedProvider = Provider<bool>((ref) {
  final teachingState = ref.watch(teachingProvider);
  return teachingState.session?.status == TeachingStatus.completed;
});

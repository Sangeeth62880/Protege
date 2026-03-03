import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/api_service.dart';
import '../data/models/teaching_session_model.dart';
import '../data/models/persona_model.dart';
import '../core/constants/api_constants.dart';
import 'auth_provider.dart';
import 'api_provider.dart';

/// Teaching session state
class TeachingState {
  final TeachingSessionModel? session;
  final List<PersonaModel> personas;
  final PersonaModel? selectedPersona;
  final bool isLoadingPersonas;
  final bool isLoading;
  final bool isEvaluating;
  final TeachingResultsModel? results;
  final String? error;

  const TeachingState({
    this.session,
    this.personas = const [],
    this.selectedPersona,
    this.isLoadingPersonas = false,
    this.isLoading = false,
    this.isEvaluating = false,
    this.results,
    this.error,
  });

  TeachingState copyWith({
    TeachingSessionModel? session,
    List<PersonaModel>? personas,
    PersonaModel? selectedPersona,
    bool? isLoadingPersonas,
    bool? isLoading,
    bool? isEvaluating,
    TeachingResultsModel? results,
    String? error,
    bool clearSelectedPersona = false,
    bool clearSession = false,
    bool clearResults = false,
  }) {
    return TeachingState(
      session: clearSession ? null : (session ?? this.session),
      personas: personas ?? this.personas,
      selectedPersona: clearSelectedPersona ? null : (selectedPersona ?? this.selectedPersona),
      isLoadingPersonas: isLoadingPersonas ?? this.isLoadingPersonas,
      isLoading: isLoading ?? this.isLoading,
      isEvaluating: isEvaluating ?? this.isEvaluating,
      results: clearResults ? null : (results ?? this.results),
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

  /// Load available personas
  Future<void> loadPersonas() async {
    state = state.copyWith(isLoadingPersonas: true, error: null);

    try {
      final response = await _apiService.get<List<dynamic>>(
        ApiConstants.teachingPersonas,
      );

      final personas = (response.data ?? [])
          .map((e) => PersonaModel.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        personas: personas,
        isLoadingPersonas: false,
      );
    } catch (e) {
      // Use offline personas as fallback
      state = state.copyWith(
        personas: PersonaData.personas,
        isLoadingPersonas: false,
      );
    }
  }

  /// Select a persona
  void selectPersona(PersonaModel persona) {
    state = state.copyWith(selectedPersona: persona);
  }

  /// Clear selected persona
  void clearPersonaSelection() {
    state = state.copyWith(clearSelectedPersona: true);
  }

  /// Start a new teaching session with selected persona
  Future<void> startSession({
    required String topicId,
    required String topic,
    List<String> conceptsToCover = const [],
  }) async {
    if (_userId == null) return;
    if (state.selectedPersona == null) {
      // Use default persona if none selected
      final defaultPersona = state.personas.isNotEmpty
          ? state.personas.first
          : PersonaData.personas.first;
      state = state.copyWith(selectedPersona: defaultPersona);
    }

    state = state.copyWith(isLoading: true, error: null, clearSession: true, clearResults: true);

    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiConstants.teachingSession,
        data: {
          'user_id': _userId,
          'topic_id': topicId,
          'topic': topic,
          'persona_id': state.selectedPersona!.id,
          'concepts_to_cover': conceptsToCover,
        },
      );

      final data = response.data!;
      
      // Create initial message from opening_message
      final initialMessage = TeachingMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: data['opening_message'] as String,
        role: MessageRole.ai,
        timestamp: DateTime.now(),
      );

      // Parse persona from response or use selected
      PersonaModel persona;
      if (data['persona'] != null) {
        persona = PersonaModel.fromJson(data['persona'] as Map<String, dynamic>);
      } else {
        persona = state.selectedPersona!;
      }

      final session = TeachingSessionModel(
        id: data['session_id'] as String,
        userId: _userId!,
        topicId: topicId,
        topic: topic,
        persona: persona,
        messages: [initialMessage],
        conceptsToCover: (data['concepts_to_cover'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            conceptsToCover,
        createdAt: DateTime.now(),
      );

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
        conceptsMentioned: (response['concepts_demonstrated'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
      );

      final newAhaMeterScore = (response['aha_score'] as num).toDouble();
      final isComplete = response['is_complete'] as bool? ?? false;

      // Parse breakdown
      final breakdownData = response['aha_breakdown'] as Map<String, dynamic>?;
      final ahaBreakdown = breakdownData != null
          ? AhaBreakdown.fromJson(breakdownData)
          : const AhaBreakdown();

      // Update concepts covered
      final newConceptsCovered = [
        ...currentSession.conceptsCovered,
        ...(response['concepts_demonstrated'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
      ].toSet().toList();

      final finalMessages = [...updatedMessages, aiMessage];
      state = state.copyWith(
        session: currentSession.copyWith(
          messages: finalMessages,
          ahaMeterScore: newAhaMeterScore,
          ahaBreakdown: ahaBreakdown,
          conceptsCovered: newConceptsCovered,
          status: isComplete ? TeachingStatus.completed : TeachingStatus.inProgress,
          completedAt: isComplete ? DateTime.now() : null,
          feedback: response['feedback'] as String?,
        ),
        isEvaluating: false,
      );

      // If complete, fetch detailed results
      if (isComplete) {
        await fetchResults();
      }
    } catch (e) {
      state = state.copyWith(
        isEvaluating: false,
        error: 'Failed to evaluate explanation',
      );
    }
  }

  /// Fetch detailed session results
  Future<void> fetchResults() async {
    final currentSession = state.session;
    if (currentSession == null) return;

    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '${ApiConstants.teachingResults}/${currentSession.id}',
      );

      if (response.data != null) {
        final results = TeachingResultsModel.fromJson(response.data!);
        state = state.copyWith(results: results);
      }
    } catch (e) {
      // Results fetch failed, but session is still complete
      // Create basic results from session data
      final results = TeachingResultsModel(
        sessionId: currentSession.id,
        topic: currentSession.topic,
        personaName: currentSession.persona?.name ?? 'Student',
        finalScore: currentSession.ahaMeterScore.toInt(),
        ahaBreakdown: currentSession.ahaBreakdown,
        conceptsCovered: currentSession.conceptsCovered,
        feedback: currentSession.feedback ?? 'Great job completing the teaching session!',
      );
      state = state.copyWith(results: results);
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

/// Aha breakdown provider
final ahaBreakdownProvider = Provider<AhaBreakdown>((ref) {
  final teachingState = ref.watch(teachingProvider);
  return teachingState.session?.ahaBreakdown ?? const AhaBreakdown();
});

/// Teaching session completed provider
final teachingCompletedProvider = Provider<bool>((ref) {
  final teachingState = ref.watch(teachingProvider);
  return teachingState.session?.status == TeachingStatus.completed;
});

/// Selected persona provider
final selectedPersonaProvider = Provider<PersonaModel?>((ref) {
  final teachingState = ref.watch(teachingProvider);
  return teachingState.selectedPersona;
});

/// Available personas provider
final personasProvider = Provider<List<PersonaModel>>((ref) {
  final teachingState = ref.watch(teachingProvider);
  return teachingState.personas.isNotEmpty
      ? teachingState.personas
      : PersonaData.personas;
});

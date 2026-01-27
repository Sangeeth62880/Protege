import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/resource_models.dart';
import '../data/services/resource_api_service.dart';
import 'api_provider.dart';

/// State for the Resource Provider
class ResourceState {
  final bool isLoading;
  final LessonResources? resources;
  final String? error;

  const ResourceState({
    this.isLoading = false,
    this.resources,
    this.error,
  });

  ResourceState copyWith({
    bool? isLoading,
    LessonResources? resources,
    String? error,
  }) {
    return ResourceState(
      isLoading: isLoading ?? this.isLoading,
      resources: resources ?? this.resources,
      error: error, // Nullifiable
    );
  }
}

/// Resource Provider Family
/// Uniquely identified by lessonTitle to allow caching per lesson
final resourceProvider =
    StateNotifierProvider.family<ResourceNotifier, ResourceState, String>(
        (ref, lessonTitle) {
  final apiService = ResourceApiService(ref.watch(apiServiceProvider));
  return ResourceNotifier(apiService, lessonTitle);
});

class ResourceNotifier extends StateNotifier<ResourceState> {
  final ResourceApiService _apiService;
  final String lessonTitle;

  ResourceNotifier(this._apiService, this.lessonTitle)
      : super(const ResourceState());

  Future<void> loadResources({
    required Map<String, String> searchQueries,
    bool forceRefresh = false,
  }) async {
    // If we already have resources and not forcing refresh, do nothing
    if (state.resources != null && !forceRefresh) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final resources = await _apiService.curateResources(
        lessonTitle: lessonTitle,
        searchQueries: searchQueries,
      );
      state = state.copyWith(isLoading: false, resources: resources);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

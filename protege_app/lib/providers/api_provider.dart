import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/api_service.dart';
import '../data/services/auth_api_service.dart';
import 'auth_provider.dart';

/// API Service provider
final apiServiceProvider = Provider<ApiService>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return ApiService(authRepository: authRepository);
});

/// Auth API Service provider
final authApiServiceProvider = Provider<AuthApiService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AuthApiService(apiService);
});

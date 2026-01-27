import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/services/firebase_service.dart';
import '../data/services/auth_api_service.dart'; // Import AuthApiService
import '../data/repositories/auth_repository.dart';
import '../data/models/user_model.dart';
import '../core/utils/result.dart';
import '../firebase_options.dart';
import '../data/repositories/mock_auth_repository.dart';
import 'api_provider.dart'; // Import for authApiServiceProvider

/// Firebase service provider
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

/// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  // Check for missing configuration (Demo Mode)
  final apiKey = DefaultFirebaseOptions.currentPlatform.apiKey;
  if (apiKey.contains('YOUR_') || apiKey.isEmpty) {
    return MockAuthRepository();
  }

  final firebaseService = ref.watch(firebaseServiceProvider);
  return AuthRepository(firebaseService: firebaseService);
});

/// Auth state stream provider
final authStateProvider = StreamProvider<User?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges;
});

/// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

/// Auth state notifier
class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthRepository _authRepository;
  final AuthApiService _authApiService; // Add api service dependency

  AuthNotifier(this._authRepository, this._authApiService) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    _authRepository.authStateChanges.listen((user) async {
      if (user != null) {
        try {
          final result = await _authRepository.getCurrentUserModel();
          result.when(
            success: (userModel) {
              state = AsyncValue.data(userModel);
              // Verify backend token in background
              _verifyBackend();
            },
            failure: (message, error) {
              state = AsyncValue.error(message, StackTrace.current);
            },
          );
        } catch (e, st) {
          state = AsyncValue.error(e, st);
        }
      } else {
        state = const AsyncValue.data(null);
      }
    });
  }
  
  Future<void> _verifyBackend() async {
    try {
      await _authApiService.verifyToken();
    } catch (_) {
      // Background failure is ok
    }
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    final result = await _authRepository.signInWithEmail(email, password);
    result.when(
      success: (user) {
        state = AsyncValue.data(user);
      },
      failure: (message, error) {
        state = AsyncValue.error(message, StackTrace.current);
      },
    );
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AsyncValue.loading();
    final result = await _authRepository.signUpWithEmail(
      email: email,
      password: password,
      displayName: displayName,
    );
    result.when(
      success: (user) {
        state = AsyncValue.data(user);
      },
      failure: (message, error) {
        state = AsyncValue.error(message, StackTrace.current);
      },
    );
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    final result = await _authRepository.signInWithGoogle();
    result.when(
      success: (user) {
        state = AsyncValue.data(user);
      },
      failure: (message, error) {
        state = AsyncValue.error(message, StackTrace.current);
      },
    );
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
    state = const AsyncValue.data(null);
  }

  Future<Result<void>> sendPasswordReset(String email) async {
    return await _authRepository.sendPasswordResetEmail(email);
  }
}

/// Auth notifier provider
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final authApiService = ref.watch(authApiServiceProvider); // Get api service
  return AuthNotifier(authRepository, authApiService);
});

/// Is authenticated provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

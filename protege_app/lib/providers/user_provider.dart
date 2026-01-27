import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/user_repository.dart';
import '../data/models/user_model.dart';
import 'auth_provider.dart';

/// User repository provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return UserRepository(firebaseService: firebaseService);
});

/// Current user data provider
final userDataProvider = FutureProvider<UserModel?>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return null;
  
  final userRepo = ref.watch(userRepositoryProvider);
  return await userRepo.getUserById(currentUser.uid);
});

/// User stream provider for real-time updates
final userStreamProvider = StreamProvider<UserModel?>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    return Stream.value(null);
  }
  
  final userRepo = ref.watch(userRepositoryProvider);
  return userRepo.streamUser(currentUser.uid);
});

/// User notifier for updates
class UserNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final UserRepository _userRepository;
  final String? _userId;

  UserNotifier(this._userRepository, this._userId)
      : super(const AsyncValue.loading()) {
    if (_userId != null) {
      _loadUser();
    } else {
      state = const AsyncValue.data(null);
    }
  }

  Future<void> _loadUser() async {
    if (_userId == null) return;
    try {
      final user = await _userRepository.getUserById(_userId!);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    final currentUser = state.valueOrNull;
    if (currentUser == null) return;

    state = const AsyncValue.loading();
    try {
      final updatedUser = currentUser.copyWith(
        displayName: displayName ?? currentUser.displayName,
        photoUrl: photoUrl ?? currentUser.photoUrl,
      );
      await _userRepository.updateUser(updatedUser);
      state = AsyncValue.data(updatedUser);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updatePreferences(Map<String, dynamic> preferences) async {
    if (_userId == null) return;
    try {
      await _userRepository.updatePreferences(_userId!, preferences);
      await _loadUser(); // Reload user data
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// User notifier provider
final userNotifierProvider =
    StateNotifierProvider<UserNotifier, AsyncValue<UserModel?>>((ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  final currentUser = ref.watch(currentUserProvider);
  return UserNotifier(userRepository, currentUser?.uid);
});

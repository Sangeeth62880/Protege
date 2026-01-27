import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:uuid/uuid.dart';
import '../../core/utils/result.dart';
import '../models/user_model.dart';
import 'auth_repository.dart';

/// A Mock implementation of AuthRepository for development/demo purposes
/// when real Firebase configuration is missing.
class MockAuthRepository implements AuthRepository {
  final _controller = StreamController<User?>.broadcast();
  UserModel? _currentUser;
  bool _isLoggedIn = false;

  MockAuthRepository() {
    _controller.add(null);
  }

  @override
  Stream<User?> get authStateChanges => _controller.stream;

  @override
  User? get currentUser => null; 

  @override
  bool get isAuthenticated => _isLoggedIn;

  @override
  Future<Result<UserModel?>> getCurrentUserModel() async {
    return Result.success(_currentUser);
  }

  @override
  Future<String?> getIdToken() async => 'mock_demo_token';

  @override
  Future<Result<void>> sendPasswordResetEmail(String email) async {
    await Future.delayed(const Duration(seconds: 1));
    return Result.success(null);
  }

  @override
  Future<Result<UserModel>> signInWithEmail(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    return _login(email: email, name: 'Demo User');
  }

  @override
  Future<Result<UserModel>> signInWithGoogle() async {
    await Future.delayed(const Duration(seconds: 1));
    return _login(email: 'demo.google@example.com', name: 'Google Demo User');
  }

  @override
  Future<Result<void>> signOut() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
    _isLoggedIn = false;
    _controller.add(null);
    return Result.success(null);
  }

  @override
  Future<Result<UserModel>> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    return _login(email: email, name: displayName);
  }

  Result<UserModel> _login({required String email, required String name}) {
    _currentUser = UserModel(
      id: "demo_${const Uuid().v4()}",
      email: email,
      displayName: name,
      photoUrl: null,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
    _isLoggedIn = true;
    return Result.success(_currentUser!);
  }
}

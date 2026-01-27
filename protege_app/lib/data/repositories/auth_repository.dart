import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/firebase_service.dart';
import '../models/user_model.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/result.dart';

/// Repository for authentication operations
class AuthRepository {
  final FirebaseService _firebaseService;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AuthRepository({required FirebaseService firebaseService})
      : _firebaseService = firebaseService;

  /// Get current user
  User? get currentUser => _firebaseService.currentUser;

  /// Auth state stream
  Stream<User?> get authStateChanges => _firebaseService.authStateChanges;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Sign in with email and password
  Future<Result<UserModel>> signInWithEmail(String email, String password) async {
    try {
      final credential = await _firebaseService.signInWithEmail(email, password);
      final user = credential.user!;
      
      // Update last login
      await _firebaseService.updateDoc(
        'users/${user.uid}',
        {'lastLoginAt': DateTime.now()},
      );
      
      // Fetch user data
      final doc = await _firebaseService.getDoc('users/${user.uid}');
      if (doc.exists) {
        return Result.success(UserModel.fromJson(doc.data()!));
      } else {
        // Create user if doesn't exist
        final newUser = await _createUserDocument(user, user.displayName ?? 'Learner');
        return Result.success(newUser);
      }
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Sign in failed', tag: 'AuthRepo', error: e);
      return Result.failure(_getAuthErrorMessage(e.code), e);
    } catch (e) {
      AppLogger.error('Sign in failed', tag: 'AuthRepo', error: e);
      return Result.failure('An unexpected error occurred', e);
    }
  }

  /// Sign up with email and password
  Future<Result<UserModel>> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _firebaseService.signUpWithEmail(email, password);
      final user = credential.user!;
      
      // Update display name
      await user.updateDisplayName(displayName);
      
      // Create user document
      final userModel = await _createUserDocument(user, displayName);
      
      AppLogger.success('User created: $email', tag: 'AuthRepo');
      return Result.success(userModel);
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Sign up failed', tag: 'AuthRepo', error: e);
      return Result.failure(_getAuthErrorMessage(e.code), e);
    } catch (e) {
      AppLogger.error('Sign up failed', tag: 'AuthRepo', error: e);
      return Result.failure('An unexpected error occurred', e);
    }
  }

  /// Sign in with Google
  Future<Result<UserModel>> signInWithGoogle() async {
    try {
      // Trigger Google Sign In
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return Result.failure('Google sign in was cancelled');
      }
      
      // Get auth details
      final googleAuth = await googleUser.authentication;
      
      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Sign in to Firebase
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user!;
      
      // Check if user exists in Firestore
      final doc = await _firebaseService.getDoc('users/${user.uid}');
      if (doc.exists) {
        // Update last login
        await _firebaseService.updateDoc(
          'users/${user.uid}',
          {'lastLoginAt': DateTime.now()},
        );
        return Result.success(UserModel.fromJson(doc.data()!));
      } else {
        // Create new user
        final userModel = await _createUserDocument(
          user,
          user.displayName ?? googleUser.displayName ?? 'Learner',
        );
        return Result.success(userModel);
      }
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Google sign in failed', tag: 'AuthRepo', error: e);
      return Result.failure(_getAuthErrorMessage(e.code), e);
    } catch (e) {
      AppLogger.error('Google sign in failed', tag: 'AuthRepo', error: e);
      return Result.failure('Failed to sign in with Google', e);
    }
  }

  /// Sign out
  Future<Result<void>> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _firebaseService.signOut();
      return Result.success(null);
    } catch (e) {
      AppLogger.error('Sign out failed', tag: 'AuthRepo', error: e);
      return Result.failure('Failed to sign out', e);
    }
  }

  /// Get ID token for API requests
  Future<String?> getIdToken() async {
    return await _firebaseService.getIdToken();
  }

  /// Send password reset email
  Future<Result<void>> sendPasswordResetEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      AppLogger.info('Password reset email sent to $email', tag: 'AuthRepo');
      return Result.success(null);
    } on FirebaseAuthException catch (e) {
      return Result.failure(_getAuthErrorMessage(e.code), e);
    } catch (e) {
      return Result.failure('Failed to send reset email', e);
    }
  }

  /// Get current user model
  Future<Result<UserModel?>> getCurrentUserModel() async {
    final user = currentUser;
    if (user == null) {
      return Result.success(null);
    }
    
    try {
      final doc = await _firebaseService.getDoc('users/${user.uid}');
      if (doc.exists) {
        return Result.success(UserModel.fromJson(doc.data()!));
      }
      return Result.success(null);
    } catch (e) {
      return Result.failure('Failed to get user data', e);
    }
  }

  /// Create user document in Firestore
  Future<UserModel> _createUserDocument(User user, String displayName) async {
    final userModel = UserModel(
      id: user.uid,
      email: user.email ?? '',
      displayName: displayName,
      photoUrl: user.photoURL,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
    
    await _firebaseService.setDoc('users/${user.uid}', userModel.toJson());
    return userModel;
  }

  /// Convert Firebase auth error codes to user-friendly messages
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'weak-password':
        return 'Password is too weak';
      case 'operation-not-allowed':
        return 'This sign in method is not enabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'invalid-credential':
        return 'Invalid email or password';
      default:
        return 'Authentication failed. Please try again';
    }
  }
}

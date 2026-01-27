import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/logger.dart';

/// Firebase service for Auth and Firestore operations
class FirebaseService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirebaseService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  // ============ AUTH ============

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email and password
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      AppLogger.success('User signed in: ${credential.user?.email}', tag: 'Auth');
      return credential;
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Sign in failed', tag: 'Auth', error: e);
      rethrow;
    }
  }

  /// Sign up with email and password
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      AppLogger.success('User created: ${credential.user?.email}', tag: 'Auth');
      return credential;
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Sign up failed', tag: 'Auth', error: e);
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    AppLogger.info('User signed out', tag: 'Auth');
  }

  /// Get ID token for API requests
  Future<String?> getIdToken() async {
    return await currentUser?.getIdToken();
  }

  // ============ FIRESTORE ============

  /// Get a collection reference
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _firestore.collection(path);
  }

  /// Get a document reference
  DocumentReference<Map<String, dynamic>> doc(String path) {
    return _firestore.doc(path);
  }

  /// Get a document
  Future<DocumentSnapshot<Map<String, dynamic>>> getDoc(String path) async {
    return await _firestore.doc(path).get();
  }

  /// Set a document
  Future<void> setDoc(
    String path,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    await _firestore.doc(path).set(data, SetOptions(merge: merge));
  }

  /// Update a document
  Future<void> updateDoc(String path, Map<String, dynamic> data) async {
    await _firestore.doc(path).update(data);
  }

  /// Delete a document
  Future<void> deleteDoc(String path) async {
    await _firestore.doc(path).delete();
  }

  /// Query a collection
  Future<QuerySnapshot<Map<String, dynamic>>> queryCollection(
    String path, {
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    Query<Map<String, dynamic>> query = _firestore.collection(path);

    if (filters != null) {
      for (final filter in filters) {
        query = query.where(
          filter.field,
          isEqualTo: filter.isEqualTo,
          isNotEqualTo: filter.isNotEqualTo,
          isLessThan: filter.isLessThan,
          isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
          isGreaterThan: filter.isGreaterThan,
          isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
          arrayContains: filter.arrayContains,
          whereIn: filter.whereIn,
        );
      }
    }

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return await query.get();
  }

  /// Listen to a document
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamDoc(String path) {
    return _firestore.doc(path).snapshots();
  }

  /// Listen to a collection
  Stream<QuerySnapshot<Map<String, dynamic>>> streamCollection(String path) {
    return _firestore.collection(path).snapshots();
  }
}

/// Query filter helper
class QueryFilter {
  final String field;
  final dynamic isEqualTo;
  final dynamic isNotEqualTo;
  final dynamic isLessThan;
  final dynamic isLessThanOrEqualTo;
  final dynamic isGreaterThan;
  final dynamic isGreaterThanOrEqualTo;
  final dynamic arrayContains;
  final List<dynamic>? whereIn;

  QueryFilter({
    required this.field,
    this.isEqualTo,
    this.isNotEqualTo,
    this.isLessThan,
    this.isLessThanOrEqualTo,
    this.isGreaterThan,
    this.isGreaterThanOrEqualTo,
    this.arrayContains,
    this.whereIn,
  });
}

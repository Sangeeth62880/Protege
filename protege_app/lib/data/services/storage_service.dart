import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/logger.dart';

/// Local storage service using SharedPreferences
class StorageService {
  SharedPreferences? _prefs;

  /// Initialize the storage service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    AppLogger.success('StorageService initialized', tag: 'Storage');
  }

  /// Check if initialized
  bool get isInitialized => _prefs != null;

  // ============ STRING ============

  /// Get a string value
  String? getString(String key) {
    return _prefs?.getString(key);
  }

  /// Set a string value
  Future<bool> setString(String key, String value) async {
    return await _prefs?.setString(key, value) ?? false;
  }

  // ============ BOOL ============

  /// Get a bool value
  bool? getBool(String key) {
    return _prefs?.getBool(key);
  }

  /// Set a bool value
  Future<bool> setBool(String key, bool value) async {
    return await _prefs?.setBool(key, value) ?? false;
  }

  // ============ INT ============

  /// Get an int value
  int? getInt(String key) {
    return _prefs?.getInt(key);
  }

  /// Set an int value
  Future<bool> setInt(String key, int value) async {
    return await _prefs?.setInt(key, value) ?? false;
  }

  // ============ DOUBLE ============

  /// Get a double value
  double? getDouble(String key) {
    return _prefs?.getDouble(key);
  }

  /// Set a double value
  Future<bool> setDouble(String key, double value) async {
    return await _prefs?.setDouble(key, value) ?? false;
  }

  // ============ STRING LIST ============

  /// Get a string list
  List<String>? getStringList(String key) {
    return _prefs?.getStringList(key);
  }

  /// Set a string list
  Future<bool> setStringList(String key, List<String> value) async {
    return await _prefs?.setStringList(key, value) ?? false;
  }

  // ============ UTILITY ============

  /// Remove a value
  Future<bool> remove(String key) async {
    return await _prefs?.remove(key) ?? false;
  }

  /// Clear all values
  Future<bool> clear() async {
    return await _prefs?.clear() ?? false;
  }

  /// Check if key exists
  bool containsKey(String key) {
    return _prefs?.containsKey(key) ?? false;
  }

  // ============ APP SPECIFIC KEYS ============

  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyThemeMode = 'theme_mode';
  static const String keyLastLearningPathId = 'last_learning_path_id';
  static const String keyNotificationsEnabled = 'notifications_enabled';

  /// Check if onboarding is complete
  bool get isOnboardingComplete => getBool(keyOnboardingComplete) ?? false;

  /// Set onboarding complete
  Future<void> setOnboardingComplete() async {
    await setBool(keyOnboardingComplete, true);
  }

  /// Get theme mode (light/dark/system)
  String get themeMode => getString(keyThemeMode) ?? 'system';

  /// Set theme mode
  Future<void> setThemeMode(String mode) async {
    await setString(keyThemeMode, mode);
  }
}

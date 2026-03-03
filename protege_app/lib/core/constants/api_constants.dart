class ApiConstants {
  // ═══════════════════════════════════════════════════════════════════════════
  // BASE URL CONFIGURATION
  // ═══════════════════════════════════════════════════════════════════════════
  // 
  // INSTRUCTIONS:
  // 1. For Android Emulator: Use 'http://10.0.2.2:8000'
  // 2. For iOS Simulator / Web (Chrome): Use 'http://localhost:8000'  
  // 3. For Physical Device: Use your computer's local IP
  //    - Run: ifconfig | grep "inet " | grep -v 127.0.0.1
  //    - Look for 192.168.x.x address
  //
  // ⚠️ Web (Chrome) is auto-detected — always uses localhost.
  // ═══════════════════════════════════════════════════════════════════════════

  // Device-specific URLs
  static const String _androidEmulatorUrl = 'http://10.0.2.2:8000';
  static const String _iosSimulatorUrl = 'http://localhost:8000';
  static const String _webUrl = 'http://localhost:8000';
  static const String _physicalDeviceUrl = 'http://172.16.145.19:8000'; // Updated IP
  
  // Production URL (for deployed backend)
  static const String _productionUrl = 'https://protege-backend.onrailway.app';

  // ═══════════════════════════════════════════════════════════════════════════
  // SELECT YOUR ENVIRONMENT HERE (applies to native only; web is auto-detected):
  // ═══════════════════════════════════════════════════════════════════════════
  static const _Environment _currentEnv = _Environment.androidEmulator;
  
  static String get baseUrl {
    // Web (Chrome) always uses localhost — no 10.0.2.2 needed
    if (_isWeb) return _webUrl;

    switch (_currentEnv) {
      case _Environment.androidEmulator:
        return _androidEmulatorUrl;
      case _Environment.iosSimulator:
        return _iosSimulatorUrl;
      case _Environment.physicalDevice:
        return _physicalDeviceUrl;
      case _Environment.production:
        return _productionUrl;
    }
  }

  // Can't use kIsWeb directly in a const context, so we use a static getter
  static bool get _isWeb {
    return const bool.fromEnvironment('dart.library.js_util', defaultValue: false) ||
           identical(0, 0.0); // true on web, false on native
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // API ENDPOINTS
  // ═══════════════════════════════════════════════════════════════════════════
  
  // Health
  static const String health = '/health';
  
  // Auth
  static const String authVerify = '/api/v1/auth/verify';
  static const String authProfile = '/api/v1/auth/profile';
  
  // Learning
  static const String learningPaths = '/api/v1/learning/paths';
  static const String generatePath = '/api/v1/learning/generate';
  static const String generatePathTest = '/api/v1/learning/generate-syllabus-test';
  static const String savePath = '/api/v1/learning/save';
  static const String savePathTest = '/api/v1/learning/save-test';
  
  // Resources
  static const String resources = '/api/v1/resources';
  static const String curateResources = '/api/v1/resources/curate';
  static const String curateResourcesTest = '/api/v1/resources/curate-test';
  
  // Quiz
  static const String quizGenerate = '/api/v1/quiz/generate';
  static const String quizSubmit = '/api/v1/quiz/submit';

  // Teaching (Phase 5)
  static const String teachingPersonas = '/api/v1/teaching/personas';
  static const String teachingSession = '/api/v1/teaching/session';
  static const String teachingEvaluate = '/api/v1/teaching/evaluate';
  static const String teachingResults = '/api/v1/teaching/results';

  // Documents (RAG Feature)
  static const String documentsUpload = '/api/v1/documents/upload';
  static const String documentsList = '/api/v1/documents/';
  static const String documentsBase = '/api/v1/documents';

  // Lesson Content & Completion
  static const String lessonContent = '/api/v1/learning/lesson-content';
  static const String completeLesson = '/api/v1/learning/complete-lesson';
}

// Environment enum for cleaner switching
enum _Environment {
  androidEmulator,
  iosSimulator,
  physicalDevice,
  production,
}

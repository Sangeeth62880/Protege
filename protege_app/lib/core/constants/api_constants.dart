class ApiConstants {
  // Base URLs
  // Use 10.0.2.2 for Android Emulator, localhost/127.0.0.1 for iOS Simulator
  // Or your computer's local IP address for physical devices
  static const String devBaseUrl = 'http://192.168.29.25:8000'; // Local IP 
  static const String prodBaseUrl = 'https://protege-backend.onrailway.app'; // Placeholder
  
  static String get baseUrl {
    // Logic to switch environments can be added here
    return devBaseUrl;
  }
  
  // Endpoints
  static const String health = '/health';
  
  // Auth
  static const String authVerify = '/api/v1/auth/verify';
  static const String authProfile = '/api/v1/auth/profile';
  
  // Learning
  static const String learningPaths = '/api/v1/learning/paths';
  static const String generatePath = '/api/v1/learning/generate';
  static const String savePath = '/api/v1/learning/save';
  
  // Resources
  static const String resources = '/api/v1/resources';
  
  // Quiz
  static const String quizGenerate = '/api/v1/quiz/generate';
  static const String quizSubmit = '/api/v1/quiz/submit';

  // Teaching
  static const String teachingSession = '/api/v1/teaching/session';
  static const String teachingEvaluate = '/api/v1/teaching/evaluate';
}

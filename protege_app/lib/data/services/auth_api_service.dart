import 'package:dio/dio.dart';
import 'package:protege_app/data/models/user_model.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/result.dart';
import 'api_service.dart';

/// Service for auth-related API calls
class AuthApiService {
  final ApiService _apiService;

  AuthApiService(this._apiService);

  /// Verify token with backend
  Future<Result<void>> verifyToken() async {
    try {
      await _apiService.post(ApiConstants.authVerify);
      return Result.success(null);
    } catch (e) {
      return Result.failure('Token verification failed', e);
    }
  }

  /// Update user profile on backend
  Future<Result<UserModel>> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.put<Map<String, dynamic>>(
        ApiConstants.authProfile, // Note: Endpoint might need adjustment based on backend
        data: data,
      );
      
      if (response.data != null && response.data!['user'] != null) {
        return Result.success(UserModel.fromJson(response.data!['user']));
      }
      
      return Result.failure('Failed to parse profile update response');
    } catch (e) {
      return Result.failure('Profile update failed', e);
    }
  }
}

// Auth-related API calls (login, etc.) using ApiClient.
import '../../../core/api/api_client.dart';
import '../models/auth_user.dart';

class AuthApiService {
  AuthApiService(this._apiClient);

  final ApiClient _apiClient;

  Future<void> sendCommonFacilitiesForgotPasswordOtp({
    required String email,
  }) async {
    await _apiClient.post(
      '/api/auth/common-facilities/forgot-password/send-otp',
      body: {'email': email},
    );
  }

  Future<String> verifyCommonFacilitiesForgotPasswordOtp({
    required String email,
    required String otp,
  }) async {
    final data =
        await _apiClient.post(
              '/api/auth/common-facilities/forgot-password/verify-otp',
              body: {'email': email, 'otp': otp},
            )
            as Map<String, dynamic>;

    return data['resetToken']?.toString() ?? '';
  }

  Future<void> resetCommonFacilitiesPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    await _apiClient.post(
      '/api/auth/common-facilities/forgot-password/reset-password',
      body: {'resetToken': resetToken, 'newPassword': newPassword},
    );
  }

  Future<Map<String, dynamic>> requestCommonFacilitiesAccount({
    required String name,
    required String category,
    required String email,
    required String password,
  }) async {
    final data =
        await _apiClient.post(
              '/api/auth/common-facilities/request',
              body: {
                'name': name,
                'category': category,
                'email': email,
                'password': password,
              },
            )
            as Map<String, dynamic>;

    return data;
  }

  Future<AuthUser> login({
    required UserRole role,
    required String loginId,
    required String password,
  }) async {
    final data =
        await _apiClient.post(
              '/api/auth/login',
              body: {
                'role': role.value,
                'loginId': loginId,
                'password': password,
              },
            )
            as Map<String, dynamic>;

    return AuthUser.fromJson(data);
  }
}

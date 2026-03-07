// Auth-related API calls (login, etc.) using ApiClient.
import '../../../core/api/api_client.dart';
import '../models/auth_user.dart';

class AuthApiService {
  AuthApiService(this._apiClient);

  final ApiClient _apiClient;

  Future<AuthUser> login({
    required UserRole role,
    required String loginId,
    required String password,
  }) async {
    final data = await _apiClient.post(
      '/api/auth/login',
      body: {
        'role': role.value,
        'loginId': loginId,
        'password': password,
      },
    ) as Map<String, dynamic>;

    return AuthUser.fromJson(data);
  }
}

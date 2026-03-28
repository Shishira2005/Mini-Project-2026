
import '../../../core/api/api_client.dart';
import '../models/swap_models.dart';

class SwapApiService {
  SwapApiService(this._apiClient);

  final ApiClient _apiClient;

  Future<void> clearAllSwapHistory() async {
    await _apiClient.delete('/api/swap/history');
  }

  Future<SwapOptionsResult> fetchSwapOptions({
    required String facultyId,
    required String date,
    required String startTime,
    required String endTime,
    required bool projectorRequired,
  }) async {
    final data = await _apiClient.get(
      '/api/swap/options',
      query: {
        'facultyId': facultyId,
        'date': date,
        'startTime': startTime,
        'endTime': endTime,
        'projectorRequired': '$projectorRequired',
      },
    ) as Map<String, dynamic>;

    return SwapOptionsResult.fromJson(data);
  }

  Future<SwapRequestModel> createSwapRequest({
    required String date,
    required String startTime,
    required String endTime,
    required bool projectorRequired,
    required String requesterFacultyId,
    required String requesterFacultyName,
    required String requesterClassroomName,
    required String targetClassroomName,
    required String targetFacultyId,
    required String targetFacultyName,
    required String reason,
  }) async {
    final data = await _apiClient.post(
      '/api/swap/requests',
      body: {
        'date': date,
        'startTime': startTime,
        'endTime': endTime,
        'projectorRequired': projectorRequired,
        'requesterFacultyId': requesterFacultyId,
        'requesterFacultyName': requesterFacultyName,
        'requesterClassroomName': requesterClassroomName,
        'targetClassroomName': targetClassroomName,
        'targetFacultyId': targetFacultyId,
        'targetFacultyName': targetFacultyName,
        'reason': reason,
      },
    ) as Map<String, dynamic>;

    return SwapRequestModel.fromJson(data);
  }

  Future<List<SwapRequestModel>> fetchHistory({String? facultyId}) async {
    final data = await _apiClient.get(
      '/api/swap/history',
      query: facultyId != null ? {'facultyId': facultyId} : null,
    ) as Map<String, dynamic>;

    final list = data['history'] as List<dynamic>? ?? <dynamic>[];
    return list
        .map((e) => SwapRequestModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<SwapRequestModel>> fetchNotifications({
    required String facultyId,
  }) async {
    final data = await _apiClient.get(
      '/api/swap/notifications',
      query: {'facultyId': facultyId},
    ) as Map<String, dynamic>;

    final list = data['notifications'] as List<dynamic>? ?? <dynamic>[];
    return list
        .map((e) => SwapRequestModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SwapRequestModel> updateRequestStatus({
    required String requestId,
    required String action,
  }) async {
    final data = await _apiClient.patch(
      '/api/swap/requests/$requestId',
      body: {'action': action},
    ) as Map<String, dynamic>;

    return SwapRequestModel.fromJson(data);
  }
}

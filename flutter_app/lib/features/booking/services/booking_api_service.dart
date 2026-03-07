// Booking-related API calls for classrooms and reservations.
import '../../../core/api/api_client.dart';
import '../models/booking_model.dart';
import '../models/classroom_model.dart';

class BookingApiService {
  BookingApiService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<ClassroomModel>> fetchClassrooms() async {
    final data = await _apiClient.get('/api/classrooms') as List<dynamic>;
    return data
        .map((json) => ClassroomModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<dynamic>> checkAvailability({
    required String date,
    required String startTime,
    required String endTime,
    int? minCapacity,
    bool? projector,
    String? type,
  }) async {
    final query = <String, String>{
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
    };

    if (minCapacity != null) {
      query['minCapacity'] = '$minCapacity';
    }
    if (projector != null) {
      query['projector'] = '$projector';
    }
    if (type != null && type.isNotEmpty) {
      query['type'] = type;
    }

    return await _apiClient.get('/api/bookings/availability', query: query)
        as List<dynamic>;
  }

  Future<BookingModel> createBooking({
    required String roomId,
    required String date,
    required String startTime,
    required String endTime,
    required String requestedBy,
    required String purpose,
    required String createdByRole,
    required String createdByLoginId,
    required String createdByName,
    String? batch,
  }) async {
    final data = await _apiClient.post(
      '/api/bookings',
      body: {
        'room': roomId,
        'date': date,
        'startTime': startTime,
        'endTime': endTime,
        'requestedBy': requestedBy,
        'purpose': purpose,
        'createdByRole': createdByRole,
        'createdByLoginId': createdByLoginId,
        'createdByName': createdByName,
        'batch': batch,
      },
    ) as Map<String, dynamic>;

    return BookingModel.fromJson(data);
  }

  Future<List<BookingModel>> fetchAllBookings() async {
    final data = await _apiClient.get('/api/bookings') as List<dynamic>;
    return data
        .map((json) => BookingModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<BookingModel> updateBookingStatus({
    required String bookingId,
    required String status,
  }) async {
    final data = await _apiClient.patch(
      '/api/bookings/$bookingId/status',
      body: {
        'status': status,
      },
    ) as Map<String, dynamic>;

    return BookingModel.fromJson(data);
  }

  Future<void> clearAllBookings() async {
    await _apiClient.delete('/api/bookings');
  }
}

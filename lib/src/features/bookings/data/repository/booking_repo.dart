import '../../../../core/network/api_client.dart';
import '../models/booking_model.dart';

class BookingRepository {
  BookingRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Owner/Barber: fetch saloon bookings.
  ///
  /// [sessionDate] filters by date ('YYYY-MM-DD'); maps to the `session_date`
  /// query param (renamed from old `slot_date`).
  Future<List<SaloonBooking>> fetchSaloonBookings({
    required String saloonId,
    String? sessionDate,
    String? sessionId,
    String? status,
  }) async {
    final data = await _apiClient.getJson(
      '/bookings/saloon-bookings/$saloonId',
      queryParameters: {
        if (sessionDate != null) 'session_date': sessionDate,
        if (sessionId != null) 'session_id': sessionId,
        if (status != null) 'status': status,
      },
      requiresAuth: true,
    );
    final list = (data['bookings'] as List<dynamic>?) ?? [];
    return list
        .map((e) => SaloonBooking.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Owner/Barber: verify customer arrival OTP.
  Future<SaloonBooking> verifyOtp({
    required String bookingId,
    required String otp,
  }) async {
    final data = await _apiClient.postJson(
      '/bookings/$bookingId/verify-otp',
      body: {'otp': otp},
      requiresAuth: true,
    );
    // Response only returns id + status + session fields; reconstruct minimal object.
    final b = data['booking'] as Map<String, dynamic>;
    final now = DateTime.now();
    return SaloonBooking(
      id: b['id'] as String,
      status: BookingStatus.arrived,
      sessionId: b['session_id'] as String? ?? '',
      sessionDate: '',
      sessionLabel: '',
      sessionStart: '',
      sessionEnd: '',
      queuePosition: (b['queue_position'] as num?)?.toInt() ?? 0,
      estimatedArrivalAt: b['estimated_arrival_at'] != null
          ? DateTime.tryParse(b['estimated_arrival_at'] as String)
                  ?.toLocal() ??
              now
          : now,
      allocatedDurationMinutes:
          (b['allocated_duration_minutes'] as num?)?.toInt() ?? 0,
      barberId: '',
      barberName: '',
    );
  }

  /// Owner/Barber: complete a booking.
  Future<void> completeBooking({required String bookingId}) async {
    await _apiClient.postJson(
      '/bookings/$bookingId/complete',
      requiresAuth: true,
    );
  }

  /// Any authorized party: cancel a booking.
  Future<void> cancelBooking({required String bookingId}) async {
    await _apiClient.postJson(
      '/bookings/$bookingId/cancel',
      requiresAuth: true,
    );
  }
}

import '../../../../core/network/api_client.dart';
import '../models/booking_model.dart';

class BookingRepository {
  BookingRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Owner/Barber: fetch saloon bookings.
  Future<List<SaloonBooking>> fetchSaloonBookings({
    required String saloonId,
    String? slotDate,
    String? status,
  }) async {
    final data = await _apiClient.getJson(
      '/bookings/saloon-bookings/$saloonId',
      queryParameters: {
        if (slotDate != null) 'slot_date': slotDate,
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
    // Response only returns id + status; reconstruct minimal object.
    final b = data['booking'] as Map<String, dynamic>;
    return SaloonBooking(
      id: b['id'] as String,
      status: BookingStatus.arrived,
      slotDate: '',
      startTime: '',
      endTime: '',
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

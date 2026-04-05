import '../../../core/network/api_client.dart';
import 'seat_models.dart';

class SeatRemoteDataSource {
  SeatRemoteDataSource({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<Seat>> fetchSeats(String saloonId) async {
    final json = await _apiClient.getJson('/seats/$saloonId', requiresAuth: true);
    final seatsJson = (json['seats'] as List?) ?? const [];
    return seatsJson
        .whereType<Map>()
        .map((seat) => Seat.fromJson(seat.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<SeatBatchResponse> addSeats(AddSeatsRequest request) async {
    final json = await _apiClient.postJson('/seats', body: request.toJson(), requiresAuth: true);
    return SeatBatchResponse.fromJson(json);
  }

  Future<SeatBatchResponse> deleteSeat(String seatId) async {
    final json = await _apiClient.deleteJson('/seats/$seatId', requiresAuth: true);
    return SeatBatchResponse.fromJson(json);
  }
}
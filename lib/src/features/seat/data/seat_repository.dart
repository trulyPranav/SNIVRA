import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'seat_models.dart';
import 'seat_remote_data_source.dart';

class SeatRepository {
  SeatRepository({required ApiClient apiClient}) : _remoteDataSource = SeatRemoteDataSource(apiClient: apiClient);

  final SeatRemoteDataSource _remoteDataSource;

  Future<List<Seat>> getSeats(String saloonId) async {
    try {
      return await _remoteDataSource.fetchSeats(saloonId);
    } on ApiException catch (error) {
      throw error.toApiError();
    }
  }

  Future<SeatBatchResponse> addSeats({required String saloonId, required int numberOfSeats}) async {
    try {
      return await _remoteDataSource.addSeats(AddSeatsRequest(saloonId: saloonId, numberOfSeats: numberOfSeats));
    } on ApiException catch (error) {
      throw error.toApiError();
    }
  }

  Future<SeatBatchResponse> deleteSeat(String seatId) async {
    try {
      return await _remoteDataSource.deleteSeat(seatId);
    } on ApiException catch (error) {
      throw error.toApiError();
    }
  }
}
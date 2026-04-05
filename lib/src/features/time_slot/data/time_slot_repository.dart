import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'time_slot_models.dart';
import 'time_slot_remote_data_source.dart';

class TimeSlotRepository {
  TimeSlotRepository({required ApiClient apiClient}) : _remoteDataSource = TimeSlotRemoteDataSource(apiClient: apiClient);

  final TimeSlotRemoteDataSource _remoteDataSource;

  Future<List<DateTime>> getConfiguredDates({required String saloonId, required DateTime monthDate}) async {
    try {
      return await _remoteDataSource.fetchConfiguredDates(
        saloonId: saloonId,
        month: TimeSlotRemoteDataSource.toYearMonth(monthDate),
      );
    } on ApiException catch (error) {
      throw error.toApiError();
    }
  }

  Future<List<TimeSlot>> getSlotsByDate({required String saloonId, required DateTime date, int? seatNumber}) async {
    try {
      return await _remoteDataSource.fetchSlotsByDate(saloonId: saloonId, date: date, seatNumber: seatNumber);
    } on ApiException catch (error) {
      throw error.toApiError();
    }
  }

  Future<TimeSlotBatchResponse> createSlotsForDate({
    required String saloonId,
    required DateTime date,
    required String startTime,
    required String endTime,
    required int slotDurationMin,
  }) async {
    try {
      return await _remoteDataSource.createSlotsForDate(
        saloonId: saloonId,
        date: date,
        startTime: startTime,
        endTime: endTime,
        slotDurationMin: slotDurationMin,
      );
    } on ApiException catch (error) {
      throw error.toApiError();
    }
  }

  Future<TimeSlotBatchResponse> updateAvailability({required String slotId, required bool isAvailable}) async {
    try {
      return await _remoteDataSource.updateAvailability(slotId: slotId, isAvailable: isAvailable);
    } on ApiException catch (error) {
      throw error.toApiError();
    }
  }
}

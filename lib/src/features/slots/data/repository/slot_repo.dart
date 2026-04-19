import '../../../../core/network/api_client.dart';
import '../models/slot_model.dart';

class SlotRepository {
  SlotRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Fetch configured dates + slot counts for a given month (YYYY-MM).
  Future<List<ConfiguredDate>> fetchConfiguredDates({
    required String saloonId,
    required String month,
  }) async {
    final data = await _apiClient.getJson(
      '/time-slots/$saloonId/configured-dates',
      queryParameters: {'month': month},
      requiresAuth: true,
    );
    final slotCountByDate =
        (data['slot_count_by_date'] as Map<String, dynamic>?) ?? {};
    final dates = (data['configured_dates'] as List<dynamic>?) ?? [];
    return dates.map((d) {
      final dateStr = d as String;
      final count = (slotCountByDate[dateStr] as num?)?.toInt() ?? 0;
      return ConfiguredDate(
        date: DateTime.parse(dateStr),
        slotCount: count,
      );
    }).toList();
  }

  /// Fetch all time slots for a specific date (YYYY-MM-DD).
  Future<List<SlotDetail>> fetchSlotsForDate({
    required String saloonId,
    required String date,
  }) async {
    final data = await _apiClient.getJson(
      '/time-slots/$saloonId',
      queryParameters: {'slot_date': date},
      requiresAuth: true,
    );
    final list = (data['slots'] as List<dynamic>?) ?? [];
    return list
        .map((e) => SlotDetail.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch members (barbers + owner) of a saloon.
  Future<List<SaloonMember>> fetchSaloonMembers({
    required String saloonId,
  }) async {
    final data = await _apiClient.getJson(
      '/saloons/$saloonId/barbers',
      requiresAuth: true,
    );
    final list = (data['barbers'] as List<dynamic>?) ?? [];
    return list
        .map((e) => SaloonMember.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Toggle availability for a specific slot.
  Future<SlotDetail> toggleSlotAvailability({
    required String slotId,
    required bool isAvailable,
  }) async {
    final path = isAvailable
        ? '/time-slots/$slotId/available'
        : '/time-slots/$slotId/unavailable';
    final data = await _apiClient.patchJson(path, requiresAuth: true);
    return SlotDetail.fromJson(data['slot'] as Map<String, dynamic>);
  }

  /// Generate slots for a single date.
  Future<void> generateSlots({
    required String saloonId,
    required String slotDate,
    required String startTime,
    required String endTime,
    required int slotDurationMin,
    String? barberId,
  }) async {
    final body = <String, dynamic>{
      'saloon_id': saloonId,
      'slot_date': slotDate,
      'start_time': startTime,
      'end_time': endTime,
      'slot_duration_min': slotDurationMin,
      if (barberId != null) 'barber_id': barberId,
    };
    await _apiClient.postJson(
      '/time-slots',
      body: body,
      requiresAuth: true,
    );
  }

  /// Generate slots for a range of dates.
  Future<BulkSlotSummary> generateBulkSlots({
    required String saloonId,
    required String startDate,
    required String endDate,
    required String startTime,
    required String endTime,
    required int slotDurationMin,
    String? barberId,
  }) async {
    final body = <String, dynamic>{
      'saloon_id': saloonId,
      'start_date': startDate,
      'end_date': endDate,
      'start_time': startTime,
      'end_time': endTime,
      'slot_duration_min': slotDurationMin,
      if (barberId != null) 'barber_id': barberId,
    };
    final data = await _apiClient.postJson(
      '/time-slots/bulk',
      body: body,
      requiresAuth: true,
    );
    return BulkSlotSummary.fromJson(
        data['summary'] as Map<String, dynamic>);
  }
}
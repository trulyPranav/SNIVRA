import '../../../core/network/api_client.dart';
import 'time_slot_models.dart';

class TimeSlotRemoteDataSource {
  TimeSlotRemoteDataSource({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<DateTime>> fetchConfiguredDates({required String saloonId, required String month}) async {
    final json = await _apiClient.getJson(
      '/time-slots/$saloonId/configured-dates',
      queryParameters: {'month': month},
      requiresAuth: true,
    );

    final datesValue = json['dates'] ?? json['configured_dates'] ?? json['data'];
    final dates = datesValue is List ? datesValue : const [];

    return dates
        .map((entry) => _parseDate(entry?.toString()))
        .whereType<DateTime>()
        .toList(growable: false);
  }

  Future<List<TimeSlot>> fetchSlotsByDate({
    required String saloonId,
    required DateTime date,
    int? seatNumber,
  }) async {
    final query = <String, dynamic>{'slot_date': _toDateOnly(date)};
    late final Map<String, dynamic> json;

    if (seatNumber != null && seatNumber > 0) {
      query['seat_number'] = seatNumber;
      json = await _apiClient.getJson(
        '/time-slots/$saloonId/seat-slots',
        queryParameters: query,
        requiresAuth: true,
      );
    } else {
      json = await _apiClient.getJson(
        '/time-slots/$saloonId',
        queryParameters: query,
        requiresAuth: true,
      );
    }

    return _extractSlots(json)
        .whereType<Map>()
        .map((item) => TimeSlot.fromJson(item.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<TimeSlotBatchResponse> createSlotsForDate({
    required String saloonId,
    required DateTime date,
    required String startTime,
    required String endTime,
    required int slotDurationMin,
  }) async {
    final body = {
      'saloon_id': saloonId,
      'slot_date': _toDateOnly(date),
      'start_time': startTime,
      'end_time': endTime,
      'slot_duration_min': slotDurationMin,
    };

    final json = await _apiClient.postJson('/time-slots', body: body, requiresAuth: true);

    return TimeSlotBatchResponse.fromJson(json);
  }

  Future<TimeSlotBatchResponse> updateAvailability({required String slotId, required bool isAvailable}) async {
    final path = isAvailable ? '/time-slots/$slotId/available' : '/time-slots/$slotId/unavailable';
    final json = await _apiClient.patchJson(path, body: const {}, requiresAuth: true);

    return TimeSlotBatchResponse.fromJson(json);
  }

  static List<dynamic> _extractSlots(Map<String, dynamic> json) {
    final slots = json['time_slots'] ?? json['slots'] ?? json['data'];
    if (slots is List) {
      return slots;
    }
    return const [];
  }

  static String _toDateOnly(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static String toYearMonth(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';
  }

  static DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return null;
    }
    return DateTime(parsed.year, parsed.month, parsed.day);
  }
}

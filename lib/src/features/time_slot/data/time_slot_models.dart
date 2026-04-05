import 'package:equatable/equatable.dart';

class TimeSlot extends Equatable {
  const TimeSlot({
    required this.id,
    required this.saloonId,
    required this.seatId,
    required this.seatNumber,
    required this.slotDate,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
  });

  final String id;
  final String saloonId;
  final String seatId;
  final int seatNumber;
  final DateTime slotDate;
  final String startTime;
  final String endTime;
  final bool isAvailable;

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    final slotDateValue = json['slot_date'] ?? json['date'] ?? json['slotDate'];
    return TimeSlot(
      id: json['id']?.toString() ?? json['time_slot_id']?.toString() ?? '',
      saloonId: json['saloon_id']?.toString() ?? '',
      seatId: json['seat_id']?.toString() ?? '',
      seatNumber: int.tryParse((json['seat_number'] ?? json['seatNo'] ?? '').toString()) ?? 0,
      slotDate: _parseDate(slotDateValue),
      startTime: json['start_time']?.toString() ?? json['startTime']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? json['endTime']?.toString() ?? '',
      isAvailable: json['is_available'] == true || json['available'] == true || json['status']?.toString().toUpperCase() == 'AVAILABLE',
    );
  }

  TimeSlot copyWith({
    String? id,
    String? saloonId,
    String? seatId,
    int? seatNumber,
    DateTime? slotDate,
    String? startTime,
    String? endTime,
    bool? isAvailable,
  }) {
    return TimeSlot(
      id: id ?? this.id,
      saloonId: saloonId ?? this.saloonId,
      seatId: seatId ?? this.seatId,
      seatNumber: seatNumber ?? this.seatNumber,
      slotDate: slotDate ?? this.slotDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return DateTime(parsed.year, parsed.month, parsed.day);
      }
    }
    if (value is int) {
      final parsed = DateTime.fromMillisecondsSinceEpoch(value);
      return DateTime(parsed.year, parsed.month, parsed.day);
    }
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  List<Object?> get props => [id, saloonId, seatId, seatNumber, slotDate, startTime, endTime, isAvailable];
}

class TimeSlotBatchResponse extends Equatable {
  const TimeSlotBatchResponse({required this.message, required this.timeSlots});

  final String message;
  final List<TimeSlot> timeSlots;

  factory TimeSlotBatchResponse.fromJson(Map<String, dynamic> json) {
    final slotList = _extractSlots(json);
    return TimeSlotBatchResponse(
      message: json['message']?.toString() ?? '',
      timeSlots: slotList
          .whereType<Map>()
          .map((item) => TimeSlot.fromJson(item.cast<String, dynamic>()))
          .toList(growable: false),
    );
  }

  static List<dynamic> _extractSlots(Map<String, dynamic> json) {
    final slots = json['time_slots'] ?? json['slots'] ?? json['data'];
    if (slots is List) {
      return slots;
    }
    return const [];
  }

  @override
  List<Object?> get props => [message, timeSlots];
}

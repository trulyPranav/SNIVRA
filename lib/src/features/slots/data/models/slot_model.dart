import 'package:equatable/equatable.dart';

// ─── Saloon member (barber) ───────────────────────────────────────────────────

class SaloonMember extends Equatable {
  const SaloonMember({
    required this.id,
    required this.name,
    required this.role,
  });

  final String id;
  final String name;
  final String role;

  factory SaloonMember.fromJson(Map<String, dynamic> json) {
    return SaloonMember(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [id, name, role];
}

// ─── Individual time slot detail ─────────────────────────────────────────────

class SlotDetail extends Equatable {
  const SlotDetail({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
    this.barberId,
    this.barberName,
  });

  final String id;
  final String startTime; // 'HH:mm'
  final String endTime;
  final bool isAvailable;
  final String? barberId;
  final String? barberName;

  SlotDetail copyWith({bool? isAvailable}) => SlotDetail(
        id: id,
        startTime: startTime,
        endTime: endTime,
        isAvailable: isAvailable ?? this.isAvailable,
        barberId: barberId,
        barberName: barberName,
      );

  factory SlotDetail.fromJson(Map<String, dynamic> json) {
    // API returns 'HH:mm:ss' — strip seconds for display
    String trimTime(String t) =>
        t.length >= 5 ? t.substring(0, 5) : t;
    return SlotDetail(
      id: json['id'] as String,
      startTime: trimTime(json['start_time'] as String),
      endTime: trimTime(json['end_time'] as String),
      isAvailable: json['is_available'] as bool? ?? true,
      barberId: json['barber_id'] as String?,
      barberName: json['barber_name'] as String?,
    );
  }

  @override
  List<Object?> get props =>
      [id, startTime, endTime, isAvailable, barberId, barberName];
}

// ─── Calendar date ────────────────────────────────────────────────────────────

class ConfiguredDate extends Equatable {
  const ConfiguredDate({
    required this.date,
    required this.slotCount,
  });

  final DateTime date;
  final int slotCount;

  @override
  List<Object?> get props => [date, slotCount];
}

class SlotSummary extends Equatable {
  const SlotSummary({
    required this.totalSlots,
    required this.availableSlots,
    required this.unavailableSlots,
  });

  final int totalSlots;
  final int availableSlots;
  final int unavailableSlots;

  factory SlotSummary.fromJson(Map<String, dynamic> json) {
    return SlotSummary(
      totalSlots: (json['total_slots'] as num).toInt(),
      availableSlots: (json['available_slots'] as num).toInt(),
      unavailableSlots: (json['unavailable_slots'] as num).toInt(),
    );
  }

  @override
  List<Object?> get props => [totalSlots, availableSlots, unavailableSlots];
}

class BulkSlotSummary extends Equatable {
  const BulkSlotSummary({
    required this.totalDates,
    required this.totalRequestedSlots,
    required this.totalInsertedSlots,
  });

  final int totalDates;
  final int totalRequestedSlots;
  final int totalInsertedSlots;

  factory BulkSlotSummary.fromJson(Map<String, dynamic> json) {
    return BulkSlotSummary(
      totalDates: (json['total_dates'] as num).toInt(),
      totalRequestedSlots: (json['total_requested_slots'] as num).toInt(),
      totalInsertedSlots: (json['total_inserted_slots'] as num).toInt(),
    );
  }

  @override
  List<Object?> get props =>
      [totalDates, totalRequestedSlots, totalInsertedSlots];
}

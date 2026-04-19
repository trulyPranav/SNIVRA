import 'package:equatable/equatable.dart';

sealed class SlotEvent extends Equatable {
  const SlotEvent();

  @override
  List<Object?> get props => [];
}

/// Load the calendar view for [saloonId] and [month] ('YYYY-MM').
class SlotMonthRequested extends SlotEvent {
  const SlotMonthRequested({
    required this.saloonId,
    required this.month,
  });

  final String saloonId;
  final String month;

  @override
  List<Object?> get props => [saloonId, month];
}

/// Generate slots for a single date.
class SlotGenerateSingleRequested extends SlotEvent {
  const SlotGenerateSingleRequested({
    required this.saloonId,
    required this.slotDate,
    required this.startTime,
    required this.endTime,
    required this.slotDurationMin,
    this.barberId,
  });

  final String saloonId;
  final String slotDate;
  final String startTime;
  final String endTime;
  final int slotDurationMin;
  final String? barberId;

  @override
  List<Object?> get props => [
        saloonId,
        slotDate,
        startTime,
        endTime,
        slotDurationMin,
        barberId,
      ];
}

/// Generate slots for a date range (bulk).
class SlotGenerateBulkRequested extends SlotEvent {
  const SlotGenerateBulkRequested({
    required this.saloonId,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    required this.slotDurationMin,
    this.barberId,
  });

  final String saloonId;
  final String startDate;
  final String endDate;
  final String startTime;
  final String endTime;
  final int slotDurationMin;
  final String? barberId;

  @override
  List<Object?> get props => [
        saloonId,
        startDate,
        endDate,
        startTime,
        endTime,
        slotDurationMin,
        barberId,
      ];
}

/// Load the saloon member list (for barber picker).
class SlotMembersRequested extends SlotEvent {
  const SlotMembersRequested({required this.saloonId});

  final String saloonId;

  @override
  List<Object?> get props => [saloonId];
}

/// Load all time slots for a specific date.
class SlotDayDetailRequested extends SlotEvent {
  const SlotDayDetailRequested({
    required this.saloonId,
    required this.date, // 'YYYY-MM-DD'
  });

  final String saloonId;
  final String date;

  @override
  List<Object?> get props => [saloonId, date];
}

/// Toggle a single slot's availability.
class SlotAvailabilityToggled extends SlotEvent {
  const SlotAvailabilityToggled({
    required this.slotId,
    required this.isAvailable,
  });

  final String slotId;
  final bool isAvailable;

  @override
  List<Object?> get props => [slotId, isAvailable];
}

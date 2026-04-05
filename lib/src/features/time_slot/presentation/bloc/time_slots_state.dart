part of 'time_slots_cubit.dart';

enum TimeSlotsStatus { initial, loading, ready, updating, empty, failure }

class TimeSlotsState extends Equatable {
  const TimeSlotsState({
    required this.saloonId,
    required this.selectedDate,
    this.status = TimeSlotsStatus.initial,
    this.seats = const [],
    this.slots = const [],
    this.configuredDates = const {},
    this.selectedSeatId,
    this.errorMessage,
    this.successMessage,
  });

  final String? saloonId;
  final DateTime selectedDate;
  final TimeSlotsStatus status;
  final List<Seat> seats;
  final List<TimeSlot> slots;
  final Set<DateTime> configuredDates;
  final String? selectedSeatId;
  final String? errorMessage;
  final String? successMessage;

  bool get isLoading => status == TimeSlotsStatus.loading || status == TimeSlotsStatus.updating;

  List<TimeSlot> get visibleSlots {
    return slots;
  }

  TimeSlotsState copyWith({
    String? saloonId,
    DateTime? selectedDate,
    TimeSlotsStatus? status,
    List<Seat>? seats,
    List<TimeSlot>? slots,
    Set<DateTime>? configuredDates,
    String? selectedSeatId,
    String? errorMessage,
    String? successMessage,
  }) {
    return TimeSlotsState(
      saloonId: saloonId ?? this.saloonId,
      selectedDate: selectedDate ?? this.selectedDate,
      status: status ?? this.status,
      seats: seats ?? this.seats,
      slots: slots ?? this.slots,
      configuredDates: configuredDates ?? this.configuredDates,
      selectedSeatId: selectedSeatId ?? this.selectedSeatId,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
        saloonId,
        selectedDate,
        status,
        seats,
        slots,
        configuredDates,
        selectedSeatId,
        errorMessage,
        successMessage,
      ];
}

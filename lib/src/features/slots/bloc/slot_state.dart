import 'package:equatable/equatable.dart';

import '../data/models/slot_model.dart';

sealed class SlotState extends Equatable {
  const SlotState();

  @override
  List<Object?> get props => [];
}

class SlotInitial extends SlotState {
  const SlotInitial();
}

class SlotCalendarLoading extends SlotState {
  const SlotCalendarLoading();
}

class SlotCalendarLoaded extends SlotState {
  const SlotCalendarLoaded({
    required this.saloonId,
    required this.month,
    required this.configuredDates,
  });

  final String saloonId;
  final String month; // 'YYYY-MM'
  final List<ConfiguredDate> configuredDates;

  @override
  List<Object?> get props => [saloonId, month, configuredDates];
}

class SlotCalendarError extends SlotState {
  const SlotCalendarError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

// ─── Members ─────────────────────────────────────────────────────────────────

class SlotMembersLoading extends SlotState {
  const SlotMembersLoading();
}

class SlotMembersLoaded extends SlotState {
  const SlotMembersLoaded({required this.members});

  final List<SaloonMember> members;

  @override
  List<Object?> get props => [members];
}

class SlotMembersError extends SlotState {
  const SlotMembersError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

// ─── Day detail ──────────────────────────────────────────────────────────────

class SlotDayLoading extends SlotState {
  const SlotDayLoading();
}

class SlotDayLoaded extends SlotState {
  const SlotDayLoaded({required this.date, required this.slots});

  final String date;
  final List<SlotDetail> slots;

  @override
  List<Object?> get props => [date, slots];
}

class SlotDayError extends SlotState {
  const SlotDayError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

// ─── Toggle availability ─────────────────────────────────────────────────────

class SlotToggling extends SlotState {
  const SlotToggling({required this.slotId});

  final String slotId;

  @override
  List<Object?> get props => [slotId];
}

class SlotToggleSuccess extends SlotState {
  const SlotToggleSuccess({required this.updated});

  final SlotDetail updated;

  @override
  List<Object?> get props => [updated];
}

class SlotToggleError extends SlotState {
  const SlotToggleError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

// ─── Generate ─────────────────────────────────────────────────────────────────

class SlotGenerating extends SlotState {
  const SlotGenerating();
}

class SlotGenerateSuccess extends SlotState {
  const SlotGenerateSuccess({this.summary});

  final BulkSlotSummary? summary;

  @override
  List<Object?> get props => [summary];
}

class SlotGenerateError extends SlotState {
  const SlotGenerateError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

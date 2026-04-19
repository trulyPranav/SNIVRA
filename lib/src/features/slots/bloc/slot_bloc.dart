import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../data/repository/slot_repo.dart';
import 'slot_event.dart';
import 'slot_state.dart';

class SlotBloc extends Bloc<SlotEvent, SlotState> {
  SlotBloc({required SlotRepository slotRepository})
      : _repo = slotRepository,
        super(const SlotInitial()) {
    on<SlotMonthRequested>(_onMonthRequested);
    on<SlotGenerateSingleRequested>(_onGenerateSingle);
    on<SlotGenerateBulkRequested>(_onGenerateBulk);
    on<SlotMembersRequested>(_onMembersRequested);
    on<SlotDayDetailRequested>(_onDayDetailRequested);
    on<SlotAvailabilityToggled>(_onAvailabilityToggled);
  }

  final SlotRepository _repo;

  Future<void> _onMonthRequested(
    SlotMonthRequested event,
    Emitter<SlotState> emit,
  ) async {
    emit(const SlotCalendarLoading());
    try {
      final dates = await _repo.fetchConfiguredDates(
        saloonId: event.saloonId,
        month: event.month,
      );
      emit(SlotCalendarLoaded(
        saloonId: event.saloonId,
        month: event.month,
        configuredDates: dates,
      ));
    } on ApiException catch (e) {
      emit(SlotCalendarError(message: e.message));
    } catch (e) {
      emit(SlotCalendarError(message: e.toString()));
    }
  }

  Future<void> _onGenerateSingle(
    SlotGenerateSingleRequested event,
    Emitter<SlotState> emit,
  ) async {
    emit(const SlotGenerating());
    try {
      await _repo.generateSlots(
        saloonId: event.saloonId,
        slotDate: event.slotDate,
        startTime: event.startTime,
        endTime: event.endTime,
        slotDurationMin: event.slotDurationMin,
        barberId: event.barberId,
      );
      emit(const SlotGenerateSuccess());
    } on ApiException catch (e) {
      emit(SlotGenerateError(message: e.message));
    } catch (e) {
      emit(SlotGenerateError(message: e.toString()));
    }
  }

  Future<void> _onGenerateBulk(
    SlotGenerateBulkRequested event,
    Emitter<SlotState> emit,
  ) async {
    emit(const SlotGenerating());
    try {
      final summary = await _repo.generateBulkSlots(
        saloonId: event.saloonId,
        startDate: event.startDate,
        endDate: event.endDate,
        startTime: event.startTime,
        endTime: event.endTime,
        slotDurationMin: event.slotDurationMin,
        barberId: event.barberId,
      );
      emit(SlotGenerateSuccess(summary: summary));
    } on ApiException catch (e) {
      emit(SlotGenerateError(message: e.message));
    } catch (e) {
      emit(SlotGenerateError(message: e.toString()));
    }
  }

  Future<void> _onMembersRequested(
    SlotMembersRequested event,
    Emitter<SlotState> emit,
  ) async {
    emit(const SlotMembersLoading());
    try {
      final members =
          await _repo.fetchSaloonMembers(saloonId: event.saloonId);
      emit(SlotMembersLoaded(members: members));
    } on ApiException catch (e) {
      emit(SlotMembersError(message: e.message));
    } catch (e) {
      emit(SlotMembersError(message: e.toString()));
    }
  }

  Future<void> _onDayDetailRequested(
    SlotDayDetailRequested event,
    Emitter<SlotState> emit,
  ) async {
    emit(const SlotDayLoading());
    try {
      final slots = await _repo.fetchSlotsForDate(
        saloonId: event.saloonId,
        date: event.date,
      );
      emit(SlotDayLoaded(date: event.date, slots: slots));
    } on ApiException catch (e) {
      emit(SlotDayError(message: e.message));
    } catch (e) {
      emit(SlotDayError(message: e.toString()));
    }
  }

  Future<void> _onAvailabilityToggled(
    SlotAvailabilityToggled event,
    Emitter<SlotState> emit,
  ) async {
    emit(SlotToggling(slotId: event.slotId));
    try {
      final updated = await _repo.toggleSlotAvailability(
        slotId: event.slotId,
        isAvailable: event.isAvailable,
      );
      emit(SlotToggleSuccess(updated: updated));
    } on ApiException catch (e) {
      emit(SlotToggleError(message: e.message));
    } catch (e) {
      emit(SlotToggleError(message: e.toString()));
    }
  }
}

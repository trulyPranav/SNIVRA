import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/api_error.dart';
import '../../../seat/data/seat_models.dart';
import '../../../seat/data/seat_repository.dart';
import '../../data/time_slot_models.dart';
import '../../data/time_slot_repository.dart';

part 'time_slots_state.dart';

class TimeSlotsCubit extends Cubit<TimeSlotsState> {
  TimeSlotsCubit({
    required TimeSlotRepository timeSlotRepository,
    required SeatRepository seatRepository,
    required String? saloonId,
  })  : _timeSlotRepository = timeSlotRepository,
        _seatRepository = seatRepository,
        _saloonId = saloonId,
        super(
          TimeSlotsState(
            saloonId: saloonId,
            selectedDate: _normalizeDate(DateTime.now()),
          ),
        ) {
    initialize();
  }

  final TimeSlotRepository _timeSlotRepository;
  final SeatRepository _seatRepository;
  final String? _saloonId;

  Future<void> initialize() async {
    final saloonId = _saloonId;
    if (saloonId == null || saloonId.isEmpty) {
      emit(state.copyWith(status: TimeSlotsStatus.empty, errorMessage: 'No active saloon selected.'));
      return;
    }

    emit(state.copyWith(status: TimeSlotsStatus.loading, errorMessage: null, successMessage: null));

    try {
      final results = await Future.wait<dynamic>([
        _seatRepository.getSeats(saloonId),
        _timeSlotRepository.getConfiguredDates(saloonId: saloonId, monthDate: state.selectedDate),
        _timeSlotRepository.getSlotsByDate(saloonId: saloonId, date: state.selectedDate),
      ]);

      final seats = results[0] as List<Seat>;
      final configuredDates = results[1] as List<DateTime>;
      final slots = results[2] as List<TimeSlot>;

      emit(
        state.copyWith(
          status: TimeSlotsStatus.ready,
          seats: seats,
          configuredDates: configuredDates.map(_normalizeDate).toSet(),
          slots: slots,
          selectedSeatId: _pickValidSeatId(previousSeatId: state.selectedSeatId, seats: seats),
        ),
      );
    } on ApiError catch (error) {
      emit(state.copyWith(status: TimeSlotsStatus.failure, errorMessage: error.message));
    } catch (_) {
      emit(state.copyWith(status: TimeSlotsStatus.failure, errorMessage: 'Failed to load time slots.'));
    }
  }

  Future<void> selectDate(DateTime date) async {
    final normalizedDate = _normalizeDate(date);
    final saloonId = _saloonId;

    emit(
      state.copyWith(
        selectedDate: normalizedDate,
        status: TimeSlotsStatus.loading,
        errorMessage: null,
        successMessage: null,
      ),
    );

    if (saloonId == null || saloonId.isEmpty) {
      emit(state.copyWith(status: TimeSlotsStatus.empty, errorMessage: 'No active saloon selected.'));
      return;
    }

    try {
      final slots = await _loadSlotsForCurrentSelection(saloonId: saloonId, selectedDate: normalizedDate, selectedSeatId: state.selectedSeatId);
      final configuredDates = await _timeSlotRepository.getConfiguredDates(saloonId: saloonId, monthDate: normalizedDate);
      emit(
        state.copyWith(
          status: TimeSlotsStatus.ready,
          slots: slots,
          configuredDates: configuredDates.map(_normalizeDate).toSet(),
        ),
      );
    } on ApiError catch (error) {
      emit(state.copyWith(status: TimeSlotsStatus.failure, errorMessage: error.message));
    } catch (_) {
      emit(state.copyWith(status: TimeSlotsStatus.failure, errorMessage: 'Failed to load slots for selected date.'));
    }
  }

  Future<void> selectSeat(String? seatId) async {
    final normalizedSeatId = (seatId == null || seatId.isEmpty) ? null : seatId;
    final saloonId = _saloonId;
    if (saloonId == null || saloonId.isEmpty) {
      emit(state.copyWith(status: TimeSlotsStatus.empty, errorMessage: 'No active saloon selected.'));
      return;
    }

    emit(state.copyWith(selectedSeatId: normalizedSeatId, status: TimeSlotsStatus.loading, errorMessage: null, successMessage: null));

    try {
      final slots = await _loadSlotsForCurrentSelection(
        saloonId: saloonId,
        selectedDate: state.selectedDate,
        selectedSeatId: normalizedSeatId,
      );
      emit(state.copyWith(status: TimeSlotsStatus.ready, slots: slots));
    } on ApiError catch (error) {
      emit(state.copyWith(status: TimeSlotsStatus.failure, errorMessage: error.message));
    } catch (_) {
      emit(state.copyWith(status: TimeSlotsStatus.failure, errorMessage: 'Failed to filter slots by seat.'));
    }
  }

  Future<void> generateSlotsForSelectedDate({
    required String startTime,
    required String endTime,
    required int slotDurationMin,
  }) async {
    final saloonId = _saloonId;
    if (saloonId == null || saloonId.isEmpty) {
      emit(state.copyWith(status: TimeSlotsStatus.failure, errorMessage: 'No active saloon selected.'));
      return;
    }

    if (!_isValidTime(startTime) || !_isValidTime(endTime)) {
      emit(
        state.copyWith(
          status: TimeSlotsStatus.failure,
          errorMessage: 'Enter start and end time in HH:mm format (e.g. 09:00).',
        ),
      );
      return;
    }

    if (slotDurationMin <= 0) {
      emit(state.copyWith(status: TimeSlotsStatus.failure, errorMessage: 'Slot duration must be greater than 0.'));
      return;
    }

    emit(state.copyWith(status: TimeSlotsStatus.updating, errorMessage: null, successMessage: null));

    try {
      final response = await _timeSlotRepository.createSlotsForDate(
        saloonId: saloonId,
        date: state.selectedDate,
        startTime: startTime,
        endTime: endTime,
        slotDurationMin: slotDurationMin,
      );
      final refreshedSlots = await _loadSlotsForCurrentSelection(
        saloonId: saloonId,
        selectedDate: state.selectedDate,
        selectedSeatId: state.selectedSeatId,
      );
      final refreshedDates = await _timeSlotRepository.getConfiguredDates(saloonId: saloonId, monthDate: state.selectedDate);

      emit(
        state.copyWith(
          status: TimeSlotsStatus.ready,
          slots: refreshedSlots,
          configuredDates: refreshedDates.map(_normalizeDate).toSet(),
          successMessage: response.message.isNotEmpty ? response.message : 'Slots created for selected date.',
        ),
      );
    } on ApiError catch (error) {
      emit(state.copyWith(status: TimeSlotsStatus.failure, errorMessage: error.message));
    } catch (_) {
      emit(state.copyWith(status: TimeSlotsStatus.failure, errorMessage: 'Failed to generate slots.'));
    }
  }

  Future<void> setAvailability(TimeSlot slot, bool isAvailable) async {
    if (slot.id.isEmpty) {
      emit(state.copyWith(status: TimeSlotsStatus.failure, errorMessage: 'Cannot update this slot. Invalid slot ID.'));
      return;
    }

    emit(state.copyWith(status: TimeSlotsStatus.updating, errorMessage: null, successMessage: null));

    try {
      await _timeSlotRepository.updateAvailability(slotId: slot.id, isAvailable: isAvailable);

      final updatedSlots = state.slots
          .map((item) => item.id == slot.id ? item.copyWith(isAvailable: isAvailable) : item)
          .toList(growable: false);

      emit(
        state.copyWith(
          status: TimeSlotsStatus.ready,
          slots: updatedSlots,
          successMessage: isAvailable ? 'Marked slot as available.' : 'Marked slot as unavailable.',
        ),
      );
    } on ApiError catch (error) {
      emit(state.copyWith(status: TimeSlotsStatus.failure, errorMessage: error.message));
    } catch (_) {
      emit(state.copyWith(status: TimeSlotsStatus.failure, errorMessage: 'Failed to update slot availability.'));
    }
  }

  void clearMessages() {
    emit(state.copyWith(errorMessage: null, successMessage: null));
  }

  Future<List<TimeSlot>> _loadSlotsForCurrentSelection({
    required String saloonId,
    required DateTime selectedDate,
    required String? selectedSeatId,
  }) {
    final seatNumber = _seatNumberFromSeatId(selectedSeatId);
    return _timeSlotRepository.getSlotsByDate(
      saloonId: saloonId,
      date: selectedDate,
      seatNumber: seatNumber,
    );
  }

  int? _seatNumberFromSeatId(String? seatId) {
    if (seatId == null || seatId.isEmpty) {
      return null;
    }
    for (final seat in state.seats) {
      if (seat.id == seatId) {
        return seat.seatNumber;
      }
    }
    return null;
  }

  bool _isValidTime(String time) {
    final normalized = time.trim();
    final pattern = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');
    return pattern.hasMatch(normalized);
  }

  String? _pickValidSeatId({required String? previousSeatId, required List<Seat> seats}) {
    if (previousSeatId == null || previousSeatId.isEmpty) {
      return null;
    }
    final exists = seats.any((seat) => seat.id == previousSeatId);
    return exists ? previousSeatId : null;
  }

  static DateTime _normalizeDate(DateTime date) => DateTime(date.year, date.month, date.day);
}

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/api_error.dart';
import '../../data/seat_models.dart';
import '../../data/seat_repository.dart';

part 'seats_state.dart';

class SeatsCubit extends Cubit<SeatsState> {
  SeatsCubit({required SeatRepository repository, required String? saloonId})
      : _repository = repository,
        _saloonId = saloonId,
        super(SeatsState(saloonId: saloonId)) {
    if (saloonId != null && saloonId.isNotEmpty) {
      loadSeats();
    }
  }

  final SeatRepository _repository;
  final String? _saloonId;

  Future<void> loadSeats() async {
    final saloonId = _saloonId;
    if (saloonId == null || saloonId.isEmpty) {
      emit(state.copyWith(status: SeatsStatus.empty, errorMessage: 'No active saloon selected.'));
      return;
    }

    emit(state.copyWith(status: SeatsStatus.loading, errorMessage: null, successMessage: null));

    try {
      final seats = await _repository.getSeats(saloonId);
      emit(state.copyWith(status: SeatsStatus.ready, seats: seats));
    } on ApiError catch (error) {
      emit(state.copyWith(status: SeatsStatus.failure, errorMessage: error.message));
    } catch (_) {
      emit(state.copyWith(status: SeatsStatus.failure, errorMessage: 'Failed to load seats.'));
    }
  }

  Future<void> addSeats(String numberOfSeatsText) async {
    final saloonId = _saloonId;
    final numberOfSeats = int.tryParse(numberOfSeatsText.trim());

    if (saloonId == null || saloonId.isEmpty) {
      emit(state.copyWith(status: SeatsStatus.failure, errorMessage: 'No active saloon selected.'));
      return;
    }

    if (numberOfSeats == null || numberOfSeats <= 0) {
      emit(state.copyWith(status: SeatsStatus.failure, errorMessage: 'Enter a valid number of seats.'));
      return;
    }

    emit(state.copyWith(status: SeatsStatus.loading, errorMessage: null, successMessage: null));

    try {
      final response = await _repository.addSeats(saloonId: saloonId, numberOfSeats: numberOfSeats);
      emit(
        state.copyWith(
          status: SeatsStatus.success,
          successMessage: response.message.isNotEmpty ? response.message : 'Seats added successfully.',
          seats: response.seats.isNotEmpty ? response.seats : state.seats,
        ),
      );
      await loadSeats();
    } on ApiError catch (error) {
      emit(state.copyWith(status: SeatsStatus.failure, errorMessage: error.message));
    } catch (_) {
      emit(state.copyWith(status: SeatsStatus.failure, errorMessage: 'Failed to add seats.'));
    }
  }

  Future<void> deleteSeat(String seatId) async {
    emit(state.copyWith(status: SeatsStatus.loading, errorMessage: null, successMessage: null));

    try {
      final response = await _repository.deleteSeat(seatId);
      emit(
        state.copyWith(
          status: SeatsStatus.success,
          successMessage: response.message.isNotEmpty ? response.message : 'Seat removed successfully.',
          seats: response.seats.isNotEmpty ? response.seats : state.seats,
        ),
      );
      await loadSeats();
    } on ApiError catch (error) {
      emit(state.copyWith(status: SeatsStatus.failure, errorMessage: error.message));
    } catch (_) {
      emit(state.copyWith(status: SeatsStatus.failure, errorMessage: 'Failed to remove seat.'));
    }
  }

  void clearMessages() {
    emit(state.copyWith(errorMessage: null, successMessage: null, status: SeatsStatus.ready));
  }
}
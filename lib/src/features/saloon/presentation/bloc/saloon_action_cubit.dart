import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/api_error.dart';
import '../../data/saloon_models.dart';
import '../../data/saloon_repository.dart';

part 'saloon_action_state.dart';

class SaloonActionCubit extends Cubit<SaloonActionState> {
  SaloonActionCubit({required SaloonRepository repository})
      : _repository = repository,
        super(const SaloonActionState());

  final SaloonRepository _repository;

  Future<void> createSaloon({
    required String creationCode,
    required String name,
    required String locationName,
    required String lat,
    required String lng,
  }) async {
    final parsedLat = double.tryParse(lat.trim());
    final parsedLng = double.tryParse(lng.trim());

    if (creationCode.trim().isEmpty || name.trim().isEmpty || locationName.trim().isEmpty || parsedLat == null || parsedLng == null) {
      emit(state.copyWith(status: SaloonActionStatus.failure, errorMessage: 'Please fill all fields with valid values.'));
      return;
    }

    emit(state.copyWith(status: SaloonActionStatus.loading, errorMessage: null, successMessage: null));

    try {
      final saloon = await _repository.createSaloon(
        creationCode: creationCode.trim(),
        name: name.trim(),
        locationName: locationName.trim(),
        lat: parsedLat,
        lng: parsedLng,
      );
      emit(
        state.copyWith(
          status: SaloonActionStatus.success,
          successMessage: 'Saloon created: ${saloon.name}',
          saloon: saloon,
        ),
      );
    } on ApiError catch (error) {
      emit(state.copyWith(status: SaloonActionStatus.failure, errorMessage: error.message));
    } catch (_) {
      emit(state.copyWith(status: SaloonActionStatus.failure, errorMessage: 'Failed to create saloon.'));
    }
  }

  Future<void> joinSaloon({required String hashCode}) async {
    if (hashCode.trim().isEmpty) {
      emit(state.copyWith(status: SaloonActionStatus.failure, errorMessage: 'Please enter a saloon hash code.'));
      return;
    }

    emit(state.copyWith(status: SaloonActionStatus.loading, errorMessage: null, successMessage: null));

    try {
      final saloon = await _repository.joinSaloon(hashCode: hashCode.trim());
      emit(
        state.copyWith(
          status: SaloonActionStatus.success,
          successMessage: 'Joined saloon: ${saloon.name}',
          saloon: saloon,
        ),
      );
    } on ApiError catch (error) {
      emit(state.copyWith(status: SaloonActionStatus.failure, errorMessage: error.message));
    } catch (_) {
      emit(state.copyWith(status: SaloonActionStatus.failure, errorMessage: 'Failed to join saloon.'));
    }
  }

  void clearMessages() {
    emit(state.copyWith(errorMessage: null, successMessage: null, status: SaloonActionStatus.initial));
  }
}
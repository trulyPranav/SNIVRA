import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../data/repository/saloon_repo.dart';
import 'saloon_setup_event.dart';
import 'saloon_setup_state.dart';

class SaloonSetupBloc extends Bloc<SaloonSetupEvent, SaloonSetupState> {
  SaloonSetupBloc({required SaloonRepository saloonRepository})
      : _repo = saloonRepository,
        super(const SaloonSetupInitial()) {
    on<SaloonCreateRequested>(_onCreate);
    on<SaloonJoinRequested>(_onJoin);
  }

  final SaloonRepository _repo;

  Future<void> _onCreate(
    SaloonCreateRequested event,
    Emitter<SaloonSetupState> emit,
  ) async {
    emit(const SaloonSetupLoading());
    try {
      final saloon = await _repo.createSaloon(
        creationCode: event.creationCode,
        name: event.name,
        lat: event.lat,
        lng: event.lng,
        locationName: event.locationName,
      );
      emit(SaloonSetupSuccess(saloon: saloon));
    } on ApiException catch (e) {
      emit(SaloonSetupFailure(error: mapSaloonApiException(e)));
    } catch (e) {
      emit(SaloonSetupFailure(
        error: mapSaloonApiException(ApiException(message: e.toString())),
      ));
    }
  }

  Future<void> _onJoin(
    SaloonJoinRequested event,
    Emitter<SaloonSetupState> emit,
  ) async {
    emit(const SaloonSetupLoading());
    try {
      final saloon = await _repo.joinSaloon(hashCode: event.inviteCode);
      emit(SaloonSetupSuccess(saloon: saloon));
    } on ApiException catch (e) {
      emit(SaloonSetupFailure(error: mapSaloonApiException(e)));
    } catch (e) {
      emit(SaloonSetupFailure(
        error: mapSaloonApiException(ApiException(message: e.toString())),
      ));
    }
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../data/repository/insights_repo.dart';
import 'insights_event.dart';
import 'insights_state.dart';

class InsightsBloc extends Bloc<InsightsEvent, InsightsState> {
  InsightsBloc({required InsightsRepository insightsRepository})
      : _repo = insightsRepository,
        super(const InsightsInitial()) {
    on<InsightsLoadRequested>(_onLoad);
  }

  final InsightsRepository _repo;

  Future<void> _onLoad(
    InsightsLoadRequested event,
    Emitter<InsightsState> emit,
  ) async {
    emit(const InsightsLoading());
    try {
      final insights =
          await _repo.fetchInsights(event.saloonId, month: event.month);
      emit(InsightsLoaded(insights));
    } on ApiException catch (e) {
      emit(InsightsError(e.message));
    }
  }
}

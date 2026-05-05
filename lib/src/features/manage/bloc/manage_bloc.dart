import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../data/models/manage_model.dart';
import '../data/repository/manage_repo.dart';
import 'manage_event.dart';
import 'manage_state.dart';

class ManageBloc extends Bloc<ManageEvent, ManageState> {
  ManageBloc({required ManageRepository manageRepository})
      : _repo = manageRepository,
        super(const ManageInitial()) {
    on<ManageLoadRequested>(_onLoad);
    on<ManageRoleChangeRequested>(_onRoleChange);
    on<ManageRemoveRequested>(_onRemove);
  }

  final ManageRepository _repo;

  Future<void> _onLoad(
    ManageLoadRequested event,
    Emitter<ManageState> emit,
  ) async {
    emit(const ManageLoading());
    try {
      final members = await _repo.fetchMembers(event.saloonId);
      emit(ManageLoaded(members));
    } on ApiException catch (e) {
      emit(ManageError(e.message));
    }
  }

  Future<void> _onRoleChange(
    ManageRoleChangeRequested event,
    Emitter<ManageState> emit,
  ) async {
    final current = _currentMembers();
    if (current == null) return;

    emit(ManageActionLoading(members: current, actingId: event.barberId));
    try {
      final message = await _repo.updateRole(
        saloonId: event.saloonId,
        barberId: event.barberId,
        role: event.role,
      );
      // Update the local list optimistically.
      final updated = current.map((m) {
        if (m.id == event.barberId) return m.copyWith(role: event.role);
        return m;
      }).toList();
      emit(ManageActionSuccess(members: updated, message: message));
    } on ApiException catch (e) {
      emit(ManageActionError(members: current, message: e.message));
    }
  }

  Future<void> _onRemove(
    ManageRemoveRequested event,
    Emitter<ManageState> emit,
  ) async {
    final current = _currentMembers();
    if (current == null) return;

    emit(ManageActionLoading(members: current, actingId: event.barberId));
    try {
      final message = await _repo.removeMember(
        saloonId: event.saloonId,
        barberId: event.barberId,
      );
      final updated =
          current.where((m) => m.id != event.barberId).toList();
      emit(ManageActionSuccess(members: updated, message: message));
    } on ApiException catch (e) {
      emit(ManageActionError(members: current, message: e.message));
    }
  }

  List<SaloonMember>? _currentMembers() {
    final s = state;
    if (s is ManageLoaded) return s.members;
    if (s is ManageActionLoading) return s.members;
    if (s is ManageActionSuccess) return s.members;
    if (s is ManageActionError) return s.members;
    return null;
  }
}

import 'package:equatable/equatable.dart';

import '../data/models/manage_model.dart';

abstract class ManageState extends Equatable {
  const ManageState();

  @override
  List<Object?> get props => [];
}

class ManageInitial extends ManageState {
  const ManageInitial();
}

class ManageLoading extends ManageState {
  const ManageLoading();
}

class ManageLoaded extends ManageState {
  const ManageLoaded(this.members);

  final List<SaloonMember> members;

  @override
  List<Object?> get props => [members];
}

class ManageError extends ManageState {
  const ManageError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

// Emitted during a role-change or removal action (optimistic loading).
class ManageActionLoading extends ManageState {
  const ManageActionLoading({required this.members, required this.actingId});

  final List<SaloonMember> members;
  final String actingId;

  @override
  List<Object?> get props => [members, actingId];
}

class ManageActionSuccess extends ManageState {
  const ManageActionSuccess({
    required this.members,
    required this.message,
  });

  final List<SaloonMember> members;
  final String message;

  @override
  List<Object?> get props => [members, message];
}

class ManageActionError extends ManageState {
  const ManageActionError({
    required this.members,
    required this.message,
  });

  final List<SaloonMember> members;
  final String message;

  @override
  List<Object?> get props => [members, message];
}

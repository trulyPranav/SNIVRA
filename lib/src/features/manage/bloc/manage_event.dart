import 'package:equatable/equatable.dart';

import '../data/models/manage_model.dart';

abstract class ManageEvent extends Equatable {
  const ManageEvent();

  @override
  List<Object?> get props => [];
}

class ManageLoadRequested extends ManageEvent {
  const ManageLoadRequested({required this.saloonId});

  final String saloonId;

  @override
  List<Object?> get props => [saloonId];
}

class ManageRoleChangeRequested extends ManageEvent {
  const ManageRoleChangeRequested({
    required this.saloonId,
    required this.barberId,
    required this.role,
  });

  final String saloonId;
  final String barberId;
  final BarberRole role;

  @override
  List<Object?> get props => [saloonId, barberId, role];
}

class ManageRemoveRequested extends ManageEvent {
  const ManageRemoveRequested({
    required this.saloonId,
    required this.barberId,
  });

  final String saloonId;
  final String barberId;

  @override
  List<Object?> get props => [saloonId, barberId];
}

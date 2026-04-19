import 'package:equatable/equatable.dart';

import '../data/models/home_model.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

/// Main loaded state. All UI rebuilds stay within this state
/// to avoid full-page flickers during actions.
class HomeLoaded extends HomeState {
  const HomeLoaded({
    required this.barbers,
    this.services = const [],
    this.isOpen,
    this.actioningId,
  });

  final List<SaloonBarber> barbers;
  final List<SaloonService> services;

  /// null = unknown (no API call made yet or after refresh).
  final bool? isOpen;

  /// ID of the entity currently being actioned.
  /// Use 'saloon' for the saloon open/close toggle, a barber's id for barber
  /// actions, a service id for service actions, or 'service_add' when adding.
  /// null = no action in progress.
  final String? actioningId;

  HomeLoaded copyWith({
    List<SaloonBarber>? barbers,
    List<SaloonService>? services,
    bool? isOpen,
    String? actioningId,
    bool clearActioning = false,
  }) {
    return HomeLoaded(
      barbers: barbers ?? this.barbers,
      services: services ?? this.services,
      isOpen: isOpen ?? this.isOpen,
      actioningId: clearActioning ? null : (actioningId ?? this.actioningId),
    );
  }

  @override
  List<Object?> get props => [barbers, services, isOpen, actioningId];
}

class HomeError extends HomeState {
  const HomeError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Transient state emitted when an action (toggle saloon/barber) fails.
/// The bloc immediately follows this with the restored [HomeLoaded] state.
class HomeActionError extends HomeState {
  const HomeActionError({
    required this.message,
    required this.restored,
  });

  final String message;
  final HomeLoaded restored;

  @override
  List<Object?> get props => [message, restored];
}

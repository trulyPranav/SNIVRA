import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

/// Fetch barbers list for the saloon.
class HomeLoadRequested extends HomeEvent {
  const HomeLoadRequested({required this.saloonId});

  final String saloonId;

  @override
  List<Object?> get props => [saloonId];
}

/// Owner toggles saloon open / closed.
class HomeSaloonOpenToggled extends HomeEvent {
  const HomeSaloonOpenToggled({required this.saloonId, required this.isOpen});

  final String saloonId;
  final bool isOpen;

  @override
  List<Object?> get props => [saloonId, isOpen];
}

/// Set a barber unavailable for a time window.
/// [barberId] — the barber being set unavailable (always provide for
/// optimistic UI update; API ignores it for non-owner barbers).
class HomeBarberUnavailableRequested extends HomeEvent {
  const HomeBarberUnavailableRequested({
    required this.saloonId,
    required this.barberId,
    required this.unavailableFrom,
    required this.unavailableUntil,
  });

  final String saloonId;
  final String barberId;
  final DateTime unavailableFrom;
  final DateTime unavailableUntil;

  @override
  List<Object?> get props => [saloonId, barberId, unavailableFrom, unavailableUntil];
}

/// Restore a barber's availability (cancel active unavailability window).
/// [barberId] — the barber being restored.
class HomeBarberRestoreRequested extends HomeEvent {
  const HomeBarberRestoreRequested({
    required this.saloonId,
    required this.barberId,
  });

  final String saloonId;
  final String barberId;

  @override
  List<Object?> get props => [saloonId, barberId];
}

/// Load the services list for the saloon.
class HomeServicesLoadRequested extends HomeEvent {
  const HomeServicesLoadRequested({required this.saloonId});

  final String saloonId;

  @override
  List<Object?> get props => [saloonId];
}

/// Owner adds a new service.
class HomeServiceAddRequested extends HomeEvent {
  const HomeServiceAddRequested({
    required this.saloonId,
    required this.name,
    this.description,
    this.price,
    this.durationMinutes,
  });

  final String saloonId;
  final String name;
  final String? description;
  final double? price;
  final int? durationMinutes;

  @override
  List<Object?> get props => [saloonId, name, description, price, durationMinutes];
}

/// Owner updates an existing service.
class HomeServiceUpdateRequested extends HomeEvent {
  const HomeServiceUpdateRequested({
    required this.saloonId,
    required this.serviceId,
    this.name,
    this.description,
    this.price,
    this.durationMinutes,
    this.isActive,
  });

  final String saloonId;
  final String serviceId;
  final String? name;
  final String? description;
  final double? price;
  final int? durationMinutes;
  final bool? isActive;

  @override
  List<Object?> get props =>
      [saloonId, serviceId, name, description, price, durationMinutes, isActive];
}

/// Owner deletes a service.
class HomeServiceDeleteRequested extends HomeEvent {
  const HomeServiceDeleteRequested({
    required this.saloonId,
    required this.serviceId,
  });

  final String saloonId;
  final String serviceId;

  @override
  List<Object?> get props => [saloonId, serviceId];
}

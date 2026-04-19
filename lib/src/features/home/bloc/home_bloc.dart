import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../data/models/home_model.dart';
import '../data/repository/home_repo.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({required HomeRepository homeRepository})
      : _repo = homeRepository,
        super(const HomeInitial()) {
    on<HomeLoadRequested>(_onLoad);
    on<HomeSaloonOpenToggled>(_onSaloonToggle);
    on<HomeBarberUnavailableRequested>(_onBarberUnavailable);
    on<HomeBarberRestoreRequested>(_onBarberRestore);
    on<HomeServicesLoadRequested>(_onServicesLoad);
    on<HomeServiceAddRequested>(_onServiceAdd);
    on<HomeServiceUpdateRequested>(_onServiceUpdate);
    on<HomeServiceDeleteRequested>(_onServiceDelete);
  }

  final HomeRepository _repo;

  Future<void> _onLoad(
    HomeLoadRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(const HomeLoading());
    try {
      final results = await Future.wait([
        _repo.fetchBarbers(event.saloonId),
        _repo.fetchServices(event.saloonId),
      ]);
      final barbers = results[0] as List<SaloonBarber>;
      final services = results[1] as List<SaloonService>;
      final prevIsOpen = state is HomeLoaded ? (state as HomeLoaded).isOpen : null;
      emit(HomeLoaded(barbers: barbers, services: services, isOpen: prevIsOpen));
    } on ApiException catch (e) {
      emit(HomeError(message: e.message));
    }
  }

  Future<void> _onSaloonToggle(
    HomeSaloonOpenToggled event,
    Emitter<HomeState> emit,
  ) async {
    final current = _loadedOrNull();
    if (current == null) return;

    emit(current.copyWith(actioningId: 'saloon'));
    try {
      final newIsOpen = await _repo.setSaloonOpen(
        event.saloonId,
        isOpen: event.isOpen,
      );
      emit(current.copyWith(isOpen: newIsOpen, clearActioning: true));
    } on ApiException catch (e) {
      final restored = current.copyWith(clearActioning: true);
      emit(HomeActionError(message: e.message, restored: restored));
      emit(restored);
    }
  }

  Future<void> _onBarberUnavailable(
    HomeBarberUnavailableRequested event,
    Emitter<HomeState> emit,
  ) async {
    final current = _loadedOrNull();
    if (current == null) return;

    emit(current.copyWith(actioningId: event.barberId));
    try {
      await _repo.setBarberUnavailable(
        saloonId: event.saloonId,
        unavailableFrom: event.unavailableFrom,
        unavailableUntil: event.unavailableUntil,
        // Pass barberId so API can target another barber (owner use-case).
        // API ignores it for non-owner callers.
        barberId: event.barberId,
      );
      final updated = current.barbers
          .map((b) => b.id == event.barberId ? b.copyWith(isAvailable: false) : b)
          .toList();
      emit(current.copyWith(barbers: updated, clearActioning: true));
    } on ApiException catch (e) {
      final restored = current.copyWith(clearActioning: true);
      emit(HomeActionError(message: e.message, restored: restored));
      emit(restored);
    }
  }

  Future<void> _onBarberRestore(
    HomeBarberRestoreRequested event,
    Emitter<HomeState> emit,
  ) async {
    final current = _loadedOrNull();
    if (current == null) return;

    emit(current.copyWith(actioningId: event.barberId));
    try {
      await _repo.restoreBarberAvailability(
        saloonId: event.saloonId,
        barberId: event.barberId,
      );
      final updated = current.barbers
          .map((b) => b.id == event.barberId ? b.copyWith(isAvailable: true) : b)
          .toList();
      emit(current.copyWith(barbers: updated, clearActioning: true));
    } on ApiException catch (e) {
      final restored = current.copyWith(clearActioning: true);
      emit(HomeActionError(message: e.message, restored: restored));
      emit(restored);
    }
  }

  HomeLoaded? _loadedOrNull() => state is HomeLoaded ? state as HomeLoaded : null;

  Future<void> _onServicesLoad(
    HomeServicesLoadRequested event,
    Emitter<HomeState> emit,
  ) async {
    final current = _loadedOrNull();
    if (current == null) return;
    // Silently refresh services without a loading spinner (list already visible).
    try {
      final services = await _repo.fetchServices(event.saloonId);
      emit(current.copyWith(services: services));
    } on ApiException catch (e) {
      final restored = current.copyWith(clearActioning: true);
      emit(HomeActionError(message: e.message, restored: restored));
      emit(restored);
    }
  }

  Future<void> _onServiceAdd(
    HomeServiceAddRequested event,
    Emitter<HomeState> emit,
  ) async {
    final current = _loadedOrNull();
    if (current == null) return;

    emit(current.copyWith(actioningId: 'service_add'));
    try {
      final service = await _repo.addService(
        event.saloonId,
        name: event.name,
        description: event.description,
        price: event.price,
        durationMinutes: event.durationMinutes,
      );
      emit(current.copyWith(
        services: [...current.services, service],
        clearActioning: true,
      ));
    } on ApiException catch (e) {
      final restored = current.copyWith(clearActioning: true);
      emit(HomeActionError(message: e.message, restored: restored));
      emit(restored);
    }
  }

  Future<void> _onServiceUpdate(
    HomeServiceUpdateRequested event,
    Emitter<HomeState> emit,
  ) async {
    final current = _loadedOrNull();
    if (current == null) return;

    emit(current.copyWith(actioningId: event.serviceId));
    try {
      final updated = await _repo.updateService(
        event.saloonId,
        event.serviceId,
        name: event.name,
        description: event.description,
        price: event.price,
        durationMinutes: event.durationMinutes,
        isActive: event.isActive,
      );
      final newList = current.services
          .map((s) => s.id == event.serviceId ? updated : s)
          .toList();
      emit(current.copyWith(services: newList, clearActioning: true));
    } on ApiException catch (e) {
      final restored = current.copyWith(clearActioning: true);
      emit(HomeActionError(message: e.message, restored: restored));
      emit(restored);
    }
  }

  Future<void> _onServiceDelete(
    HomeServiceDeleteRequested event,
    Emitter<HomeState> emit,
  ) async {
    final current = _loadedOrNull();
    if (current == null) return;

    emit(current.copyWith(actioningId: event.serviceId));
    try {
      await _repo.deleteService(event.saloonId, event.serviceId);
      final newList =
          current.services.where((s) => s.id != event.serviceId).toList();
      emit(current.copyWith(services: newList, clearActioning: true));
    } on ApiException catch (e) {
      final restored = current.copyWith(clearActioning: true);
      emit(HomeActionError(message: e.message, restored: restored));
      emit(restored);
    }
  }
}

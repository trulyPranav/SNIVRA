part of 'seats_cubit.dart';

enum SeatsStatus { initial, loading, ready, empty, failure, success }

class SeatsState extends Equatable {
  const SeatsState({
    required this.saloonId,
    this.status = SeatsStatus.initial,
    this.seats = const [],
    this.errorMessage,
    this.successMessage,
  });

  final String? saloonId;
  final SeatsStatus status;
  final List<Seat> seats;
  final String? errorMessage;
  final String? successMessage;

  bool get isLoading => status == SeatsStatus.loading;

  SeatsState copyWith({
    String? saloonId,
    SeatsStatus? status,
    List<Seat>? seats,
    String? errorMessage,
    String? successMessage,
  }) {
    return SeatsState(
      saloonId: saloonId ?? this.saloonId,
      status: status ?? this.status,
      seats: seats ?? this.seats,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [saloonId, status, seats, errorMessage, successMessage];
}
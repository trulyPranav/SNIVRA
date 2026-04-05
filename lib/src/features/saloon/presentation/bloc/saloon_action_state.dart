part of 'saloon_action_cubit.dart';

enum SaloonActionStatus { initial, loading, success, failure }

class SaloonActionState extends Equatable {
  const SaloonActionState({
    this.status = SaloonActionStatus.initial,
    this.errorMessage,
    this.successMessage,
    this.saloon,
  });

  final SaloonActionStatus status;
  final String? errorMessage;
  final String? successMessage;
  final Saloon? saloon;

  bool get isLoading => status == SaloonActionStatus.loading;

  SaloonActionState copyWith({
    SaloonActionStatus? status,
    String? errorMessage,
    String? successMessage,
    Saloon? saloon,
  }) {
    return SaloonActionState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      successMessage: successMessage,
      saloon: saloon ?? this.saloon,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, successMessage, saloon];
}
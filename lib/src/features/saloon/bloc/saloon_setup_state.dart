import 'package:equatable/equatable.dart';

import '../../../core/errors/api_error.dart';
import '../data/models/saloon_model.dart';

sealed class SaloonSetupState extends Equatable {
  const SaloonSetupState();

  @override
  List<Object?> get props => [];
}

class SaloonSetupInitial extends SaloonSetupState {
  const SaloonSetupInitial();
}

class SaloonSetupLoading extends SaloonSetupState {
  const SaloonSetupLoading();
}

class SaloonSetupSuccess extends SaloonSetupState {
  const SaloonSetupSuccess({required this.saloon});

  final Saloon saloon;

  @override
  List<Object?> get props => [saloon];
}

class SaloonSetupFailure extends SaloonSetupState {
  const SaloonSetupFailure({required this.error});

  final ApiError error;

  @override
  List<Object?> get props => [error];
}

import 'package:equatable/equatable.dart';

import '../data/models/insights_model.dart';

abstract class InsightsState extends Equatable {
  const InsightsState();

  @override
  List<Object?> get props => [];
}

class InsightsInitial extends InsightsState {
  const InsightsInitial();
}

class InsightsLoading extends InsightsState {
  const InsightsLoading();
}

class InsightsLoaded extends InsightsState {
  const InsightsLoaded(this.insights);

  final SaloonInsights insights;

  @override
  List<Object?> get props => [insights];
}

class InsightsError extends InsightsState {
  const InsightsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

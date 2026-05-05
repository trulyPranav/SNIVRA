import 'package:equatable/equatable.dart';

abstract class InsightsEvent extends Equatable {
  const InsightsEvent();

  @override
  List<Object?> get props => [];
}

class InsightsLoadRequested extends InsightsEvent {
  const InsightsLoadRequested({
    required this.saloonId,
    required this.month,
  });

  final String saloonId;

  /// Format: "YYYY-MM", e.g. "2026-05"
  final String month;

  @override
  List<Object?> get props => [saloonId, month];
}

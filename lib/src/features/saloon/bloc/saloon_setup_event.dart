import 'package:equatable/equatable.dart';

sealed class SaloonSetupEvent extends Equatable {
  const SaloonSetupEvent();

  @override
  List<Object?> get props => [];
}

class SaloonCreateRequested extends SaloonSetupEvent {
  const SaloonCreateRequested({
    required this.creationCode,
    required this.name,
    required this.lat,
    required this.lng,
    required this.locationName,
  });

  final String creationCode;
  final String name;
  final double lat;
  final double lng;
  final String locationName;

  @override
  List<Object?> get props => [creationCode, name, lat, lng, locationName];
}

class SaloonJoinRequested extends SaloonSetupEvent {
  const SaloonJoinRequested({required this.inviteCode});

  final String inviteCode;

  @override
  List<Object?> get props => [inviteCode];
}

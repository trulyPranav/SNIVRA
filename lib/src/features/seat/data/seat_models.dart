import 'package:equatable/equatable.dart';

class Seat extends Equatable {
  const Seat({
    required this.id,
    required this.saloonId,
    required this.seatNumber,
    required this.isActive,
  });

  final String id;
  final String saloonId;
  final int seatNumber;
  final bool isActive;

  factory Seat.fromJson(Map<String, dynamic> json) {
    return Seat(
      id: json['id']?.toString() ?? '',
      saloonId: json['saloon_id']?.toString() ?? '',
      seatNumber: int.tryParse(json['seat_number']?.toString() ?? '') ?? 0,
      isActive: json['is_active'] == true,
    );
  }

  @override
  List<Object?> get props => [id, saloonId, seatNumber, isActive];
}

class AddSeatsRequest extends Equatable {
  const AddSeatsRequest({required this.saloonId, required this.numberOfSeats});

  final String saloonId;
  final int numberOfSeats;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'saloon_id': saloonId,
      'number_of_seats': numberOfSeats,
    };
  }

  @override
  List<Object?> get props => [saloonId, numberOfSeats];
}

class SeatBatchResponse extends Equatable {
  const SeatBatchResponse({required this.message, required this.seats});

  final String message;
  final List<Seat> seats;

  factory SeatBatchResponse.fromJson(Map<String, dynamic> json) {
    final seatsJson = (json['seats'] as List?) ?? const [];
    return SeatBatchResponse(
      message: json['message']?.toString() ?? '',
      seats: seatsJson
          .whereType<Map>()
          .map((seat) => Seat.fromJson(seat.cast<String, dynamic>()))
          .toList(growable: false),
    );
  }

  @override
  List<Object?> get props => [message, seats];
}
import 'package:equatable/equatable.dart';

enum BookingStatus { booked, arrived, completed, cancelled, noShow }

BookingStatus _statusFromString(String? s) {
  switch (s?.toUpperCase()) {
    case 'ARRIVED':
      return BookingStatus.arrived;
    case 'COMPLETED':
      return BookingStatus.completed;
    case 'CANCELLED':
      return BookingStatus.cancelled;
    case 'NO_SHOW':
      return BookingStatus.noShow;
    default:
      return BookingStatus.booked;
  }
}

String _trimTime(String t) => t.length >= 5 ? t.substring(0, 5) : t;

// ─── Saloon booking (GET /bookings/saloon-bookings/:id) ──────────────────────

class SaloonBooking extends Equatable {
  const SaloonBooking({
    required this.id,
    required this.status,
    required this.slotDate,
    required this.startTime,
    required this.endTime,
    required this.barberId,
    required this.barberName,
    this.customerName,
    this.customerPhone,
  });

  final String id;
  final BookingStatus status;
  final String slotDate;
  final String startTime;
  final String endTime;
  final String barberId;
  final String barberName;
  final String? customerName;
  final String? customerPhone;

  factory SaloonBooking.fromJson(Map<String, dynamic> json) => SaloonBooking(
        id: json['id'] as String,
        status: _statusFromString(json['status'] as String?),
        slotDate: json['slot_date'] as String? ?? '',
        startTime: _trimTime(json['start_time'] as String? ?? ''),
        endTime: _trimTime(json['end_time'] as String? ?? ''),
        barberId: json['barber_id'] as String? ?? '',
        barberName: json['barber_name'] as String? ?? '',
        customerName: json['customer_name'] as String?,
        customerPhone: json['customer_phone'] as String?,
      );

  SaloonBooking copyWith({BookingStatus? status}) => SaloonBooking(
        id: id,
        status: status ?? this.status,
        slotDate: slotDate,
        startTime: startTime,
        endTime: endTime,
        barberId: barberId,
        barberName: barberName,
        customerName: customerName,
        customerPhone: customerPhone,
      );

  @override
  List<Object?> get props => [
        id, status, slotDate, startTime, endTime,
        barberId, barberName, customerName, customerPhone,
      ];
}

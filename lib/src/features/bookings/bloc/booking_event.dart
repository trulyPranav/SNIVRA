import 'package:equatable/equatable.dart';

sealed class BookingEvent extends Equatable {
  const BookingEvent();
}

/// Owner/Barber: load saloon bookings (with optional date/status filter).
class BookingSaloonListRequested extends BookingEvent {
  const BookingSaloonListRequested({
    required this.saloonId,
    this.slotDate,
    this.status,
  });

  final String saloonId;
  final String? slotDate;
  final String? status;

  @override
  List<Object?> get props => [saloonId, slotDate, status];
}

/// Owner/Barber: verify customer arrival OTP.
class BookingOtpVerifyRequested extends BookingEvent {
  const BookingOtpVerifyRequested({
    required this.bookingId,
    required this.otp,
  });

  final String bookingId;
  final String otp;

  @override
  List<Object?> get props => [bookingId, otp];
}

/// Owner/Barber: mark booking as completed.
class BookingCompleteRequested extends BookingEvent {
  const BookingCompleteRequested({required this.bookingId});

  final String bookingId;

  @override
  List<Object?> get props => [bookingId];
}

/// Any role: cancel a booking.
class BookingCancelRequested extends BookingEvent {
  const BookingCancelRequested({required this.bookingId});

  final String bookingId;

  @override
  List<Object?> get props => [bookingId];
}

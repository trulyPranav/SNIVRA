import 'package:equatable/equatable.dart';

import '../data/models/booking_model.dart';

sealed class BookingState extends Equatable {
  const BookingState();
}

class BookingInitial extends BookingState {
  const BookingInitial();

  @override
  List<Object?> get props => [];
}

// ─── List loading ────────────────────────────────────────────────────────────

class BookingListLoading extends BookingState {
  const BookingListLoading();

  @override
  List<Object?> get props => [];
}

class BookingSaloonListLoaded extends BookingState {
  const BookingSaloonListLoaded({required this.bookings});

  final List<SaloonBooking> bookings;

  @override
  List<Object?> get props => [bookings];
}

class BookingListError extends BookingState {
  const BookingListError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

// ─── Action (cancel / complete / verify-otp) ─────────────────────────────────

class BookingActionLoading extends BookingState {
  const BookingActionLoading({required this.bookingId});

  final String bookingId;

  @override
  List<Object?> get props => [bookingId];
}

class BookingActionSuccess extends BookingState {
  const BookingActionSuccess({required this.message, required this.bookingId});

  final String message;
  final String bookingId;

  @override
  List<Object?> get props => [message, bookingId];
}

class BookingActionError extends BookingState {
  const BookingActionError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

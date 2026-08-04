import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/repository/booking_repo.dart';
import 'booking_event.dart';
import 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  BookingBloc({required BookingRepository bookingRepository})
      : _repo = bookingRepository,
        super(const BookingInitial()) {
    on<BookingSaloonListRequested>(_onSaloonList);
    on<BookingOtpVerifyRequested>(_onVerifyOtp);
    on<BookingCompleteRequested>(_onComplete);
    on<BookingCancelRequested>(_onCancel);
  }

  final BookingRepository _repo;

  Future<void> _onSaloonList(
    BookingSaloonListRequested event,
    Emitter<BookingState> emit,
  ) async {
    emit(const BookingListLoading());
    try {
      final bookings = await _repo.fetchSaloonBookings(
        saloonId: event.saloonId,
        sessionDate: event.sessionDate,
        sessionId: event.sessionId,
        status: event.status,
      );
      emit(BookingSaloonListLoaded(bookings: bookings));
    } catch (e) {
      emit(BookingListError(message: e.toString()));
    }
  }

  Future<void> _onVerifyOtp(
    BookingOtpVerifyRequested event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingActionLoading(bookingId: event.bookingId));
    try {
      await _repo.verifyOtp(bookingId: event.bookingId, otp: event.otp);
      emit(BookingActionSuccess(
        message: 'OTP verified — customer has arrived.',
        bookingId: event.bookingId,
      ));
    } catch (e) {
      emit(BookingActionError(message: e.toString()));
    }
  }

  Future<void> _onComplete(
    BookingCompleteRequested event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingActionLoading(bookingId: event.bookingId));
    try {
      await _repo.completeBooking(bookingId: event.bookingId);
      emit(BookingActionSuccess(
        message: 'Booking marked as completed.',
        bookingId: event.bookingId,
      ));
    } catch (e) {
      emit(BookingActionError(message: e.toString()));
    }
  }

  Future<void> _onCancel(
    BookingCancelRequested event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingActionLoading(bookingId: event.bookingId));
    try {
      await _repo.cancelBooking(bookingId: event.bookingId);
      emit(BookingActionSuccess(
        message: 'Booking cancelled.',
        bookingId: event.bookingId,
      ));
    } catch (e) {
      emit(BookingActionError(message: e.toString()));
    }
  }
}

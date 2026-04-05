import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/api_error.dart';
import '../../data/auth_models.dart';
import '../../data/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthState()) {
    on<AuthPhoneChanged>(_onPhoneChanged);
    on<AuthNameChanged>(_onNameChanged);
    on<AuthOtpChanged>(_onOtpChanged);
    on<AuthLoginSubmitted>(_onLoginSubmitted);
    on<AuthOtpSubmitted>(_onOtpSubmitted);
    on<AuthResetRequested>(_onResetRequested);
    on<AuthModeToggled>(_onModeToggled);
  }

  final AuthRepository _authRepository;

  Future<void> _onPhoneChanged(AuthPhoneChanged event, Emitter<AuthState> emit) async {
    emit(state.copyWith(phone: event.phone, clearStatus: true, errorMessage: null, infoMessage: null, successMessage: null));
  }

  Future<void> _onNameChanged(AuthNameChanged event, Emitter<AuthState> emit) async {
    emit(state.copyWith(name: event.name, clearStatus: true, errorMessage: null, infoMessage: null, successMessage: null));
  }

  Future<void> _onOtpChanged(AuthOtpChanged event, Emitter<AuthState> emit) async {
    emit(state.copyWith(otp: event.otp, errorMessage: null, infoMessage: null, successMessage: null));
  }

  Future<void> _onLoginSubmitted(AuthLoginSubmitted event, Emitter<AuthState> emit) async {
    final normalizedPhone = _normalizePhone(state.phone);
    if (!_isValidPhone(normalizedPhone)) {
      emit(state.copyWith(status: AuthStatus.failure, errorMessage: 'Enter a valid 10-digit Indian phone number.'));
      return;
    }

    if (state.isRegisterMode && state.name.trim().isEmpty) {
      emit(state.copyWith(status: AuthStatus.failure, errorMessage: 'Please enter your name to register.'));
      return;
    }

    if (state.name.trim().isNotEmpty && state.name.trim().length < 2) {
      emit(state.copyWith(status: AuthStatus.failure, errorMessage: 'Enter a valid name or leave it blank.'));
      return;
    }

    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null, infoMessage: null, successMessage: null));

    try {
      final response = await _authRepository.login(
        phone: normalizedPhone,
        name: state.name.trim().isEmpty ? null : state.name.trim(),
      );
      emit(
        state.copyWith(
          status: AuthStatus.otpSent,
          phone: response.phone.isNotEmpty ? response.phone : normalizedPhone,
          isNewUser: response.isNewUser,
          infoMessage: response.message,
          clearOtp: true,
        ),
      );
    } on ApiError catch (error) {
      emit(state.copyWith(status: AuthStatus.failure, errorMessage: error.message));
    } catch (_) {
      emit(state.copyWith(status: AuthStatus.failure, errorMessage: 'Unable to start login. Please try again.'));
    }
  }

  Future<void> _onOtpSubmitted(AuthOtpSubmitted event, Emitter<AuthState> emit) async {
    final normalizedPhone = _normalizePhone(state.phone);
    final normalizedOtp = state.otp.replaceAll(RegExp(r'\s+'), '');

    if (!_isValidPhone(normalizedPhone)) {
      emit(state.copyWith(status: AuthStatus.failure, errorMessage: 'Phone number is missing. Start login again.'));
      return;
    }

    if (normalizedOtp.length != 6 || int.tryParse(normalizedOtp) == null) {
      emit(state.copyWith(status: AuthStatus.failure, errorMessage: 'Enter the 6-digit OTP sent to your phone.'));
      return;
    }

    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null, infoMessage: null, successMessage: null));

    try {
      final session = await _authRepository.verifyOtp(phone: normalizedPhone, otp: normalizedOtp);
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          successMessage: session.message,
          session: session,
        ),
      );
    } on ApiError catch (error) {
      emit(state.copyWith(status: AuthStatus.failure, errorMessage: error.message));
    } catch (_) {
      emit(state.copyWith(status: AuthStatus.failure, errorMessage: 'OTP verification failed. Please try again.'));
    }
  }

  Future<void> _onResetRequested(AuthResetRequested event, Emitter<AuthState> emit) async {
    await _authRepository.clearToken();
    emit(const AuthState());
  }

  Future<void> _onModeToggled(AuthModeToggled event, Emitter<AuthState> emit) async {
    emit(state.copyWith(isRegisterMode: !state.isRegisterMode, name: '', errorMessage: null, infoMessage: null, successMessage: null));
  }

  String _normalizePhone(String phone) {
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length == 10) {
      return digitsOnly;
    }
    if (digitsOnly.length == 12 && digitsOnly.startsWith('91')) {
      return digitsOnly.substring(2);
    }
    return digitsOnly;
  }

  bool _isValidPhone(String phone) {
    return RegExp(r'^[6-9]\d{9}$').hasMatch(phone);
  }
}
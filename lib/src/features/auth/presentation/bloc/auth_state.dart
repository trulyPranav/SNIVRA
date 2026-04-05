part of 'auth_bloc.dart';

enum AuthStatus { initial, loading, otpSent, authenticated, failure }

class AuthState extends Equatable {
  const AuthState({
    this.phone = '',
    this.name = '',
    this.otp = '',
    this.isNewUser = false,
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.infoMessage,
    this.successMessage,
    this.session,
  });

  final String phone;
  final String name;
  final String otp;
  final bool isNewUser;
  final AuthStatus status;
  final String? errorMessage;
  final String? infoMessage;
  final String? successMessage;
  final AuthSession? session;

  bool get isOtpStep => status == AuthStatus.otpSent || (status == AuthStatus.loading && otp.isNotEmpty);

  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith({
    String? phone,
    String? name,
    String? otp,
    bool? isNewUser,
    AuthStatus? status,
    String? errorMessage,
    String? infoMessage,
    String? successMessage,
    AuthSession? session,
    bool clearStatus = false,
    bool clearOtp = false,
  }) {
    return AuthState(
      phone: phone ?? this.phone,
      name: name ?? this.name,
      otp: clearOtp ? '' : (otp ?? this.otp),
      isNewUser: isNewUser ?? this.isNewUser,
      status: clearStatus ? AuthStatus.initial : (status ?? this.status),
      errorMessage: errorMessage,
      infoMessage: infoMessage,
      successMessage: successMessage,
      session: session ?? this.session,
    );
  }

  @override
  List<Object?> get props => [
        phone,
        name,
        otp,
        isNewUser,
        status,
        errorMessage,
        infoMessage,
        successMessage,
        session,
      ];
}
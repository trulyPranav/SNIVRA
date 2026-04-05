import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/auth_models.dart';
import '../../saloon_setup/presentation/saloon_setup_page.dart';
import 'bloc/auth_bloc.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) => previous.status != current.status || previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearSnackBars();

        if (state.errorMessage != null && state.status == AuthStatus.failure) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        if (state.status == AuthStatus.otpSent && state.infoMessage != null) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(state.infoMessage!),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        if (state.status == AuthStatus.authenticated && state.successMessage != null) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              behavior: SnackBarBehavior.floating,
            ),
          );

          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => SaloonSetupPage(currentUser: state.session!.user),
            ),
          );
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              const _Backdrop(),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: const _LoginCard(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.expand(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF9F3EC), Color(0xFFE8D3C0), Color(0xFFF5EFE8)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -50,
              right: -40,
              child: _GlowOrb(color: Color(0xFFB07C4F), size: 180),
            ),
            Positioned(
              bottom: 70,
              left: -30,
              child: _GlowOrb(color: Color(0xFF1D1B19), size: 140),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 50,
            spreadRadius: 14,
          ),
        ],
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(state: state),
                    const SizedBox(height: 24),
                    if (state.status == AuthStatus.authenticated && state.session != null)
                      _SuccessPanel(session: state.session)
                    else
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: state.isOtpStep ? _OtpStep(state: state) : _PhoneStep(state: state),
                      ),
                    if (state.status != AuthStatus.authenticated) const SizedBox(height: 20),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state});

  final AuthState state;

  @override
  Widget build(BuildContext context) {
    final title = state.isOtpStep ? 'Verify access' : (state.isRegisterMode ? 'Create account' : 'Welcome back');
    final subtitle = state.isOtpStep
        ? 'Enter the OTP sent to ${state.phone} to continue.'
        : state.isRegisterMode
            ? 'Sign up to manage bookings and barber operations.'
            : 'Sign in to manage bookings, salons, and barber operations from one place.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFF1D1B19),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.content_cut_rounded, color: Colors.white),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF5D5147),
                height: 1.45,
              ),
        ),
      ],
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.isRegisterMode, required this.isLoading});

  final bool isRegisterMode;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AuthBloc>();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: isLoading ? null : () => bloc.add(const AuthModeToggled()),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: !isRegisterMode ? Colors.white70 : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'Login',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: !isRegisterMode ? const Color(0xFF1D1B19) : const Color(0xFF7B6A5D),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: isLoading ? null : () => bloc.add(const AuthModeToggled()),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isRegisterMode ? Colors.white70 : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'Register',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: isRegisterMode ? const Color(0xFF1D1B19) : const Color(0xFF7B6A5D),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneStep extends StatelessWidget {
  const _PhoneStep({required this.state});

  final AuthState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AuthBloc>();
    final isLoading = state.isLoading;

    return Column(
      key: const ValueKey('phone-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ModeToggle(isRegisterMode: state.isRegisterMode, isLoading: isLoading),
        const SizedBox(height: 20),
        TextField(
          keyboardType: TextInputType.phone,
          maxLength: 10,
          enabled: !isLoading,
          decoration: const InputDecoration(
            labelText: 'Phone number',
            hintText: '9876543210',
            counterText: '',
          ),
          onChanged: (value) => bloc.add(AuthPhoneChanged(value)),
        ),
        const SizedBox(height: 14),
        if (state.isRegisterMode)
          TextField(
            enabled: !isLoading,
            decoration: const InputDecoration(
              labelText: 'Full name',
              hintText: 'John Doe',
            ),
            onChanged: (value) => bloc.add(AuthNameChanged(value)),
          )
        else
          Text(
            'Don\'t have an account? Tap Register above.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF7B6A5D),
                ),
          ),
        const SizedBox(height: 12),
        if (state.isRegisterMode)
          Text(
            'Use your real name so customers can identify you.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF7B6A5D),
                ),
          ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: isLoading ? null : () => bloc.add(const AuthLoginSubmitted()),
          child: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                )
              : const Text('Send OTP'),
        ),
      ],
    );
  }
}

class _OtpStep extends StatelessWidget {
  const _OtpStep({required this.state});

  final AuthState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AuthBloc>();
    final isLoading = state.isLoading;

    return Column(
      key: const ValueKey('otp-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          keyboardType: TextInputType.number,
          maxLength: 6,
          enabled: !isLoading,
          decoration: const InputDecoration(
            labelText: 'OTP',
            hintText: '123456',
            counterText: '',
          ),
          onChanged: (value) => bloc.add(AuthOtpChanged(value)),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isLoading ? null : () => bloc.add(const AuthResetRequested()),
                child: const Text('Change phone'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: isLoading ? null : () => bloc.add(const AuthOtpSubmitted()),
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                      )
                    : const Text('Verify OTP'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Check the OTP sent by SNIVRA. You can reuse this screen for both customers and barbers.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF7B6A5D),
              ),
        ),
      ],
    );
  }
}

class _SuccessPanel extends StatelessWidget {
  const _SuccessPanel({required this.session});

  final AuthSession? session;

  @override
  Widget build(BuildContext context) {
    if (session == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1B19),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Signed in as ${session!.user.name}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '${session!.user.role} • ${session!.user.phone}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Access token stored in the API client. Next step can route into role-specific home shells.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white60,
                ),
          ),
        ],
      ),
    );
  }
}
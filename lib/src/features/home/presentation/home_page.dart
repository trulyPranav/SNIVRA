import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/login_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SNIVRA'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_user_rounded, size: 56, color: Color(0xFF1D1B19)),
                const SizedBox(height: 16),
                Text(
                  'Signed in successfully',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'You have an active access token. Next we can wire role-based home modules here.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () async {
                    await context.read<AuthRepository>().clearToken();
                    if (!context.mounted) {
                      return;
                    }
                    context.read<AuthBloc>().add(const AuthResetRequested());
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Logout'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
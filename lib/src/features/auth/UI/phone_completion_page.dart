import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class PhoneCompletionPage extends StatefulWidget {
  const PhoneCompletionPage({
    super.key,
    required this.supabaseAccessToken,
    required this.email,
    required this.suggestedName,
  });

  final String supabaseAccessToken;
  final String email;
  final String suggestedName;

  @override
  State<PhoneCompletionPage> createState() => _PhoneCompletionPageState();
}

class _PhoneCompletionPageState extends State<PhoneCompletionPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _phoneController;
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
    _nameController = TextEditingController(text: widget.suggestedName);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthBloc>().add(
          AuthPhoneSubmitted(
            supabaseAccessToken: widget.supabaseAccessToken,
            phone: _phoneController.text.trim(),
            name: _nameController.text.trim().isNotEmpty
                ? _nameController.text.trim()
                : null,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          final route = state.user.isOwnerOrBarber ? '/home' : '/saloon-setup';
          Navigator.of(context).pushNamedAndRemoveUntil(route, (_) => false);
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(state.error.message)),
            );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            leading: BackButton(
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Heading
                    Text(
                      'One more step',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We need your phone number to complete your SNIVRA profile.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 6),

                    // Email chip
                    if (widget.email.isNotEmpty)
                      Chip(
                        avatar: const Icon(Icons.email_outlined,
                            size: 16, color: AppColors.primary),
                        label: Text(
                          widget.email,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary),
                        ),
                        backgroundColor: AppColors.surfaceVariant,
                        side: BorderSide.none,
                      ),

                    const SizedBox(height: 32),

                    // Phone field
                    Text(
                      'Phone number',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: const InputDecoration(
                        hintText: '10-digit mobile number',
                        prefixIcon: Icon(Icons.phone_outlined,
                            color: AppColors.textSecondary),
                        prefixText: '+91  ',
                        prefixStyle: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.length != 10) {
                          return 'Enter a valid 10-digit phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Name field
                    Text(
                      'Display name',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      keyboardType: TextInputType.name,
                      textInputAction: TextInputAction.done,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'Your name (optional)',
                        prefixIcon: Icon(Icons.person_outline,
                            color: AppColors.textSecondary),
                      ),
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 40),

                    // Submit button
                    ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Complete sign-up'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

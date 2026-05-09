import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../bloc/saloon_setup_bloc.dart';
import '../bloc/saloon_setup_event.dart';
import '../bloc/saloon_setup_state.dart';

class SaloonSetupPage extends StatelessWidget {
  const SaloonSetupPage({super.key, required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstName = userName.split(' ').first;

    return BlocListener<SaloonSetupBloc, SaloonSetupState>(
      listener: (context, state) {
        if (state is SaloonSetupSuccess) {
          context.read<AuthBloc>().add(const AuthUserRefreshRequested());
          Navigator.of(context).pushReplacementNamed('/home');
        } else if (state is SaloonSetupFailure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.error.message),
                backgroundColor: Colors.red.shade700,
              ),
            );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 1,
          title: const Text('SNIVRA'),
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_outlined),
              tooltip: 'Sign out',
              onPressed: () =>
                  context.read<AuthBloc>().add(const AuthSignOutRequested()),
            ),
          ],
        ),
        body: BlocBuilder<SaloonSetupBloc, SaloonSetupState>(
          builder: (context, state) {
            final isLoading = state is SaloonSetupLoading;
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, $firstName!',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Set up your workspace to get started.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _OptionCard(
                    icon: Icons.storefront_outlined,
                    title: 'Create Saloon',
                    subtitle: 'Register a new saloon and become the owner',
                    isLoading: isLoading,
                    onTap: () => _showCreateSheet(context),
                  ),
                  const SizedBox(height: 12),
                  _OptionCard(
                    icon: Icons.group_add_outlined,
                    title: 'Join a Saloon',
                    subtitle: 'Enter an invite code to join as a barber',
                    isLoading: isLoading,
                    onTap: () => _showJoinSheet(context),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<SaloonSetupBloc>(),
        child: const _CreateSaloonSheet(),
      ),
    );
  }

  void _showJoinSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<SaloonSetupBloc>(),
        child: const _JoinSaloonSheet(),
      ),
    );
  }
}

// Option card

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isLoading,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textHint,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Create Saloon sheet

class _CreateSaloonSheet extends StatefulWidget {
  const _CreateSaloonSheet();

  @override
  State<_CreateSaloonSheet> createState() => _CreateSaloonSheetState();
}

class _CreateSaloonSheetState extends State<_CreateSaloonSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationNameController = TextEditingController();
  final _codeController = TextEditingController();

  double? _lat;
  double? _lng;
  bool _locating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _locationNameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    setState(() => _locating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Location permission denied. Enable it in device settings.'),
            ),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) {
        setState(() {
          _lat = pos.latitude;
          _lng = pos.longitude;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fetch your current location.')),
      );
      return;
    }
    context.read<SaloonSetupBloc>().add(SaloonCreateRequested(
          creationCode: _codeController.text.trim(),
          name: _nameController.text.trim(),
          lat: _lat!,
          lng: _lng!,
          locationName: _locationNameController.text.trim(),
        ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'Create Saloon',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SheetField(
              controller: _nameController,
              label: 'Saloon Name',
              hint: 'e.g. Elite Barber Shop',
              icon: Icons.storefront_outlined,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 14),
            _SheetField(
              controller: _locationNameController,
              label: 'Location Name',
              hint: 'e.g. Bandra West, Mumbai',
              icon: Icons.place_outlined,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Location name is required'
                  : null,
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _locating ? null : _getLocation,
              icon: _locating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary),
                    )
                  : Icon(
                      _lat != null
                          ? Icons.my_location_rounded
                          : Icons.location_searching_rounded,
                      size: 18,
                    ),
              label: Text(
                _lat != null
                    ? 'Location: ${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}'
                    : 'Use Current Location',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    _lat != null ? AppColors.primary : AppColors.textSecondary,
                side: BorderSide(
                  color: _lat != null ? AppColors.primary : AppColors.divider,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                textStyle: const TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(height: 14),
            _SheetField(
              controller: _codeController,
              label: 'Creation Code',
              hint: 'Secret code from admin',
              icon: Icons.lock_outline_rounded,
              obscureText: true,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Creation code is required'
                  : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                textStyle: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
              child: const Text('Create Saloon'),
            ),
          ],
        ),
      ),
    );
  }
}

// Join Saloon sheet

class _JoinSaloonSheet extends StatefulWidget {
  const _JoinSaloonSheet();

  @override
  State<_JoinSaloonSheet> createState() => _JoinSaloonSheetState();
}

class _JoinSaloonSheetState extends State<_JoinSaloonSheet> {
  final _formKey = GlobalKey<FormState>();
  final _hashController = TextEditingController();

  @override
  void dispose() {
    _hashController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<SaloonSetupBloc>().add(
          SaloonJoinRequested(inviteCode: _hashController.text.trim()),
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'Join a Saloon',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SheetField(
              controller: _hashController,
              label: 'Invite Code',
              hint: 'e.g. A1B2C3',
              icon: Icons.tag_rounded,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                LengthLimitingTextInputFormatter(10),
              ],
              textCapitalization: TextCapitalization.characters,
              validator: (v) => (v == null || v.trim().length < 4)
                  ? 'Enter a valid invite code'
                  : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                textStyle: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
              child: const Text('Join Saloon'),
            ),
          ],
        ),
      ),
    );
  }
}

// Shared sheet widgets

class _SheetScaffold extends StatelessWidget {
  const _SheetScaffold({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      validator: validator,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.textHint, size: 20),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        filled: true,
        fillColor: AppColors.surface,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textHint),
      ),
    );
  }
}

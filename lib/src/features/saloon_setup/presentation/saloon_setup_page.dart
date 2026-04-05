import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../../auth/data/auth_models.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/login_page.dart';
import '../../home/presentation/home_page.dart';
import '../../saloon/data/saloon_repository.dart';
import '../../saloon/presentation/bloc/saloon_action_cubit.dart';

class SaloonSetupPage extends StatefulWidget {
  const SaloonSetupPage({super.key, required this.currentUser});

  final AuthUser currentUser;

  @override
  State<SaloonSetupPage> createState() => _SaloonSetupPageState();
}

class _SaloonSetupPageState extends State<SaloonSetupPage> {
  final creationCodeController = TextEditingController();
  final nameController = TextEditingController();
  final locationNameController = TextEditingController();
  final latController = TextEditingController();
  final lngController = TextEditingController();
  final hashCodeController = TextEditingController();

  int _activeTabIndex = 0;
  bool _isFetchingLocation = false;

  @override
  void dispose() {
    creationCodeController.dispose();
    nameController.dispose();
    locationNameController.dispose();
    latController.dispose();
    lngController.dispose();
    hashCodeController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    if (_isFetchingLocation) {
      return;
    }

    setState(() {
      _isFetchingLocation = true;
    });

    final messenger = ScaffoldMessenger.of(context);

    try {
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        messenger.showSnackBar(const SnackBar(content: Text('Location service is disabled. Enable GPS and try again.')));
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        messenger.showSnackBar(const SnackBar(content: Text('Location permission is required to fetch coordinates.')));
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      latController.text = position.latitude.toStringAsFixed(6);
      lngController.text = position.longitude.toStringAsFixed(6);
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Unable to fetch location right now.')));
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingLocation = false;
        });
      }
    }
  }

  Future<void> _goToShellAfterSaloonAction() async {
    final authRepository = context.read<AuthRepository>();
    final refreshedUser = await authRepository.getCurrentUser();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => HomePage(currentUser: refreshedUser)),
      (route) => false,
    );
  }

  Widget _buildCreateTab(SaloonActionState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Create Saloon', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(controller: creationCodeController, decoration: const InputDecoration(labelText: 'Creation code')),
            const SizedBox(height: 10),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Saloon name')),
            const SizedBox(height: 10),
            TextField(controller: locationNameController, decoration: const InputDecoration(labelText: 'Location name')),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: latController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: const InputDecoration(labelText: 'Latitude'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: lngController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: const InputDecoration(labelText: 'Longitude'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: state.isLoading || _isFetchingLocation ? null : _useCurrentLocation,
              icon: _isFetchingLocation
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_rounded),
              label: const Text('Use device location'),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: state.isLoading
                  ? null
                  : () {
                      context.read<SaloonActionCubit>().createSaloon(
                            creationCode: creationCodeController.text,
                            name: nameController.text,
                            locationName: locationNameController.text,
                            lat: latController.text,
                            lng: lngController.text,
                          );
                    },
              child: state.isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                    )
                  : const Text('Create Saloon'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinTab(SaloonActionState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Join Saloon', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(controller: hashCodeController, decoration: const InputDecoration(labelText: 'Saloon hash code')),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: state.isLoading
                  ? null
                  : () {
                      context.read<SaloonActionCubit>().joinSaloon(hashCode: hashCodeController.text);
                    },
              child: const Text('Join Saloon'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SaloonActionCubit(repository: context.read<SaloonRepository>()),
      child: BlocListener<SaloonActionCubit, SaloonActionState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) async {
          final messenger = ScaffoldMessenger.of(context);
          messenger.clearSnackBars();

          if (state.status == SaloonActionStatus.failure && state.errorMessage != null) {
            messenger.showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }

          if (state.status == SaloonActionStatus.success && state.successMessage != null) {
            messenger.showSnackBar(SnackBar(content: Text(state.successMessage!)));
            await _goToShellAfterSaloonAction();
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('SNIVRA'),
            actions: [
              IconButton(
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
                tooltip: 'Logout',
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Welcome, ${widget.currentUser.name}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create a saloon or join one. Once you do, you will move into the main app shell.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _activeTabIndex = 0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _activeTabIndex == 0 ? Colors.white70 : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Create Saloon',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: _activeTabIndex == 0 ? const Color(0xFF1D1B19) : const Color(0xFF7B6A5D),
                                  ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _activeTabIndex = 1),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _activeTabIndex == 1 ? Colors.white70 : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Join Saloon',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: _activeTabIndex == 1 ? const Color(0xFF1D1B19) : const Color(0xFF7B6A5D),
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                BlocBuilder<SaloonActionCubit, SaloonActionState>(
                  builder: (context, state) {
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _activeTabIndex == 0 ? _buildCreateTab(state) : _buildJoinTab(state),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

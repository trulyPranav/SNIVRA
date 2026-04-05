import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/data/auth_models.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/login_page.dart';
import '../../saloon/data/saloon_repository.dart';
import '../../seat/data/seat_models.dart';
import '../../seat/data/seat_repository.dart';
import '../../seat/presentation/bloc/seats_cubit.dart';
import '../../time_slot/data/time_slot_repository.dart';
import '../../time_slot/presentation/bloc/time_slots_cubit.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.currentUser, this.activeSaloonId});

  final AuthUser currentUser;
  final String? activeSaloonId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => SeatsCubit(
            repository: context.read<SeatRepository>(),
            saloonId: activeSaloonId,
          ),
        ),
        BlocProvider(
          create: (_) => TimeSlotsCubit(
            timeSlotRepository: context.read<TimeSlotRepository>(),
            seatRepository: context.read<SeatRepository>(),
            saloonId: activeSaloonId,
          ),
        ),
      ],
      child: _HomeShell(
        currentUser: currentUser,
        activeSaloonId: activeSaloonId,
      ),
    );
  }
}

class _HomeShell extends StatefulWidget {
  const _HomeShell({required this.currentUser, this.activeSaloonId});

  final AuthUser currentUser;
  final String? activeSaloonId;

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      _BookingsTab(currentUser: widget.currentUser, activeSaloonId: widget.activeSaloonId),
      const _SeatsTab(),
      _CalendarTab(activeSaloonId: widget.activeSaloonId),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('SNIVRA'),
        actions: [
          IconButton(
            onPressed: () async {
              final authRepository = context.read<AuthRepository>();
              final saloonRepository = context.read<SaloonRepository>();

              await authRepository.clearToken();
              await saloonRepository.clearActiveSaloonId();
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
      body: IndexedStack(index: _currentIndex, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_seat_outlined),
            selectedIcon: Icon(Icons.event_seat),
            label: 'Seats',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
        ],
      ),
    );
  }
}

class _BookingsTab extends StatelessWidget {
  const _BookingsTab({required this.currentUser, required this.activeSaloonId});

  final AuthUser currentUser;
  final String? activeSaloonId;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Bookings',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'Track bookings, OTP status, and daily activity from one place.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        _InfoCard(
          icon: Icons.person,
          title: currentUser.name,
          subtitle: 'Active account',
        ),
        const SizedBox(height: 12),
        _InfoCard(
          icon: Icons.storefront_rounded,
          title: activeSaloonId == null || activeSaloonId!.isEmpty ? 'No active saloon' : 'Saloon ID: $activeSaloonId',
          subtitle: 'Used for seats, calendar, and bookings.',
        ),
      ],
    );
  }
}

class _SeatsTab extends StatefulWidget {
  const _SeatsTab();

  @override
  State<_SeatsTab> createState() => _SeatsTabState();
}

class _SeatsTabState extends State<_SeatsTab> {
  final _seatCountController = TextEditingController(text: '1');

  @override
  void dispose() {
    _seatCountController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(BuildContext context, Seat seat) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove seat?'),
          content: Text('Delete seat ${seat.seatNumber}? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && context.mounted) {
      await context.read<SeatsCubit>().deleteSeat(seat.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SeatsCubit, SeatsState>(
      listenWhen: (previous, current) => previous.status != current.status || previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);
        if (state.errorMessage != null && state.status == SeatsStatus.failure) {
          messenger.showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
        if (state.successMessage != null && state.status == SeatsStatus.success) {
          messenger.showSnackBar(SnackBar(content: Text(state.successMessage!)));
        }
      },
      child: BlocBuilder<SeatsCubit, SeatsState>(
        builder: (context, state) {
          final saloonId = state.saloonId;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Seats',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                saloonId == null || saloonId.isEmpty
                    ? 'No active saloon is available. Create or join a saloon first.'
                    : 'Manage the seats for saloon ID $saloonId.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              if (saloonId != null && saloonId.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Add seats', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _seatCountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Number of seats'),
                        ),
                        const SizedBox(height: 14),
                        FilledButton(
                          onPressed: state.isLoading
                              ? null
                              : () => context.read<SeatsCubit>().addSeats(_seatCountController.text),
                          child: state.isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                                )
                              : const Text('Add Seats'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Current seats', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                if (state.isLoading && state.seats.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                else if (state.seats.isEmpty)
                  const _InfoCard(
                    icon: Icons.event_seat,
                    title: 'No seats yet',
                    subtitle: 'Add seats to get started.',
                  )
                else
                  ...state.seats.map(
                    (seat) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFF1E4D5),
                            child: Text(
                              '${seat.seatNumber}',
                              style: const TextStyle(color: Color(0xFF1D1B19)),
                            ),
                          ),
                          title: Text('Seat ${seat.seatNumber}'),
                          subtitle: Text(seat.isActive ? 'Active' : 'Inactive'),
                          trailing: IconButton(
                            onPressed: state.isLoading ? null : () => _confirmDelete(context, seat),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ),
                      ),
                    ),
                  ),
              ] else ...[
                const _InfoCard(
                  icon: Icons.event_seat,
                  title: 'No saloon selected',
                  subtitle: 'Seats will appear here after you create or join a saloon.',
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _CalendarTab extends StatefulWidget {
  const _CalendarTab({required this.activeSaloonId});

  final String? activeSaloonId;

  @override
  State<_CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<_CalendarTab> {
  final _startTimeController = TextEditingController(text: '09:00');
  final _endTimeController = TextEditingController(text: '18:00');
  final _durationController = TextEditingController(text: '30');

  @override
  void dispose() {
    _startTimeController.dispose();
    _endTimeController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TimeSlotsCubit, TimeSlotsState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.errorMessage != current.errorMessage ||
          previous.successMessage != current.successMessage,
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);
        if (state.errorMessage != null && state.status == TimeSlotsStatus.failure) {
          messenger.showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          context.read<TimeSlotsCubit>().clearMessages();
        }
        if (state.successMessage != null && state.status == TimeSlotsStatus.ready) {
          messenger.showSnackBar(SnackBar(content: Text(state.successMessage!)));
          context.read<TimeSlotsCubit>().clearMessages();
        }
      },
      child: BlocBuilder<TimeSlotsCubit, TimeSlotsState>(
        builder: (context, state) {
          final saloonId = state.saloonId;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Calendar',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                saloonId == null || saloonId.isEmpty
                    ? 'No active saloon is available. Create or join a saloon first.'
                    : 'Select a day, pick a seat, and mark slot availability.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              if (saloonId == null || saloonId.isEmpty)
                const _InfoCard(
                  icon: Icons.calendar_month,
                  title: 'No saloon selected',
                  subtitle: 'Calendar slots appear here after you create or join a saloon.',
                )
              else ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Select day', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        CalendarDatePicker(
                          initialDate: state.selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          onDateChanged: (selectedDate) => context.read<TimeSlotsCubit>().selectDate(selectedDate),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(
                              avatar: const Icon(Icons.today, size: 18),
                              label: Text('Selected: ${_formatDate(state.selectedDate)}'),
                            ),
                            if (_isConfiguredDate(state.configuredDates, state.selectedDate))
                              const Chip(
                                avatar: Icon(Icons.check_circle, size: 18),
                                label: Text('Configured date'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Filter by seat', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: state.selectedSeatId,
                          decoration: const InputDecoration(labelText: 'Seat'),
                          hint: const Text('All seats'),
                          items: [
                            const DropdownMenuItem<String>(
                              value: '',
                              child: Text('All seats'),
                            ),
                            ...state.seats.map(
                              (seat) => DropdownMenuItem<String>(
                                value: seat.id,
                                child: Text('Seat ${seat.seatNumber}'),
                              ),
                            ),
                          ],
                          onChanged: state.seats.isEmpty
                              ? null
                              : (seatId) async {
                                  await context.read<TimeSlotsCubit>().selectSeat(seatId);
                                },
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: state.isLoading
                              ? null
                              : () {
                                  final duration = int.tryParse(_durationController.text.trim()) ?? 0;
                                  context.read<TimeSlotsCubit>().generateSlotsForSelectedDate(
                                        startTime: _startTimeController.text,
                                        endTime: _endTimeController.text,
                                        slotDurationMin: duration,
                                      );
                                },
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('Generate slots for selected date'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _startTimeController,
                          keyboardType: TextInputType.datetime,
                          decoration: const InputDecoration(labelText: 'Start time (HH:mm)'),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _endTimeController,
                          keyboardType: TextInputType.datetime,
                          decoration: const InputDecoration(labelText: 'End time (HH:mm)'),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _durationController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Slot duration (minutes)'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Time slots',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                if (state.isLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                else if (state.visibleSlots.isEmpty)
                  const _InfoCard(
                    icon: Icons.schedule,
                    title: 'No slots for this day',
                    subtitle: 'Generate slots for this date or change date/seat filter.',
                  )
                else
                  ...state.visibleSlots.map(
                    (slot) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: slot.isAvailable ? const Color(0xFFE2F3E6) : const Color(0xFFF5E2E2),
                            child: Icon(
                              slot.isAvailable ? Icons.check : Icons.close,
                              color: slot.isAvailable ? const Color(0xFF1E6B35) : const Color(0xFF9F2C2C),
                            ),
                          ),
                          title: Text('${slot.startTime} - ${slot.endTime}'),
                          subtitle: Text(
                            slot.seatNumber > 0
                                ? 'Seat ${slot.seatNumber}'
                                : (slot.seatId.isNotEmpty ? 'Seat ID: ${slot.seatId}' : 'Seat not mapped'),
                          ),
                          trailing: Switch.adaptive(
                            value: slot.isAvailable,
                            onChanged: state.status == TimeSlotsStatus.updating
                                ? null
                                : (value) => context.read<TimeSlotsCubit>().setAvailability(slot, value),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  static bool _isConfiguredDate(Set<DateTime> configuredDates, DateTime selectedDate) {
    final key = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    return configuredDates.contains(key);
  }

  static String _formatDate(DateTime date) {
    final monthNames = <int, String>{
      1: 'Jan',
      2: 'Feb',
      3: 'Mar',
      4: 'Apr',
      5: 'May',
      6: 'Jun',
      7: 'Jul',
      8: 'Aug',
      9: 'Sep',
      10: 'Oct',
      11: 'Nov',
      12: 'Dec',
    };
    return '${date.day.toString().padLeft(2, '0')} ${monthNames[date.month]} ${date.year}';
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF1E4D5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: const Color(0xFF1D1B19)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

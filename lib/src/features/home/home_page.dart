import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_theme.dart';
import '../../core/notifications/notification_service.dart';
import '../auth/bloc/auth_bloc.dart';
import '../auth/bloc/auth_event.dart';
import '../auth/bloc/auth_state.dart';
import '../auth/data/models/auth_model.dart';
import '../bookings/UI/bookings_page.dart';
import '../slots/UI/slots_page.dart';
import '../insights/UI/insights_page.dart';
// import '../manage/UI/manage_page.dart';
import 'bloc/home_bloc.dart';
import 'bloc/home_event.dart';
import 'bloc/home_state.dart';
import 'data/models/home_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  static const _kBaseNavItems = [
    _NavItem(
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    _NavItem(
      label: 'Bookings',
      icon: Icons.edit_calendar_outlined,
      activeIcon: Icons.edit_calendar_rounded,
    ),
    _NavItem(
      label: 'Slots',
      icon: Icons.settings_suggest_outlined,
      activeIcon: Icons.settings_suggest_rounded,
    ),
  ];

  static const _kInsightsNavItem = _NavItem(
    label: 'Insights',
    icon: Icons.bar_chart_outlined,
    activeIcon: Icons.bar_chart_rounded,
  );

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthInitial || state is AuthFailure) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/login', (_) => false);
        }
      },
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = state.user;
        final isOwner = user.role == UserRole.owner;
        final navItems = [
          _kBaseNavItems[0], // Home
          if (isOwner) _kInsightsNavItem, // Insights (owners only)
          _kBaseNavItems[1], // Bookings
          _kBaseNavItems[2], // Slots
        ];
        final pages = [
          const _HomeTab(),
          if (isOwner) const InsightsPage(),
          const BookingsPage(),
          const SlotsPage(),
        ];
        final safeIndex = _currentIndex.clamp(0, navItems.length - 1);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            scrolledUnderElevation: 1,
            iconTheme: const IconThemeData(color: AppColors.textPrimary),
            title: Text(navItems[safeIndex].label),
            centerTitle: false,
          ),
          drawer: _AppDrawer(user: user),
          body: pages[safeIndex],
          bottomNavigationBar: NavigationBar(
            selectedIndex: safeIndex,
            onDestinationSelected: (i) =>
                setState(() => _currentIndex = i),
            backgroundColor: Colors.white,
            indicatorColor: AppColors.primary.withAlpha(20),
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            labelBehavior:
                NavigationDestinationLabelBehavior.alwaysShow,
            destinations: navItems
                .map(
                  (item) => NavigationDestination(
                    icon: Icon(item.icon,
                        color: AppColors.textSecondary),
                    selectedIcon: Icon(item.activeIcon,
                        color: AppColors.primary),
                    label: item.label,
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

// ─────────────────────────────────────────────────────────────────────────────
// Home tab — saloon status + availability dashboard
// ─────────────────────────────────────────────────────────────────────────────

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  @override
  void initState() {
    super.initState();
    _load();
    // Register FCM token with the backend now that auth is guaranteed.
    NotificationService.instance.registerToken();
  }

  void _load() {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    final saloons = authState.user.saloons;
    if (saloons.isNotEmpty) {
      context.read<HomeBloc>().add(HomeLoadRequested(
            saloonId: saloons.first.id,
            initialIsOpen: saloons.first.isOpen,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final user = authState.user;

    if (user.saloons.isEmpty) {
      return const Center(
        child: Text(
          'No saloon linked to your account.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      );
    }

    return BlocConsumer<HomeBloc, HomeState>(
      listenWhen: (_, s) => s is HomeActionError,
      listener: (context, state) {
        if (state is HomeActionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is HomeLoading || state is HomeInitial) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (state is HomeError) {
          return _ErrorRetry(
            message: state.message,
            onRetry: _load,
          );
        }

        if (state is HomeLoaded) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => _load(),
            child: _HomeContent(
              user: user,
              saloonId: user.saloons.first.id,
              saloonName: user.saloons.first.name,
              state: state,
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Home content layout
// ─────────────────────────────────────────────────────────────────────────────

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.user,
    required this.saloonId,
    required this.saloonName,
    required this.state,
  });

  final AuthUser user;
  final String saloonId;
  final String saloonName;
  final HomeLoaded state;

  @override
  Widget build(BuildContext context) {
    final isOwner = user.role == UserRole.owner;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      children: [
        // Saloon status card — owner only
        if (isOwner) ...[
          _SaloonStatusCard(
            saloonId: saloonId,
            saloonName: saloonName,
            isOpen: state.isOpen,
            isActioning: state.actioningId == 'saloon',
          ),
          const SizedBox(height: 14),
        ],

        // Section header
        _SectionHeader(
          icon: Icons.group_outlined,
          label: isOwner ? 'Barber Availability' : 'My Availability',
        ),
        const SizedBox(height: 10),

        // Barber availability cards
        ...(() {
          final barbers = isOwner
              ? state.barbers
              : state.barbers.where((b) => b.id == user.id).toList();

          if (barbers.isEmpty) {
            return [
              const _EmptyCard(label: 'No barbers found for this saloon.'),
            ];
          }

          return barbers.map((barber) {
            // Owner can manage any barber; barber can only manage themselves.
            final canManage = isOwner || barber.id == user.id;
            // When owner sets for themselves, pass null to API; for others pass barberId.
            // When barber acts for themselves, also pass null.
            // We always know barberId for optimistic update — just need what to send to API.
            final apiBarberIdParam = isOwner && barber.id != user.id ? barber.id : null;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _BarberAvailabilityCard(
                barber: barber,
                saloonId: saloonId,
                isActioning: state.actioningId == barber.id,
                canManage: canManage,
                apiBarberIdParam: apiBarberIdParam,
              ),
            );
          }).toList();
        })(),

        // Services section — owner only
        if (isOwner) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                child: _SectionHeader(
                  icon: Icons.content_cut_rounded,
                  label: 'Services',
                ),
              ),
              _SmallButton(
                label: '+ Add',
                color: AppColors.primary,
                onTap: () => _showServiceDialog(context, saloonId: saloonId),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (state.services.isEmpty)
            const _EmptyCard(label: 'No services yet. Tap "+ Add" to create one.')
          else
            ...state.services.map((service) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ServiceCard(
                    service: service,
                    saloonId: saloonId,
                    isActioning: state.actioningId == service.id,
                  ),
                )),
        ],
      ],
    );
  }
}

void _showServiceDialog(
  BuildContext context, {
  required String saloonId,
  SaloonService? existing,
}) {
  showDialog<void>(
    context: context,
    builder: (_) => BlocProvider.value(
      value: context.read<HomeBloc>(),
      child: _ServiceDialog(saloonId: saloonId, existing: existing),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Service card (owner only)
// ─────────────────────────────────────────────────────────────────────────────

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.service,
    required this.saloonId,
    required this.isActioning,
  });

  final SaloonService service;
  final String saloonId;
  final bool isActioning;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        service.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (!service.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.textHint.withAlpha(25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Inactive',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textHint,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                if (service.description != null &&
                    service.description!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    service.description!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (service.price != null) ...[
                      const Icon(Icons.currency_rupee,
                          size: 13, color: AppColors.primary),
                      Text(
                        service.price!.toStringAsFixed(0),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    if (service.durationMinutes != null)
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined,
                              size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 3),
                          Text(
                            '${service.durationMinutes} min',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Actions
          if (isActioning)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _showServiceDialog(
                    context,
                    saloonId: saloonId,
                    existing: service,
                  ),
                  child: const Icon(Icons.edit_outlined,
                      size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _confirmDeleteService(
                    context,
                    saloonId: saloonId,
                    service: service,
                  ),
                  child: const Icon(Icons.delete_outline,
                      size: 18, color: AppColors.error),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

void _confirmDeleteService(
  BuildContext context, {
  required String saloonId,
  required SaloonService service,
}) {
  showDialog<void>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: const Text(
        'Delete Service',
        style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary),
      ),
      content: Text(
        'Delete "${service.name}"? This cannot be undone. To hide it temporarily, use Edit and toggle it inactive.',
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx),
          child: const Text('Cancel',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(dialogCtx);
            context.read<HomeBloc>().add(HomeServiceDeleteRequested(
                  saloonId: saloonId,
                  serviceId: service.id,
                ));
          },
          child: const Text('Delete',
              style: TextStyle(color: AppColors.error)),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Service add / edit dialog
// ─────────────────────────────────────────────────────────────────────────────

class _ServiceDialog extends StatefulWidget {
  const _ServiceDialog({required this.saloonId, this.existing});

  final String saloonId;
  final SaloonService? existing;

  @override
  State<_ServiceDialog> createState() => _ServiceDialogState();
}

class _ServiceDialogState extends State<_ServiceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _price;
  late final TextEditingController _duration;
  bool _isActive = true;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    _name = TextEditingController(text: s?.name ?? '');
    _desc = TextEditingController(text: s?.description ?? '');
    _price = TextEditingController(
        text: s?.price != null ? s!.price!.toStringAsFixed(0) : '');
    _duration = TextEditingController(
        text: s?.durationMinutes?.toString() ?? '');
    _isActive = s?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _price.dispose();
    _duration.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final price = _price.text.trim().isEmpty
        ? null
        : double.tryParse(_price.text.trim());
    final duration = _duration.text.trim().isEmpty
        ? null
        : int.tryParse(_duration.text.trim());

    if (_isEdit) {
      context.read<HomeBloc>().add(HomeServiceUpdateRequested(
            saloonId: widget.saloonId,
            serviceId: widget.existing!.id,
            name: _name.text.trim(),
            description:
                _desc.text.trim().isEmpty ? null : _desc.text.trim(),
            price: price,
            durationMinutes: duration,
            isActive: _isActive,
          ));
    } else {
      context.read<HomeBloc>().add(HomeServiceAddRequested(
            saloonId: widget.saloonId,
            name: _name.text.trim(),
            description:
                _desc.text.trim().isEmpty ? null : _desc.text.trim(),
            price: price,
            durationMinutes: duration,
          ));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(
        _isEdit ? 'Edit Service' : 'Add Service',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DialogField(
                controller: _name,
                label: 'Name',
                hint: 'e.g. Haircut',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 10),
              _DialogField(
                controller: _desc,
                label: 'Description (optional)',
                hint: 'Short description',
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _DialogField(
                      controller: _price,
                      label: 'Price (₹)',
                      hint: '0',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DialogField(
                      controller: _duration,
                      label: 'Duration (min)',
                      hint: '30',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              if (_isEdit) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: _isActive,
                      activeColor: AppColors.primary,
                      onChanged: (v) => setState(() => _isActive = v),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _submit,
          child: Text(_isEdit ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}

class _DialogField extends StatelessWidget {
  const _DialogField({
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle:
            const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        hintStyle:
            const TextStyle(fontSize: 12, color: AppColors.textHint),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Saloon status card (owner only)
// ─────────────────────────────────────────────────────────────────────────────

class _SaloonStatusCard extends StatelessWidget {
  const _SaloonStatusCard({
    required this.saloonId,
    required this.saloonName,
    required this.isOpen,
    required this.isActioning,
  });

  final String saloonId;
  final String saloonName;
  final bool? isOpen;
  final bool isActioning;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  saloonName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                _StatusPill(isOpen: isOpen),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Toggle area
          if (isActioning)
            const SizedBox(
              width: 36,
              height: 22,
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            )
          else if (isOpen == null)
            // Unknown state — show compact open/close buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CompactToggleBtn(
                  label: 'Open',
                  color: AppColors.success,
                  onTap: () => context.read<HomeBloc>().add(
                        HomeSaloonOpenToggled(
                          saloonId: saloonId,
                          isOpen: true,
                        ),
                      ),
                ),
                const SizedBox(width: 6),
                _CompactToggleBtn(
                  label: 'Close',
                  color: AppColors.error,
                  onTap: () => context.read<HomeBloc>().add(
                        HomeSaloonOpenToggled(
                          saloonId: saloonId,
                          isOpen: false,
                        ),
                      ),
                ),
              ],
            )
          else
            Switch(
              value: isOpen!,
              activeColor: AppColors.primary,
              onChanged: (val) => context.read<HomeBloc>().add(
                    HomeSaloonOpenToggled(saloonId: saloonId, isOpen: val),
                  ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Barber availability card
// ─────────────────────────────────────────────────────────────────────────────

class _BarberAvailabilityCard extends StatelessWidget {
  const _BarberAvailabilityCard({
    required this.barber,
    required this.saloonId,
    required this.isActioning,
    required this.canManage,
    required this.apiBarberIdParam,
  });

  final SaloonBarber barber;
  final String saloonId;
  final bool isActioning;
  final bool canManage;

  /// The barberId value to send to the API for this action.
  /// null = the caller is acting for themselves (barber or owner-self).
  /// non-null = owner acting on behalf of another barber.
  final String? apiBarberIdParam;

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // Avatar circle
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.divider),
            ),
            child: Center(
              child: Text(
                _initials(barber.name),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name + role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        barber.name.isNotEmpty ? barber.name : 'Unknown',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _RoleBadge(role: barber.role),
                  ],
                ),
                const SizedBox(height: 4),
                _AvailabilityChip(isAvailable: barber.isAvailable),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Action button or spinner
          if (isActioning)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          else if (canManage)
            barber.isAvailable
                ? _SmallButton(
                    label: 'Set Off',
                    color: AppColors.error,
                    onTap: () => _onSetUnavailable(context),
                  )
                : _SmallButton(
                    label: 'Restore',
                    color: AppColors.success,
                    onTap: () => context.read<HomeBloc>().add(
                          HomeBarberRestoreRequested(
                            saloonId: saloonId,
                            barberId: barber.id,
                          ),
                        ),
                  ),
        ],
      ),
    );
  }

  Future<void> _onSetUnavailable(BuildContext context) async {
    final result = await showDialog<_UnavailabilityRange>(
      context: context,
      builder: (_) => const _UnavailabilityDialog(),
    );
    if (result == null || !context.mounted) return;
    context.read<HomeBloc>().add(
          HomeBarberUnavailableRequested(
            saloonId: saloonId,
            barberId: barber.id,
            unavailableFrom: result.from,
            unavailableUntil: result.until,
          ),
        );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Unavailability time-range dialog
// ─────────────────────────────────────────────────────────────────────────────

class _UnavailabilityRange {
  const _UnavailabilityRange({required this.from, required this.until});
  final DateTime from;
  final DateTime until;
}

class _UnavailabilityDialog extends StatefulWidget {
  const _UnavailabilityDialog();

  @override
  State<_UnavailabilityDialog> createState() => _UnavailabilityDialogState();
}

class _UnavailabilityDialogState extends State<_UnavailabilityDialog> {
  late DateTime _fromDate;
  late TimeOfDay _fromTime;
  late DateTime _untilDate;
  late TimeOfDay _untilTime;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fromDate = now;
    _fromTime = TimeOfDay.fromDateTime(now);
    final later = now.add(const Duration(hours: 2));
    _untilDate = later;
    _untilTime = TimeOfDay.fromDateTime(later);
  }

  DateTime _combine(DateTime date, TimeOfDay time) =>
      DateTime(date.year, date.month, date.day, time.hour, time.minute);

  DateTime get _fromDt => _combine(_fromDate, _fromTime);
  DateTime get _untilDt => _combine(_untilDate, _untilTime);

  bool get _isValid => _untilDt.isAfter(_fromDt);

  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: _datePickerTheme,
    );
    if (picked != null) setState(() => _fromDate = picked);
  }

  Future<void> _pickFromTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _fromTime,
      builder: _timePickerTheme,
    );
    if (picked != null) setState(() => _fromTime = picked);
  }

  Future<void> _pickUntilDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _untilDate,
      firstDate: _fromDate,
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: _datePickerTheme,
    );
    if (picked != null) setState(() => _untilDate = picked);
  }

  Future<void> _pickUntilTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _untilTime,
      builder: _timePickerTheme,
    );
    if (picked != null) setState(() => _untilTime = picked);
  }

  Widget _datePickerTheme(BuildContext context, Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          onSurface: AppColors.textPrimary,
        ),
      ),
      child: child!,
    );
  }

  Widget _timePickerTheme(BuildContext context, Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          onSurface: AppColors.textPrimary,
        ),
      ),
      child: child!,
    );
  }

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      title: const Text(
        'Set Unavailable',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TimeRangeRow(
            label: 'From',
            dateText: _fmtDate(_fromDate),
            timeText: _fmtTime(_fromTime),
            onDateTap: _pickFromDate,
            onTimeTap: _pickFromTime,
          ),
          const SizedBox(height: 10),
          _TimeRangeRow(
            label: 'Until',
            dateText: _fmtDate(_untilDate),
            timeText: _fmtTime(_untilTime),
            onDateTap: _pickUntilDate,
            onTimeTap: _pickUntilTime,
          ),
          if (!_isValid) ...[
            const SizedBox(height: 8),
            const Text(
              '"Until" must be after "From".',
              style: TextStyle(fontSize: 12, color: AppColors.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
          onPressed: _isValid
              ? () => Navigator.of(context).pop(
                    _UnavailabilityRange(from: _fromDt, until: _untilDt),
                  )
              : null,
          child: const Text('Confirm', style: TextStyle(fontSize: 13)),
        ),
      ],
    );
  }
}

class _TimeRangeRow extends StatelessWidget {
  const _TimeRangeRow({
    required this.label,
    required this.dateText,
    required this.timeText,
    required this.onDateTap,
    required this.onTimeTap,
  });

  final String label;
  final String dateText;
  final String timeText;
  final VoidCallback onDateTap;
  final VoidCallback onTimeTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 38,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 6),
        _PickerChip(text: dateText, icon: Icons.calendar_today_outlined, onTap: onDateTap),
        const SizedBox(width: 6),
        _PickerChip(text: timeText, icon: Icons.access_time_outlined, onTap: onTimeTap),
      ],
    );
  }
}

class _PickerChip extends StatelessWidget {
  const _PickerChip({
    required this.text,
    required this.icon,
    required this.onTap,
  });

  final String text;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppColors.primary),
            const SizedBox(width: 5),
            Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isOpen});

  final bool? isOpen;

  @override
  Widget build(BuildContext context) {
    final Color dotColor;
    final String label;

    if (isOpen == null) {
      dotColor = AppColors.textHint;
      label = 'Status unknown';
    } else if (isOpen!) {
      dotColor = AppColors.success;
      label = 'Open';
    } else {
      dotColor = AppColors.error;
      label = 'Closed';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isOpen == null ? AppColors.textHint : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _AvailabilityChip extends StatelessWidget {
  const _AvailabilityChip({required this.isAvailable});

  final bool isAvailable;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isAvailable
            ? AppColors.success.withAlpha(20)
            : AppColors.error.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isAvailable ? 'Available' : 'Unavailable',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isAvailable ? AppColors.success : AppColors.error,
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final BarberRole role;

  @override
  Widget build(BuildContext context) {
    final label = role == BarberRole.owner ? 'Owner' : 'Barber';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryDark,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(18),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _CompactToggleBtn extends StatelessWidget {
  const _CompactToggleBtn({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withAlpha(18),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 36),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App Drawer

class _AppDrawer extends StatefulWidget {
  const _AppDrawer({required this.user});

  final AuthUser user;

  @override
  State<_AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<_AppDrawer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _avatarScale;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );

    _avatarScale = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    );
    _fadeIn = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
    ));

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return 'Owner';
      case UserRole.barber:
        return 'Barber';
      case UserRole.customer:
        return 'Customer';
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final initials = _initials(user.name);
    final roleLabel = _roleLabel(user.role);
    final isOwner = user.role == UserRole.owner;

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Animated header ─────────────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryDark, AppColors.primaryLight],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar with scale animation
                  ScaleTransition(
                    scale: _avatarScale,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withAlpha(30),
                        border: Border.all(
                            color: Colors.white.withAlpha(120), width: 2),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Name + phone fade+slide
                  FadeTransition(
                    opacity: _fadeIn,
                    child: SlideTransition(
                      position: _slideUp,
                      child: Column(
                        children: [
                          Text(
                            user.name.isNotEmpty ? user.name : 'User',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                          if (user.phone.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              user.phone,
                              style: TextStyle(
                                color: Colors.white.withAlpha(190),
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 12),
                          // Role chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(30),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withAlpha(80),
                                  width: 1),
                            ),
                            child: Text(
                              roleLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.divider),

            // ── Current saloon card ─────────────────────────────────────────
            if (user.saloons.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.storefront_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.saloons.first.name,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),

                            const SizedBox(height: 4),

                            // Saloon join code
                            Text(
                              'Code: ${user.saloons.first.hashCode_}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(
                height: 1,
                color: AppColors.divider,
                indent: 16,
                endIndent: 16,
              ),
            ],

            // ── Menu items ──────────────────────────────────────────────────
            const SizedBox(height: 8),

            _DrawerTile(
              icon: Icons.person_outline_rounded,
              label: 'Profile',
              trailing: _ComingSoonBadge(),
              onTap: () {},
            ),

            if (isOwner)
              _DrawerTile(
                icon: Icons.storefront_outlined,
                label: 'Edit Saloon',
                trailing: _ComingSoonBadge(),
                onTap: () {},
              ),

            // if (isOwner)
            //   _DrawerTile(
            //     icon: Icons.group_outlined,
            //     label: 'Manage',
            //     onTap: () {
            //       Navigator.of(context).pop();
            //       Navigator.of(context).push(
            //         MaterialPageRoute(
            //           builder: (_) => const ManagePage(),
            //         ),
            //       );
            //     },
            //   ),

            if(isOwner)
              _DrawerTile(
                icon: Icons.group_outlined,
                label: 'Manage',
                trailing: _ComingSoonBadge(),
                onTap: () {},
              ),

            const Spacer(),

            // ── Sign out ────────────────────────────────────────────────────
            const Divider(height: 1, color: AppColors.divider),
            _DrawerTile(
              icon: Icons.logout_outlined,
              label: 'Sign Out',
              iconColor: AppColors.textSecondary,
              labelColor: AppColors.textSecondary,
              onTap: () {
                Navigator.of(context).pop();
                context
                    .read<AuthBloc>()
                    .add(const AuthSignOutRequested());
              },
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => showGeneralDialog(
                context: context,
                barrierDismissible: true,
                barrierLabel: 'About',
                barrierColor: Colors.black87,
                transitionDuration: const Duration(milliseconds: 500),
                pageBuilder: (_, __, ___) => const _AboutDialog(),
                transitionBuilder: (_, anim, __, child) {
                  final curved = CurvedAnimation(
                    parent: anim,
                    curve: Curves.easeOutCubic,
                  );
                  return FadeTransition(
                    opacity: curved,
                    child: ScaleTransition(
                      scale: Tween(begin: 0.85, end: 1.0).animate(curved),
                      child: child,
                    ),
                  );
                },
              ),
              child: Text(
                '© ${DateTime.now().year} SNIVRA · powered by Zlyro',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textHint,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Shared drawer tile ───────────────────────────────────────────────────────

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = AppColors.primary,
    this.labelColor = AppColors.textPrimary,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color iconColor;
  final Color labelColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(
        label,
        style: TextStyle(
          color: labelColor,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

// ── "Coming soon" badge ──────────────────────────────────────────────────────

class _ComingSoonBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Text(
        'Coming Soon',
        style: TextStyle(
          color: AppColors.textHint,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── About dialog ─────────────────────────────────────────────────────────────

class _AboutDialog extends StatefulWidget {
  const _AboutDialog();

  @override
  State<_AboutDialog> createState() => _AboutDialogState();
}

class _AboutDialogState extends State<_AboutDialog>
    with TickerProviderStateMixin {
  late final AnimationController _mainCtrl;
  late final AnimationController _glowCtrl;

  late final Animation<double> _backgroundFade;

  late final Animation<double> _snivraFade;
  late final Animation<double> _snivraScale;
  late final Animation<Offset> _snivraSlide;

  late final Animation<double> _poweredFade;

  late final Animation<double> _zlyroFade;
  late final Animation<double> _zlyroScale;
  late final Animation<Offset> _zlyroSlide;

  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();

    _mainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _backgroundFade = CurvedAnimation(
      parent: _mainCtrl,
      curve: const Interval(0.0, 0.18, curve: Curves.easeOut),
    );

    // ───────────────── SNIVRA ─────────────────

    _snivraFade = CurvedAnimation(
      parent: _mainCtrl,
      curve: const Interval(0.08, 0.42, curve: Curves.easeOut),
    );

    _snivraScale = Tween<double>(
      begin: 0.82,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.08, 0.42, curve: Curves.easeOutBack),
      ),
    );

    _snivraSlide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.08, 0.42, curve: Curves.easeOutCubic),
      ),
    );

    // ───────────────── POWERED BY ─────────────────

    _poweredFade = CurvedAnimation(
      parent: _mainCtrl,
      curve: const Interval(0.38, 0.55, curve: Curves.easeOut),
    );

    // ───────────────── ZLYRO ─────────────────

    _zlyroFade = CurvedAnimation(
      parent: _mainCtrl,
      curve: const Interval(0.52, 0.9, curve: Curves.easeOut),
    );

    _zlyroScale = Tween<double>(
      begin: 0.88,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.52, 0.9, curve: Curves.easeOutBack),
      ),
    );

    _zlyroSlide = Tween<Offset>(
      begin: const Offset(0, 0.16),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.52, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _glowAnim = Tween<double>(
      begin: 0.7,
      end: 1.1,
    ).animate(
      CurvedAnimation(
        parent: _glowCtrl,
        curve: Curves.easeInOut,
      ),
    );

    _mainCtrl.forward();
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  Widget _glassLogo({
    required Widget child,
    required double size,
    bool square = true,
  }) {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (context, _) {
        return Container(
          width: square ? size : size * 1.7,
          height: size,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: Colors.white.withOpacity(0.06),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.04 * _glowAnim.value),
                blurRadius: 28 * _glowAnim.value,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: const Color(0xFF6C63FF)
                    .withOpacity(0.12 * _glowAnim.value),
                blurRadius: 42 * _glowAnim.value,
                spreadRadius: 2,
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.contain,
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.82),
        body: FadeTransition(
          opacity: _backgroundFade,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background radial glow
              IgnorePointer(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      radius: 0.9,
                      colors: [
                        Color(0x221565C0),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ───────────── SNIVRA ─────────────

                  FadeTransition(
                    opacity: _snivraFade,
                    child: SlideTransition(
                      position: _snivraSlide,
                      child: ScaleTransition(
                        scale: _snivraScale,
                        child: _glassLogo(
                          size: 120,
                          square: true,
                          child: Image.asset(
                            'assets/snivra.png',
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ───────────── POWERED BY ─────────────

                  FadeTransition(
                    opacity: _poweredFade,
                    child: ShaderMask(
                      shaderCallback: (bounds) {
                        return const LinearGradient(
                          colors: [
                            Colors.white38,
                            Colors.white70,
                            Colors.white38,
                          ],
                        ).createShader(bounds);
                      },
                      child: const Text(
                        'POWERED BY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ───────────── ZLYRO ─────────────

                  FadeTransition(
                    opacity: _zlyroFade,
                    child: SlideTransition(
                      position: _zlyroSlide,
                      child: ScaleTransition(
                        scale: _zlyroScale,
                        child: _glassLogo(
                          size: 90,
                          square: false,
                          child: Image.asset(
                            'assets/zlyro_with_text.png',
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 42),

                  FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _mainCtrl,
                      curve: const Interval(0.82, 1),
                    ),
                    child: const Text(
                      'Crafting modern salon experiences',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
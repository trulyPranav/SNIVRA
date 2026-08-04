import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart' show AuthAuthenticated;
import '../../auth/data/models/auth_model.dart';
import '../bloc/booking_bloc.dart';
import '../bloc/booking_event.dart';
import '../bloc/booking_state.dart';
import '../data/models/booking_model.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  void _loadBookings() {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    final user = authState.user;
    if (user.saloons.isNotEmpty) {
      context.read<BookingBloc>().add(
            BookingSaloonListRequested(saloonId: user.saloons.first.id),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      return const Center(child: CircularProgressIndicator());
    }
    return _SaloonBookingsView(user: authState.user);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Owner / Barber view
// ─────────────────────────────────────────────────────────────────────────────

const _kStatusFilters = ['ALL', 'BOOKED', 'ARRIVED', 'COMPLETED', 'CANCELLED'];

class _SaloonBookingsView extends StatefulWidget {
  const _SaloonBookingsView({required this.user});

  final AuthUser user;

  @override
  State<_SaloonBookingsView> createState() => _SaloonBookingsViewState();
}

class _SaloonBookingsViewState extends State<_SaloonBookingsView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  List<SaloonBooking> _bookings = [];
  String? _actionBookingId;
  String? _otpInput;

  // Optional date filter — null means "all dates"
  DateTime? _dateFilter;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: _kStatusFilters.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _applyFilter();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _applyFilter() {
    final status = _kStatusFilters[_tabController.index];
    context.read<BookingBloc>().add(
          BookingSaloonListRequested(
            saloonId: widget.user.saloons.first.id,
            status: status == 'ALL' ? null : status,
            sessionDate:
                _dateFilter != null ? _fmtDate(_dateFilter!) : null,
          ),
        );
  }

  List<SaloonBooking> get _filtered {
    final status = _kStatusFilters[_tabController.index];
    // Sort by estimatedArrivalAt ascending (per spec — never sort by queue_position)
    final sorted = [..._bookings]
      ..sort((a, b) =>
          a.estimatedArrivalAt.compareTo(b.estimatedArrivalAt));
    if (status == 'ALL') return sorted;
    return sorted
        .where((b) => _statusLabel(b.status).toUpperCase() == status)
        .toList();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateFilter ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _dateFilter = picked);
      _applyFilter();
    }
  }

  void _clearDate() {
    setState(() => _dateFilter = null);
    _applyFilter();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BookingBloc, BookingState>(
      listenWhen: (_, s) =>
          s is BookingSaloonListLoaded ||
          s is BookingActionSuccess ||
          s is BookingActionError ||
          s is BookingActionLoading,
      listener: (context, state) {
        if (state is BookingSaloonListLoaded) {
          setState(() => _bookings = state.bookings);
        } else if (state is BookingActionLoading) {
          setState(() => _actionBookingId = state.bookingId);
        } else if (state is BookingActionSuccess) {
          setState(() {
            _actionBookingId = null;
            // Update local booking status optimistically.
            _bookings = _bookings.map((b) {
              if (b.id != state.bookingId) return b;
              if (state.message.contains('arrived') ||
                  state.message.contains('OTP')) {
                return b.copyWith(status: BookingStatus.arrived);
              }
              if (state.message.contains('completed')) {
                return b.copyWith(status: BookingStatus.completed);
              }
              return b.copyWith(status: BookingStatus.cancelled);
            }).toList();
          });
          _showSnack(context, state.message, success: true);
        } else if (state is BookingActionError) {
          setState(() => _actionBookingId = null);
          _showSnack(context, state.message, success: false);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Saloon Bookings'),
          backgroundColor: AppColors.background,
          surfaceTintColor: AppColors.background,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(96),
            child: Column(
              children: [
                // ── Date filter chip ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      if (_dateFilter != null) ...[
                        ActionChip(
                          label: Text(
                            _fmtDateLabel(_dateFilter!),
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary),
                          ),
                          onPressed: _pickDate,
                          deleteIcon: const Icon(Icons.close,
                              size: 14, color: AppColors.primary),
                          onDeleted: _clearDate,
                          backgroundColor: AppColors.surfaceVariant,
                          side: const BorderSide(color: AppColors.divider),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ] else ...[
                        ActionChip(
                          label: const Text(
                            'All Dates',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary),
                          ),
                          onPressed: _pickDate,
                          avatar: const Icon(Icons.filter_list,
                              size: 13, color: AppColors.textSecondary),
                          backgroundColor: AppColors.surface,
                          side: const BorderSide(color: AppColors.divider),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ],
                  ),
                ),
                // ── Status tabs ───────────────────────────────────────
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: AppColors.primary,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorWeight: 2.5,
                  labelStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  unselectedLabelStyle: const TextStyle(fontSize: 13),
                  tabs: _kStatusFilters
                      .map((s) => Tab(text: s))
                      .toList(),
                ),
              ],
            ),
          ),
        ),
        body: BlocBuilder<BookingBloc, BookingState>(
          buildWhen: (_, s) =>
              s is BookingListLoading ||
              s is BookingSaloonListLoaded ||
              s is BookingListError,
          builder: (context, state) {
            if (state is BookingListLoading) {
              return const Center(
                child:
                    CircularProgressIndicator(color: AppColors.primary),
              );
            }
            if (state is BookingListError) {
              return _ErrorRetry(
                message: state.message,
                onRetry: _applyFilter,
              );
            }
            final items = _filtered;
            if (items.isEmpty) {
              return const _EmptyState(label: 'No bookings found.');
            }
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => _applyFilter(),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                itemCount: items.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final b = items[index];
                  return _SaloonBookingCard(
                    booking: b,
                    isActioning: _actionBookingId == b.id,
                    onVerifyOtp: b.status == BookingStatus.booked
                        ? () => _showOtpDialog(context, b.id)
                        : null,
                    onComplete: b.status == BookingStatus.arrived
                        ? () => _confirmComplete(context, b.id)
                        : null,
                    onCancel: (b.status == BookingStatus.booked ||
                            b.status == BookingStatus.arrived)
                        ? () => _confirmCancel(context, b.id)
                        : null,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _showOtpDialog(BuildContext context, String bookingId) async {
    _otpInput = null;
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Verify Customer OTP'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(
            labelText: 'Enter OTP',
            border: OutlineInputBorder(),
            counterText: '',
          ),
          onChanged: (v) => _otpInput = v,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
    if (ok == true && (_otpInput?.length == 6) && context.mounted) {
      context.read<BookingBloc>().add(
            BookingOtpVerifyRequested(
                bookingId: bookingId, otp: _otpInput!),
          );
    }
  }

  Future<void> _confirmComplete(
      BuildContext context, String bookingId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Complete Booking'),
        content: const Text('Mark this booking as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes',
                style: TextStyle(color: AppColors.success)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context
          .read<BookingBloc>()
          .add(BookingCompleteRequested(bookingId: bookingId));
    }
  }

  Future<void> _confirmCancel(
      BuildContext context, String bookingId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text(
            'Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context
          .read<BookingBloc>()
          .add(BookingCancelRequested(bookingId: bookingId));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Booking card
// ─────────────────────────────────────────────────────────────────────────────

class _SaloonBookingCard extends StatelessWidget {
  const _SaloonBookingCard({
    required this.booking,
    required this.isActioning,
    this.onVerifyOtp,
    this.onComplete,
    this.onCancel,
  });

  final SaloonBooking booking;
  final bool isActioning;
  final VoidCallback? onVerifyOtp;
  final VoidCallback? onComplete;
  final VoidCallback? onCancel;

  // Per-label accent colours (matches sessions page)
  static const _kLabelColors = {
    'MORNING': Color(0xFFFF8F00),
    'AFTERNOON': Color(0xFF1565C0),
    'EVENING': Color(0xFF4527A0),
  };

  Color get _sessionColor =>
      _kLabelColors[booking.sessionLabel] ?? AppColors.primary;

  String get _arrivalTime {
    final t = booking.estimatedArrivalAt;
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return _BookingCardShell(
      status: booking.status,
      isActioning: isActioning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: customer name + status chip ───────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.customerName ?? 'Customer',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _StatusChip(status: booking.status),
            ],
          ),
          if (booking.customerPhone != null) ...[
            const SizedBox(height: 2),
            Text(
              booking.customerPhone!,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textHint),
            ),
          ],
          const SizedBox(height: 8),

          // ── Session label + date ──────────────────────────────────────
          Row(
            children: [
              if (booking.sessionLabel.isNotEmpty) ...[
                _SessionLabelBadge(
                  label: booking.sessionLabel,
                  color: _sessionColor,
                ),
                const SizedBox(width: 8),
              ],
              const Icon(Icons.calendar_today_outlined,
                  size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                booking.sessionDate,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 5),

          // ── "Your turn at HH:MM" ─────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.schedule_outlined,
                  size: 13, color: AppColors.primary),
              const SizedBox(width: 4),
              RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Your turn at ',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                    TextSpan(
                      text: _arrivalTime,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _DurationChip(
                  minutes: booking.allocatedDurationMinutes),
            ],
          ),
          const SizedBox(height: 4),

          // ── Barber ───────────────────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.content_cut_outlined,
                  size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(booking.barberName,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),

          // ── Services ─────────────────────────────────────────────────
          if (booking.services.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.spa_outlined,
                    size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    booking.services.map((s) => s.name).join(', '),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ],

          // ── Action row ───────────────────────────────────────────────
          if (onVerifyOtp != null ||
              onComplete != null ||
              onCancel != null) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isActioning)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  )
                else ...[
                  if (onVerifyOtp != null)
                    _ActionButton(
                      label: 'Verify OTP',
                      color: AppColors.primary,
                      onTap: onVerifyOtp!,
                    ),
                  if (onComplete != null) ...[
                    const SizedBox(width: 8),
                    _ActionButton(
                      label: 'Complete',
                      color: AppColors.success,
                      onTap: onComplete!,
                    ),
                  ],
                  if (onCancel != null) ...[
                    const SizedBox(width: 8),
                    _ActionButton(
                      label: 'Cancel',
                      color: AppColors.error,
                      onTap: onCancel!,
                    ),
                  ],
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared card shell — white card with coloured left accent
// ─────────────────────────────────────────────────────────────────────────────

class _BookingCardShell extends StatelessWidget {
  const _BookingCardShell({
    required this.status,
    required this.isActioning,
    required this.child,
  });

  final BookingStatus status;
  final bool isActioning;
  final Widget child;

  Color get _accentColor {
    switch (status) {
      case BookingStatus.booked:
        return AppColors.primary;
      case BookingStatus.arrived:
        return const Color(0xFFFFA000);
      case BookingStatus.completed:
        return AppColors.success;
      case BookingStatus.cancelled:
      case BookingStatus.noShow:
        return AppColors.textHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isActioning ? 0.6 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.07),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border(
            left: BorderSide(color: _accentColor, width: 4),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SessionLabelBadge extends StatelessWidget {
  const _SessionLabelBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  const _DurationChip({required this.minutes});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${minutes}min',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final BookingStatus status;

  String get _label => _statusLabel(status);

  Color get _bg {
    switch (status) {
      case BookingStatus.booked:
        return const Color(0xFFE3F2FD);
      case BookingStatus.arrived:
        return const Color(0xFFFFF8E1);
      case BookingStatus.completed:
        return const Color(0xFFE8F5E9);
      case BookingStatus.cancelled:
      case BookingStatus.noShow:
        return const Color(0xFFF5F5F5);
    }
  }

  Color get _fg {
    switch (status) {
      case BookingStatus.booked:
        return AppColors.primary;
      case BookingStatus.arrived:
        return const Color(0xFFF57C00);
      case BookingStatus.completed:
        return AppColors.success;
      case BookingStatus.cancelled:
      case BookingStatus.noShow:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _fg,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.event_available_outlined,
              size: 52, color: AppColors.divider),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
                fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                color: AppColors.error, size: 40),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

String _statusLabel(BookingStatus s) {
  switch (s) {
    case BookingStatus.booked:
      return 'BOOKED';
    case BookingStatus.arrived:
      return 'ARRIVED';
    case BookingStatus.completed:
      return 'COMPLETED';
    case BookingStatus.cancelled:
      return 'CANCELLED';
    case BookingStatus.noShow:
      return 'NO SHOW';
  }
}

void _showSnack(BuildContext context, String msg, {required bool success}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor:
          success ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ),
  );
}

/// Formats a date as "5 Aug 2026" without requiring the intl package.
String _fmtDateLabel(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

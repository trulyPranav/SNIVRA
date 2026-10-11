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
// Status filters
// ─────────────────────────────────────────────────────────────────────────────

const _kStatusFilters = ['ALL', 'BOOKED', 'ARRIVED', 'COMPLETED', 'CANCELLED'];

class _SaloonBookingsView extends StatefulWidget {
  const _SaloonBookingsView({required this.user});
  final AuthUser user;

  @override
  State<_SaloonBookingsView> createState() => _SaloonBookingsViewState();
}

class _SaloonBookingsViewState extends State<_SaloonBookingsView> {
  List<SaloonBooking> _bookings = [];
  String? _actionBookingId;
  String? _otpInput;
  DateTime? _dateFilter;
  int _filterIndex = 0;

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _applyFilter() {
    final status = _kStatusFilters[_filterIndex];
    context.read<BookingBloc>().add(
          BookingSaloonListRequested(
            saloonId: widget.user.saloons.first.id,
            status: status == 'ALL' ? null : status,
            sessionDate: _dateFilter != null ? _fmtDate(_dateFilter!) : null,
          ),
        );
  }

  List<SaloonBooking> get _filtered {
    final status = _kStatusFilters[_filterIndex];
    final sorted = [..._bookings]
      ..sort((a, b) => a.estimatedArrivalAt.compareTo(b.estimatedArrivalAt));
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

  void _setFilter(int index) {
    setState(() => _filterIndex = index);
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Filters ──────────────────────────────────────────────
          _FiltersBar(
            filterIndex: _filterIndex,
            onFilterChanged: _setFilter,
            dateFilter: _dateFilter,
            onPickDate: _pickDate,
            onClearDate: _clearDate,
          ),

          // ── Count ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: BlocBuilder<BookingBloc, BookingState>(
              buildWhen: (_, s) =>
                  s is BookingSaloonListLoaded || s is BookingListLoading,
              builder: (context, state) {
                if (state is BookingListLoading) return const SizedBox.shrink();
                final n = _filtered.length;
                final tag = _kStatusFilters[_filterIndex] == 'ALL'
                    ? 'booking${n == 1 ? '' : 's'}'
                    : _kStatusFilters[_filterIndex].toLowerCase();
                return Text(
                  '$n $tag',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textHint,
                  ),
                );
              },
            ),
          ),

          // ── List ─────────────────────────────────────────────────
          Expanded(
            child: BlocBuilder<BookingBloc, BookingState>(
              buildWhen: (_, s) =>
                  s is BookingListLoading ||
                  s is BookingSaloonListLoaded ||
                  s is BookingListError,
              builder: (context, state) {
                if (state is BookingListLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  );
                }
                if (state is BookingListError) {
                  return _ErrorView(
                    message: state.message,
                    onRetry: _applyFilter,
                  );
                }

                final items = _filtered;
                if (items.isEmpty) return const _EmptyView();

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async => _applyFilter(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final b = items[index];
                      return _BookingCard(
                        booking: b,
                        isActioning: _actionBookingId == b.id,
                        onVerifyOtp: b.status == BookingStatus.booked
                            ? () => _showOtpSheet(context, b.id)
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
        ],
      ),
    );
  }

  // ── OTP bottom sheet ────────────────────────────────────────────────────────

  Future<void> _showOtpSheet(BuildContext ctx, String bookingId) async {
    _otpInput = null;
    final controller = TextEditingController();
    final result = await showModalBottomSheet<bool>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 20, 24, MediaQuery.of(sheetCtx).viewInsets.bottom + 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: 24),
            const Text(
              'Verify OTP',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Enter the 6-digit code from your customer',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 6,
              autofocus: true,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: 10,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                counterText: '',
                hintText: '••••••',
                hintStyle: TextStyle(
                  color: AppColors.textHint.withAlpha(80),
                  fontSize: 28,
                  letterSpacing: 10,
                ),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 18),
              ),
              onChanged: (v) => _otpInput = v,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.pop(sheetCtx, true),
                child: const Text(
                  'Verify',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (result == true && (_otpInput?.length == 6) && ctx.mounted) {
      ctx.read<BookingBloc>().add(
            BookingOtpVerifyRequested(bookingId: bookingId, otp: _otpInput!),
          );
    }
  }

  // ── Confirm complete ────────────────────────────────────────────────────────

  Future<void> _confirmComplete(BuildContext ctx, String bookingId) async {
    final ok = await showModalBottomSheet<bool>(
      context: ctx,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 28),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.success.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline_rounded,
                  color: AppColors.success, size: 28),
            ),
            const SizedBox(height: 16),
            const Text(
              'Complete Booking',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Mark this booking as completed?',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.divider),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(sheetCtx, false),
                      child: const Text('Cancel',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(sheetCtx, true),
                      child: const Text('Complete'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (ok == true && ctx.mounted) {
      ctx.read<BookingBloc>().add(BookingCompleteRequested(bookingId: bookingId));
    }
  }

  // ── Confirm cancel ──────────────────────────────────────────────────────────

  Future<void> _confirmCancel(BuildContext ctx, String bookingId) async {
    final ok = await showModalBottomSheet<bool>(
      context: ctx,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 28),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cancel_outlined,
                  color: AppColors.error, size: 28),
            ),
            const SizedBox(height: 16),
            const Text(
              'Cancel Booking',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Are you sure? This cannot be undone.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.divider),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(sheetCtx, false),
                      child: const Text('Go Back',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(sheetCtx, true),
                      child: const Text('Cancel Booking'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (ok == true && ctx.mounted) {
      ctx.read<BookingBloc>().add(BookingCancelRequested(bookingId: bookingId));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filters bar — date chip + status pills in one scrollable row
// ─────────────────────────────────────────────────────────────────────────────

class _FiltersBar extends StatelessWidget {
  const _FiltersBar({
    required this.filterIndex,
    required this.onFilterChanged,
    required this.dateFilter,
    required this.onPickDate,
    required this.onClearDate,
  });

  final int filterIndex;
  final ValueChanged<int> onFilterChanged;
  final DateTime? dateFilter;
  final VoidCallback onPickDate;
  final VoidCallback onClearDate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Date chip
            GestureDetector(
              onTap: onPickDate,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: dateFilter != null
                      ? AppColors.primary.withAlpha(12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: dateFilter != null
                        ? AppColors.primary.withAlpha(60)
                        : AppColors.divider,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 13,
                      color: dateFilter != null
                          ? AppColors.primary
                          : AppColors.textHint,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dateFilter != null
                          ? _fmtDateLabel(dateFilter!)
                          : 'All dates',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: dateFilter != null
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                    if (dateFilter != null) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: onClearDate,
                        child: Icon(Icons.close_rounded,
                            size: 14,
                            color: AppColors.primary.withAlpha(180)),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Separator
            Container(
              width: 1,
              height: 22,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              color: AppColors.divider,
            ),

            // Status pills
            ...List.generate(_kStatusFilters.length, (i) {
              final selected = i == filterIndex;
              final raw = _kStatusFilters[i];
              final label = raw == 'ALL'
                  ? 'All'
                  : raw[0] + raw.substring(1).toLowerCase();
              return Padding(
                padding: EdgeInsets.only(
                    right: i < _kStatusFilters.length - 1 ? 6 : 0),
                child: GestureDetector(
                  onTap: () => onFilterChanged(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color:
                          selected ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            selected ? AppColors.primary : AppColors.divider,
                      ),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                        color: selected
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Booking card
// ─────────────────────────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  const _BookingCard({
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

  // static const _kSessionColors = {
  //   'MORNING': Color(0xFFFF8F00),
  //   'AFTERNOON': Color(0xFF1565C0),
  //   'EVENING': Color(0xFF4527A0),
  // };

  String get _arrivalTime {
    final t = booking.estimatedArrivalAt;
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  bool get _hasActions =>
      onVerifyOtp != null || onComplete != null || onCancel != null;

  @override
  Widget build(BuildContext context) {
    final isDone = booking.status == BookingStatus.completed ||
        booking.status == BookingStatus.cancelled ||
        booking.status == BookingStatus.noShow;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isActioning ? 0.5 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDone ? 4 : 10),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: avatar + name + status ────────────────────
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _statusAccent(booking.status).withAlpha(15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _initials(booking.customerName),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _statusAccent(booking.status),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.customerName ?? 'Customer',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (booking.customerPhone != null)
                        Text(
                          booking.customerPhone!,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textHint),
                        ),
                    ],
                  ),
                ),
                _StatusPill(status: booking.status),
              ],
            ),

            const SizedBox(height: 14),

            // ── Services ──────────────────────────────────────────
            if (booking.services.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  booking.services.map((s) => s.name).join(' · '),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // ── Metadata row ──────────────────────────────────────
            Row(
              children: [
                _MetaChip(
                    icon: Icons.content_cut_rounded,
                    text: booking.barberName),
                const SizedBox(width: 14),
                _MetaChip(
                  icon: Icons.schedule_rounded,
                  text: _arrivalTime,
                  bold: true,
                ),
                const SizedBox(width: 14),
                _MetaChip(
                  icon: Icons.timer_outlined,
                  text: '${booking.allocatedDurationMinutes}m',
                ),
                const SizedBox(width: 14),
                _MetaChip(
                  icon: Icons.calendar_today_rounded,
                  text: _fmtDateLabel(DateTime.parse(booking.sessionDate)),
                ),
                // if (booking.sessionLabel.isNotEmpty) ...[
                //   const Spacer(),
                //   _SessionDot(
                //     label: booking.sessionLabel,
                //     color: _kSessionColors[booking.sessionLabel] ??
                //         AppColors.primary,
                //   ),
                // ],
              ],
            ),

            // ── Actions ───────────────────────────────────────────
            if (_hasActions) ...[
              const SizedBox(height: 14),
              const Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: 12),
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
                    if (onCancel != null) ...[
                      _CardAction(
                        label: 'Cancel',
                        color: AppColors.error,
                        filled: false,
                        onTap: onCancel!,
                      ),
                      const SizedBox(width: 10),
                    ],
                    if (onVerifyOtp != null)
                      _CardAction(
                        label: 'Verify OTP',
                        color: AppColors.primary,
                        filled: true,
                        onTap: onVerifyOtp!,
                      ),
                    if (onComplete != null)
                      _CardAction(
                        label: 'Complete',
                        color: AppColors.success,
                        filled: true,
                        onTap: onComplete!,
                      ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small widgets
// ─────────────────────────────────────────────────────────────────────────────

Color _statusAccent(BookingStatus status) {
  switch (status) {
    case BookingStatus.booked:
      return AppColors.primary;
    case BookingStatus.arrived:
      return const Color(0xFFF57C00);
    case BookingStatus.completed:
      return AppColors.success;
    case BookingStatus.cancelled:
    case BookingStatus.noShow:
      return AppColors.textHint;
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _statusAccent(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text, this.bold = false});
  final IconData icon;
  final String text;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textHint),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
            color: bold ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _SessionDot extends StatelessWidget {
  const _SessionDot({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          label[0] + label.substring(1).toLowerCase(),
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}

class _CardAction extends StatelessWidget {
  const _CardAction({
    required this.label,
    required this.color,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 34),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onTap,
        child: Text(label,
            style:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      );
    }
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withAlpha(80)),
        minimumSize: const Size(0, 34),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: onTap,
      child: Text(label,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty + Error states
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.event_available_outlined,
                size: 32, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text(
            'No bookings found',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Bookings will appear here',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline,
                  color: AppColors.error, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 42,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
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
      backgroundColor: success ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      duration: const Duration(seconds: 3),
    ),
  );
}

String _fmtDateLabel(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

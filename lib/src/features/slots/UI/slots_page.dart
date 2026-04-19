import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../auth/data/models/auth_model.dart';
import '../bloc/slot_bloc.dart';
import '../bloc/slot_event.dart';
import '../bloc/slot_state.dart';
import '../data/models/slot_model.dart';

// ─────────────────────────────── SlotsPage ────────────────────────────────────

class SlotsPage extends StatefulWidget {
  const SlotsPage({super.key});

  @override
  State<SlotsPage> createState() => _SlotsPageState();
}

class _SlotsPageState extends State<SlotsPage> {
  DateTime _focusedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  // Cached calendar data so day-detail navigation doesn't wipe it
  List<ConfiguredDate> _calendarCache = [];

  String get _monthKey =>
      '${_focusedMonth.year}-${_focusedMonth.month.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _loadCalendar();
  }

  void _loadCalendar() {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    final saloonId = _saloonId(authState.user);
    if (saloonId == null) return;
    context
        .read<SlotBloc>()
        .add(SlotMonthRequested(saloonId: saloonId, month: _monthKey));
  }

  String? _saloonId(AuthUser user) =>
      user.saloons.isNotEmpty ? user.saloons.first.id : null;

  void _changeMonth(int delta) {
    setState(() {
      _focusedMonth =
          DateTime(_focusedMonth.year, _focusedMonth.month + delta);
    });
    _loadCalendar();
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();
    final user = authState.user;
    final saloonId = _saloonId(user);
    final isOwner = user.role == UserRole.owner;
    final canGenerate = isOwner || user.role == UserRole.barber;

    if (saloonId == null) {
      return const Center(
        child: Text(
          'No saloon linked to your account.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return BlocConsumer<SlotBloc, SlotState>(
      listener: (context, state) {
        if (state is SlotCalendarLoaded) {
          setState(() => _calendarCache = state.configuredDates);
        }
        if (state is SlotGenerateSuccess) {
          final msg = state.summary != null
              ? 'Created ${state.summary!.totalInsertedSlots} slots across ${state.summary!.totalDates} day(s).'
              : 'Slots created successfully.';
          _snack(context, msg, AppColors.primary);
          context.read<SlotBloc>().add(
              SlotMonthRequested(saloonId: saloonId, month: _monthKey));
        } else if (state is SlotGenerateError) {
          _snack(context, state.message, Colors.red);
        } else if (state is SlotToggleError) {
          _snack(context, state.message, Colors.red);
        }
      },
      builder: (context, state) {
        final isCalendarLoading = state is SlotCalendarLoading;
        final isGenerating = state is SlotGenerating;

        return Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _CalendarCard(
                    focusedMonth: _focusedMonth,
                    configuredDates: _calendarCache,
                    isLoading: isCalendarLoading,
                    onPrev: () => _changeMonth(-1),
                    onNext: () => _changeMonth(1),
                    onDayTap: (date) => _openDayDetail(
                      context,
                      saloonId: saloonId,
                      date: _fmtDate(date),
                      user: user,
                      isOwner: isOwner,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                if (canGenerate)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _QuickActions(
                        onGenerateSingle: () => _showGenerateSheet(
                          context,
                          saloonId: saloonId,
                          user: user,
                        ),
                        onGenerateBulk: () => _showBulkSheet(
                          context,
                          saloonId: saloonId,
                          user: user,
                        ),
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
            if (isGenerating)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x55FFFFFF),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        );
      },
    );
  }

  void _openDayDetail(
    BuildContext context, {
    required String saloonId,
    required String date,
    required AuthUser user,
    required bool isOwner,
  }) {
    context
        .read<SlotBloc>()
        .add(SlotDayDetailRequested(saloonId: saloonId, date: date));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => BlocProvider.value(
        value: context.read<SlotBloc>(),
        child: _DayDetailSheet(
          saloonId: saloonId,
          date: date,
          isOwner: isOwner,
          user: user,
          onGenerateForDay: () {
            Navigator.of(sheetCtx).pop();
            _showGenerateSheet(context,
                saloonId: saloonId,
                user: user,
                prefillDate: DateTime.parse(date));
          },
        ),
      ),
    );
  }

  void _showGenerateSheet(
    BuildContext context, {
    required String saloonId,
    required AuthUser user,
    DateTime? prefillDate,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<SlotBloc>(),
        child: _GenerateSingleSheet(
          saloonId: saloonId,
          user: user,
          prefillDate: prefillDate,
        ),
      ),
    );
  }

  void _showBulkSheet(
    BuildContext context, {
    required String saloonId,
    required AuthUser user,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<SlotBloc>(),
        child: _GenerateBulkSheet(saloonId: saloonId, user: user),
      ),
    );
  }
}

void _snack(BuildContext context, String msg, Color color) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg),
    backgroundColor: color,
    behavior: SnackBarBehavior.floating,
  ));
}

// ─────────────────────────────── Calendar ────────────────────────────────────

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({
    required this.focusedMonth,
    required this.configuredDates,
    required this.isLoading,
    required this.onPrev,
    required this.onNext,
    required this.onDayTap,
  });

  final DateTime focusedMonth;
  final List<ConfiguredDate> configuredDates;
  final bool isLoading;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onDayTap;

  static const _weekdays = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context) {
    final configuredSet = {
      for (final d in configuredDates)
        '${d.date.year}-${d.date.month}-${d.date.day}': d,
    };
    final firstOfMonth =
        DateTime(focusedMonth.year, focusedMonth.month, 1);
    final startOffset = (firstOfMonth.weekday - 1) % 7;
    final daysInMonth =
        DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;
    final today = DateTime.now();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A0D1B2A),
                blurRadius: 8,
                offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            // Month nav
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    color: AppColors.textSecondary,
                    onPressed: onPrev,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                        minWidth: 36, minHeight: 36),
                  ),
                  Expanded(
                    child: Center(
                      child: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary),
                            )
                          : Text(
                              '${_monthNames[focusedMonth.month - 1]} ${focusedMonth.year}',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    color: AppColors.textSecondary,
                    onPressed: onNext,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                        minWidth: 36, minHeight: 36),
                  ),
                ],
              ),
            ),
            // Weekday labels
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: _weekdays
                    .map((d) => Expanded(
                          child: Center(
                            child: Text(d,
                                style: const TextStyle(
                                    color: AppColors.textHint,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 6),
            // Grid
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  childAspectRatio: 1,
                ),
                itemCount: startOffset + daysInMonth,
                itemBuilder: (_, index) {
                  if (index < startOffset) return const SizedBox.shrink();
                  final day = index - startOffset + 1;
                  final date = DateTime(
                      focusedMonth.year, focusedMonth.month, day);
                  final key =
                      '${date.year}-${date.month}-${date.day}';
                  final configured = configuredSet[key];
                  final isToday = date.year == today.year &&
                      date.month == today.month &&
                      date.day == today.day;
                  final isPast = date.isBefore(
                      DateTime(today.year, today.month, today.day));
                  return _DayCell(
                    day: day,
                    isToday: isToday,
                    isPast: isPast,
                    slotCount: configured?.slotCount,
                    onTap: () => onDayTap(date),
                  );
                },
              ),
            ),
            // Legend
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(
                children: [
                  _LegendDot(color: AppColors.primary.withAlpha(200)),
                  const SizedBox(width: 6),
                  const Text('Has slots',
                      style: TextStyle(
                          color: AppColors.textHint, fontSize: 11)),
                  const SizedBox(width: 16),
                  _LegendDot(color: AppColors.divider),
                  const SizedBox(width: 6),
                  const Text('No slots',
                      style: TextStyle(
                          color: AppColors.textHint, fontSize: 11)),
                  const SizedBox(width: 16),
                  _LegendDot(
                      color: AppColors.primaryLight, isRing: true),
                  const SizedBox(width: 6),
                  const Text('Today',
                      style: TextStyle(
                          color: AppColors.textHint, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isPast,
    required this.onTap,
    this.slotCount,
  });

  final int day;
  final bool isToday;
  final bool isPast;
  final int? slotCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasSlots = slotCount != null && slotCount! > 0;
    Color bgColor = Colors.transparent;
    Color textColor = AppColors.textPrimary;
    Color? borderColor;

    if (isToday) {
      borderColor = AppColors.primaryLight;
      textColor = AppColors.primaryLight;
    }
    if (hasSlots) {
      bgColor = AppColors.primary.withAlpha(200);
      textColor = Colors.white;
      borderColor = null;
    }
    if (isPast && !hasSlots) textColor = AppColors.textHint;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: borderColor != null
              ? Border.all(color: borderColor, width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$day',
                style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: hasSlots || isToday
                        ? FontWeight.w700
                        : FontWeight.w400)),
            if (hasSlots)
              Text('$slotCount',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, this.isRing = false});

  final Color color;
  final bool isRing;

  @override
  Widget build(BuildContext context) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isRing ? Colors.transparent : color,
          border: isRing ? Border.all(color: color, width: 1.5) : null,
        ),
      );
}

// ─────────────────────────────── Day Detail Sheet ─────────────────────────────

class _DayDetailSheet extends StatefulWidget {
  const _DayDetailSheet({
    required this.saloonId,
    required this.date,
    required this.isOwner,
    required this.user,
    required this.onGenerateForDay,
  });

  final String saloonId;
  final String date;
  final bool isOwner;
  final AuthUser user;
  final VoidCallback onGenerateForDay;

  @override
  State<_DayDetailSheet> createState() => _DayDetailSheetState();
}

class _DayDetailSheetState extends State<_DayDetailSheet> {
  // Local cache — survives any unrelated bloc state changes
  List<SlotDetail> _slots = [];
  bool _loading = true; // true on open: event was already dispatched
  String? _togglingId;

  String _prettyDate(String d) {
    try {
      final dt = DateTime.parse(d);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return d;
    }
  }

  @override
  Widget build(BuildContext context) {
    final canGenerate = widget.isOwner || widget.user.role == UserRole.barber;
    return BlocListener<SlotBloc, SlotState>(
      listenWhen: (_, s) =>
          s is SlotDayLoading ||
          s is SlotDayLoaded ||
          s is SlotDayError ||
          s is SlotToggling ||
          s is SlotToggleSuccess ||
          s is SlotToggleError,
      listener: (context, state) {
        if (state is SlotDayLoading) {
          setState(() => _loading = true);
        } else if (state is SlotDayLoaded) {
          setState(() {
            _slots = state.slots;
            _loading = false;
          });
        } else if (state is SlotDayError) {
          setState(() => _loading = false);
          _snack(context, state.message, Colors.red);
        } else if (state is SlotToggling) {
          setState(() => _togglingId = state.slotId);
        } else if (state is SlotToggleSuccess) {
          setState(() => _togglingId = null);
          context.read<SlotBloc>().add(
              SlotDayDetailRequested(
                  saloonId: widget.saloonId, date: widget.date));
        } else if (state is SlotToggleError) {
          setState(() => _togglingId = null);
          _snack(context, state.message, Colors.red);
        }
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _prettyDate(widget.date),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (!_loading)
                          Text(
                            '${_slots.length} slot${_slots.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12),
                          ),
                      ],
                    ),
                    const Spacer(),
                    if (canGenerate)
                      TextButton.icon(
                        onPressed: widget.onGenerateForDay,
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Generate'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: AppColors.textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                          minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.divider),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _slots.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.calendar_today_outlined,
                                    size: 40,
                                    color: AppColors.textHint
                                        .withAlpha(100)),
                                const SizedBox(height: 12),
                                const Text(
                                  'No slots for this day.',
                                  style: TextStyle(
                                      color: AppColors.textHint,
                                      fontSize: 14),
                                ),
                                if (canGenerate)
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(top: 12),
                                    child: OutlinedButton.icon(
                                      onPressed: widget.onGenerateForDay,
                                      icon: const Icon(
                                          Icons.add_rounded,
                                          size: 16),
                                      label:
                                          const Text('Generate slots'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor:
                                            AppColors.primary,
                                        side: const BorderSide(
                                            color: AppColors.primary),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : Stack(
                            children: [
                              ListView.separated(
                                controller: controller,
                                padding: const EdgeInsets.fromLTRB(
                                    16, 12, 16, 40),
                                itemCount: _slots.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (_, i) => _SlotTile(
                                  slot: _slots[i],
                                  isOwner: widget.isOwner,
                                  isToggling: _togglingId == _slots[i].id,
                                  onToggle: widget.isOwner
                                      ? (val) =>
                                          context
                                              .read<SlotBloc>()
                                              .add(SlotAvailabilityToggled(
                                                slotId: _slots[i].id,
                                                isAvailable: val,
                                              ))
                                      : null,
                                ),
                              ),
                              if (_togglingId != null)
                                const Positioned.fill(
                                  child: ColoredBox(
                                    color: Color(0x22FFFFFF),
                                  ),
                                ),
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.slot,
    required this.isOwner,
    required this.isToggling,
    this.onToggle,
  });

  final SlotDetail slot;
  final bool isOwner;
  final bool isToggling;
  final ValueChanged<bool>? onToggle;

  @override
  Widget build(BuildContext context) {
    final available = slot.isAvailable;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: available
            ? AppColors.primary.withAlpha(12)
            : AppColors.divider.withAlpha(80),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: available
              ? AppColors.primary.withAlpha(60)
              : AppColors.divider,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: available ? AppColors.primary : AppColors.textHint,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${slot.startTime} – ${slot.endTime}',
                  style: TextStyle(
                    color: available
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (slot.barberName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      slot.barberName!,
                      style: const TextStyle(
                          color: AppColors.textHint, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
          if (isOwner)
            isToggling
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Switch.adaptive(
                    value: available,
                    onChanged: onToggle,
                    activeColor: AppColors.primary,
                  )
          else
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: available
                    ? AppColors.primary.withAlpha(20)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      available ? AppColors.primary : AppColors.textHint,
                ),
              ),
              child: Text(
                available ? 'Available' : 'Unavailable',
                style: TextStyle(
                  color: available ? AppColors.primary : AppColors.textHint,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────── Quick Actions ───────────────────────────────

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onGenerateSingle,
    required this.onGenerateBulk,
  });

  final VoidCallback onGenerateSingle;
  final VoidCallback onGenerateBulk;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: _ActionCard(
              icon: Icons.add_circle_outline_rounded,
              label: 'Single Day',
              subtitle: 'Generate slots for one date',
              onTap: onGenerateSingle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionCard(
              icon: Icons.date_range_rounded,
              label: 'Date Range',
              subtitle: 'Bulk generate for many days',
              onTap: onGenerateBulk,
            ),
          ),
        ],
      );
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x0A0D1B2A),
                  blurRadius: 6,
                  offset: Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(height: 12),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(subtitle,
                  style: const TextStyle(
                      color: AppColors.textHint, fontSize: 11)),
            ],
          ),
        ),
      );
}

// ─────────────────────────── Shared sheet helpers ─────────────────────────────

class _SheetScaffold extends StatelessWidget {
  const _SheetScaffold({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: AppColors.textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                          minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.divider),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  children: [child],
                ),
              ),
            ],
          ),
        ),
      );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3)),
      );
}

InputDecoration _fieldDecoration(String hint, {IconData? icon}) =>
    InputDecoration(
      hintText: hint,
      hintStyle:
          const TextStyle(color: AppColors.textHint, fontSize: 14),
      prefixIcon: icon != null
          ? Icon(icon, color: AppColors.textHint, size: 18)
          : null,
      filled: true,
      fillColor: AppColors.surfaceVariant,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );

Widget _datePickerTheme(BuildContext ctx, Widget? child) => Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          surface: Colors.white,
        ),
      ),
      child: child!,
    );

// ─────────────────────────── Barber Picker ───────────────────────────────────

/// For owners: dropdown with "All members", individual barbers, and "Myself".
/// Lazy-loads via SlotMembersRequested on first build.
class _BarberPicker extends StatefulWidget {
  const _BarberPicker({
    required this.saloonId,
    required this.currentUserId,
    required this.onChanged,
  });

  final String saloonId;
  final String currentUserId;
  final ValueChanged<String?> onChanged; // null = all members

  @override
  State<_BarberPicker> createState() => _BarberPickerState();
}

class _BarberPickerState extends State<_BarberPicker> {
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    context
        .read<SlotBloc>()
        .add(SlotMembersRequested(saloonId: widget.saloonId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SlotBloc, SlotState>(
      buildWhen: (_, n) =>
          n is SlotMembersLoading ||
          n is SlotMembersLoaded ||
          n is SlotMembersError,
      builder: (context, state) {
        if (state is SlotMembersLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Center(
                child:
                    CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        final members = state is SlotMembersLoaded
            ? state.members
            : <SaloonMember>[];

        final items = <DropdownMenuItem<String?>>[];
        items.add(const DropdownMenuItem(
          value: null,
          child: Text('All members',
              style:
                  TextStyle(color: AppColors.textPrimary, fontSize: 14)),
        ));
        for (final m in members) {
          final isSelf = m.id == widget.currentUserId;
          items.add(DropdownMenuItem(
            value: m.id,
            child: Text(
              isSelf ? 'Myself (${m.name})' : m.name,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ));
        }

        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _selectedId,
              isExpanded: true,
              items: items,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 14),
              dropdownColor: Colors.white,
              onChanged: (v) {
                setState(() => _selectedId = v);
                widget.onChanged(v);
              },
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────── Generate Single Sheet ───────────────────────────

class _GenerateSingleSheet extends StatefulWidget {
  const _GenerateSingleSheet({
    required this.saloonId,
    required this.user,
    this.prefillDate,
  });

  final String saloonId;
  final AuthUser user;
  final DateTime? prefillDate;

  @override
  State<_GenerateSingleSheet> createState() =>
      _GenerateSingleSheetState();
}

class _GenerateSingleSheetState extends State<_GenerateSingleSheet> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);
  final _durationCtrl = TextEditingController(text: '30');
  String? _barberId; // null = all members (owners); barber's own id for barbers

  bool get _isOwner => widget.user.role == UserRole.owner;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.prefillDate;
    if (!_isOwner) _barberId = widget.user.id;
  }

  @override
  void dispose() {
    _durationCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      builder: _datePickerTheme,
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: _datePickerTheme,
    );
    if (picked != null) {
      setState(() => isStart ? _startTime = picked : _endTime = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      _snack(context, 'Please select a date.', Colors.red);
      return;
    }
    final duration = int.tryParse(_durationCtrl.text.trim()) ?? 0;
    if (duration <= 0) return;
    context.read<SlotBloc>().add(SlotGenerateSingleRequested(
          saloonId: widget.saloonId,
          slotDate: _fmtDate(_selectedDate!),
          startTime: _fmtTime(_startTime),
          endTime: _fmtTime(_endTime),
          slotDurationMin: duration,
          barberId: _barberId,
        ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'Generate Slots — Single Day',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Assign-to section
            if (_isOwner) ...[
              const _FieldLabel('ASSIGN TO'),
              _BarberPicker(
                saloonId: widget.saloonId,
                currentUserId: widget.user.id,
                onChanged: (v) => setState(() => _barberId = v),
              ),
              const SizedBox(height: 18),
            ] else ...[
              const _FieldLabel('ASSIGNED TO'),
              _AssignedSelfChip(name: widget.user.name),
              const SizedBox(height: 18),
            ],

            // Date
            const _FieldLabel('DATE'),
            _DateTile(date: _selectedDate, onTap: _pickDate),
            const SizedBox(height: 18),

            // Times
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FieldLabel('START TIME'),
                      _TimeTile(
                          time: _startTime, onTap: () => _pickTime(true)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FieldLabel('END TIME'),
                      _TimeTile(
                          time: _endTime, onTap: () => _pickTime(false)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Duration
            const _FieldLabel('SLOT DURATION (MINUTES)'),
            TextFormField(
              controller: _durationCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 14),
              decoration: _fieldDecoration('e.g. 30',
                  icon: Icons.timer_outlined),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Enter a valid duration';
                return null;
              },
            ),
            const SizedBox(height: 28),
            _SubmitButton(label: 'Generate Slots', onPressed: _submit),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── Generate Bulk Sheet ─────────────────────────────

class _GenerateBulkSheet extends StatefulWidget {
  const _GenerateBulkSheet({
    required this.saloonId,
    required this.user,
  });

  final String saloonId;
  final AuthUser user;

  @override
  State<_GenerateBulkSheet> createState() => _GenerateBulkSheetState();
}

class _GenerateBulkSheetState extends State<_GenerateBulkSheet> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);
  final _durationCtrl = TextEditingController(text: '30');
  String? _barberId;

  bool get _isOwner => widget.user.role == UserRole.owner;

  @override
  void initState() {
    super.initState();
    if (!_isOwner) _barberId = widget.user.id;
  }

  @override
  void dispose() {
    _durationCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? now)
          : (_endDate ?? _startDate ?? now),
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      builder: _datePickerTheme,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: _datePickerTheme,
    );
    if (picked != null) {
      setState(() => isStart ? _startTime = picked : _endTime = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      _snack(context, 'Please select start and end dates.', Colors.red);
      return;
    }
    final duration = int.tryParse(_durationCtrl.text.trim()) ?? 0;
    if (duration <= 0) return;
    context.read<SlotBloc>().add(SlotGenerateBulkRequested(
          saloonId: widget.saloonId,
          startDate: _fmtDate(_startDate!),
          endDate: _fmtDate(_endDate!),
          startTime: _fmtTime(_startTime),
          endTime: _fmtTime(_endTime),
          slotDurationMin: duration,
          barberId: _barberId,
        ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'Generate Slots — Date Range',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Assign-to section
            if (_isOwner) ...[
              const _FieldLabel('ASSIGN TO'),
              _BarberPicker(
                saloonId: widget.saloonId,
                currentUserId: widget.user.id,
                onChanged: (v) => setState(() => _barberId = v),
              ),
              const SizedBox(height: 18),
            ] else ...[
              const _FieldLabel('ASSIGNED TO'),
              _AssignedSelfChip(name: widget.user.name),
              const SizedBox(height: 18),
            ],

            // Date range
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FieldLabel('FROM'),
                      _DateTile(
                          date: _startDate,
                          onTap: () => _pickDate(true)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FieldLabel('TO'),
                      _DateTile(
                          date: _endDate,
                          onTap: () => _pickDate(false)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Times
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FieldLabel('START TIME'),
                      _TimeTile(
                          time: _startTime, onTap: () => _pickTime(true)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FieldLabel('END TIME'),
                      _TimeTile(
                          time: _endTime, onTap: () => _pickTime(false)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            const _FieldLabel('SLOT DURATION (MINUTES)'),
            TextFormField(
              controller: _durationCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 14),
              decoration: _fieldDecoration('e.g. 30',
                  icon: Icons.timer_outlined),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Enter a valid duration';
                return null;
              },
            ),
            const SizedBox(height: 10),

            if (_startDate != null && _endDate != null)
              _PreviewBanner(
                startDate: _startDate!,
                endDate: _endDate!,
                startTime: _startTime,
                endTime: _endTime,
                durationCtrl: _durationCtrl,
              ),
            const SizedBox(height: 28),
            _SubmitButton(label: 'Generate Slots', onPressed: _submit),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────── Small shared widgets ─────────────────────────────────

class _AssignedSelfChip extends StatelessWidget {
  const _AssignedSelfChip({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withAlpha(60)),
        ),
        child: Row(
          children: [
            const Icon(Icons.person_outline_rounded,
                size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(name,
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            const Text('(you)',
                style:
                    TextStyle(color: AppColors.textHint, fontSize: 12)),
          ],
        ),
      );
}

class _PreviewBanner extends StatelessWidget {
  const _PreviewBanner({
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    required this.durationCtrl,
  });

  final DateTime startDate;
  final DateTime endDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final TextEditingController durationCtrl;

  @override
  Widget build(BuildContext context) {
    final days = endDate.difference(startDate).inDays + 1;
    final duration = int.tryParse(durationCtrl.text.trim()) ?? 30;
    final startMins = startTime.hour * 60 + startTime.minute;
    final endMins = endTime.hour * 60 + endTime.minute;
    final slotsPerDay =
        endMins > startMins ? (endMins - startMins) ~/ duration : 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$days day(s) × ~$slotsPerDay slots/day = ~${days * slotsPerDay} total slots',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 15)),
      );
}

class _DateTile extends StatelessWidget {
  const _DateTile({required this.date, required this.onTap});

  final DateTime? date;
  final VoidCallback onTap;

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 15, color: AppColors.textHint),
              const SizedBox(width: 8),
              Text(
                date != null ? _fmtDate(date!) : 'Pick date',
                style: TextStyle(
                  color: date != null
                      ? AppColors.textPrimary
                      : AppColors.textHint,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({required this.time, required this.onTap});

  final TimeOfDay time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time_rounded,
                size: 15, color: AppColors.textHint),
            const SizedBox(width: 8),
            Text('$h:$m',
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

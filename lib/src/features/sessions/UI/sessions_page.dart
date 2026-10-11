import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../bloc/session_bloc.dart';
import '../bloc/session_event.dart';
import '../bloc/session_state.dart';
import '../data/models/session_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SessionsPage
// ─────────────────────────────────────────────────────────────────────────────

class SessionsPage extends StatefulWidget {
  const SessionsPage({super.key});

  @override
  State<SessionsPage> createState() => _SessionsPageState();
}

class _SessionsPageState extends State<SessionsPage> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = _today();
    _load(_selectedDate);
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _load(DateTime date) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    final saloons = authState.user.saloons;
    if (saloons.isEmpty) return;
    context.read<SessionBloc>().add(
          SessionsRequested(saloonId: saloons.first.id, date: _fmtDate(date)),
        );
  }

  void _onDateSelected(DateTime date) {
    setState(() => _selectedDate = date);
    _load(date);
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();

    if (authState.user.saloons.isEmpty) {
      return const Center(
        child: Text(
          'No saloon linked to your account.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, state) {
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => _load(_selectedDate),
          child: CustomScrollView(
            slivers: [
              // ── Date strip ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _DateStrip(
                  selected: _selectedDate,
                  onDateSelected: _onDateSelected,
                ),
              ),

              // ── Content ─────────────────────────────────────────────────
              if (state is SessionLoading)
                const SliverFillRemaining(
                  child: Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (state is SessionError)
                SliverFillRemaining(
                  child: _ErrorRetry(
                    message: state.message,
                    onRetry: () => _load(_selectedDate),
                  ),
                )
              else if (state is SessionLoaded) ...[
                if (state.sessions.isEmpty)
                  const SliverFillRemaining(
                    child: _EmptyState(
                      label:
                          'Saloon is closed on this day — no sessions available.',
                    ),
                  )
                else ...[
                  // ── Day-overview ribbon ──────────────────────────────────
                  SliverToBoxAdapter(
                    child: _DayOverviewRow(sessions: state.sessions),
                  ),
                  // ── Session detail tiles ─────────────────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    sliver: SliverList.separated(
                      itemCount: state.sessions.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                      itemBuilder: (ctx, i) => _SessionTile(
                        session: state.sessions[i],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ] else
                // SessionInitial — nothing loaded yet
                const SliverToBoxAdapter(child: SizedBox.shrink()),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Horizontal date strip (current month ± 14 days)
// ─────────────────────────────────────────────────────────────────────────────

class _DateStrip extends StatefulWidget {
  const _DateStrip({
    required this.selected,
    required this.onDateSelected,
  });

  final DateTime selected;
  final ValueChanged<DateTime> onDateSelected;

  @override
  State<_DateStrip> createState() => _DateStripState();
}

class _DateStripState extends State<_DateStrip> {
  late final ScrollController _scroll;
  late final List<DateTime> _dates;

  static const _kItemWidth = 56.0;
  static const _kRange = 30; // days before + after today

  @override
  void initState() {
    super.initState();
    final today = _stripTime(DateTime.now());
    _dates = List.generate(
      _kRange * 2 + 1,
      (i) => today.add(Duration(days: i - _kRange)),
    );
    _scroll = ScrollController(
      initialScrollOffset: (_kRange - 0) * _kItemWidth,
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  DateTime _stripTime(DateTime d) => DateTime(d.year, d.month, d.day);

  static const _kDayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SizedBox(
        height: 72,
        child: ListView.builder(
          controller: _scroll,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: _dates.length,
          itemExtent: _kItemWidth,
          itemBuilder: (ctx, i) {
            final date = _dates[i];
            final isSelected = _stripTime(date) == _stripTime(widget.selected);
            final isToday = _stripTime(date) == _stripTime(DateTime.now());
            final dayName = _kDayNames[date.weekday - 1];

            return GestureDetector(
              onTap: () => widget.onDateSelected(date),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : isToday
                          ? AppColors.surfaceVariant
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dayName,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? Colors.white70
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Colors.white
                            : isToday
                                ? AppColors.primary
                                : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Day-overview ribbon  — 3 compact cards, one per session
// ─────────────────────────────────────────────────────────────────────────────

class _DayOverviewRow extends StatelessWidget {
  const _DayOverviewRow({required this.sessions});

  final List<Session> sessions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < sessions.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: _SessionSummaryCard(session: sessions[i])),
            ],
          ],
        ),
      ),
    );
  }
}

class _SessionSummaryCard extends StatelessWidget {
  const _SessionSummaryCard({required this.session});

  final Session session;

  static const _kLabelColors = {
    'MORNING': Color(0xFFFF8F00),
    'AFTERNOON': Color(0xFF1565C0),
    'EVENING': Color(0xFF4527A0),
  };

  Color get _accent => _kLabelColors[session.label] ?? AppColors.primary;

  String get _shortLabel => switch (session.label) {
        'MORNING' => 'MORN',
        'AFTERNOON' => 'AFT',
        'EVENING' => 'EVE',
        _ => session.label,
      };

  @override
  Widget build(BuildContext context) {
    final barbers = session.barberCapacity;
    final totalMinutes =
        barbers.fold(0, (s, bc) => s + bc.totalCapacityMinutes);
    final remainingMinutes =
        barbers.fold(0, (s, bc) => s + bc.remainingMinutes);
    final totalQueue = barbers.fold(0, (s, bc) => s + bc.queueDepth);
    final fraction =
        totalMinutes > 0 ? (remainingMinutes / totalMinutes).clamp(0.0, 1.0) : 0.0;
    final pct = (fraction * 100).round();

    final gaugeColor = fraction > 0.5
        ? AppColors.success
        : fraction > 0.2
            ? const Color(0xFFFF8F00)
            : AppColors.error;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: _accent.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Accent top bar
            Container(height: 3, color: _accent),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 11),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
          // ── Arc gauge ──────────────────────────────────────────────────
          SizedBox(
            width: 46,
            height: 46,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (!session.isActive)
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface,
                    ),
                    child: const Icon(Icons.lock_outline,
                        size: 18, color: AppColors.textHint),
                  )
                else ...[
                  CircularProgressIndicator(
                    value: barbers.isEmpty ? 0.0 : fraction,
                    strokeWidth: 5,
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      barbers.isEmpty ? AppColors.divider : gaugeColor,
                    ),
                  ),
                  Center(
                    child: Text(
                      barbers.isEmpty ? '—' : '$pct%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _accent,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 7),

          // ── Label ──────────────────────────────────────────────────────
          Text(
            _shortLabel,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _accent,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),

          // ── Time range ─────────────────────────────────────────────────
          Text(
            '${session.startTime}–${session.endTime}',
            style: const TextStyle(
              fontSize: 9,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 5),

          // ── Queue / status ─────────────────────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _accent.withAlpha(23),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              !session.isActive
                  ? 'Closed'
                  : barbers.isEmpty
                      ? 'No barbers'
                      : 'Q $totalQueue · ${barbers.length} barber${barbers.length == 1 ? '' : 's'}',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: _accent,
              ),
            ),
          ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Session tile  (MORNING / AFTERNOON / EVENING)
// ─────────────────────────────────────────────────────────────────────────────

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});

  final Session session;

  // Per-label accent colours
  static const _kLabelColors = {
    'MORNING': Color(0xFFFF8F00), // amber
    'AFTERNOON': Color(0xFF1565C0), // primary blue
    'EVENING': Color(0xFF4527A0), // deep purple
  };

  static const _kLabelIcons = {
    'MORNING': Icons.wb_sunny_outlined,
    'AFTERNOON': Icons.wb_cloudy_outlined,
    'EVENING': Icons.nights_stay_outlined,
  };

  Color get _accent =>
      _kLabelColors[session.label] ?? AppColors.primary;

  IconData get _icon =>
      _kLabelIcons[session.label] ?? Icons.schedule_outlined;

  @override
  Widget build(BuildContext context) {
    final isInactive = !session.isActive;

    return Opacity(
      opacity: isInactive ? 0.45 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: _accent.withAlpha(15),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: _accent.withAlpha(20),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(13),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: _accent.withAlpha(38),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(_icon, size: 17, color: _accent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _accent,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '${session.startTime} – ${session.endTime}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isInactive)
                    _Chip(label: 'CLOSED', color: AppColors.textHint)
                  else
                    _Chip(
                      label: '${session.totalCapacityMinutes} min',
                      color: _accent,
                    ),
                ],
              ),
            ),

            // ── Barber capacity ─────────────────────────────────────────
            if (session.barberCapacity.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.person_off_outlined,
                        size: 15, color: AppColors.textHint),
                    const SizedBox(width: 6),
                    Text(
                      isInactive
                          ? 'Session is closed.'
                          : 'No barber data yet.',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textHint),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  children: session.barberCapacity
                      .map((bc) => _BarberCapacityRow(
                            capacity: bc,
                            accentColor: _accent,
                          ))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Barber capacity row inside a session tile
// ─────────────────────────────────────────────────────────────────────────────

class _BarberCapacityRow extends StatelessWidget {
  const _BarberCapacityRow({
    required this.capacity,
    required this.accentColor,
  });

  final BarberCapacity capacity;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final total = capacity.totalCapacityMinutes;
    final remaining = capacity.remainingMinutes;
    final fraction = total > 0 ? remaining / total : 0.0;
    final pct = (fraction * 100).round();

    // Fill colour turns amber → red as remaining shrinks
    final fillColor = fraction > 0.5
        ? AppColors.success
        : fraction > 0.2
            ? const Color(0xFFFF8F00)
            : AppColors.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.content_cut_outlined,
                  size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  capacity.barberName ?? 'Barber',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$remaining min left  ·  Q${capacity.queueDepth}',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(fillColor),
            ),
          ),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$pct% free',
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textHint),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small helpers
// ─────────────────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(31),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 52, color: AppColors.divider),
            const SizedBox(height: 14),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 40),
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
                minimumSize: const Size(120, 44),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

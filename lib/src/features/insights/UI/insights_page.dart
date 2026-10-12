import 'dart:math' show max, pi;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart' show AuthAuthenticated;
import '../bloc/insights_bloc.dart';
import '../bloc/insights_event.dart';
import '../bloc/insights_state.dart';
import '../data/models/insights_model.dart';

// ─── Constants ───────────────────────────────────────────────────────────────

const _kAmber = Color(0xFFFF8F00);

const _kMonthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

String _fmtMonth(DateTime dt) => '${_kMonthNames[dt.month - 1]} ${dt.year}';

String _monthParam(DateTime dt) =>
    '${dt.year}-${dt.month.toString().padLeft(2, '0')}';

// ─── Page ────────────────────────────────────────────────────────────────────

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _load();
  }

  bool get _canGoNext {
    final now = DateTime.now();
    return !(_month.year == now.year && _month.month == now.month);
  }

  void _load() {
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated) return;
    final saloons = auth.user.saloons;
    if (saloons.isEmpty) return;
    context.read<InsightsBloc>().add(
          InsightsLoadRequested(
            saloonId: saloons.first.id,
            month: _monthParam(_month),
          ),
        );
  }

  void _prev() {
    setState(() => _month = DateTime(_month.year, _month.month - 1));
    _load();
  }

  void _next() {
    if (!_canGoNext) return;
    setState(() => _month = DateTime(_month.year, _month.month + 1));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MonthBar(
          label: _fmtMonth(_month),
          onPrev: _prev,
          onNext: _canGoNext ? _next : null,
        ),
        Expanded(
          child: BlocBuilder<InsightsBloc, InsightsState>(
            builder: (context, state) {
              if (state is InsightsInitial || state is InsightsLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primary, strokeWidth: 2),
                );
              }
              if (state is InsightsError) {
                return _ErrorView(message: state.message, onRetry: _load);
              }
              if (state is InsightsLoaded) {
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async => _load(),
                  child: _Dashboard(data: state.insights),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }
}

// ─── Month navigator ─────────────────────────────────────────────────────────

class _MonthBar extends StatelessWidget {
  const _MonthBar({required this.label, required this.onPrev, this.onNext});

  final String label;
  final VoidCallback onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 22),
            onPressed: onPrev,
            color: AppColors.primary,
            splashRadius: 18,
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              label,
              key: ValueKey(label),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, size: 22),
            onPressed: onNext,
            color: onNext != null ? AppColors.primary : AppColors.divider,
            splashRadius: 18,
          ),
        ],
      ),
    );
  }
}

// ─── Error view ──────────────────────────────────────────────────────────────

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
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(0, 40),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Dashboard ───────────────────────────────────────────────────────────────

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.data});
  final SaloonInsights data;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        _HeroStats(summary: data.summary),
        const SizedBox(height: 20),
        _CompletionRing(summary: data.summary),
        const SizedBox(height: 20),
        if (data.dailyTrend.isNotEmpty) ...[
          _DailyTrendCard(trend: data.dailyTrend),
          const SizedBox(height: 16),
        ],
        if (data.peakHours.isNotEmpty) ...[
          _PeakHoursCard(peakHours: data.peakHours),
          const SizedBox(height: 16),
        ],
        if (data.barberPerformance.isNotEmpty) ...[
          _BarberCard(barbers: data.barberPerformance),
          const SizedBox(height: 16),
        ],
        if (data.topServices.isNotEmpty) _TopServicesCard(services: data.topServices),
      ],
    );
  }
}

// ─── Hero stats — animated counters at top ───────────────────────────────────

class _HeroStats extends StatelessWidget {
  const _HeroStats({required this.summary});
  final InsightsSummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _HeroTile(
            value: summary.total,
            label: 'Total',
            icon: Icons.calendar_month_rounded,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _HeroTile(
            value: summary.completed,
            label: 'Done',
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _HeroTile(
            value: summary.cancelled,
            label: 'Cancelled',
            icon: Icons.cancel_outlined,
            color: AppColors.error,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _HeroTile(
            value: summary.noShow,
            label: 'No-show',
            icon: Icons.person_off_outlined,
            color: _kAmber,
          ),
        ),
      ],
    );
  }
}

class _HeroTile extends StatefulWidget {
  const _HeroTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final int value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  State<_HeroTile> createState() => _HeroTileState();
}

class _HeroTileState extends State<_HeroTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _countAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _countAnim = Tween<double>(begin: 0, end: widget.value.toDouble())
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.05), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(covariant _HeroTile old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _countAnim = Tween<double>(
              begin: old.value.toDouble(), end: widget.value.toDouble())
          .animate(
              CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: widget.color.withAlpha(10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Icon(widget.icon, size: 20, color: widget.color),
                const SizedBox(height: 8),
                Text(
                  '${_countAnim.value.round()}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: widget.color,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.label,
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Completion ring ─────────────────────────────────────────────────────────

class _CompletionRing extends StatefulWidget {
  const _CompletionRing({required this.summary});
  final InsightsSummary summary;

  @override
  State<_CompletionRing> createState() => _CompletionRingState();
}

class _CompletionRingState extends State<_CompletionRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..forward();
  }

  @override
  void didUpdateWidget(covariant _CompletionRing old) {
    super.didUpdateWidget(old);
    if (old.summary != widget.summary) _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rate = widget.summary.completionRate ?? 0.0;
    final noShowRate = widget.summary.noShowRate ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ring
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              final progress = CurvedAnimation(
                      parent: _ctrl, curve: Curves.easeOutCubic)
                  .value;
              return SizedBox(
                width: 80,
                height: 80,
                child: CustomPaint(
                  painter: _RingPainter(
                    completionRate: rate * progress,
                    noShowRate: noShowRate * progress,
                  ),
                  child: Center(
                    child: Text(
                      '${(rate * 100 * progress).round()}%',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 24),
          // Legend
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Completion Rate',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _RingLegendRow(
                    color: AppColors.success,
                    label: 'Completed',
                    value: '${(rate * 100).round()}%'),
                const SizedBox(height: 6),
                _RingLegendRow(
                    color: _kAmber,
                    label: 'No-show',
                    value: '${(noShowRate * 100).round()}%'),
                const SizedBox(height: 6),
                _RingLegendRow(
                    color: AppColors.divider,
                    label: 'Other',
                    value:
                        '${(100 - (rate * 100) - (noShowRate * 100)).round().clamp(0, 100)}%'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.completionRate, required this.noShowRate});
  final double completionRate;
  final double noShowRate;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const strokeWidth = 10.0;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final bgPaint = Paint()
      ..color = AppColors.divider
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    final completedPaint = Paint()
      ..color = AppColors.success
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
        rect, -pi / 2, completionRate * 2 * pi, false, completedPaint);

    final noShowPaint = Paint()
      ..color = _kAmber
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -pi / 2 + completionRate * 2 * pi,
        noShowRate * 2 * pi, false, noShowPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.completionRate != completionRate || old.noShowRate != noShowRate;
}

class _RingLegendRow extends StatelessWidget {
  const _RingLegendRow(
      {required this.color, required this.label, required this.value});
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
      ],
    );
  }
}

// ─── Section card wrapper ────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child, this.trailing});
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (trailing != null) ...[const Spacer(), trailing!],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ─── Daily trend ─────────────────────────────────────────────────────────────

class _DailyTrendCard extends StatelessWidget {
  const _DailyTrendCard({required this.trend});
  final List<DailyTrend> trend;

  List<FlSpot> _spots(int Function(DailyTrend) get) => trend.map((d) {
        final day = int.tryParse(d.date.split('-').last) ?? 0;
        return FlSpot(day.toDouble(), get(d).toDouble());
      }).toList();

  @override
  Widget build(BuildContext context) {
    final maxTotal = trend.map((d) => d.total).reduce(max);
    final maxY = (maxTotal < 1 ? 4 : (maxTotal * 1.3)).ceilToDouble();
    final leftInterval = max(1.0, (maxY / 4).roundToDouble());

    return _Card(
      title: 'Daily Trend',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LegendChip(color: AppColors.primary, label: 'Total'),
          const SizedBox(width: 10),
          _LegendChip(color: AppColors.success, label: 'Done'),
        ],
      ),
      child: SizedBox(
        height: 180,
        child: LineChart(
          LineChartData(
            minX: 1,
            maxX: trend.length.toDouble(),
            minY: 0,
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => const FlLine(
                color: AppColors.divider,
                strokeWidth: 0.5,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: leftInterval,
                  getTitlesWidget: (v, _) => Text(
                    '${v.toInt()}',
                    style: const TextStyle(
                        fontSize: 9, color: AppColors.textHint),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 20,
                  interval: 5,
                  getTitlesWidget: (v, _) {
                    final d = v.toInt();
                    if (d % 5 != 0 && d != 1) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('$d',
                          style: const TextStyle(
                              fontSize: 9, color: AppColors.textHint)),
                    );
                  },
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => AppColors.textPrimary,
                tooltipRoundedRadius: 8,
                getTooltipItems: (spots) => spots.map((s) {
                  return LineTooltipItem(
                    '${s.y.toInt()}',
                    TextStyle(
                      color: s.bar.color ?? Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: _spots((d) => d.total),
                isCurved: true,
                curveSmoothness: 0.25,
                color: AppColors.primary,
                barWidth: 2.5,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary.withAlpha(30),
                      AppColors.primary.withAlpha(2),
                    ],
                  ),
                ),
              ),
              LineChartBarData(
                spots: _spots((d) => d.completed),
                isCurved: true,
                curveSmoothness: 0.25,
                color: AppColors.success,
                barWidth: 2,
                dotData: const FlDotData(show: false),
                dashArray: [5, 3],
              ),
            ],
          ),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        ),
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 3,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ─── Peak hours ──────────────────────────────────────────────────────────────

class _PeakHoursCard extends StatelessWidget {
  const _PeakHoursCard({required this.peakHours});
  final List<PeakHour> peakHours;

  @override
  Widget build(BuildContext context) {
    final maxCount = peakHours.map((h) => h.count).reduce(max);
    final maxY = (maxCount < 1 ? 4 : (maxCount * 1.3)).ceilToDouble();
    final leftInterval = max(1.0, (maxY / 4).roundToDouble());

    final groups = peakHours.asMap().entries.map((e) {
      final isPeak = e.value.count == maxCount;
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: e.value.count.toDouble(),
            gradient: isPeak
                ? const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [AppColors.primaryLight, AppColors.primary],
                  )
                : null,
            color: isPeak ? null : AppColors.primary.withAlpha(50),
            width: 16,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      );
    }).toList();

    return _Card(
      title: 'Busiest Hours',
      child: SizedBox(
        height: 170,
        child: BarChart(
          BarChartData(
            maxY: maxY,
            barGroups: groups,
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => const FlLine(
                color: AppColors.divider,
                strokeWidth: 0.5,
              ),
            ),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => AppColors.textPrimary,
                tooltipRoundedRadius: 8,
                getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                  '${rod.toY.toInt()} bookings',
                  const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 11),
                ),
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: leftInterval,
                  getTitlesWidget: (v, _) => Text(
                    '${v.toInt()}',
                    style: const TextStyle(
                        fontSize: 9, color: AppColors.textHint),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22,
                  getTitlesWidget: (v, _) {
                    final idx = v.toInt();
                    if (idx < 0 || idx >= peakHours.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(peakHours[idx].label,
                          style: const TextStyle(
                              fontSize: 8, color: AppColors.textHint)),
                    );
                  },
                ),
              ),
            ),
          ),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        ),
      ),
    );
  }
}

// ─── Barber performance ──────────────────────────────────────────────────────

class _BarberCard extends StatelessWidget {
  const _BarberCard({required this.barbers});
  final List<BarberPerformance> barbers;

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Barber Performance',
      child: Column(
        children: barbers.asMap().entries.map((e) {
          final isLast = e.key == barbers.length - 1;
          return Column(
            children: [
              _BarberRow(barber: e.value, rank: e.key + 1),
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(
                      height: 1,
                      color: AppColors.divider.withAlpha(120)),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _BarberRow extends StatefulWidget {
  const _BarberRow({required this.barber, required this.rank});
  final BarberPerformance barber;
  final int rank;

  @override
  State<_BarberRow> createState() => _BarberRowState();
}

class _BarberRowState extends State<_BarberRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.barber;
    final t = b.total;
    final cR = t > 0 ? b.completed / t : 0.0;
    final xR = t > 0 ? b.cancelled / t : 0.0;
    final nR = t > 0 ? b.noShow / t : 0.0;

    final initials = b.barberName.trim().split(RegExp(r'\s+')).length > 1
        ? '${b.barberName.trim().split(RegExp(r'\s+')).first[0]}${b.barberName.trim().split(RegExp(r'\s+')).last[0]}'
            .toUpperCase()
        : b.barberName.trim().isNotEmpty
            ? b.barberName.trim()[0].toUpperCase()
            : '?';

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final progress =
            CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic).value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(initials,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b.barberName,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      Text('${b.total} bookings',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textHint)),
                    ],
                  ),
                ),
                // Mini stats
                _MiniStat(
                    color: AppColors.success, value: '${b.completed}'),
                const SizedBox(width: 8),
                _MiniStat(color: AppColors.error, value: '${b.cancelled}'),
                const SizedBox(width: 8),
                _MiniStat(color: _kAmber, value: '${b.noShow}'),
              ],
            ),
            const SizedBox(height: 10),
            // Animated segmented bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 6,
                child: Row(
                  children: [
                    if (cR > 0)
                      Flexible(
                          flex: (cR * progress * 1000).round().clamp(1, 1000),
                          child: Container(
                              decoration: BoxDecoration(
                                  color: AppColors.success,
                                  borderRadius: BorderRadius.circular(4)))),
                    if (xR > 0)
                      Flexible(
                          flex: (xR * progress * 1000).round().clamp(1, 1000),
                          child: Container(color: AppColors.error)),
                    if (nR > 0)
                      Flexible(
                          flex: (nR * progress * 1000).round().clamp(1, 1000),
                          child: Container(color: _kAmber)),
                    Flexible(
                        flex: max(
                            1,
                            (1000 -
                                    (cR * progress * 1000).round() -
                                    (xR * progress * 1000).round() -
                                    (nR * progress * 1000).round())
                                .clamp(0, 1000)),
                        child: Container(color: AppColors.surfaceVariant)),
                  ],
                ),
              ),
            ),
            if (b.totalReviews != null && b.totalReviews! > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.thumb_up_alt_rounded,
                      size: 12, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text('${b.satisfactionRate}% satisfied',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success)),
                  const SizedBox(width: 6),
                  Text(
                      '(${b.satisfiedCount}/${b.totalReviews} reviews)',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.color, required this.value});
  final Color color;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(value,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
      ],
    );
  }
}

// ─── Top services ────────────────────────────────────────────────────────────

class _TopServicesCard extends StatelessWidget {
  const _TopServicesCard({required this.services});
  final List<TopService> services;

  @override
  Widget build(BuildContext context) {
    final maxCount = services.map((s) => s.count).reduce(max);

    return _Card(
      title: 'Top Services',
      child: Column(
        children: services.asMap().entries.map((e) {
          final isLast = e.key == services.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
            child:
                _ServiceBar(service: e.value, maxCount: maxCount, rank: e.key),
          );
        }).toList(),
      ),
    );
  }
}

class _ServiceBar extends StatefulWidget {
  const _ServiceBar(
      {required this.service, required this.maxCount, required this.rank});
  final TopService service;
  final int maxCount;
  final int rank;

  @override
  State<_ServiceBar> createState() => _ServiceBarState();
}

class _ServiceBarState extends State<_ServiceBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ratio =
        widget.maxCount > 0 ? widget.service.count / widget.maxCount : 0.0;
    final isTop = widget.rank == 0;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final progress =
            CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic).value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isTop)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(Icons.emoji_events_rounded,
                        size: 14, color: _kAmber),
                  ),
                Expanded(
                  child: Text(
                    widget.service.serviceName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isTop ? FontWeight.w600 : FontWeight.w400,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${widget.service.count}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isTop ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: SizedBox(
                height: 5,
                child: LinearProgressIndicator(
                  value: ratio * progress,
                  backgroundColor: AppColors.surface,
                  valueColor: AlwaysStoppedAnimation(
                    isTop ? AppColors.primary : AppColors.primaryLight,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

import 'dart:math' show max;

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

// ─── Local constants ──────────────────────────────────────────────────────────

const _kAmber = Color(0xFFFF8F00);

const _kMonthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

String _formatMonth(DateTime dt) =>
    '${_kMonthNames[dt.month - 1]} ${dt.year}';

String _monthParam(DateTime dt) =>
    '${dt.year}-${dt.month.toString().padLeft(2, '0')}';

// ─── Page ─────────────────────────────────────────────────────────────────────

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
    setState(
        () => _month = DateTime(_month.year, _month.month - 1));
    _load();
  }

  void _next() {
    if (!_canGoNext) return;
    setState(
        () => _month = DateTime(_month.year, _month.month + 1));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MonthBar(
          label: _formatMonth(_month),
          onPrev: _prev,
          onNext: _canGoNext ? _next : null,
        ),
        const Divider(height: 1, color: AppColors.divider),
        Expanded(
          child: BlocBuilder<InsightsBloc, InsightsState>(
            builder: (context, state) {
              if (state is InsightsInitial || state is InsightsLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }
              if (state is InsightsError) {
                return _ErrorView(message: state.message, onRetry: _load);
              }
              if (state is InsightsLoaded) {
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async => _load(),
                  child: _InsightsDashboard(data: state.insights),
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

// ─── Month navigator bar ──────────────────────────────────────────────────────

class _MonthBar extends StatelessWidget {
  const _MonthBar({
    required this.label,
    required this.onPrev,
    this.onNext,
  });

  final String label;
  final VoidCallback onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: onPrev,
            color: AppColors.primary,
            splashRadius: 20,
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: onNext,
            color: onNext != null ? AppColors.primary : AppColors.textHint,
            splashRadius: 20,
          ),
        ],
      ),
    );
  }
}

// ─── Error view ───────────────────────────────────────────────────────────────

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
            const Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 40),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
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

// ─── Dashboard (scrollable body) ──────────────────────────────────────────────

class _InsightsDashboard extends StatelessWidget {
  const _InsightsDashboard({required this.data});

  final SaloonInsights data;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _SummarySection(summary: data.summary),
        const SizedBox(height: 20),
        if (data.dailyTrend.isNotEmpty) ...[
          _DailyTrendSection(trend: data.dailyTrend),
          const SizedBox(height: 20),
        ],
        if (data.peakHours.isNotEmpty) ...[
          _PeakHoursSection(peakHours: data.peakHours),
          const SizedBox(height: 20),
        ],
        if (data.barberPerformance.isNotEmpty) ...[
          _BarberSection(barbers: data.barberPerformance),
          const SizedBox(height: 20),
        ],
        _TopServicesSection(services: data.topServices),
      ],
    );
  }
}

// ─── Shared section card ──────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ],
    );
  }
}

// ─── Summary stat tiles ───────────────────────────────────────────────────────

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.summary});

  final InsightsSummary summary;

  @override
  Widget build(BuildContext context) {
    final rate = summary.completionRate;
    final rateStr =
        rate != null ? '${(rate * 100).toStringAsFixed(0)}%' : '—';

    return _SectionCard(
      title: 'OVERVIEW',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Total',
                  value: '${summary.total}',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  label: 'Completed',
                  value: '${summary.completed}',
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Cancelled',
                  value: '${summary.cancelled}',
                  color: AppColors.error,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  label: 'No-Show',
                  value: '${summary.noShow}',
                  color: _kAmber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Completion rate',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              const Spacer(),
              Text(
                rateStr,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: rate ?? 0,
              minHeight: 6,
              backgroundColor: AppColors.surfaceVariant,
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.success),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─── Daily trend (LineChart) ──────────────────────────────────────────────────

class _DailyTrendSection extends StatelessWidget {
  const _DailyTrendSection({required this.trend});

  final List<DailyTrend> trend;

  List<FlSpot> _spots(int Function(DailyTrend) get) => trend.map((d) {
        final day =
            int.tryParse(d.date.split('-').last) ?? 0;
        return FlSpot(day.toDouble(), get(d).toDouble());
      }).toList();

  @override
  Widget build(BuildContext context) {
    final maxTotal =
        trend.map((d) => d.total).reduce(max);
    final maxY =
        (maxTotal < 1 ? 4 : (maxTotal * 1.3)).ceilToDouble();
    final leftInterval =
        max(1.0, (maxY / 4).roundToDouble());

    return _SectionCard(
      title: 'DAILY TREND',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Legend
          Row(
            children: [
              _LegendDot(color: AppColors.primary),
              const SizedBox(width: 4),
              const Text('Total',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary)),
              const SizedBox(width: 12),
              _LegendDot(color: AppColors.success),
              const SizedBox(width: 4),
              const Text('Completed',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
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
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles:
                          SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles:
                          SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: leftInterval,
                      getTitlesWidget: (v, _) => Text(
                        '${v.toInt()}',
                        style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.textHint),
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
                          padding:
                              const EdgeInsets.only(top: 4),
                          child: Text(
                            '$d',
                            style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.textHint),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  // Total — solid blue with subtle fill
                  LineChartBarData(
                    spots: _spots((d) => d.total),
                    isCurved: true,
                    curveSmoothness: 0.2,
                    color: AppColors.primary,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withAlpha(18),
                    ),
                  ),
                  // Completed — dashed green
                  LineChartBarData(
                    spots: _spots((d) => d.completed),
                    isCurved: true,
                    curveSmoothness: 0.2,
                    color: AppColors.success,
                    barWidth: 1.5,
                    dotData: const FlDotData(show: false),
                    dashArray: [4, 3],
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

// ─── Peak hours (BarChart) ────────────────────────────────────────────────────

class _PeakHoursSection extends StatelessWidget {
  const _PeakHoursSection({required this.peakHours});

  final List<PeakHour> peakHours;

  @override
  Widget build(BuildContext context) {
    final maxCount =
        peakHours.map((h) => h.count).reduce(max);
    final maxY =
        (maxCount < 1 ? 4 : (maxCount * 1.3)).ceilToDouble();
    final leftInterval =
        max(1.0, (maxY / 4).roundToDouble());

    final groups = peakHours.asMap().entries.map((e) {
      final isPeak = e.value.count == maxCount;
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: e.value.count.toDouble(),
            color: isPeak
                ? AppColors.primary
                : AppColors.primary.withAlpha(80),
            width: 18,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();

    return _SectionCard(
      title: 'BUSIEST HOURS',
      child: SizedBox(
        height: 180,
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
                strokeWidth: 1,
              ),
            ),
            barTouchData: BarTouchData(enabled: false),
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
                        fontSize: 9,
                        color: AppColors.textHint),
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
                      child: Text(
                        peakHours[idx].label,
                        style: const TextStyle(
                            fontSize: 8,
                            color: AppColors.textHint),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Barber performance ───────────────────────────────────────────────────────

class _BarberSection extends StatelessWidget {
  const _BarberSection({required this.barbers});

  final List<BarberPerformance> barbers;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'BARBER PERFORMANCE',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Dot(color: AppColors.success),
              const SizedBox(width: 4),
              const Text('Completed',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(width: 12),
              _Dot(color: AppColors.error),
              const SizedBox(width: 4),
              const Text('Cancelled',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(width: 12),
              _Dot(color: _kAmber),
              const SizedBox(width: 4),
              const Text('No-show',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          ...barbers.asMap().entries.map((e) {
            final isLast = e.key == barbers.length - 1;
            return Column(
              children: [
                _BarberRow(barber: e.value),
                if (!isLast)
                  const Divider(
                      height: 20, color: AppColors.divider),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _BarberRow extends StatelessWidget {
  const _BarberRow({required this.barber});

  final BarberPerformance barber;

  @override
  Widget build(BuildContext context) {
    final t = barber.total;
    final cR = t > 0 ? barber.completed / t : 0.0;
    final xR = t > 0 ? barber.cancelled / t : 0.0;
    final nR = t > 0 ? barber.noShow / t : 0.0;

    final cFlex = (cR * 1000).round();
    final xFlex = (xR * 1000).round();
    final nFlex = (nR * 1000).round();
    final bgFlex = max(0, 1000 - cFlex - xFlex - nFlex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                barber.barberName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              '${barber.total} bookings',
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            child: Row(
              children: [
                if (cFlex > 0)
                  Flexible(
                      flex: cFlex,
                      child: Container(color: AppColors.success)),
                if (xFlex > 0)
                  Flexible(
                      flex: xFlex,
                      child: Container(color: AppColors.error)),
                if (nFlex > 0)
                  Flexible(
                      flex: nFlex,
                      child: Container(color: _kAmber)),
                if (bgFlex > 0)
                  Flexible(
                      flex: bgFlex,
                      child:
                          Container(color: AppColors.surfaceVariant)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _Dot(color: AppColors.success),
                const SizedBox(width: 3),
                Text(
                  '${barber.completed}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 10),
                _Dot(color: AppColors.error),
                const SizedBox(width: 3),
                Text(
                  '${barber.cancelled}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 10),
                _Dot(color: _kAmber),
                const SizedBox(width: 3),
                Text(
                  '${barber.noShow}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
        if (barber.totalReviews != null && barber.totalReviews! > 0) ...
          [
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.thumb_up_alt_rounded,
                  size: 12,
                  color: AppColors.success,
                ),
                const SizedBox(width: 4),
                Text(
                  '${barber.satisfactionRate}% satisfied',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${barber.satisfiedCount}/${barber.totalReviews} reviews)',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
          ],
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 7,
        height: 7,
        decoration:
            BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

// ─── Top services ─────────────────────────────────────────────────────────────

class _TopServicesSection extends StatelessWidget {
  const _TopServicesSection({required this.services});

  final List<TopService> services;

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) {
      return _SectionCard(
        title: 'TOP SERVICES',
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'No services configured',
            style: TextStyle(
                fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final maxCount = services.map((s) => s.count).reduce(max);

    return _SectionCard(
      title: 'TOP SERVICES',
      child: Column(
        children: services.asMap().entries.map((e) {
          final isLast = e.key == services.length - 1;
          return Column(
            children: [
              _ServiceRow(
                  service: e.value, maxCount: maxCount),
              if (!isLast)
                const Divider(
                    height: 16, color: AppColors.divider),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow(
      {required this.service, required this.maxCount});

  final TopService service;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    final ratio =
        maxCount > 0 ? service.count / maxCount : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                service.serviceName,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${service.count}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: AppColors.surfaceVariant,
            valueColor: const AlwaysStoppedAnimation(
                AppColors.primaryLight),
          ),
        ),
      ],
    );
  }
}

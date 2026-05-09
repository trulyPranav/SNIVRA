import 'package:equatable/equatable.dart';

class InsightsSummary extends Equatable {
  const InsightsSummary({
    required this.total,
    required this.completed,
    required this.cancelled,
    required this.noShow,
    required this.arrived,
    required this.booked,
    this.completionRate,
    this.noShowRate,
  });

  final int total;
  final int completed;
  final int cancelled;
  final int noShow;
  final int arrived;
  final int booked;
  final double? completionRate;
  final double? noShowRate;

  factory InsightsSummary.fromJson(Map<String, dynamic> json) =>
      InsightsSummary(
        total: json['total'] as int? ?? 0,
        completed: json['completed'] as int? ?? 0,
        cancelled: json['cancelled'] as int? ?? 0,
        noShow: json['no_show'] as int? ?? 0,
        arrived: json['arrived'] as int? ?? 0,
        booked: json['booked'] as int? ?? 0,
        completionRate: (json['completion_rate'] as num?)?.toDouble(),
        noShowRate: (json['no_show_rate'] as num?)?.toDouble(),
      );

  @override
  List<Object?> get props => [
        total, completed, cancelled, noShow, arrived, booked,
        completionRate, noShowRate,
      ];
}

class DailyTrend extends Equatable {
  const DailyTrend({
    required this.date,
    required this.total,
    required this.completed,
    required this.cancelled,
    required this.noShow,
    required this.arrived,
    required this.booked,
  });

  final String date;
  final int total;
  final int completed;
  final int cancelled;
  final int noShow;
  final int arrived;
  final int booked;

  factory DailyTrend.fromJson(Map<String, dynamic> json) => DailyTrend(
        date: json['date'] as String? ?? '',
        total: json['total'] as int? ?? 0,
        completed: json['completed'] as int? ?? 0,
        cancelled: json['cancelled'] as int? ?? 0,
        noShow: json['no_show'] as int? ?? 0,
        arrived: json['arrived'] as int? ?? 0,
        booked: json['booked'] as int? ?? 0,
      );

  @override
  List<Object?> get props =>
      [date, total, completed, cancelled, noShow, arrived, booked];
}

class PeakHour extends Equatable {
  const PeakHour({
    required this.hour,
    required this.label,
    required this.count,
  });

  final int hour;
  final String label;
  final int count;

  factory PeakHour.fromJson(Map<String, dynamic> json) => PeakHour(
        hour: json['hour'] as int? ?? 0,
        label: json['label'] as String? ?? '',
        count: json['count'] as int? ?? 0,
      );

  @override
  List<Object?> get props => [hour, label, count];
}

class BarberPerformance extends Equatable {
  const BarberPerformance({
    required this.barberId,
    required this.barberName,
    required this.total,
    required this.completed,
    required this.cancelled,
    required this.noShow,
    required this.arrived,
    required this.booked,
    this.totalReviews,
    this.satisfiedCount,
    this.satisfactionRate,
  });

  final String barberId;
  final String barberName;
  final int total;
  final int completed;
  final int cancelled;
  final int noShow;
  final int arrived;
  final int booked;
  final int? totalReviews;
  final int? satisfiedCount;
  final int? satisfactionRate;

  factory BarberPerformance.fromJson(Map<String, dynamic> json) =>
      BarberPerformance(
        barberId: json['barber_id'] as String? ?? '',
        barberName: json['barber_name'] as String? ?? '',
        total: json['total'] as int? ?? 0,
        completed: json['completed'] as int? ?? 0,
        cancelled: json['cancelled'] as int? ?? 0,
        noShow: json['no_show'] as int? ?? 0,
        arrived: json['arrived'] as int? ?? 0,
        booked: json['booked'] as int? ?? 0,
        totalReviews: json['total_reviews'] as int?,
        satisfiedCount: json['satisfied_count'] as int?,
        satisfactionRate: json['satisfaction_rate'] as int?,
      );

  @override
  List<Object?> get props => [
        barberId, barberName, total, completed, cancelled, noShow, arrived, booked,
        totalReviews, satisfiedCount, satisfactionRate,
      ];
}

class TopService extends Equatable {
  const TopService({
    required this.serviceId,
    required this.serviceName,
    required this.count,
  });

  final String serviceId;
  final String serviceName;
  final int count;

  factory TopService.fromJson(Map<String, dynamic> json) => TopService(
        serviceId: json['service_id'] as String? ?? '',
        serviceName: json['service_name'] as String? ?? '',
        count: json['count'] as int? ?? 0,
      );

  @override
  List<Object?> get props => [serviceId, serviceName, count];
}

class SaloonInsights extends Equatable {
  const SaloonInsights({
    required this.period,
    required this.saloonId,
    required this.summary,
    required this.dailyTrend,
    required this.peakHours,
    required this.barberPerformance,
    required this.topServices,
  });

  final String period;
  final String saloonId;
  final InsightsSummary summary;
  final List<DailyTrend> dailyTrend;
  final List<PeakHour> peakHours;
  final List<BarberPerformance> barberPerformance;
  final List<TopService> topServices;

  factory SaloonInsights.fromJson(Map<String, dynamic> json) => SaloonInsights(
        period: json['period'] as String? ?? '',
        saloonId: json['saloon_id'] as String? ?? '',
        summary: InsightsSummary.fromJson(
            json['summary'] as Map<String, dynamic>),
        dailyTrend: (json['daily_trend'] as List<dynamic>)
            .map((e) => DailyTrend.fromJson(e as Map<String, dynamic>))
            .toList(),
        peakHours: (json['peak_hours'] as List<dynamic>)
            .map((e) => PeakHour.fromJson(e as Map<String, dynamic>))
            .toList(),
        barberPerformance: (json['barber_performance'] as List<dynamic>)
            .map((e) => BarberPerformance.fromJson(e as Map<String, dynamic>))
            .toList(),
        topServices: (json['top_services'] as List<dynamic>)
            .map((e) => TopService.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [
        period, saloonId, summary, dailyTrend, peakHours,
        barberPerformance, topServices,
      ];
}

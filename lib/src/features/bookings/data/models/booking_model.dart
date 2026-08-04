import 'package:equatable/equatable.dart';

enum BookingStatus { booked, arrived, completed, cancelled, noShow }

BookingStatus _statusFromString(String? s) {
  switch (s?.toUpperCase()) {
    case 'ARRIVED':
      return BookingStatus.arrived;
    case 'COMPLETED':
      return BookingStatus.completed;
    case 'CANCELLED':
      return BookingStatus.cancelled;
    case 'NO_SHOW':
      return BookingStatus.noShow;
    default:
      return BookingStatus.booked;
  }
}

String _trimTime(String t) => t.length >= 5 ? t.substring(0, 5) : t;

// ─── Booking service reference ────────────────────────────────────────────────

class BookingService extends Equatable {
  const BookingService({
    required this.id,
    required this.name,
    this.durationMinutes,
  });

  final String id;
  final String name;
  final int? durationMinutes;

  factory BookingService.fromJson(Map<String, dynamic> json) =>
      BookingService(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
      );

  @override
  List<Object?> get props => [id, name, durationMinutes];
}

// ─── Saloon booking (GET /bookings/saloon-bookings/:id) ───────────────────────

class SaloonBooking extends Equatable {
  const SaloonBooking({
    required this.id,
    required this.status,
    // Session fields (new)
    required this.sessionId,
    required this.sessionDate,
    required this.sessionLabel,
    required this.sessionStart,
    required this.sessionEnd,
    required this.queuePosition,
    required this.estimatedArrivalAt,
    required this.allocatedDurationMinutes,
    // People
    required this.barberId,
    required this.barberName,
    this.customerName,
    this.customerPhone,
    this.services = const [],
  });

  final String id;
  final BookingStatus status;
  // ── Session context ───────────────────────────────────────────────────────
  final String sessionId;
  final String sessionDate; // 'YYYY-MM-DD'
  final String sessionLabel; // 'MORNING' | 'AFTERNOON' | 'EVENING'
  final String sessionStart; // 'HH:MM'
  final String sessionEnd;
  final int queuePosition;
  final DateTime estimatedArrivalAt; // UTC timestamp
  final int allocatedDurationMinutes;
  // ── People ────────────────────────────────────────────────────────────────
  final String barberId;
  final String barberName;
  final String? customerName;
  final String? customerPhone;
  final List<BookingService> services;

  factory SaloonBooking.fromJson(Map<String, dynamic> json) {
    DateTime _parseTs(String? s) {
      if (s == null || s.isEmpty) return DateTime.now();
      try {
        return DateTime.parse(s).toLocal();
      } catch (_) {
        return DateTime.now();
      }
    }

    return SaloonBooking(
      id: json['id'] as String,
      status: _statusFromString(json['status'] as String?),
      sessionId: json['session_id'] as String? ?? '',
      sessionDate: json['session_date'] as String? ?? '',
      sessionLabel: json['session_label'] as String? ?? '',
      sessionStart: _trimTime(json['session_start'] as String? ?? ''),
      sessionEnd: _trimTime(json['session_end'] as String? ?? ''),
      queuePosition: (json['queue_position'] as num?)?.toInt() ?? 0,
      estimatedArrivalAt: _parseTs(json['estimated_arrival_at'] as String?),
      allocatedDurationMinutes:
          (json['allocated_duration_minutes'] as num?)?.toInt() ?? 0,
      barberId: json['barber_id'] as String? ?? '',
      barberName: json['barber_name'] as String? ?? '',
      customerName: json['customer_name'] as String?,
      customerPhone: json['customer_phone'] as String?,
      services: (json['services'] as List<dynamic>?)
              ?.map((e) =>
                  BookingService.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  SaloonBooking copyWith({BookingStatus? status}) => SaloonBooking(
        id: id,
        status: status ?? this.status,
        sessionId: sessionId,
        sessionDate: sessionDate,
        sessionLabel: sessionLabel,
        sessionStart: sessionStart,
        sessionEnd: sessionEnd,
        queuePosition: queuePosition,
        estimatedArrivalAt: estimatedArrivalAt,
        allocatedDurationMinutes: allocatedDurationMinutes,
        barberId: barberId,
        barberName: barberName,
        customerName: customerName,
        customerPhone: customerPhone,
        services: services,
      );

  @override
  List<Object?> get props => [
        id,
        status,
        sessionId,
        sessionDate,
        sessionLabel,
        sessionStart,
        sessionEnd,
        queuePosition,
        estimatedArrivalAt,
        allocatedDurationMinutes,
        barberId,
        barberName,
        customerName,
        customerPhone,
        services,
      ];
}

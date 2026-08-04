import 'package:equatable/equatable.dart';

// ─── Barber capacity inside a session ────────────────────────────────────────

class BarberCapacity extends Equatable {
  const BarberCapacity({
    required this.barberId,
    required this.totalCapacityMinutes,
    required this.consumedMinutes,
    required this.remainingMinutes,
    required this.queueDepth,
    this.barberName,
    this.nextQueuePosition,
  });

  final String barberId;
  final int totalCapacityMinutes;
  final int consumedMinutes;
  final int remainingMinutes;
  final int queueDepth;
  final String? barberName;
  final int? nextQueuePosition;

  factory BarberCapacity.fromJson(Map<String, dynamic> json) => BarberCapacity(
        barberId: json['barber_id'] as String,
        totalCapacityMinutes:
            (json['total_capacity_minutes'] as num).toInt(),
        consumedMinutes: (json['consumed_minutes'] as num).toInt(),
        remainingMinutes: (json['remaining_minutes'] as num).toInt(),
        queueDepth: (json['queue_depth'] as num).toInt(),
        barberName: json['barber_name'] as String?,
        nextQueuePosition:
            (json['next_queue_position'] as num?)?.toInt(),
      );

  @override
  List<Object?> get props => [
        barberId,
        totalCapacityMinutes,
        consumedMinutes,
        remainingMinutes,
        queueDepth,
        barberName,
        nextQueuePosition,
      ];
}

// ─── Session ─────────────────────────────────────────────────────────────────

/// One of the three daily windows: MORNING, AFTERNOON, EVENING.
class Session extends Equatable {
  const Session({
    required this.id,
    required this.saloonId,
    required this.sessionDate,
    required this.label,
    required this.startTime,
    required this.endTime,
    required this.isActive,
    required this.totalCapacityMinutes,
    this.barberCapacity = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String saloonId;
  final String sessionDate; // 'YYYY-MM-DD'
  final String label; // 'MORNING' | 'AFTERNOON' | 'EVENING'
  final String startTime; // 'HH:MM'
  final String endTime;
  final bool isActive;
  final int totalCapacityMinutes;
  final List<BarberCapacity> barberCapacity;
  final String? createdAt;
  final String? updatedAt;

  factory Session.fromJson(Map<String, dynamic> json) {
    String trimTime(String? t) =>
        (t != null && t.length >= 5) ? t.substring(0, 5) : (t ?? '');

    return Session(
      id: json['id'] as String,
      saloonId: json['saloon_id'] as String? ?? '',
      sessionDate: json['session_date'] as String? ?? '',
      label: json['label'] as String? ?? '',
      startTime: trimTime(json['start_time'] as String?),
      endTime: trimTime(json['end_time'] as String?),
      isActive: json['is_active'] as bool? ?? true,
      totalCapacityMinutes:
          (json['total_capacity_minutes'] as num?)?.toInt() ?? 0,
      barberCapacity: (json['barber_capacity'] as List<dynamic>?)
              ?.map((e) =>
                  BarberCapacity.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        saloonId,
        sessionDate,
        label,
        startTime,
        endTime,
        isActive,
        totalCapacityMinutes,
        barberCapacity,
      ];
}

// ─── Availability detail (GET /sessions/:session_id/availability) ─────────────

class SessionAvailability extends Equatable {
  const SessionAvailability({
    required this.session,
    required this.totalCapacityMinutes,
    required this.barbers,
  });

  final Session session;
  final int totalCapacityMinutes;
  final List<BarberCapacity> barbers;

  factory SessionAvailability.fromJson(Map<String, dynamic> json) {
    final sessionJson = json['session'] as Map<String, dynamic>;
    final barbersJson = json['barbers'] as List<dynamic>? ?? [];
    return SessionAvailability(
      session: Session.fromJson(sessionJson),
      totalCapacityMinutes:
          (json['total_capacity_minutes'] as num?)?.toInt() ?? 0,
      barbers: barbersJson
          .map((e) =>
              BarberCapacity.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [session, totalCapacityMinutes, barbers];
}

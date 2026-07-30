enum EventType { sleep, feed, pee, poop }

enum FeedType { breast, bottle }

enum FeedSide { left, right, both }

enum DiaperTexture { normal, soft, liquid, dry }

class BabyEvent {
  final String id;
  final String babyId;
  final EventType type;
  final DateTime startTime;
  final DateTime? endTime;
  final String? notes;

  // Feed-specific
  final FeedType? feedType;
  final FeedSide? feedSide;
  final int? durationMinutes;
  final int? volumeMl;

  // Diaper-specific
  final bool hasPee;
  final bool hasPoop;
  final DiaperTexture? diaperTexture;

  BabyEvent({
    required this.id,
    required this.babyId,
    required this.type,
    required this.startTime,
    this.endTime,
    this.notes,
    this.feedType,
    this.feedSide,
    this.durationMinutes,
    this.volumeMl,
    this.hasPee = false,
    this.hasPoop = false,
    this.diaperTexture,
  });

  Duration? get duration {
    if (endTime == null) return null;
    return endTime!.difference(startTime);
  }

  String get durationLabel {
    final d = duration;
    if (d == null) return '';
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}min';
    }
    return '${d.inMinutes}min';
  }

  bool get isOngoing => (type == EventType.sleep || type == EventType.feed) && endTime == null;

  String get typeLabel {
    switch (type) {
      case EventType.sleep:
        return 'Sleep';
      case EventType.feed:
        return 'Feed';
      case EventType.pee:
        return hasPoop ? 'Pee & Poop' : 'Pee';
      case EventType.poop:
        return 'Poop';
    }
  }

  String localizedTypeLabel(dynamic strings) {
    switch (type) {
      case EventType.sleep:
        return strings.eventTypeSleep;
      case EventType.feed:
        return strings.eventTypeFeed;
      case EventType.pee:
        return hasPoop ? strings.eventTypePeeAndPoop : strings.eventTypePee;
      case EventType.poop:
        return strings.eventTypePoop;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'babyId': babyId,
        'type': type.name,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'notes': notes,
        'feedType': feedType?.name,
        'feedSide': feedSide?.name,
        'durationMinutes': durationMinutes,
        'volumeMl': volumeMl,
        'hasPee': hasPee,
        'hasPoop': hasPoop,
        'diaperTexture': diaperTexture?.name,
      };

  factory BabyEvent.fromJson(Map<String, dynamic> json) => BabyEvent(
        id: json['id'] as String,
        babyId: json['babyId'] as String,
        type: EventType.values.firstWhere((e) => e.name == json['type']),
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: json['endTime'] != null
            ? DateTime.parse(json['endTime'] as String)
            : null,
        notes: json['notes'] as String?,
        feedType: json['feedType'] != null
            ? FeedType.values.firstWhere((e) => e.name == json['feedType'])
            : null,
        feedSide: json['feedSide'] != null
            ? FeedSide.values.firstWhere((e) => e.name == json['feedSide'])
            : null,
        durationMinutes: json['durationMinutes'] as int?,
        volumeMl: json['volumeMl'] as int?,
        hasPee: json['hasPee'] as bool? ?? false,
        hasPoop: json['hasPoop'] as bool? ?? false,
        diaperTexture: json['diaperTexture'] != null
            ? DiaperTexture.values
                .firstWhere((e) => e.name == json['diaperTexture'])
            : null,
      );

  BabyEvent copyWith({
    String? id,
    String? babyId,
    EventType? type,
    DateTime? startTime,
    DateTime? endTime,
    String? notes,
    FeedType? feedType,
    FeedSide? feedSide,
    int? durationMinutes,
    int? volumeMl,
    bool? hasPee,
    bool? hasPoop,
    DiaperTexture? diaperTexture,
  }) =>
      BabyEvent(
        id: id ?? this.id,
        babyId: babyId ?? this.babyId,
        type: type ?? this.type,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        notes: notes ?? this.notes,
        feedType: feedType ?? this.feedType,
        feedSide: feedSide ?? this.feedSide,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        volumeMl: volumeMl ?? this.volumeMl,
        hasPee: hasPee ?? this.hasPee,
        hasPoop: hasPoop ?? this.hasPoop,
        diaperTexture: diaperTexture ?? this.diaperTexture,
      );
}

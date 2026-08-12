class Baby {
  final String id;
  final String name;
  final String? photoPath;
  final DateTime dateOfBirth;
  final DateTime createdAt;

  Baby({
    required this.id,
    required this.name,
    this.photoPath,
    required this.dateOfBirth,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  int get ageInWeeks {
    final diff = DateTime.now().difference(dateOfBirth);
    return (diff.inDays / 7).floor();
  }

  int get ageInMonths {
    final now = DateTime.now();
    int months = (now.year - dateOfBirth.year) * 12 +
        (now.month - dateOfBirth.month);
    if (now.day < dateOfBirth.day) months--;
    return months;
  }

  String get ageLabel {
    if (ageInMonths < 1) {
      return '$ageInWeeks semanas';
    }
    return '$ageInMonths meses';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'photoPath': photoPath,
        'dateOfBirth': dateOfBirth.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Baby.fromJson(Map<String, dynamic> json) => Baby(
        id: json['id'] as String,
        name: json['name'] as String,
        photoPath: (json['photoPath'] ?? json['photo_path']) as String?,
        dateOfBirth: DateTime.parse((json['dateOfBirth'] ?? json['date_of_birth']) as String),
        createdAt: DateTime.parse((json['createdAt'] ?? json['created_at']) as String),
      );

  Baby copyWith({
    String? id,
    String? name,
    String? photoPath,
    DateTime? dateOfBirth,
    DateTime? createdAt,
  }) =>
      Baby(
        id: id ?? this.id,
        name: name ?? this.name,
        photoPath: photoPath ?? this.photoPath,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        createdAt: createdAt ?? this.createdAt,
      );
}

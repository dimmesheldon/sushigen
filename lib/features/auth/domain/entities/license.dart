class License {
  final String id;
  final String licenseKey;
  final String? userId;
  final DateTime expirationDate;
  final bool isActive;
  final int maxDevices;
  final DateTime createdAt;
  final DateTime updatedAt;

  License({
    required this.id,
    required this.licenseKey,
    this.userId,
    required this.expirationDate,
    required this.isActive,
    required this.maxDevices,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isExpired => DateTime.now().isAfter(expirationDate);

  bool get isValid => isActive && !isExpired;

  int get daysRemaining {
    if (isExpired) return 0;
    return expirationDate.difference(DateTime.now()).inDays;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'license_key': licenseKey,
      'user_id': userId,
      'expiration_date': expirationDate.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'max_devices': maxDevices,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory License.fromMap(Map<String, dynamic> map) {
    return License(
      id: map['id'],
      licenseKey: map['license_key'],
      userId: map['user_id'],
      expirationDate: DateTime.parse(map['expiration_date']),
      isActive: map['is_active'] == 1,
      maxDevices: map['max_devices'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  License copyWith({
    String? id,
    String? licenseKey,
    String? userId,
    DateTime? expirationDate,
    bool? isActive,
    int? maxDevices,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return License(
      id: id ?? this.id,
      licenseKey: licenseKey ?? this.licenseKey,
      userId: userId ?? this.userId,
      expirationDate: expirationDate ?? this.expirationDate,
      isActive: isActive ?? this.isActive,
      maxDevices: maxDevices ?? this.maxDevices,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

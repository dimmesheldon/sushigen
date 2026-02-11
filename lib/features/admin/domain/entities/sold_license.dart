class SoldLicense {
  final String id;
  final String customerId;
  final String licenseKey;
  final int days;
  final DateTime startDate;
  final DateTime expirationDate;
  final String status; // 'active', 'expired', 'revoked'
  final double? price;
  final String? paymentMethod;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  SoldLicense({
    required this.id,
    required this.customerId,
    required this.licenseKey,
    required this.days,
    required this.startDate,
    required this.expirationDate,
    this.status = 'active',
    this.price,
    this.paymentMethod,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isExpired => DateTime.now().isAfter(expirationDate);

  int get daysRemaining {
    if (isExpired) return 0;
    return expirationDate.difference(DateTime.now()).inDays;
  }

  String get statusDisplay {
    if (status == 'revoked') return 'Revogada';
    if (isExpired) return 'Expirada';
    return 'Ativa';
  }

  SoldLicense copyWith({
    String? id,
    String? customerId,
    String? licenseKey,
    int? days,
    DateTime? startDate,
    DateTime? expirationDate,
    String? status,
    double? price,
    String? paymentMethod,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SoldLicense(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      licenseKey: licenseKey ?? this.licenseKey,
      days: days ?? this.days,
      startDate: startDate ?? this.startDate,
      expirationDate: expirationDate ?? this.expirationDate,
      status: status ?? this.status,
      price: price ?? this.price,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'license_key': licenseKey,
      'days': days,
      'start_date': startDate.toIso8601String(),
      'expiration_date': expirationDate.toIso8601String(),
      'status': status,
      'price': price,
      'payment_method': paymentMethod,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory SoldLicense.fromMap(Map<String, dynamic> map) {
    return SoldLicense(
      id: map['id'] as String,
      customerId: map['customer_id'] as String,
      licenseKey: map['license_key'] as String,
      days: map['days'] as int,
      startDate: DateTime.parse(map['start_date'] as String),
      expirationDate: DateTime.parse(map['expiration_date'] as String),
      status: map['status'] as String,
      price: map['price'] as double?,
      paymentMethod: map['payment_method'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

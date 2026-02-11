class CompanyUser {
  final String id;
  final String customerId; // Empresa à qual pertence
  final String username;
  final String passwordHash;
  final String fullName;
  final String? email;
  final String role; // 'owner', 'manager', 'operator'
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  CompanyUser({
    required this.id,
    required this.customerId,
    required this.username,
    required this.passwordHash,
    required this.fullName,
    this.email,
    this.role = 'operator',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  CompanyUser copyWith({
    String? id,
    String? customerId,
    String? username,
    String? passwordHash,
    String? fullName,
    String? email,
    String? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CompanyUser(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'username': username,
      'password_hash': passwordHash,
      'full_name': fullName,
      'email': email,
      'role': role,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory CompanyUser.fromMap(Map<String, dynamic> map) {
    return CompanyUser(
      id: map['id'] as String,
      customerId: map['customer_id'] as String,
      username: map['username'] as String,
      passwordHash: map['password_hash'] as String,
      fullName: map['full_name'] as String,
      email: map['email'] as String?,
      role: map['role'] as String? ?? 'operator',
      isActive: (map['is_active'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  String get roleDisplay {
    switch (role) {
      case 'owner':
        return 'Proprietário';
      case 'manager':
        return 'Gerente';
      case 'operator':
        return 'Operador';
      default:
        return role;
    }
  }
}

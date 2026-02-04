import 'package:uuid/uuid.dart';

class Product {
  final String id;
  final String name;
  final String? description;
  final String category;
  final double price;
  final double cost;
  final String? imageUrl;
  final bool isActive;
  final int preparationTime;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.price,
    this.cost = 0,
    this.imageUrl,
    this.isActive = true,
    this.preparationTime = 0,
    required this.createdAt,
    required this.updatedAt,
    this.synced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'cost': cost,
      'image_url': imageUrl,
      'is_active': isActive ? 1 : 0,
      'preparation_time': preparationTime,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'synced': synced ? 1 : 0,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      category: map['category'],
      price: map['price'],
      cost: map['cost'] ?? 0,
      imageUrl: map['image_url'],
      isActive: map['is_active'] == 1,
      preparationTime: map['preparation_time'] ?? 0,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      synced: map['synced'] == 1,
    );
  }

  factory Product.create({
    required String name,
    String? description,
    required String category,
    required double price,
    double cost = 0,
    String? imageUrl,
    int preparationTime = 0,
  }) {
    final now = DateTime.now();
    return Product(
      id: const Uuid().v4(),
      name: name,
      description: description,
      category: category,
      price: price,
      cost: cost,
      imageUrl: imageUrl,
      preparationTime: preparationTime,
      createdAt: now,
      updatedAt: now,
    );
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    double? price,
    double? cost,
    String? imageUrl,
    bool? isActive,
    int? preparationTime,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? synced,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      preparationTime: preparationTime ?? this.preparationTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
    );
  }
}

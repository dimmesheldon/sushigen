class StockEntry {
  final String id;
  final String productId;
  final String productName;
  final double quantity;
  final String unit;
  final double minQuantity;
  final double? maxQuantity;
  final DateTime? lastPurchaseDate;
  final double? lastPurchasePrice;
  final DateTime updatedAt;

  StockEntry({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    this.unit = 'un',
    this.minQuantity = 0,
    this.maxQuantity,
    this.lastPurchaseDate,
    this.lastPurchasePrice,
    required this.updatedAt,
  });

  // Status do estoque
  String get status {
    if (quantity <= 0) return 'out_of_stock';
    if (quantity <= minQuantity) return 'low_stock';
    if (maxQuantity != null && quantity >= maxQuantity!) return 'overstock';
    return 'ok';
  }

  bool get isLowStock => status == 'low_stock' || status == 'out_of_stock';
  bool get isOutOfStock => status == 'out_of_stock';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'quantity': quantity,
      'unit': unit,
      'min_quantity': minQuantity,
      'max_quantity': maxQuantity,
      'last_purchase_date': lastPurchaseDate?.toIso8601String(),
      'last_purchase_price': lastPurchasePrice,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory StockEntry.fromMap(Map<String, dynamic> map) {
    return StockEntry(
      id: map['id'],
      productId: map['product_id'],
      productName: map['product_name'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      unit: map['unit'] ?? 'un',
      minQuantity: (map['min_quantity'] ?? 0).toDouble(),
      maxQuantity: map['max_quantity']?.toDouble(),
      lastPurchaseDate: map['last_purchase_date'] != null
          ? DateTime.parse(map['last_purchase_date'])
          : null,
      lastPurchasePrice: map['last_purchase_price']?.toDouble(),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  StockEntry copyWith({
    String? id,
    String? productId,
    String? productName,
    double? quantity,
    String? unit,
    double? minQuantity,
    double? maxQuantity,
    DateTime? lastPurchaseDate,
    double? lastPurchasePrice,
    DateTime? updatedAt,
  }) {
    return StockEntry(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      minQuantity: minQuantity ?? this.minQuantity,
      maxQuantity: maxQuantity ?? this.maxQuantity,
      lastPurchaseDate: lastPurchaseDate ?? this.lastPurchaseDate,
      lastPurchasePrice: lastPurchasePrice ?? this.lastPurchasePrice,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

import 'package:uuid/uuid.dart';

class Sale {
  final String id;
  final int saleNumber;
  final String userId;
  final String? customerName;
  final String? customerPhone;
  final double totalAmount;
  final double discountAmount;
  final double finalAmount;
  final String paymentMethod;
  final String status;
  final String? notes;
  final DateTime saleDate;
  final DateTime createdAt;
  final bool synced;
  final bool isIfood;
  final String deliveryType;
  final double deliveryCost;

  Sale({
    required this.id,
    required this.saleNumber,
    required this.userId,
    this.customerName,
    this.customerPhone,
    required this.totalAmount,
    this.discountAmount = 0,
    required this.finalAmount,
    required this.paymentMethod,
    this.status = 'completed',
    this.notes,
    required this.saleDate,
    required this.createdAt,
    this.synced = false,
    this.isIfood = false,
    this.deliveryType = 'Retirada',
    this.deliveryCost = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sale_number': saleNumber,
      'user_id': userId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'total_amount': totalAmount,
      'discount_amount': discountAmount,
      'final_amount': finalAmount,
      'payment_method': paymentMethod,
      'status': status,
      'notes': notes,
      'sale_date': saleDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'synced': synced ? 1 : 0,
      'is_ifood': isIfood ? 1 : 0,
      'delivery_type': deliveryType,
      'delivery_cost': deliveryCost,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'],
      saleNumber: map['sale_number'],
      userId: map['user_id'],
      customerName: map['customer_name'],
      customerPhone: map['customer_phone'],
      totalAmount: map['total_amount'],
      discountAmount: map['discount_amount'] ?? 0,
      finalAmount: map['final_amount'],
      paymentMethod: map['payment_method'],
      status: map['status'] ?? 'completed',
      notes: map['notes'],
      saleDate: DateTime.parse(map['sale_date']),
      createdAt: DateTime.parse(map['created_at']),
      synced: map['synced'] == 1,
      isIfood: (map['is_ifood'] as int?) == 1,
      deliveryType: map['delivery_type'] as String? ?? 'Retirada',
      deliveryCost: (map['delivery_cost'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class SaleItem {
  final String id;
  final String saleId;
  final String productId;
  final String productName;
  final double quantity;
  final double unitPrice;
  final double totalPrice;
  final String? notes;
  final DateTime createdAt;
  final bool synced;

  SaleItem({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.notes,
    required this.createdAt,
    this.synced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sale_id': saleId,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'synced': synced ? 1 : 0,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'],
      saleId: map['sale_id'],
      productId: map['product_id'],
      productName: map['product_name'],
      quantity: map['quantity'],
      unitPrice: map['unit_price'],
      totalPrice: map['total_price'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
      synced: map['synced'] == 1,
    );
  }

  factory SaleItem.create({
    required String saleId,
    required String productId,
    required String productName,
    required double quantity,
    required double unitPrice,
    String? notes,
  }) {
    return SaleItem(
      id: const Uuid().v4(),
      saleId: saleId,
      productId: productId,
      productName: productName,
      quantity: quantity,
      unitPrice: unitPrice,
      totalPrice: quantity * unitPrice,
      notes: notes,
      createdAt: DateTime.now(),
    );
  }
}

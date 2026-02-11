class CashFlowEntry {
  final String id;
  final String type; // 'income' ou 'expense'
  final String category;
  final double amount;
  final String description;
  final DateTime date;
  final String? saleId; // Se for de uma venda
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;

  CashFlowEntry({
    required this.id,
    required this.type,
    required this.category,
    required this.amount,
    required this.description,
    required this.date,
    this.saleId,
    required this.createdAt,
    required this.updatedAt,
    this.synced = false,
  });

  // Factory para criar nova entrada
  factory CashFlowEntry.create({
    required String type,
    required String category,
    required double amount,
    required String description,
    required DateTime date,
    String? saleId,
  }) {
    final now = DateTime.now();
    return CashFlowEntry(
      id: '', // Será gerado pelo banco
      type: type,
      category: category,
      amount: amount,
      description: description,
      date: date,
      saleId: saleId,
      createdAt: now,
      updatedAt: now,
      synced: false,
    );
  }

  // Converter para Map (banco de dados)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'category': category,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
      'sale_id': saleId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'synced': synced ? 1 : 0,
    };
  }

  // Criar do Map
  factory CashFlowEntry.fromMap(Map<String, dynamic> map) {
    return CashFlowEntry(
      id: map['id'] as String,
      type: map['type'] as String,
      category: map['category'] as String,
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String,
      date: DateTime.parse(map['date'] as String),
      saleId: map['sale_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      synced: (map['synced'] as int) == 1,
    );
  }

  // Copiar com modificações
  CashFlowEntry copyWith({
    String? id,
    String? type,
    String? category,
    double? amount,
    String? description,
    DateTime? date,
    String? saleId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? synced,
  }) {
    return CashFlowEntry(
      id: id ?? this.id,
      type: type ?? this.type,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      date: date ?? this.date,
      saleId: saleId ?? this.saleId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
    );
  }

  // Helpers
  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';
  bool get isFromSale => saleId != null;
}

// Categorias padrão
class CashFlowCategories {
  // Despesas
  static const String rent = 'Aluguel';
  static const String salaries = 'Salários';
  static const String suppliers = 'Fornecedores';
  static const String utilities = 'Contas (Água, Luz, etc)';
  static const String maintenance = 'Manutenção';
  static const String marketing = 'Marketing';
  static const String taxes = 'Impostos';
  static const String otherExpenses = 'Outras Despesas';

  // Receitas
  static const String sales = 'Vendas';
  static const String otherIncome = 'Outras Receitas';

  static List<String> get expenseCategories => [
    rent,
    salaries,
    suppliers,
    utilities,
    maintenance,
    marketing,
    taxes,
    otherExpenses,
  ];

  static List<String> get incomeCategories => [sales, otherIncome];

  static List<String> getAllCategories() {
    return [...incomeCategories, ...expenseCategories];
  }
}

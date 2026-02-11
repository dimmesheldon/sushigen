import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/cash_flow_entry.dart';
import '../../data/repositories/cash_flow_repository.dart';
import '../../../sales/data/repositories/sale_repository.dart';

// Estado do fluxo de caixa
class CashFlowState {
  final List<CashFlowEntry> entries;
  final bool isLoading;
  final String? error;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? selectedType; // 'income', 'expense' ou null (todos)
  final String? selectedCategory;
  final bool onlyIfood; // Filtro para vendas do iFood
  final Map<String, double> balance;

  CashFlowState({
    this.entries = const [],
    this.isLoading = false,
    this.error,
    this.startDate,
    this.endDate,
    this.selectedType,
    this.selectedCategory,
    this.onlyIfood = false,
    this.balance = const {'income': 0, 'expense': 0, 'balance': 0},
  });

  CashFlowState copyWith({
    List<CashFlowEntry>? entries,
    bool? isLoading,
    String? error,
    DateTime? startDate,
    DateTime? endDate,
    String? selectedType,
    String? selectedCategory,
    bool? onlyIfood,
    Map<String, double>? balance,
    bool clearType = false,
    bool clearCategory = false,
  }) {
    return CashFlowState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      selectedType: clearType ? null : (selectedType ?? this.selectedType),
      selectedCategory: clearCategory
          ? null
          : (selectedCategory ?? this.selectedCategory),
      onlyIfood: onlyIfood ?? this.onlyIfood,
      balance: balance ?? this.balance,
    );
  }
}

// Notifier
class CashFlowNotifier extends StateNotifier<CashFlowState> {
  final CashFlowRepository _repository;

  CashFlowNotifier(this._repository) : super(CashFlowState()) {
    _initializeWithCurrentMonth();
  }

  // Inicializar com mês atual
  void _initializeWithCurrentMonth() {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    state = state.copyWith(startDate: startDate, endDate: endDate);

    loadEntries();
  }

  // Carregar entradas
  Future<void> loadEntries() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      List<CashFlowEntry> entries;

      if (state.startDate != null && state.endDate != null) {
        entries = await _repository.getEntriesByPeriod(
          startDate: state.startDate!,
          endDate: state.endDate!,
        );
      } else {
        entries = await _repository.getAllEntries();
      }

      // Aplicar filtros
      if (state.selectedType != null) {
        entries = entries.where((e) => e.type == state.selectedType).toList();
      }

      if (state.selectedCategory != null) {
        entries = entries
            .where((e) => e.category == state.selectedCategory)
            .toList();
      }

      // Filtro iFood (só vendas)
      if (state.onlyIfood) {
        final saleRepo = SaleRepository();
        final ifoodEntries = <CashFlowEntry>[];
        
        for (final entry in entries) {
          if (entry.saleId != null) {
            try {
              final saleData = await saleRepo.getSaleWithItems(entry.saleId!);
              if (saleData != null && saleData['sale'].isIfood) {
                ifoodEntries.add(entry);
              }
            } catch (e) {
              // Ignorar erros de vendas não encontradas
            }
          }
        }
        
        entries = ifoodEntries;
      }

      // Calcular saldo
      final balance = await _calculateBalance();

      state = state.copyWith(
        entries: entries,
        isLoading: false,
        balance: balance,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Calcular saldo
  Future<Map<String, double>> _calculateBalance() async {
    if (state.startDate != null && state.endDate != null) {
      return await _repository.getBalanceByPeriod(
        startDate: state.startDate!,
        endDate: state.endDate!,
      );
    }

    final totalBalance = await _repository.getTotalBalance();
    return {'income': 0, 'expense': 0, 'balance': totalBalance};
  }

  // Adicionar entrada
  Future<void> addEntry(CashFlowEntry entry) async {
    try {
      await _repository.addEntry(entry);
      await loadEntries();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Atualizar entrada
  Future<void> updateEntry(CashFlowEntry entry) async {
    try {
      await _repository.updateEntry(entry);
      await loadEntries();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Deletar entrada
  Future<void> deleteEntry(String id) async {
    try {
      await _repository.deleteEntry(id);
      await loadEntries();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Filtrar por período
  void filterByPeriod(DateTime startDate, DateTime endDate) {
    state = state.copyWith(startDate: startDate, endDate: endDate);
    loadEntries();
  }

  // Filtrar por tipo
  void filterByType(String? type) {
    state = state.copyWith(selectedType: type, clearType: type == null);
    loadEntries();
  }

  // Filtrar por categoria
  void filterByCategory(String? category) {
    state = state.copyWith(
      selectedCategory: category,
      clearCategory: category == null,
    );
    loadEntries();
  }

  // Filtrar por iFood
  void toggleIfoodFilter() {
    state = state.copyWith(onlyIfood: !state.onlyIfood);
    loadEntries();
  }

  // Limpar filtros
  void clearFilters() {
    final now = DateTime.now();
    state = state.copyWith(
      startDate: DateTime(now.year, now.month, 1),
      endDate: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
      clearType: true,
      clearCategory: true,
      onlyIfood: false,
    );
    loadEntries();
  }
}

// Provider
final cashFlowProvider = StateNotifierProvider<CashFlowNotifier, CashFlowState>(
  (ref) {
    return CashFlowNotifier(CashFlowRepository());
  },
);

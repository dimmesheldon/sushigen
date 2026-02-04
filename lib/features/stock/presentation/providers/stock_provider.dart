import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/stock_entry.dart';
import '../../data/repositories/stock_repository.dart';

// Provider do repositório
final stockRepositoryProvider = Provider<StockRepository>((ref) {
  return StockRepository();
});

// Estado do estoque
class StockState {
  final List<StockEntry> entries;
  final bool isLoading;
  final String? error;
  final String filter; // 'all', 'low_stock', 'out_of_stock'

  StockState({
    this.entries = const [],
    this.isLoading = false,
    this.error,
    this.filter = 'all',
  });

  StockState copyWith({
    List<StockEntry>? entries,
    bool? isLoading,
    String? error,
    String? filter,
  }) {
    return StockState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      filter: filter ?? this.filter,
    );
  }

  // Getters para estatísticas
  int get totalProducts => entries.length;

  int get lowStockCount => entries.where((e) => e.isLowStock).length;

  int get outOfStockCount => entries.where((e) => e.isOutOfStock).length;

  double get totalStockValue {
    return entries.fold(0.0, (sum, entry) {
      final price = entry.lastPurchasePrice ?? 0;
      return sum + (price * entry.quantity);
    });
  }
}

// Notifier do estoque
class StockNotifier extends StateNotifier<StockState> {
  final StockRepository _repository;

  StockNotifier(this._repository) : super(StockState()) {
    loadStock();
  }

  // Carregar estoque
  Future<void> loadStock() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      List<StockEntry> entries;

      switch (state.filter) {
        case 'low_stock':
          entries = await _repository.getLowStockProducts();
          break;
        case 'out_of_stock':
          entries = await _repository.getOutOfStockProducts();
          break;
        default:
          entries = await _repository.getAllStock();
      }

      state = state.copyWith(entries: entries, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Filtrar estoque
  void setFilter(String filter) {
    state = state.copyWith(filter: filter);
    loadStock();
  }

  // Adicionar quantidade (entrada)
  Future<bool> addStock(
    String productId,
    double quantity, {
    double? purchasePrice,
  }) async {
    try {
      await _repository.addStock(
        productId,
        quantity,
        purchasePrice: purchasePrice,
      );
      await loadStock();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // Remover quantidade (saída)
  Future<bool> removeStock(String productId, double quantity) async {
    try {
      final success = await _repository.removeStock(productId, quantity);
      if (success) {
        await loadStock();
      }
      return success;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // Atualizar quantidade diretamente
  Future<bool> updateStock(String productId, double newQuantity) async {
    try {
      await _repository.updateStock(productId, newQuantity);
      await loadStock();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // Atualizar configurações de estoque
  Future<bool> updateSettings(
    String productId, {
    String? unit,
    double? minQuantity,
    double? maxQuantity,
  }) async {
    try {
      await _repository.updateStockSettings(
        productId,
        unit: unit,
        minQuantity: minQuantity,
        maxQuantity: maxQuantity,
      );
      await loadStock();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // Criar entrada de estoque para novo produto
  Future<bool> createStockEntry(
    String productId, {
    double quantity = 0,
    String unit = 'un',
    double minQuantity = 0,
    double? maxQuantity,
  }) async {
    try {
      await _repository.createStockEntry(
        productId,
        quantity: quantity,
        unit: unit,
        minQuantity: minQuantity,
        maxQuantity: maxQuantity,
      );
      await loadStock();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

// Provider do estoque
final stockProvider = StateNotifierProvider<StockNotifier, StockState>((ref) {
  final repository = ref.watch(stockRepositoryProvider);
  return StockNotifier(repository);
});

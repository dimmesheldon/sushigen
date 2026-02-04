import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/product.dart';
import '../../data/repositories/product_repository.dart';

// Provider do repositório
final productRepositoryProvider = Provider((ref) => ProductRepository());

// Provider da lista de produtos
final productsProvider = StateNotifierProvider<ProductsNotifier, ProductsState>(
  (ref) {
    return ProductsNotifier(ref.read(productRepositoryProvider));
  },
);

// Estado dos produtos
class ProductsState {
  final List<Product> products;
  final List<Product> filteredProducts;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final String? selectedCategory;

  ProductsState({
    this.products = const [],
    this.filteredProducts = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.selectedCategory,
  });

  ProductsState copyWith({
    List<Product>? products,
    List<Product>? filteredProducts,
    bool? isLoading,
    String? error,
    String? searchQuery,
    String? selectedCategory,
  }) {
    return ProductsState(
      products: products ?? this.products,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }
}

// Notifier para gerenciar produtos
class ProductsNotifier extends StateNotifier<ProductsState> {
  final ProductRepository _repository;

  ProductsNotifier(this._repository) : super(ProductsState()) {
    loadProducts();
  }

  Future<void> loadProducts() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final products = await _repository.getAllProducts();
      state = state.copyWith(
        products: products,
        filteredProducts: products,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void search(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFilters();
  }

  void filterByCategory(String? category) {
    state = state.copyWith(selectedCategory: category);
    _applyFilters();
  }

  void _applyFilters() {
    var filtered = state.products;

    // Filtrar por categoria
    if (state.selectedCategory != null && state.selectedCategory!.isNotEmpty) {
      filtered = filtered
          .where((p) => p.category == state.selectedCategory)
          .toList();
    }

    // Filtrar por busca
    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      filtered = filtered.where((p) {
        final nameMatch = p.name.toLowerCase().contains(query);
        final descMatch = (p.description ?? '').toLowerCase().contains(query);
        return nameMatch || descMatch;
      }).toList();
    }

    state = state.copyWith(filteredProducts: filtered);
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _repository.deleteProduct(id);
      await loadProducts();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<String> createProduct(Product product) async {
    try {
      final createdProduct = await _repository.createProduct(product);
      await loadProducts();
      return createdProduct.id;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      await _repository.updateProduct(product);
      await loadProducts();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}

// Provider de categorias
final categoriesProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.read(productRepositoryProvider);
  return await repository.getAllCategories();
});

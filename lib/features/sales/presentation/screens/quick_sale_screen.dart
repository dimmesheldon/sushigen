import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../products/data/models/product.dart';
import '../../../products/presentation/providers/products_provider.dart';
import '../../data/models/sale.dart';
import '../../data/repositories/sale_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class QuickSaleScreen extends ConsumerStatefulWidget {
  const QuickSaleScreen({super.key});

  @override
  ConsumerState<QuickSaleScreen> createState() => _QuickSaleScreenState();
}

class _QuickSaleScreenState extends ConsumerState<QuickSaleScreen> {
  final List<CartItem> _cart = [];
  final _searchController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _observationsController = TextEditingController();

  String _selectedCategory = 'Todos';
  String _paymentMethod = 'Dinheiro';
  String _discountType = 'R\$'; // 'R$' ou '%'
  String _deliveryType = 'Retirada'; // 'Retirada' ou 'Entrega'
  final _deliveryCostController = TextEditingController(text: '0');
  bool _isIfood = false; // Nova flag para vendas iFood

  // Métodos de pagamento
  final List<String> _paymentMethods = [
    'Dinheiro',
    'Cartão de Débito',
    'Cartão de Crédito',
    'PIX',
  ];

  // Categorias (será carregado do banco, mas mantém padrões)
  List<String> get _categories {
    final productsState = ref.watch(productsProvider);
    final categories =
        productsState.products.map((p) => p.category).toSet().toList()..sort();
    return ['Todos', ...categories];
  }

  @override
  void initState() {
    super.initState();
    // Carregar produtos ao iniciar
    Future.microtask(() {
      ref.read(productsProvider.notifier).loadProducts();
    });
  }

  List<Product> _getFilteredProducts(List<Product> allProducts) {
    var products = allProducts.where((p) => p.isActive).toList();

    if (_selectedCategory != 'Todos') {
      products = products
          .where((p) => p.category == _selectedCategory)
          .toList();
    }

    if (_searchController.text.isNotEmpty) {
      products = products
          .where(
            (p) => p.name.toLowerCase().contains(
              _searchController.text.toLowerCase(),
            ),
          )
          .toList();
    }

    return products;
  }

  double get _subtotal {
    return _cart.fold(
      0,
      (sum, item) => sum + (item.product.price * item.quantity),
    );
  }

  double get _discountAmount {
    final discountValue = double.tryParse(_discountController.text) ?? 0;
    if (_discountType == '%') {
      return _subtotal * (discountValue / 100);
    }
    return discountValue;
  }

  double get _deliveryCost {
    if (_deliveryType == 'Retirada') return 0;
    return double.tryParse(_deliveryCostController.text) ?? 0;
  }

  double get _total => _subtotal - _discountAmount + _deliveryCost;

  void _addToCart(Product product) {
    setState(() {
      final existingIndex = _cart.indexWhere(
        (item) => item.product.id == product.id,
      );
      if (existingIndex >= 0) {
        _cart[existingIndex] = CartItem(
          product: product,
          quantity: _cart[existingIndex].quantity + 1,
        );
      } else {
        _cart.add(CartItem(product: product, quantity: 1));
      }
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      _cart.removeAt(index);
    });
  }

  void _updateQuantity(int index, int quantity) {
    setState(() {
      if (quantity <= 0) {
        _cart.removeAt(index);
      } else {
        _cart[index] = CartItem(
          product: _cart[index].product,
          quantity: quantity,
        );
      }
    });
  }

  Future<void> _finalizeSale() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione itens ao pedido'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Mostrar diálogo de carregamento
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      // Obter usuário atual
      final authState = ref.read(authProvider);
      final userId = authState.user?.id ?? 'unknown';

      // Converter carrinho para itens de venda
      final saleItems = _cart.map((cartItem) {
        return SaleItem.create(
          saleId: '', // Será preenchido pelo repositório
          productId: cartItem.product.id,
          productName: cartItem.product.name,
          quantity: cartItem.quantity.toDouble(),
          unitPrice: cartItem.product.price,
        );
      }).toList();

      // Salvar venda no banco
      final saleRepo = SaleRepository();
      final sale = await saleRepo.createSale(
        userId: userId,
        items: saleItems,
        totalAmount: _total,
        discountAmount: _discountAmount,
        paymentMethod: _paymentMethod,
        notes: _observationsController.text.trim().isEmpty
            ? null
            : _observationsController.text.trim(),
        isIfood: _isIfood,
        deliveryType: _deliveryType,
        deliveryCost: _deliveryCost,
      );

      // Limpar carrinho e campos
      setState(() {
        _cart.clear();
        _discountController.text = '0';
        _observationsController.clear();
        _deliveryCostController.text = '0';
        _paymentMethod = 'Dinheiro';
        _discountType = 'R\$';
        _deliveryType = 'Retirada';
        _isIfood = false;
      });

      // Fechar diálogo de carregamento
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Mostrar sucesso
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Venda #${sale.saleNumber} finalizada! Total: R\$ ${sale.finalAmount.toStringAsFixed(2)}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Fechar diálogo de carregamento se estiver aberto
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Mostrar erro
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao finalizar venda: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _discountController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(productsProvider);
    final filteredProducts = _getFilteredProducts(productsState.products);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lançamento Rápido'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            onPressed: () {
              Navigator.pushNamed(context, '/cashflow');
            },
            tooltip: 'Fluxo de Caixa',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // TODO: Ir para histórico de vendas
            },
            tooltip: 'Histórico',
          ),
        ],
      ),
      body: Row(
        children: [
          // Lado esquerdo - Lista de produtos
          Expanded(
            flex: 3,
            child: Column(
              children: [
                // Barra de pesquisa
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar produto...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ),

                // Categorias
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          backgroundColor: Colors.grey.shade200,
                          selectedColor: Colors.red.shade700,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),

                // Grid de produtos
                Expanded(
                  child: productsState.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : productsState.error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Erro ao carregar produtos',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () => ref
                                    .read(productsProvider.notifier)
                                    .loadProducts(),
                                child: const Text('Tentar novamente'),
                              ),
                            ],
                          ),
                        )
                      : filteredProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Nenhum produto encontrado',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/products');
                                },
                                child: const Text('Cadastrar produtos'),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 0.8,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            return _ProductCard(
                              product: product,
                              onTap: () => _addToCart(product),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          // Lado direito - Carrinho
          Container(
            width: 400,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26),
                  blurRadius: 10,
                  offset: const Offset(-2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.red.shade700,
                  child: const Row(
                    children: [
                      Icon(Icons.shopping_cart, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Pedido',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Itens do carrinho
                Expanded(
                  child: _cart.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_cart_outlined,
                                size: 80,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Carrinho vazio',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _cart.length,
                          itemBuilder: (context, index) {
                            final item = _cart[index];
                            return _CartItemCard(
                              item: item,
                              onRemove: () => _removeFromCart(index),
                              onQuantityChanged: (quantity) =>
                                  _updateQuantity(index, quantity),
                            );
                          },
                        ),
                ),

                // Resumo e finalização
                Expanded(
                  flex: 0,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(26),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Forma de Pagamento
                          DropdownButtonFormField<String>(
                            value: _paymentMethod,
                            decoration: InputDecoration(
                              labelText: 'Pagamento',
                              prefixIcon: const Icon(Icons.payment, size: 20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items: _paymentMethods.map((method) {
                              return DropdownMenuItem(
                                value: method,
                                child: Text(
                                  method,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _paymentMethod = value);
                              }
                            },
                          ),
                          const SizedBox(height: 8),

                          // Desconto
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: _discountController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontSize: 14),
                                  decoration: InputDecoration(
                                    labelText: 'Desconto',
                                    labelStyle: const TextStyle(fontSize: 12),
                                    prefixIcon: const Icon(
                                      Icons.discount,
                                      size: 20,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  onChanged: (value) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _discountType,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'R\$',
                                      child: Text(
                                        'R\$',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: '%',
                                      child: Text(
                                        '%',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _discountType = value);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Observações
                          TextField(
                            controller: _observationsController,
                            maxLines: 2,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              labelText: 'Observações',
                              labelStyle: const TextStyle(fontSize: 12),
                              hintText: 'Observações...',
                              hintStyle: const TextStyle(fontSize: 12),
                              prefixIcon: const Icon(Icons.note, size: 20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Checkbox Venda iFood
                          CheckboxListTile(
                            title: const Text(
                              'Venda iFood',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: const Text(
                              'Marque se esta venda foi feita através do iFood',
                              style: TextStyle(fontSize: 11),
                            ),
                            value: _isIfood,
                            onChanged: (value) {
                              setState(() {
                                _isIfood = value ?? false;
                              });
                            },
                            secondary: Icon(
                              Icons.restaurant,
                              color: _isIfood ? Colors.red : Colors.grey,
                            ),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                          const SizedBox(height: 8),

                          // Tipo de Entrega
                          DropdownButtonFormField<String>(
                            value: _deliveryType,
                            decoration: InputDecoration(
                              labelText: 'Tipo de Entrega',
                              prefixIcon: const Icon(
                                Icons.delivery_dining,
                                size: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Retirada',
                                child: Row(
                                  children: [
                                    Icon(Icons.store, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'Retirada no Local',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Entrega',
                                child: Row(
                                  children: [
                                    Icon(Icons.two_wheeler, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'Entrega',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _deliveryType = value;
                                  if (value == 'Retirada') {
                                    _deliveryCostController.text = '0';
                                  }
                                });
                              }
                            },
                          ),

                          // Taxa de Entrega (apenas se for entrega)
                          if (_deliveryType == 'Entrega') ...[
                            const SizedBox(height: 8),
                            TextField(
                              controller: _deliveryCostController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                labelText: 'Taxa de Entrega',
                                labelStyle: const TextStyle(fontSize: 12),
                                prefixText: 'R\$ ',
                                prefixIcon: const Icon(
                                  Icons.attach_money,
                                  size: 20,
                                ),
                                helperText: 'Custo do motoboy',
                                helperStyle: const TextStyle(fontSize: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.orange.shade50,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              onChanged: (value) => setState(() {}),
                            ),
                          ],
                          const SizedBox(height: 12),

                          // Subtotal
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Subtotal:',
                                style: TextStyle(fontSize: 14),
                              ),
                              Text(
                                'R\$ ${_subtotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          // Desconto aplicado
                          if (_discountAmount > 0) ...[
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Desconto ($_discountType):',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.orange,
                                  ),
                                ),
                                Text(
                                  '- R\$ ${_discountAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ],

                          // Taxa de Entrega
                          if (_deliveryCost > 0) ...[
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.delivery_dining,
                                      size: 16,
                                      color: Colors.blue,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Taxa de Entrega:',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '+ R\$ ${_deliveryCost.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const Divider(height: 16),

                          // Total
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'TOTAL:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'R\$ ${_total.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Botão Finalizar
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton(
                              onPressed: _finalizeSale,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'FINALIZAR VENDA',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CartItem {
  final Product product;
  final int quantity;

  CartItem({required this.product, required this.quantity});
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.onTap});

  // Método para construir a imagem do produto (URL ou arquivo local)
  Widget _buildProductImage(String imageUrl) {
    // Verificar se é um arquivo local (caminho absoluto)
    if (imageUrl.startsWith('/') ||
        imageUrl.startsWith('C:\\') ||
        imageUrl.startsWith('file://')) {
      final file = File(imageUrl.replaceFirst('file://', ''));
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        );
      }
    }

    // Se não for arquivo local, tratar como URL
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (_, __, ___) => _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(Icons.restaurant, size: 48, color: Colors.grey.shade400),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child:
                        product.imageUrl != null && product.imageUrl!.isNotEmpty
                        ? _buildProductImage(product.imageUrl!)
                        : Center(
                            child: Icon(
                              Icons.restaurant,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'R\$ ${product.price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback onRemove;
  final ValueChanged<int> onQuantityChanged;

  const _CartItemCard({
    required this.item,
    required this.onRemove,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'R\$ ${item.product.price.toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => onQuantityChanged(item.quantity - 1),
                  color: Colors.red,
                  iconSize: 24,
                ),
                Text(
                  '${item.quantity}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => onQuantityChanged(item.quantity + 1),
                  color: Colors.green,
                  iconSize: 24,
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onRemove,
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}

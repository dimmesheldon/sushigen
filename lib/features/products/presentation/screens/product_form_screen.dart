import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../data/models/product.dart';
import '../providers/products_provider.dart';
import '../../../../core/utils/currency_input_formatter.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _costController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _prepTimeController = TextEditingController();

  String _selectedCategory = 'Sushi';
  bool _isLoading = false;
  String? _localImagePath; // Caminho da imagem local
  bool _useLocalImage = false; // Toggle entre URL e arquivo local

  final List<String> _categories = [
    'Sushi',
    'Sashimi',
    'Hot Rolls',
    'Temaki',
    'Yakisoba',
    'Bebidas',
    'Sobremesas',
    'Entradas',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description ?? '';
      _priceController.text = CurrencyParser.format(widget.product!.price);
      _costController.text = CurrencyParser.format(widget.product!.cost);
      _imageUrlController.text = widget.product!.imageUrl ?? '';
      _prepTimeController.text = widget.product!.preparationTime.toString();
      _selectedCategory = widget.product!.category;
    } else {
      _prepTimeController.text = '0';
      _costController.text = '0.00';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _imageUrlController.dispose();
    _prepTimeController.dispose();
    super.dispose();
  }

  // Selecionar imagem do computador
  Future<void> _pickImage() async {
    try {
      print('🖼️ Abrindo seletor de imagens...');

      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      print('📁 Resultado: ${result?.files.length ?? 0} arquivo(s)');

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        print('📷 Arquivo selecionado: ${file.name}');
        print('📂 Caminho: ${file.path}');

        if (file.path != null) {
          setState(() {
            _localImagePath = file.path;
            _useLocalImage = true;
            _imageUrlController.clear(); // Limpa URL se existir
          });

          print('✅ Imagem configurada com sucesso!');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Imagem selecionada: ${file.name}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          print('❌ Caminho do arquivo é null');
        }
      } else {
        print('⚠️ Nenhum arquivo selecionado');
      }
    } catch (e, stackTrace) {
      print('❌ ERRO ao selecionar imagem: $e');
      print('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao selecionar imagem: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // Copiar imagem para pasta do app
  Future<String?> _saveImageLocally(String sourcePath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(path.join(appDir.path, 'products'));

      // Criar pasta se não existir
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      // Gerar nome único para a imagem
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(sourcePath);
      final fileName = 'product_$timestamp$extension';
      final destinationPath = path.join(imagesDir.path, fileName);

      // Copiar arquivo
      final sourceFile = File(sourcePath);
      await sourceFile.copy(destinationPath);

      return destinationPath;
    } catch (e) {
      print('Erro ao salvar imagem: $e');
      return null;
    }
  }

  // Remover imagem local
  void _removeLocalImage() {
    setState(() {
      _localImagePath = null;
      _useLocalImage = false;
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();

      // Processar imagem (local ou URL)
      String? finalImageUrl;

      if (_useLocalImage && _localImagePath != null) {
        // Salvar imagem local na pasta do app
        finalImageUrl = await _saveImageLocally(_localImagePath!);
      } else if (_imageUrlController.text.trim().isNotEmpty) {
        // Usar URL fornecida
        finalImageUrl = _imageUrlController.text.trim();
      }

      final product = Product.create(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        category: _selectedCategory,
        price: CurrencyParser.parse(_priceController.text),
        cost: CurrencyParser.parse(_costController.text),
        imageUrl: finalImageUrl,
        preparationTime: int.parse(_prepTimeController.text),
      );

      if (widget.product != null) {
        // Editar produto existente
        final updatedProduct = Product(
          id: widget.product!.id,
          name: product.name,
          description: product.description,
          category: product.category,
          price: product.price,
          cost: product.cost,
          imageUrl: product.imageUrl,
          isActive: widget.product!.isActive,
          preparationTime: product.preparationTime,
          createdAt: widget.product!.createdAt,
          updatedAt: now,
          synced: false,
        );

        await ref.read(productsProvider.notifier).updateProduct(updatedProduct);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Produto atualizado com sucesso'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Criar novo produto
        await ref.read(productsProvider.notifier).createProduct(product);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Produto criado com sucesso'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar produto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Produto' : 'Novo Produto'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Nome
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nome do Produto *',
                prefixIcon: const Icon(Icons.restaurant_menu),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Digite o nome do produto';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Descrição
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Descrição',
                hintText: 'Descreva os ingredientes e características',
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Categoria
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Categoria *',
                prefixIcon: const Icon(Icons.category),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // Preço e Custo
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Preço de Venda *',
                      prefixText: 'R\$ ',
                      hintText: '0,00',
                      prefixIcon: const Icon(Icons.attach_money),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      CurrencyInputFormatter(),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Digite o preço';
                      }
                      final price = CurrencyParser.parse(value);
                      if (price <= 0) {
                        return 'Preço inválido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _costController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Custo',
                      prefixText: 'R\$ ',
                      hintText: '0,00',
                      prefixIcon: const Icon(Icons.shopping_cart),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      CurrencyInputFormatter(),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tempo de preparo
            TextFormField(
              controller: _prepTimeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Tempo de Preparo (minutos)',
                prefixIcon: const Icon(Icons.timer),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),

            // Seção de Imagem
            const Text(
              'Imagem do Produto',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Botões para escolher tipo de imagem
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _useLocalImage = false;
                        _localImagePath = null;
                      });
                    },
                    icon: const Icon(Icons.link),
                    label: const Text('URL'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: !_useLocalImage
                          ? Colors.red.shade50
                          : null,
                      foregroundColor: !_useLocalImage
                          ? Colors.red.shade700
                          : null,
                      side: BorderSide(
                        color: !_useLocalImage
                            ? Colors.red.shade700
                            : Colors.grey.shade400,
                        width: !_useLocalImage ? 2 : 1,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      setState(() {
                        _useLocalImage = true;
                        _imageUrlController.clear();
                      });
                      await _pickImage();
                    },
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _useLocalImage
                          ? Colors.red.shade50
                          : null,
                      foregroundColor: _useLocalImage
                          ? Colors.red.shade700
                          : null,
                      side: BorderSide(
                        color: _useLocalImage
                            ? Colors.red.shade700
                            : Colors.grey.shade400,
                        width: _useLocalImage ? 2 : 1,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Campo URL (só aparece se não for imagem local)
            if (!_useLocalImage)
              TextFormField(
                controller: _imageUrlController,
                decoration: InputDecoration(
                  labelText: 'URL da Imagem',
                  hintText: 'https://exemplo.com/imagem.jpg',
                  prefixIcon: const Icon(Icons.image),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (_) => setState(() {}), // Atualizar preview
              ),

            // Informação da imagem local
            if (_useLocalImage && _localImagePath != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Imagem selecionada',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            path.basename(_localImagePath!),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _removeLocalImage,
                      color: Colors.red.shade700,
                      tooltip: 'Remover imagem',
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Preview da imagem
            if ((_useLocalImage && _localImagePath != null) ||
                (!_useLocalImage && _imageUrlController.text.isNotEmpty)) ...[
              const Text(
                'Preview:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _useLocalImage && _localImagePath != null
                      ? Image.file(
                          File(_localImagePath!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 8),
                                Text('Erro ao carregar imagem'),
                              ],
                            ),
                          ),
                        )
                      : Image.network(
                          _imageUrlController.text,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 8),
                                Text('Imagem não encontrada'),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Botões
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProduct,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isEditing ? 'SALVAR ALTERAÇÕES' : 'CRIAR PRODUTO',
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

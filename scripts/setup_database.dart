// Este script precisa ser executado dentro do contexto do Flutter
// Use: flutter run scripts/setup_database.dart ou execute diretamente no app

import 'dart:io';
import 'package:sushigen/core/database/database_helper.dart';
import 'package:sushigen/core/utils/license_key_generator.dart';
import 'package:sushigen/features/auth/data/repositories/auth_repository.dart';
import 'package:sushigen/features/auth/domain/entities/license.dart';
import 'package:sushigen/features/products/data/models/product.dart';

/// Script para inicializar o banco de dados com dados de exemplo
void main() async {
  print('🍣 SushiGen - Inicializando Sistema...\n');

  final dbHelper = DatabaseHelper();
  final authRepo = AuthRepository();

  try {
    // Inicializar banco de dados
    print('📦 Criando banco de dados...');
    await dbHelper.database;
    print('✅ Banco de dados criado com sucesso!\n');

    // Verificar se já existe usuário admin
    print('👤 Verificando usuário administrador...');
    final db = await dbHelper.database;
    final existingUsers = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: ['admin'],
    );

    String userId;
    String licenseKey;

    if (existingUsers.isNotEmpty) {
      // Usuário já existe
      print('ℹ️  Usuário admin já existe. Pulando criação...\n');
      userId = existingUsers.first['id'] as String;

      // Verificar se já tem licença ativa
      final existingLicenses = await db.query(
        'licenses',
        where: 'user_id = ? AND is_active = 1',
        whereArgs: [userId],
      );

      if (existingLicenses.isNotEmpty) {
        print('ℹ️  Licença ativa já existe. Pulando criação...\n');
        licenseKey = existingLicenses.first['license_key'] as String;
      } else {
        // Gerar nova licença
        print('🔑 Gerando nova chave de licença...');
        licenseKey = LicenseKeyGenerator.generateTyped(LicenseType.yearly);
        print('✅ Chave de Licença: $licenseKey');
        print('   Tipo: Anual (365 dias)\n');

        print('📄 Criando licença...');
        final expirationDate = calculateExpirationDate(LicenseType.yearly);
        final license = await authRepo.createLicense(
          userId: userId,
          licenseKey: licenseKey,
          expirationDate: expirationDate,
          maxDevices: 5,
        );
        print('✅ Licença criada com sucesso!');
        print(
          '   Expira em: ${expirationDate.day}/${expirationDate.month}/${expirationDate.year}',
        );
        print('   Máximo de dispositivos: ${license.maxDevices}\n');
      }
    } else {
      // Gerar chave de licença
      print('🔑 Gerando chave de licença...');
      licenseKey = LicenseKeyGenerator.generateTyped(LicenseType.yearly);
      print('✅ Chave de Licença: $licenseKey');
      print('   Tipo: Anual (365 dias)\n');

      // Criar usuário administrador
      print('👤 Criando usuário administrador...');
      final user = await authRepo.createUser(
        username: 'admin',
        password: 'admin123',
        email: 'admin@sushigen.com',
        role: 'admin',
      );
      print('✅ Usuário criado: ${user.username}');
      print('   ID: ${user.id}\n');
      userId = user.id;

      // Criar licença
      print('📄 Criando licença...');
      final expirationDate = calculateExpirationDate(LicenseType.yearly);
      final license = await authRepo.createLicense(
        userId: user.id,
        licenseKey: licenseKey,
        expirationDate: expirationDate,
        maxDevices: 5,
      );
      print('✅ Licença criada com sucesso!');
      print(
        '   Expira em: ${expirationDate.day}/${expirationDate.month}/${expirationDate.year}',
      );
      print('   Máximo de dispositivos: ${license.maxDevices}\n');
    }

    // Criar produtos de exemplo
    print('🍱 Criando produtos de exemplo...');
    await _createSampleProducts(dbHelper);
    print('✅ Produtos criados com sucesso!\n');

    // Resumo final
    print('═══════════════════════════════════════════════════════');
    print('🎉 SISTEMA PRONTO PARA USO!');
    print('═══════════════════════════════════════════════════════');
    print('');
    print('📋 CREDENCIAIS DE ACESSO:');
    print('   Usuário: admin');
    print('   Senha: admin123');
    print('   Chave de Licença: $licenseKey');
    print('');
    print('🚀 Agora você pode executar o aplicativo:');
    print('   flutter run -d macos');
    print('');
    print('═══════════════════════════════════════════════════════');
  } catch (e) {
    print('❌ Erro: $e');
    exit(1);
  }
}

Future<void> _createSampleProducts(DatabaseHelper dbHelper) async {
  final db = await dbHelper.database;

  final products = [
    // Sushi
    Product.create(
      name: 'Sushi Salmão',
      description: 'Sushi tradicional de salmão fresco',
      category: 'Sushi',
      price: 8.50,
      cost: 4.00,
      preparationTime: 10,
    ),
    Product.create(
      name: 'Sushi Atum',
      description: 'Sushi de atum vermelho',
      category: 'Sushi',
      price: 9.00,
      cost: 4.50,
      preparationTime: 10,
    ),
    Product.create(
      name: 'Sushi Peixe Branco',
      description: 'Sushi de peixe branco',
      category: 'Sushi',
      price: 7.50,
      cost: 3.50,
      preparationTime: 10,
    ),
    Product.create(
      name: 'Sushi Camarão',
      description: 'Sushi de camarão fresco',
      category: 'Sushi',
      price: 8.00,
      cost: 4.00,
      preparationTime: 12,
    ),

    // Sashimi
    Product.create(
      name: 'Sashimi Salmão (5un)',
      description: 'Fatias de salmão fresco - 5 unidades',
      category: 'Sashimi',
      price: 25.00,
      cost: 12.00,
      preparationTime: 8,
    ),
    Product.create(
      name: 'Sashimi Atum (5un)',
      description: 'Fatias de atum vermelho - 5 unidades',
      category: 'Sashimi',
      price: 28.00,
      cost: 14.00,
      preparationTime: 8,
    ),
    Product.create(
      name: 'Sashimi Misto (10un)',
      description: 'Variedade de peixes frescos - 10 unidades',
      category: 'Sashimi',
      price: 45.00,
      cost: 22.00,
      preparationTime: 12,
    ),

    // Hot Roll
    Product.create(
      name: 'Hot Roll Filadélfia',
      description: 'Salmão, cream cheese, empanado e frito',
      category: 'Hot Roll',
      price: 32.00,
      cost: 15.00,
      preparationTime: 15,
    ),
    Product.create(
      name: 'Hot Roll Skin',
      description: 'Salmão skin, cream cheese, empanado',
      category: 'Hot Roll',
      price: 30.00,
      cost: 14.00,
      preparationTime: 15,
    ),
    Product.create(
      name: 'Hot Roll Atum',
      description: 'Atum, cream cheese, empanado e frito',
      category: 'Hot Roll',
      price: 33.00,
      cost: 16.00,
      preparationTime: 15,
    ),

    // Temaki
    Product.create(
      name: 'Temaki Salmão',
      description: 'Cone de alga com salmão e arroz',
      category: 'Temaki',
      price: 18.00,
      cost: 8.00,
      preparationTime: 8,
    ),
    Product.create(
      name: 'Temaki Atum',
      description: 'Cone de alga com atum e arroz',
      category: 'Temaki',
      price: 19.00,
      cost: 9.00,
      preparationTime: 8,
    ),
    Product.create(
      name: 'Temaki Califórnia',
      description: 'Cone com kani, pepino e cream cheese',
      category: 'Temaki',
      price: 16.00,
      cost: 7.00,
      preparationTime: 8,
    ),

    // Yakisoba
    Product.create(
      name: 'Yakisoba Frango',
      description: 'Macarrão oriental com frango e legumes',
      category: 'Yakisoba',
      price: 28.00,
      cost: 12.00,
      preparationTime: 20,
    ),
    Product.create(
      name: 'Yakisoba Carne',
      description: 'Macarrão oriental com carne e legumes',
      category: 'Yakisoba',
      price: 30.00,
      cost: 14.00,
      preparationTime: 20,
    ),
    Product.create(
      name: 'Yakisoba Misto',
      description: 'Macarrão oriental com frango, carne e camarão',
      category: 'Yakisoba',
      price: 35.00,
      cost: 16.00,
      preparationTime: 22,
    ),

    // Bebidas
    Product.create(
      name: 'Refrigerante Lata',
      description: 'Refrigerante lata 350ml',
      category: 'Bebidas',
      price: 5.00,
      cost: 2.00,
      preparationTime: 1,
    ),
    Product.create(
      name: 'Água Mineral',
      description: 'Água mineral 500ml',
      category: 'Bebidas',
      price: 3.00,
      cost: 1.00,
      preparationTime: 1,
    ),
    Product.create(
      name: 'Suco Natural',
      description: 'Suco natural 300ml - diversos sabores',
      category: 'Bebidas',
      price: 8.00,
      cost: 3.00,
      preparationTime: 5,
    ),

    // Sobremesas
    Product.create(
      name: 'Sorvete Tempurá',
      description: 'Sorvete empanado e frito',
      category: 'Sobremesas',
      price: 15.00,
      cost: 6.00,
      preparationTime: 10,
    ),
    Product.create(
      name: 'Doce de Leite',
      description: 'Doce de leite com canela',
      category: 'Sobremesas',
      price: 12.00,
      cost: 5.00,
      preparationTime: 5,
    ),
  ];

  for (final product in products) {
    await db.insert('products', product.toMap());
  }

  print('   ✓ ${products.length} produtos adicionados');
}

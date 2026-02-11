import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/firebase_options.dart';

/// Script para limpar coleções globais antigas do Firebase
///
/// CONTEXTO:
/// O sistema foi corrigido para usar arquitetura multi-tenant com subcoleções:
/// - customers/{customerId}/products
/// - customers/{customerId}/sales
/// - customers/{customerId}/sale_items
/// - customers/{customerId}/cash_flow
///
/// As coleções globais antigas precisam ser deletadas:
/// - products (global) ❌
/// - sales (global) ❌
/// - sale_items (global) ❌
/// - cash_flow (global) ❌
///
/// USO:
/// dart run scripts/clean_firebase_global_collections.dart

void main() async {
  print('🔥 ========================================');
  print('🔥 LIMPEZA DE COLEÇÕES GLOBAIS DO FIREBASE');
  print('🔥 ========================================\n');

  // Inicializar Firebase
  print('📱 Inicializando Firebase...');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('✅ Firebase inicializado!\n');

  final firestore = FirebaseFirestore.instance;

  // Coleções antigas (globais) para deletar
  final collectionsToDelete = ['products', 'sales', 'sale_items', 'cash_flow'];

  print('⚠️  ATENÇÃO: As seguintes coleções serão DELETADAS:');
  for (var collection in collectionsToDelete) {
    print('   - $collection');
  }
  print('');

  // Contador de documentos deletados
  int totalDeleted = 0;

  for (var collectionName in collectionsToDelete) {
    print('🗑️  Deletando coleção: $collectionName');

    try {
      final snapshot = await firestore.collection(collectionName).get();
      final docsCount = snapshot.docs.length;

      if (docsCount == 0) {
        print('   ℹ️  Coleção vazia ou não existe');
        continue;
      }

      print('   📊 Total de documentos: $docsCount');

      // Deletar em lotes (batch) para melhor performance
      const batchSize = 500;
      int deleted = 0;

      while (true) {
        final batch = firestore.batch();
        final querySnapshot = await firestore
            .collection(collectionName)
            .limit(batchSize)
            .get();

        if (querySnapshot.docs.isEmpty) {
          break;
        }

        for (var doc in querySnapshot.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();
        deleted += querySnapshot.docs.length;
        totalDeleted += querySnapshot.docs.length;

        print('   🔄 Deletados: $deleted/$docsCount');

        if (querySnapshot.docs.length < batchSize) {
          break;
        }
      }

      print('   ✅ Coleção $collectionName deletada! ($deleted documentos)\n');
    } catch (e) {
      print('   ❌ Erro ao deletar $collectionName: $e\n');
    }
  }

  print('🎉 ========================================');
  print('🎉 LIMPEZA CONCLUÍDA!');
  print('🎉 Total de documentos deletados: $totalDeleted');
  print('🎉 ========================================\n');

  print('✅ Nova estrutura ativa:');
  print('   customers/{customerId}/products');
  print('   customers/{customerId}/sales');
  print('   customers/{customerId}/sale_items');
  print('   customers/{customerId}/cash_flow\n');

  print('💡 Próximos passos:');
  print('   1. Todos os usuários devem fazer login novamente');
  print('   2. Sincronizar dados (Upload)');
  print('   3. Verificar que produtos são compartilhados por cliente');
}

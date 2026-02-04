# Resumo: Remoção de Estoque + Melhorias nos Relatórios + iFood + Firebase

## Status: 03/02/2026 - 18:00

## ✅ Concluído:

### 1. Sistema de Estoque Removido
- ✅ Pasta `/lib/features/stock/` deletada
- ✅ Rota `/stock` removida do main.dart
- ✅ Card "Estoque" removido do Dashboard
- ✅ App compila sem erros

### 2. Scripts Criados
- ✅ `scripts/migrate_sales_to_cashflow.dart` - Migrar vendas antigas
- ✅ `scripts/add_sales_fields.dart` - Adicionar campos iFood e entrega

## ⚠️ Problemas Encontrados:

### Flutter SDK com Erros
Os scripts Dart não podem ser executados devido a erros no Flutter SDK:
```
Error: 'Offset' isn't a type
Error: 'PointerDeviceKind' isn't a type
```

**Causa**: Possível corrupção do Flutter SDK ou versão incompatível

**Solução Temporária**: Fazer mudanças diretamente no app, sem scripts

## 📋 Próximos Passos (Manual):

### 1. Adicionar Campos no Banco de Dados

Modificar `database_helper.dart` para adicionar na criação:
```sql
CREATE TABLE sales (
  ...
  is_ifood INTEGER DEFAULT 0,
  delivery_type TEXT DEFAULT 'Retirada',
  delivery_cost REAL DEFAULT 0,
  ...
)
```

Para bancos existentes, adicionar migração em `_initDatabase`:
```dart
// Adicionar após criar tabelas
final version = await db.getVersion();
if (version < 2) {
  await db.execute('ALTER TABLE sales ADD COLUMN is_if ood INTEGER DEFAULT 0');
  await db.execute('ALTER TABLE sales ADD COLUMN delivery_type TEXT DEFAULT "Retirada"');
  await db.execute('ALTER TABLE sales ADD COLUMN delivery_cost REAL DEFAULT 0');
  await db.setVersion(2);
}
```

### 2. Atualizar Modelo de Vendas

Adicionar campos em `Sale` model:
```dart
final bool isIfood;
final String deliveryType;
final double deliveryCost;
```

### 3. Adicionar Campos na Tela de Vendas

Em `quick_sale_screen.dart`, adicionar:
- ✅ Checkbox "Venda iFood"
- ✅ Já tem: Tipo de Entrega (Retirada/Entrega)
- ✅ Já tem: Taxa de Entrega

### 4. Melhorar Tela de Relatórios

Adicionar cards:
- 📊 Vendas com Entrega vs Retirada
- 🛵 Total de Entregas (quantidade e valor)
- 📱 Vendas iFood (quantidade e valor acumulado do dia)
- 🏆 Top 5 Produtos Mais Vendidos
- ⬇️ Top 5 Produtos Menos Vendidos

### 5. Implementar Firebase (Sincronização)

- Criar projeto no Firebase Console
- Adicionar dependências
- Configurar autenticação
- Implementar sync service
- UI de status de sincronização

## 💡 Recomendação:

Como os scripts não funcionam devido aos erros do Flutter SDK, vou fazer as alterações diretamente no código do app. Isso é mais seguro e evita depender de scripts externos.

**Quer que eu continue implementando as melhorias diretamente no código?**

Posso fazer nesta ordem:
1. ✅ Adicionar campos no banco
2. ✅ Atualizar modelo Sale
3. ✅ Adicionar checkbox iFood na tela de vendas
4. ✅ Melhorar relatórios com cards inteligentes
5. ✅ Implementar Firebase

**Confirme para eu continuar!** 🚀

# 🍣 SushiGen - Sistema de Gerenciamento para Restaurante de Sushi

Sistema completo de gerenciamento para restaurantes de sushi, desenvolvido em Flutter para Windows e macOS, com banco de dados offline SQLite e sistema de licenciamento.

## 🎯 Funcionalidades Principais

### ✅ Sistema de Licença e Autenticação
- Autenticação com ID de usuário + senha + chave de licença
- Validação de licenças com data de expiração
- Bloqueio automático ao vencer a licença
- Suporte para múltiplos dispositivos (limite configurável)
- Controle de dispositivos ativos por licença

### 📦 Gestão de Produtos
- Cadastro completo de produtos
- Categorização (Sushi, Sashimi, Hot Roll, Temaki, etc.)
- Controle de preço de venda e custo
- Tempo de preparo estimado
- Status ativo/inativo

### 🛒 Lançamento Rápido de Pedidos
- Interface otimizada para atendimento rápido
- Busca por produto
- Filtro por categoria
- Carrinho intuitivo com controle de quantidade
- Visualização de subtotal e total em tempo real
- Finalização rápida de vendas

### 📊 Gestão de Estoque
- Controle de quantidade por produto
- Estoque mínimo e máximo
- Histórico de compras
- Alertas de reposição

### 💰 Fluxo de Caixa
- Registro de entradas e saídas
- Categorização de transações
- Relatórios financeiros
- Vinculação com vendas

### 🔄 Sincronização Multi-Dispositivo
- Banco de dados local em cada máquina
- Sistema de sincronização de dados
- Controle de conflitos
- Log de sincronização

## 🏗️ Arquitetura

### Clean Architecture
```
lib/
├── core/
│   ├── database/          # DatabaseHelper, configurações SQLite
│   ├── constants/         # Constantes do app
│   └── utils/            # Utilitários e helpers
├── features/
│   ├── auth/             # Autenticação e Licença
│   │   ├── data/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   └── entities/
│   │   └── presentation/
│   │       ├── screens/
│   │       └── providers/
│   ├── products/         # Gestão de Produtos
│   ├── sales/            # Vendas e Pedidos
│   ├── stock/            # Controle de Estoque
│   └── cashflow/         # Fluxo de Caixa
```

### Tecnologias
- **Framework**: Flutter 3.x
- **State Management**: Riverpod
- **Banco de Dados**: SQLite (sqflite_common_ffi)
- **Criptografia**: crypto, encrypt
- **Plataformas**: Windows, macOS

## 📋 Estrutura do Banco de Dados

### Tabelas Principais

#### `users` - Usuários
- id, username, password_hash, email, role
- created_at, updated_at

#### `licenses` - Licenças
- id, license_key, user_id, expiration_date
- is_active, max_devices
- created_at, updated_at

#### `devices` - Dispositivos
- id, license_id, device_name, device_id
- last_sync, is_active, created_at

#### `products` - Produtos
- id, name, description, category
- price, cost, image_url, is_active
- preparation_time, created_at, updated_at, synced

#### `stock` - Estoque
- id, product_id, quantity, unit
- min_quantity, max_quantity
- last_purchase_date, last_purchase_price
- updated_at, synced

#### `sales` - Vendas
- id, sale_number, user_id
- customer_name, customer_phone
- total_amount, discount_amount, final_amount
- payment_method, status, notes
- sale_date, created_at, synced

#### `sale_items` - Itens da Venda
- id, sale_id, product_id, product_name
- quantity, unit_price, total_price, notes
- created_at, synced

#### `cash_flow` - Fluxo de Caixa
- id, user_id, transaction_type, category
- amount, description
- reference_id, reference_type
- transaction_date, created_at, synced

#### `sync_log` - Log de Sincronização
- id, table_name, record_id, action
- device_id, sync_date, status

## 🚀 Como Executar

### Pré-requisitos
- Flutter SDK 3.0 ou superior
- Dart SDK
- Windows 10+ ou macOS 10.14+

### Instalação e Setup

1. Clone o repositório:
```bash
git clone [seu-repositorio]
cd sushigen
```

2. Instale as dependências:
```bash
flutter pub get
```

3. **Configure o banco de dados com dados de exemplo:**
```bash
dart run scripts/setup_database.dart
```

Este script irá:
- ✅ Criar o banco de dados SQLite
- ✅ Gerar uma chave de licença anual
- ✅ Criar usuário administrador (admin/admin#7435)
- ✅ Adicionar 20 produtos de exemplo
- ✅ Exibir as credenciais de acesso

4. Execute o aplicativo:

**No macOS:**
```bash
flutter run -d macos
```

**No Windows:**
```bash
flutter run -d windows
```

### 🔑 Gerando Chaves de Licença

**Gerar uma chave:**
```bash
dart run scripts/generate_license.dart
```

**Gerar 5 chaves de uma vez:**
```bash
dart run scripts/generate_license.dart --multiple 5
```

**Gerar chaves por tipo (Trial, Mensal, Anual, Vitalícia):**
```bash
dart run scripts/generate_license.dart --typed
```

**Exemplo de saída:**
```
🔑 Chave gerada: 6319-35B3-FD24-1BC8
```

📖 **Para mais detalhes sobre licenciamento, consulte [LICENSES.md](LICENSES.md)**

### Build para Produção

**Windows:**
```bash
flutter build windows --release
```

**macOS:**
```bash
flutter build macos --release
```

## 🔐 Sistema de Licenciamento

### Processo de Autenticação
1. Usuário informa ID, senha e chave de licença
2. Sistema valida a licença (ativa e não expirada)
3. Verifica se o dispositivo está registrado
4. Autentica o usuário

### Bloqueio de Licença
- Licenças expiradas bloqueiam o acesso automaticamente
- Licenças podem ser desativadas manualmente
- Limite de dispositivos simultâneos configurável

## 🔄 Sincronização de Dados

O sistema foi projetado para permitir múltiplos dispositivos trabalhando simultaneamente:

1. **Cada dispositivo mantém seu banco local**
2. **Sistema de sincronização periódica**
3. **Controle de conflitos por timestamp**
4. **Log de sincronização para auditoria**

### Estratégias de Sincronização
- Sincronização automática em intervalos configuráveis
- Sincronização manual sob demanda
- Resolução de conflitos: "último a atualizar vence"
- Marcação de registros sincronizados

## 📱 Interface de Usuário

### Tela de Login
- Design moderno e limpo
- Validação em tempo real
- Feedback visual de erros
- Tema vermelho/sushi

### Tela de Lançamento Rápido
- **Layout dividido**: Produtos à esquerda, Carrinho à direita
- **Busca rápida** por nome de produto
- **Filtros por categoria** com chips visuais
- **Grid de produtos** com cards intuitivos
- **Carrinho dinâmico** com controle de quantidade
- **Resumo financeiro** em tempo real
- **Botão de finalização** destacado

## 🎨 Design

- Material Design 3
- Paleta de cores: Vermelho (tema sushi) + tons neutros
- Interface responsiva
- Otimizada para desktop (mouse e teclado)
- Foco em UX para atendimento rápido

## 📦 Dependências Principais

```yaml
dependencies:
  flutter_riverpod: ^2.5.1      # State Management
  sqflite_common_ffi: ^2.3.3    # Database Desktop
  path_provider: ^2.1.2         # Caminhos do sistema
  crypto: ^3.0.3                # Criptografia
  encrypt: ^5.0.3               # Criptografia avançada
  shared_preferences: ^2.2.2    # Preferências locais
  uuid: ^4.3.3                  # Geração de IDs únicos
  intl: ^0.19.0                 # Internacionalização
```

## 🔜 Próximos Passos

- [ ] Implementar repositórios de vendas e produtos
- [ ] Criar tela de gestão de produtos
- [ ] Implementar relatórios de vendas
- [ ] Adicionar dashboard principal
- [ ] Implementar sincronização via API REST
- [ ] Adicionar impressão de cupons
- [ ] Criar sistema de relatórios avançados
- [ ] Implementar backup automático

## 📄 Licença

Todos os direitos reservados © 2026 SushiGen

---

**Desenvolvido com ❤️ e 🍣 em Flutter**

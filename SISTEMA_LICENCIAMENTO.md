# Sistema de Licenciamento - SushiGen

## 📋 Visão Geral

O sistema de licenciamento do SushiGen foi aprimorado para oferecer uma experiência mais fluida e intuitiva ao usuário. A chave de licença agora é solicitada **apenas uma vez** e permanece ativa até a data de expiração.

---

## 🔐 Funcionalidades Implementadas

### 1. **Licença Persistente**
- ✅ A chave de licença é solicitada apenas no **primeiro login**
- ✅ Após a primeira ativação, o campo fica **desabilitado e preenchido automaticamente**
- ✅ Não é necessário digitar a chave novamente enquanto estiver válida
- ✅ Sistema verifica automaticamente se o usuário já possui licença ativa

### 2. **Contador de Dias Restantes**
- ✅ Exibe visualmente quantos dias faltam para a licença expirar
- ✅ **Código de cores** indicando o status:
  - 🟢 **Verde**: Mais de 30 dias restantes
  - 🟡 **Amarelo**: Entre 8 e 30 dias
  - 🟠 **Laranja**: 7 dias ou menos
  - 🔴 **Vermelho**: Expirada ou expira hoje

### 3. **Tela de Renovação de Licença**
- ✅ Opção acessível dentro do sistema
- ✅ Localizada no **menu lateral** (Drawer) e no **card de Configurações**
- ✅ Exibe status completo da licença atual
- ✅ Permite inserir nova chave de licença
- ✅ Desativa automaticamente licenças antigas ao renovar

---

## 🚀 Como Funciona

### **Primeiro Acesso (Nova Instalação)**
1. Usuário abre o sistema
2. Preenche: **ID do Usuário** + **Senha** + **Chave de Licença**
3. Sistema valida e salva a licença
4. Próximos logins não solicitarão a chave novamente

### **Acessos Subsequentes**
1. Usuário digita o **ID do Usuário**
2. Sistema detecta automaticamente se já existe licença ativa
3. Campo de licença fica **desabilitado e preenchido**
4. Exibe **contador de dias** abaixo do campo
5. Usuário digita apenas a **senha** e acessa

### **Renovação de Licença**
1. Dentro do sistema, usuário acessa:
   - **Menu Lateral** → "Renovar Licença"
   - **Dashboard** → "Configurações" → "Renovar Licença"
2. Visualiza status da licença atual (chave, data de expiração, dias restantes)
3. Insere a **nova chave de licença**
4. Sistema valida e atualiza automaticamente
5. Licença antiga é desativada

---

## 🎨 Interface Visual

### **Tela de Login com Licença Ativa**
```
┌─────────────────────────────────────┐
│ ID do Usuário: [admin           ]  │
│ Senha: [••••••••                ]  │
│ Chave de Licença: [1A56-0FD1... ]🔒│ ← Desabilitado
│ ┌──────────────────────────────┐   │
│ │ ✅ Ativa - 364 dias restantes│   │ ← Status verde
│ └──────────────────────────────┘   │
│          [  ENTRAR  ]              │
└─────────────────────────────────────┘
```

### **Alerta de Expiração Próxima**
```
┌─────────────────────────────────────┐
│ ID do Usuário: [admin           ]  │
│ Senha: [••••••••                ]  │
│ Chave de Licença: [1A56-0FD1... ]🔒│
│ ┌──────────────────────────────┐   │
│ │ ⚠️ Expira em 5 dias          │   │ ← Status laranja
│ └──────────────────────────────┘   │
│          [  ENTRAR  ]              │
└─────────────────────────────────────┘
```

### **Licença Expirada**
```
┌─────────────────────────────────────┐
│ ID do Usuário: [admin           ]  │
│ Senha: [••••••••                ]  │
│ Chave de Licença: [                ]│ ← Campo habilitado
│ ┌──────────────────────────────┐   │
│ │ ⚠️ Licença expirada!         │   │ ← Status vermelho
│ └──────────────────────────────┘   │
│          [  ENTRAR  ]              │
└─────────────────────────────────────┘
```

---

## 🔧 Detalhes Técnicos

### **Novos Métodos no AuthRepository**

#### `getActiveLicense(String username)`
```dart
// Busca licença ativa associada ao usuário
// Retorna null se não encontrar ou se estiver expirada
```

#### `authenticateWithoutLicense(String username, String password)`
```dart
// Autentica usuário sem validar licença
// Usado para logins após a primeira ativação
```

#### `updateUserLicense(String username, String licenseKey)`
```dart
// Atualiza/renova a licença de um usuário
// Desativa licenças antigas automaticamente
```

### **Fluxo de Verificação**
1. Usuário digita ID → Dispara listener
2. Sistema busca no banco se existe licença ativa
3. Se encontrar: preenche e desabilita campo
4. Se não encontrar: mantém campo habilitado
5. Exibe indicador visual do status

---

## 📱 Acessos no Sistema

### **Opção 1: Menu Lateral (Drawer)**
```
Dashboard
Nova Venda
Produtos
Relatórios
─────────────────
🔑 Renovar Licença  ← Nova opção
Sair
```

### **Opção 2: Dashboard - Configurações**
```
Dashboard → Configurações → Modal:
  • 🔑 Renovar Licença
  • ℹ️ Sobre o Sistema
```

---

## ✅ Checklist de Funcionalidades

### **Tela de Login**
- [x] Campo de licença desabilitado após primeira ativação
- [x] Contador de dias restantes visível
- [x] Código de cores por status
- [x] Detecção automática de licença ao digitar usuário
- [x] Preenchimento automático da chave salva

### **Sistema de Renovação**
- [x] Tela dedicada de renovação
- [x] Exibição de status da licença atual
- [x] Validação de nova chave
- [x] Desativação automática de licenças antigas
- [x] Feedback visual de sucesso/erro
- [x] Acesso via menu lateral
- [x] Acesso via configurações do dashboard

### **Banco de Dados**
- [x] Consulta de licença ativa por usuário
- [x] Atualização de licenças
- [x] Desativação de licenças expiradas
- [x] Validação de data de expiração

---

## 🐛 Correções Aplicadas

### **LocaleDataException Corrigido**
```dart
// Antes (causava erro)
final dateFormat = DateFormat('dd/MM/yyyy', 'pt_BR');

// Depois (funcionando)
final now = DateTime.now();
final today = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
```

**Motivo**: O `DateFormat` com locale precisa de inicialização assíncrona. Para datas simples, formatação manual é mais segura.

### **Inicialização Completa de Locale**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ Inicializar localização PT-BR
  await initializeDateFormatting('pt_BR', null);
  Intl.defaultLocale = 'pt_BR';
  
  runApp(const ProviderScope(child: MyApp()));
}
```

---

## 📝 Notas Importantes

1. **Backup do Banco**: A licença é armazenada no SQLite local. Se o usuário desinstalar o app, perderá a ativação.

2. **Multi-dispositivo**: O sistema permite que a mesma licença seja usada em vários computadores (limitado por `max_devices`).

3. **Segurança**: As chaves são validadas via SHA-256. Não é possível gerar chaves falsas.

4. **Renovação Antecipada**: É possível renovar antes da expiração. O novo período começa imediatamente.

---

## 🎯 Próximas Melhorias Sugeridas

- [ ] Notificação automática 7 dias antes da expiração
- [ ] Export/Import de licença (para backup)
- [ ] Histórico de renovações
- [ ] Dashboard de licenças (para admin)
- [ ] Sincronização de licenças entre dispositivos
- [ ] Recuperação de licença via email

---

## 📞 Suporte

Para geração de novas chaves de licença, utilize:
```bash
dart run scripts/generate_license.dart
```

---

**Versão do Documento**: 1.0  
**Data**: 03/02/2026  
**Status**: ✅ Implementado e Testado

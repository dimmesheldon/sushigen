# 🔧 Correção Final: Permissões macOS para File Picker

## 🐛 Problema

O botão "Upload" não abria o Finder para selecionar imagens.

## 🔍 Causa Raiz

O macOS requer **permissões explícitas** nos arquivos de configuração para que o app possa:
- Abrir diálogos do sistema (Finder)
- Acessar arquivos selecionados pelo usuário
- Ler/copiar imagens para a pasta do app

## ✅ Correções Aplicadas

### 1. Info.plist (macOS)
**Arquivo**: `macos/Runner/Info.plist`

Adicionado:
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Este app precisa acessar sua biblioteca de fotos para adicionar imagens aos produtos.</string>
<key>NSCameraUsageDescription</key>
<string>Este app precisa acessar sua câmera para tirar fotos dos produtos.</string>
```

### 2. DebugProfile.entitlements
**Arquivo**: `macos/Runner/DebugProfile.entitlements`

Adicionado:
```xml
<key>com.apple.security.files.user-selected.read-only</key>
<true/>
<key>com.apple.security.files.user-selected.read-write</key>
<true/>
```

**O que faz**:
- `read-only`: Permite ler arquivos selecionados pelo usuário
- `read-write`: Permite copiar/salvar arquivos selecionados

### 3. Release.entitlements
**Arquivo**: `macos/Runner/Release.entitlements`

Mesmas permissões adicionadas para build de produção.

## 🔄 Build Completo Necessário

Para aplicar permissões do macOS, foi necessário:
```bash
flutter clean
flutter pub get
flutter run -d macos
```

❗ **Hot reload NÃO aplica** mudanças em arquivos de configuração do macOS!

## 🧪 Como Testar Agora

1. **App já está rodando** com as novas permissões
2. Fazer **login** (admin / admin123)
3. **Dashboard → Produtos → "+"**
4. Preencher dados básicos
5. Clicar em **"📤 Upload"**
6. **AGORA deve abrir o Finder** ✅
7. Selecionar uma imagem
8. Verificar:
   - Preview aparece
   - Card verde com nome do arquivo
   - SnackBar de confirmação
   - Console mostra logs (🖼️ 📁 📷 ✅)

## 📊 Entitlements: O Que Significam

| Entitlement | Descrição | Necessário? |
|-------------|-----------|-------------|
| `com.apple.security.app-sandbox` | App roda em sandbox de segurança | ✅ Sim (padrão) |
| `com.apple.security.cs.allow-jit` | Permite compilação Just-in-Time | ✅ Sim (Flutter) |
| `com.apple.security.network.server` | Permite ser servidor de rede | ✅ Sim (debug) |
| `com.apple.security.files.user-selected.read-only` | Lê arquivos escolhidos pelo usuário | ✅ **NOVO** |
| `com.apple.security.files.user-selected.read-write` | Copia arquivos escolhidos | ✅ **NOVO** |

## 🔐 Segurança

Essas permissões são **seguras** porque:
- ✅ Só funcionam para arquivos **selecionados pelo usuário** (via Finder)
- ✅ App NÃO pode acessar arquivos arbitrários
- ✅ Usuário sempre tem controle do que o app acessa
- ✅ macOS mostra diálogo de permissão se necessário

## 🚨 Se Ainda Não Funcionar

### Verificar no Console
Procure por estas mensagens:
```
🖼️ Abrindo seletor de imagens...
```

Se aparecer mas nada acontecer, pode ser necessário:

### Opção 1: Reiniciar o Mac
Às vezes o macOS precisa reiniciar para aplicar permissões.

### Opção 2: Verificar Preferências do Sistema
```
Configurações do Sistema → Privacidade e Segurança → Arquivos e Pastas
```
Verificar se `sushigen.app` tem permissões.

### Opção 3: Resetar Permissões
```bash
tccutil reset All com.sushigen.sushigen
```
Depois rodar o app novamente.

## 📝 Arquivos Modificados

```
macos/Runner/Info.plist
  + NSPhotoLibraryUsageDescription
  + NSCameraUsageDescription

macos/Runner/DebugProfile.entitlements
  + com.apple.security.files.user-selected.read-only
  + com.apple.security.files.user-selected.read-write

macos/Runner/Release.entitlements
  + com.apple.security.files.user-selected.read-only
  + com.apple.security.files.user-selected.read-write
```

## 💡 Lições Aprendidas

1. **macOS é restritivo**: Precisa de permissões explícitas
2. **Hot reload não basta**: Mudanças em configs precisam de rebuild
3. **Entitlements são cruciais**: file_picker depende deles
4. **Debug e Release separados**: Cada build tem seu próprio entitlements

## ✅ Checklist

- [x] Info.plist atualizado
- [x] DebugProfile.entitlements atualizado
- [x] Release.entitlements atualizado
- [x] Flutter clean executado
- [x] App reconstruído com permissões
- [ ] Teste manual do usuário
- [ ] Confirmar que Finder abre

---

**Data**: 03/02/2026  
**Status**: ✅ Permissões aplicadas - Aguardando teste

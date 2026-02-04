# Etapa 15: Upload de Imagens Local no Cadastro de Produtos

## 🎯 Objetivo

Permitir que o usuário faça **upload de imagens do computador** ao cadastrar produtos, além da opção existente de URL.

## 📦 O Que Foi Implementado

### 1. **Dependências Adicionadas**

```yaml
# pubspec.yaml
dependencies:
  file_picker: ^8.1.6  # Seletor de arquivos nativo
```

### 2. **Nova Interface de Seleção**

Adicionamos dois botões para escolher o tipo de imagem:

- **🔗 URL**: Digitar link da imagem
- **📤 Upload**: Selecionar arquivo do computador

### 3. **Funcionalidades Implementadas**

#### a) Seleção de Arquivo
```dart
Future<void> _pickImage() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    allowMultiple: false,
  );
  
  if (result != null && result.files.isNotEmpty) {
    setState(() {
      _localImagePath = result.files.first.path;
      _useLocalImage = true;
    });
  }
}
```

#### b) Salvamento Local
```dart
Future<String?> _saveImageLocally(String sourcePath) async {
  final appDir = await getApplicationDocumentsDirectory();
  final imagesDir = Directory(path.join(appDir.path, 'products'));
  
  // Criar pasta se não existir
  if (!await imagesDir.exists()) {
    await imagesDir.create(recursive: true);
  }

  // Gerar nome único: product_1234567890.jpg
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final extension = path.extension(sourcePath);
  final fileName = 'product_$timestamp$extension';
  
  // Copiar arquivo
  final sourceFile = File(sourcePath);
  await sourceFile.copy(destinationPath);
  
  return destinationPath;
}
```

#### c) Preview Dinâmico
```dart
// Preview de imagem local
Image.file(
  File(_localImagePath!),
  fit: BoxFit.cover,
)

// Preview de URL
Image.network(
  _imageUrlController.text,
  fit: BoxFit.cover,
)
```

### 4. **Integração no Salvamento**

```dart
Future<void> _saveProduct() async {
  String? finalImageUrl;
  
  if (_useLocalImage && _localImagePath != null) {
    // Salvar imagem local na pasta do app
    finalImageUrl = await _saveImageLocally(_localImagePath!);
  } else if (_imageUrlController.text.trim().isNotEmpty) {
    // Usar URL fornecida
    finalImageUrl = _imageUrlController.text.trim();
  }
  
  final product = Product.create(
    // ...outros campos
    imageUrl: finalImageUrl,
  );
}
```

## 🎨 Interface Nova

### Botões de Seleção
```
┌─────────────┬─────────────┐
│  🔗 URL     │  📤 Upload  │  ← Botões toggle
└─────────────┴─────────────┘
```

### Modo URL
```
┌────────────────────────────┐
│ URL da Imagem             │
│ https://exemplo.com/...   │
└────────────────────────────┘
```

### Modo Upload
```
┌──────────────────────────────────┐
│ ✅ Imagem selecionada       ❌   │
│ produto_imagem.jpg               │
└──────────────────────────────────┘
```

### Preview
```
┌──────────────────────────┐
│                          │
│   [Preview da Imagem]    │
│                          │
└──────────────────────────┘
```

## 📂 Estrutura de Armazenamento

### Localização das Imagens

**macOS:**
```
/Users/[usuario]/Library/Containers/com.sushigen.sushigen/
  Data/Documents/products/
    product_1675432123456.jpg
    product_1675432234567.png
    ...
```

**Windows:**
```
C:\Users\[usuario]\AppData\Roaming\SushiGen\products\
    product_1675432123456.jpg
    ...
```

### Nomenclatura
- Formato: `product_[timestamp].[extensão]`
- Timestamp em milissegundos garante nomes únicos
- Extensão preservada do arquivo original

## 🔄 Fluxo de Uso

### 1. Cadastro Novo Produto
```
1. Clicar em "Cadastrar Produto"
2. Preencher nome, categoria, preço
3. Escolher "Upload" para imagem
4. Selecionar arquivo do computador
5. Ver preview da imagem
6. Salvar produto
   → Imagem copiada para pasta do app
   → Caminho salvo no banco de dados
```

### 2. Edição de Produto
```
1. Editar produto existente
2. Trocar imagem:
   - URL → Upload: Escolher novo arquivo
   - Upload → URL: Digitar nova URL
3. Salvar
   → Nova imagem substituiu a antiga
```

## 🧪 Como Testar

### Teste 1: Upload Básico
1. Dashboard → Produtos → "+"
2. Preencher dados básicos
3. Clicar em "Upload"
4. Selecionar imagem (JPG, PNG, GIF)
5. Verificar preview apareceu
6. Salvar produto
7. ✅ Verificar produto aparece com imagem na listagem

### Teste 2: Alternância URL ↔ Upload
1. Criar produto
2. Clicar "URL" → digitar link
3. Ver preview da URL
4. Clicar "Upload" → selecionar arquivo
5. ✅ Verificar preview mudou para arquivo local
6. ✅ URL foi limpa

### Teste 3: Remover Imagem Local
1. Selecionar imagem
2. Clicar no "❌" ao lado do nome
3. ✅ Imagem removida
4. ✅ Pode escolher outra

### Teste 4: Tipos de Arquivo
- ✅ JPG/JPEG
- ✅ PNG
- ✅ GIF
- ✅ BMP
- ✅ WEBP

### Teste 5: Editar Produto com Imagem
1. Editar produto que tem imagem URL
2. Trocar para Upload
3. Salvar
4. ✅ Nova imagem local substituiu URL

## 🎁 Benefícios

### Para o Usuário
- ✅ **Mais prático**: Não precisa hospedar imagens online
- ✅ **Offline**: Funciona sem internet
- ✅ **Privacidade**: Imagens ficam localmente
- ✅ **Qualidade**: Imagens originais sem compressão de URL

### Para o Sistema
- ✅ **Performance**: Carregamento instantâneo (arquivo local)
- ✅ **Confiabilidade**: Links não quebram
- ✅ **Controle**: Gerenciar todas as imagens
- ✅ **Backup**: Fácil fazer backup da pasta

## 📊 Comparação: URL vs Upload

| Aspecto | URL | Upload |
|---------|-----|--------|
| **Internet** | Necessária | Não |
| **Velocidade** | Depende da rede | Instantâneo |
| **Confiabilidade** | Link pode quebrar | 100% confiável |
| **Setup** | Precisa hospedar | Automático |
| **Privacidade** | Pública | Privada |
| **Espaço** | Zero local | Ocupa disco |

## 🔮 Melhorias Futuras

### Curto Prazo
- [ ] Redimensionar imagens automaticamente (otimizar espaço)
- [ ] Comprimir imagens grandes (ex: > 2MB)
- [ ] Limitar tamanho máximo (ex: 5MB)
- [ ] Crop/edição básica de imagem

### Médio Prazo
- [ ] Galeria de imagens (múltiplas fotos por produto)
- [ ] Arrastar e soltar arquivo
- [ ] Cole (Ctrl+V) imagem da área de transferência
- [ ] Remover imagens antigas não usadas

### Longo Prazo
- [ ] Sincronização de imagens entre dispositivos
- [ ] Backup automático em nuvem
- [ ] CDN para distribuição
- [ ] IA para remover fundo automaticamente

## 📝 Arquivos Modificados

```
pubspec.yaml
  - Adicionado: file_picker: ^8.1.6

lib/features/products/presentation/screens/product_form_screen.dart
  - Adicionado: imports (dart:io, file_picker, path_provider, path)
  - Adicionado: _localImagePath, _useLocalImage (state)
  - Adicionado: _pickImage() (seleção de arquivo)
  - Adicionado: _saveImageLocally() (cópia para pasta do app)
  - Adicionado: _removeLocalImage() (limpar seleção)
  - Modificado: _saveProduct() (processar imagem local)
  - Modificado: UI (botões URL/Upload, preview dinâmico)

assets/images/products/
  - Criado: Pasta para assets (não usada ainda, preparação futura)
```

## 💡 Notas Técnicas

### FilePicker
- Usa diálogos nativos do OS (macOS Finder, Windows Explorer)
- Suporta filtros por tipo de arquivo
- Retorna caminho completo do arquivo selecionado

### Path Provider
- `getApplicationDocumentsDirectory()`: Pasta de documentos do app
- Localização varia por SO mas sempre acessível
- Persistente entre execuções do app

### Gestão de Memória
- Imagens não são carregadas na memória até preview/uso
- `Image.file()` faz lazy loading
- Recomendado implementar cache para performance

### Segurança
- Arquivos salvos em pasta privada do app
- Outros apps não têm acesso
- Backup automático do OS (Time Machine, etc)

## ✅ Checklist de Implementação

- [x] Adicionar dependência file_picker
- [x] Criar pasta assets/images/products
- [x] Adicionar state para imagem local
- [x] Implementar _pickImage()
- [x] Implementar _saveImageLocally()
- [x] Implementar _removeLocalImage()
- [x] Atualizar _saveProduct() para processar imagem
- [x] Criar UI com botões URL/Upload
- [x] Adicionar preview dinâmico (File vs Network)
- [x] Mostrar nome do arquivo selecionado
- [x] Botão para remover imagem local
- [x] Testar fluxo completo
- [x] Documentação criada

## 🚀 Próxima Etapa

Com upload de imagens implementado, sugestões para próxima etapa:

1. **Exibir Imagens na Tela de Vendas**: Mostrar fotos dos produtos no grid
2. **Gestão de Estoque**: Controle de quantidade, alertas de mínimo
3. **Histórico de Vendas**: Relatório detalhado por produto
4. **Sistema de Clientes**: Cadastro, histórico, programas de fidelidade

---

**Data de Implementação**: 03/02/2026  
**Versão**: 1.0.0  
**Status**: ✅ Concluído

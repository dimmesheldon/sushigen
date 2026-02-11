# 🚀 BUILD E DMG - Comandos Finais

## ⏳ STATUS ATUAL

O build está em progresso...

```
Building macOS application...
```

---

## ✅ QUANDO O BUILD TERMINAR

### Você verá esta mensagem:
```
✓ Built build/macos/Build/Products/Release/sushigen.app
```

### Então execute:
```bash
./create_dmg.sh
```

---

## 📦 O QUE SERÁ CRIADO

### Arquivo:
```
SushiGen_v1.0.1_macOS.dmg
```

### Tamanho esperado:
```
~50-80 MB (com todo o conteúdo do app)
```

### Localização:
```
/Users/dimmesheldon/sushigen/SushiGen_v1.0.1_macOS.dmg
```

---

## 🧪 TESTAR ANTES DE DISTRIBUIR

### 1. Abrir o DMG:
```bash
open SushiGen_v1.0.1_macOS.dmg
```

### 2. Verificar conteúdo:
- ✅ sushigen.app visível
- ✅ Applications (atalho) visível
- ✅ Tamanho do app correto (~70-90 MB)

### 3. Testar instalação:
- Arraste sushigen.app para Applications
- Vá em Applications
- Clique duplo em sushigen
- App deve abrir normalmente

---

## 🌐 UPLOAD PARA LANDING PAGE

### Opções:

#### 1. GitHub Releases (Recomendado):
```bash
# Criar release
gh release create v1.0.1 \
    SushiGen_v1.0.1_macOS.dmg \
    --title "SushiGen v1.0.1 para macOS" \
    --notes "Instalador oficial do SushiGen para macOS"

# URL de download será:
# https://github.com/dimmesheldon/sushigen/releases/download/v1.0.1/SushiGen_v1.0.1_macOS.dmg
```

#### 2. Firebase Hosting:
```bash
# Upload manual
# Depois linkar na landing page
```

#### 3. Google Drive / Dropbox:
```bash
# Upload manual
# Gerar link compartilhável
# Adicionar na landing page
```

#### 4. Servidor próprio:
```bash
# Upload via FTP/SSH
# Link direto: https://seusite.com/downloads/SushiGen_v1.0.1_macOS.dmg
```

---

## 📋 INFORMAÇÕES PARA LANDING PAGE

### Título:
```
SushiGen para macOS
```

### Versão:
```
v1.0.1
```

### Tamanho:
```
~50-80 MB
```

### Requisitos:
```
macOS 10.15 (Catalina) ou superior
Apple Silicon (M1/M2/M3) e Intel suportados
```

### Instruções de instalação:
```markdown
## Como Instalar

1. **Baixe** o arquivo SushiGen_v1.0.1_macOS.dmg
2. **Clique duplo** no arquivo baixado
3. **Arraste** o ícone SushiGen para a pasta Applications
4. **Abra** o aplicativo pela primeira vez
5. Se aparecer aviso de segurança: 
   - Vá em Preferências do Sistema
   - Segurança e Privacidade
   - Clique em "Abrir mesmo assim"
```

---

## 🎨 BOTÃO DE DOWNLOAD PARA LANDING PAGE

### HTML:
```html
<a href="https://github.com/dimmesheldon/sushigen/releases/download/v1.0.1/SushiGen_v1.0.1_macOS.dmg" 
   class="download-btn">
  <i class="fab fa-apple"></i> Baixar para macOS
  <span class="version">v1.0.1 • 50 MB</span>
</a>
```

### Markdown:
```markdown
[![Baixar para macOS](https://img.shields.io/badge/Download-macOS-blue?style=for-the-badge&logo=apple)](https://github.com/dimmesheldon/sushigen/releases/download/v1.0.1/SushiGen_v1.0.1_macOS.dmg)
```

---

## 📸 SCREENSHOTS PARA LANDING PAGE

### Sugestões:
1. Tela de login
2. Dashboard principal
3. Tela de vendas
4. Relatórios
5. Gestão de produtos

### Tirar screenshots:
```bash
# Mac: Cmd + Shift + 4 (selecionar área)
# ou Cmd + Shift + 3 (tela inteira)
```

---

## ✅ CHECKLIST FINAL

Antes de publicar na landing page:

- [ ] Build concluído com sucesso
- [ ] DMG criado (tamanho correto ~50-80 MB)
- [ ] DMG testado em macOS limpo
- [ ] App abre corretamente
- [ ] Screenshots tiradas
- [ ] Release notes escritas
- [ ] Upload para servidor/GitHub
- [ ] Link de download funciona
- [ ] Instruções claras na landing page

---

## 🐛 SE DER ERRO

### "App danificado":
```bash
xattr -cr /Applications/sushigen.app
```

### Build não completa:
```bash
flutter clean
flutter pub get
flutter build macos --release
```

### DMG muito pequeno (< 10 MB):
```bash
# Verificar se app tem conteúdo
du -sh build/macos/Build/Products/Release/sushigen.app

# Se vazio, rebuild
flutter build macos --release
```

---

## 📞 PRÓXIMO PASSO

**AGUARDE O BUILD TERMINAR** e então:

```bash
./create_dmg.sh
```

Depois teste e faça upload! 🚀

---

**Data**: 11/02/2026
**Versão**: 1.0.1
**Status**: ⏳ Aguardando build...

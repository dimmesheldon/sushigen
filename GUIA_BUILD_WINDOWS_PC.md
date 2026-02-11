# 🪟 Build Windows - Guia Completo no seu PC

**Data:** 11 de Fevereiro de 2026  
**Estratégia:** ✅ Build local no PC Windows (MUITO MAIS SIMPLES!)

---

## 🎯 PLANO DE AÇÃO

### Fase 1: Preparar PC Windows (15-30 minutos - uma vez)
### Fase 2: Build Windows (5 minutos)
### Fase 3: Publicar Release (2 minutos)

---

## 📋 FASE 1: PREPARAR PC WINDOWS (Primeira vez)

### 1. Instalar Flutter no Windows

#### Opção A: Download Manual (Recomendado)
```powershell
# 1. Baixar Flutter SDK
# Acesse: https://docs.flutter.dev/get-started/install/windows
# Baixe: flutter_windows_3.27.3-stable.zip

# 2. Extrair para C:\src\flutter
# Criar pasta: C:\src\
# Extrair ZIP para: C:\src\flutter\

# 3. Adicionar ao PATH
# Painel de Controle → Sistema → Configurações Avançadas
# Variáveis de Ambiente → Path (usuário)
# Adicionar: C:\src\flutter\bin

# 4. Verificar instalação
flutter doctor
```

#### Opção B: Usando winget (Windows 11)
```powershell
winget install --id=Flutter.Flutter -e
flutter doctor
```

### 2. Instalar Dependências do Windows

```powershell
# Flutter vai pedir para instalar:
# ✅ Visual Studio 2022 (Build Tools)
# ✅ Windows SDK

# Executar:
flutter doctor

# Seguir instruções para instalar o que falta
```

### 3. Clonar Repositório

```powershell
# Opção A: Via HTTPS
cd C:\Users\[SEU_USUARIO]\Documents
git clone https://github.com/dimmesheldon/sushigen.git
cd sushigen

# Opção B: Via SSH (se configurado)
git clone git@github.com:dimmesheldon/sushigen.git
cd sushigen
```

### 4. Instalar Dependências do Projeto

```powershell
cd sushigen
flutter pub get
```

---

## 🚀 FASE 2: BUILD WINDOWS (5 minutos)

### 1. Verificar Tudo Está OK

```powershell
# Verificar Flutter
flutter doctor

# Ver dispositivos disponíveis
flutter devices
# Deve mostrar: Windows (desktop)
```

### 2. Fazer Build Release

```powershell
# Limpar builds anteriores
flutter clean

# Build release
flutter build windows --release

# Aguardar ~5 minutos
# Deve mostrar: ✓ Built build\windows\x64\runner\Release\sushigen.exe
```

### 3. Verificar Arquivos Gerados

```powershell
# Ver tamanho
dir build\windows\x64\runner\Release\

# Deve ter:
# sushigen.exe (~25-30 MB)
# flutter_windows.dll
# data\ (pasta com assets)
# + outras DLLs
```

### 4. Criar ZIP para Distribuição

```powershell
# Ir para pasta Release
cd build\windows\x64\runner\Release

# Criar ZIP com PowerShell
Compress-Archive -Path * -DestinationPath ..\..\..\..\..\..\sushigen-v1.0.2-windows.zip

# Voltar para raiz
cd ..\..\..\..\..\..

# Verificar ZIP criado
dir sushigen-v1.0.2-windows.zip
```

---

## 📤 FASE 3: PUBLICAR RELEASE (2 minutos)

### Opção A: Upload via GitHub CLI (Recomendado)

```powershell
# 1. Deletar tag antiga (se existir)
git tag -d v1.0.2
git push origin :refs/tags/v1.0.2

# 2. Criar tag nova
git tag -a v1.0.2 -m "SushiGen v1.0.2 - Windows + macOS"
git push origin v1.0.2

# 3. Criar release com ambos arquivos
gh release create v1.0.2 `
  sushigen-v1.0.2-windows.zip `
  --title "SushiGen v1.0.2 - Windows + macOS" `
  --notes "🍣 SushiGen v1.0.2

## 📦 Downloads

### Windows
- Arquivo: sushigen-v1.0.2-windows.zip (25-30 MB)
- Requisitos: Windows 10 ou superior

### macOS  
- Arquivo: SushiGen_v1.0.2_macOS.dmg (41 MB)
- Requisitos: macOS 10.13 ou superior

## 🚀 Instalação

### Windows:
1. Baixe sushigen-v1.0.2-windows.zip
2. Extraia para uma pasta (ex: C:\Program Files\SushiGen)
3. Execute sushigen.exe
4. **IMPORTANTE**: Mantenha todos os arquivos juntos!

### macOS:
1. Baixe SushiGen_v1.0.2_macOS.dmg
2. Clique duas vezes
3. Arraste para Applications
4. Abra (Sistema pode pedir permissão)

## ✨ Funcionalidades

✅ Sistema de licenciamento inteligente
✅ Lançamento rápido de pedidos
✅ Gestão completa de produtos
✅ Relatórios e analytics detalhados
✅ Fluxo de caixa integrado
✅ Suporte para iFood e delivery
✅ Banco de dados SQLite offline
✅ Geração de PDFs
✅ Upload de imagens de produtos

## 🔐 Credenciais de Teste

- Usuário: admin
- Senha: admin123
- Chave de Licença: 1A56-0FD1-4814-E762

## 🔗 Links

- 🌐 Site: https://sushigen.web.app
- 💬 Suporte: https://wa.me/5599984532007
- 📧 Email: dimme.spa@gmail.com

**Obrigado por usar o SushiGen!** 🍣"
```

### Opção B: Upload via GitHub Web

```powershell
# 1. Abrir GitHub Releases
start https://github.com/dimmesheldon/sushigen/releases/new

# 2. Preencher formulário:
# Tag: v1.0.2
# Title: SushiGen v1.0.2 - Windows + macOS
# Description: (copiar do exemplo acima)

# 3. Arrastar arquivos:
# - sushigen-v1.0.2-windows.zip
# - SushiGen_v1.0.2_macOS.dmg (do Mac)

# 4. Publicar Release
```

---

## 🔄 ADICIONAR DMG DO MACOS

### No Mac (você já tem!):

```bash
# 1. Renomear DMG existente
mv SushiGen_v1.0.1_macOS.dmg SushiGen_v1.0.2_macOS.dmg

# 2. Copiar para PC Windows via:
# - Pendrive
# - Google Drive / Dropbox
# - iCloud
# - Email (se < 25 MB)
# - AirDrop (se próximo)

# 3. No Windows, adicionar ao release:
gh release upload v1.0.2 SushiGen_v1.0.2_macOS.dmg
```

---

## 📊 RESULTADO FINAL

### Release v1.0.2 terá:

```
✅ sushigen-v1.0.2-windows.zip (25-30 MB)
✅ SushiGen_v1.0.2_macOS.dmg (41 MB)
✅ Release notes completas
✅ Links de download diretos
```

### Links de Download:

**Windows:**
```
https://github.com/dimmesheldon/sushigen/releases/download/v1.0.2/sushigen-v1.0.2-windows.zip
```

**macOS:**
```
https://github.com/dimmesheldon/sushigen/releases/download/v1.0.2/SushiGen_v1.0.2_macOS.dmg
```

---

## ⏱️ TEMPO TOTAL

```
Primeira vez (setup Windows):  15-30 minutos
Build Windows:                   5 minutos
Criar ZIP:                       1 minuto
Publicar Release:                2 minutos
---------------------------------------------
Total primeira vez:             23-38 minutos
Total próximas vezes:            8 minutos
```

---

## 🎯 VANTAGENS DESTA ABORDAGEM

### vs GitHub Actions:
- ✅ **Controle total** - você vê o que acontece
- ✅ **Rápido** - 5 min vs 15 min
- ✅ **Confiável** - não depende de nuvem
- ✅ **Flexível** - testa antes de publicar
- ✅ **Sem limites** - não consome minutos grátis

### vs Build Manual Complexo:
- ✅ **Simples** - só 3 comandos
- ✅ **Repetível** - mesmo processo sempre
- ✅ **Documentado** - tudo explicado

---

## 🐛 TROUBLESHOOTING

### Erro: "flutter command not found"
```powershell
# Adicionar ao PATH manualmente:
# C:\src\flutter\bin

# Ou reinstalar Flutter
```

### Erro: "Visual Studio not found"
```powershell
# Instalar Visual Studio Build Tools:
# https://visualstudio.microsoft.com/downloads/
# Selecionar: "Desktop development with C++"
```

### Erro: Build falha
```powershell
# Limpar e tentar novamente:
flutter clean
flutter pub get
flutter build windows --release
```

### ZIP muito pequeno (< 5 MB)
```
# Provavelmente faltou incluir arquivos
# Criar ZIP da pasta Release completa
```

---

## 📝 CHECKLIST

### Preparação (primeira vez):
- [ ] Flutter instalado
- [ ] Visual Studio Build Tools instalado
- [ ] Repositório clonado
- [ ] flutter pub get executado

### Build:
- [ ] flutter clean
- [ ] flutter build windows --release
- [ ] Verificar sushigen.exe gerado
- [ ] Criar ZIP

### Publicar:
- [ ] Deletar tag antiga
- [ ] Criar tag nova
- [ ] Criar release com ZIP Windows
- [ ] Adicionar DMG macOS
- [ ] Testar links de download

---

## 🚀 PRÓXIMOS PASSOS

1. **Ir para o PC Windows**
2. **Seguir Fase 1** (se primeira vez)
3. **Executar Fase 2** (build)
4. **Executar Fase 3** (publicar)
5. **Atualizar landing page** com links

**Tempo total: 8 minutos (após setup inicial)** ⚡

**Quer que eu crie um script PowerShell automatizado?** 🎯

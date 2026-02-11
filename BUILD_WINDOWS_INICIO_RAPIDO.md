# 🪟 BUILD WINDOWS - INÍCIO RÁPIDO

**Use este guia no seu PC Windows com VS Code + Copilot**

---

## 🎯 OBJETIVO

Fazer build do SushiGen para Windows e publicar release v1.0.2

---

## ⚡ COMANDOS RÁPIDOS

### 1️⃣ Primeira Vez (Setup - 15 min)

```powershell
# Baixar e instalar Flutter
# https://docs.flutter.dev/get-started/install/windows

# Verificar instalação
flutter doctor

# Clonar repositório
git clone https://github.com/dimmesheldon/sushigen.git
cd sushigen

# Instalar dependências
flutter pub get
```

### 2️⃣ Build (5-10 min)

```powershell
# Limpar builds anteriores
flutter clean

# Build release
flutter build windows --release

# Criar ZIP
Compress-Archive -Path "build\windows\x64\runner\Release\*" -DestinationPath "sushigen-v1.0.2-windows.zip" -Force
```

### 3️⃣ Publicar (2 min)

```powershell
# Criar release
gh release create v1.0.2 `
  sushigen-v1.0.2-windows.zip `
  --title "SushiGen v1.0.2 - Windows + macOS" `
  --notes "🍣 Release completo para Windows e macOS"

# Testar link
start https://github.com/dimmesheldon/sushigen/releases/tag/v1.0.2
```

---

## 📚 DOCUMENTAÇÃO COMPLETA

Se precisar de ajuda detalhada:

1. **GUIA_BUILD_WINDOWS_PC.md** 
   - Setup completo do Flutter
   - Troubleshooting
   - Checklist detalhado

2. **build_windows_script.md**
   - Script automatizado PowerShell
   - Uso: `.\build_windows.ps1`
   - Faz tudo de uma vez

3. **ESTRATEGIA_BUILD_WINDOWS.md**
   - Por que escolhemos build local
   - Comparação com GitHub Actions
   - Lições aprendidas

---

## 🤖 USANDO COPILOT

### No VS Code, pergunte:

**"Como instalar Flutter no Windows?"**
```
Copilot vai guiar instalação passo a passo
```

**"Execute o build do Flutter para Windows"**
```
Copilot vai executar: flutter build windows --release
```

**"Crie o ZIP de distribuição"**
```
Copilot vai criar: sushigen-v1.0.2-windows.zip
```

**"Publique no GitHub Releases v1.0.2"**
```
Copilot vai executar gh release create...
```

---

## ✅ CHECKLIST

### Setup (primeira vez):
- [ ] Flutter instalado
- [ ] Visual Studio Build Tools instalado
- [ ] Repositório clonado
- [ ] `flutter pub get` executado
- [ ] GitHub CLI instalado

### Build:
- [ ] `flutter clean` executado
- [ ] `flutter build windows --release` concluído
- [ ] `sushigen.exe` gerado em `build\windows\x64\runner\Release\`
- [ ] ZIP criado

### Publicar:
- [ ] Release v1.0.2 criado
- [ ] ZIP Windows anexado
- [ ] Link testado

---

## 📦 RESULTADO ESPERADO

Após concluir, você terá:

```
✅ sushigen-v1.0.2-windows.zip (25-30 MB)
✅ Release no GitHub: 
   https://github.com/dimmesheldon/sushigen/releases/tag/v1.0.2
```

---

## 🆘 PROBLEMAS?

### Flutter não reconhecido
```powershell
# Adicionar ao PATH:
# C:\src\flutter\bin
```

### Build falha
```powershell
# Limpar e tentar novamente:
flutter clean
flutter pub get
flutter build windows --release --verbose
```

### ZIP muito pequeno
```powershell
# Verificar conteúdo:
Expand-Archive -Path sushigen-v1.0.2-windows.zip -DestinationPath test
dir test
```

---

## ⏱️ TEMPO TOTAL

```
Setup (primeira vez):  15-30 min
Build Windows:          5-10 min  
Criar ZIP:                 1 min
Publicar Release:          2 min
--------------------------------
Total primeira vez:    23-43 min
Total próximas vezes:   8-13 min
```

---

## 🚀 COMEÇAR AGORA

1. **Abra o PowerShell** no Windows
2. **Siga os comandos** da seção "⚡ COMANDOS RÁPIDOS"
3. **Use o Copilot** para ajudar em cada etapa
4. **Qualquer dúvida**, leia os guias detalhados

**Boa sorte! 🍣**

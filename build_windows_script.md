# 🚀 Script Automatizado - Build Windows

**Arquivo:** `build_windows.ps1`  
**Descrição:** Script PowerShell para automatizar build e release

---

## 📄 SCRIPT COMPLETO

Salve como `build_windows.ps1` na raiz do projeto:

```powershell
# ========================================
# SushiGen - Build Windows Automatizado
# ========================================

Write-Host "🍣 SushiGen - Build Windows" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan
Write-Host ""

# 1. Verificar Flutter
Write-Host "📋 Verificando Flutter..." -ForegroundColor Yellow
flutter doctor
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro: Flutter não configurado corretamente" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Flutter OK" -ForegroundColor Green
Write-Host ""

# 2. Limpar builds anteriores
Write-Host "🧹 Limpando builds anteriores..." -ForegroundColor Yellow
flutter clean
Write-Host "✅ Limpeza concluída" -ForegroundColor Green
Write-Host ""

# 3. Instalar dependências
Write-Host "📦 Instalando dependências..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro ao instalar dependências" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Dependências instaladas" -ForegroundColor Green
Write-Host ""

# 4. Build Release
Write-Host "🔨 Compilando aplicativo..." -ForegroundColor Yellow
Write-Host "⏱️  Isso pode levar 5-10 minutos..." -ForegroundColor Gray
flutter build windows --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro no build" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Build concluído!" -ForegroundColor Green
Write-Host ""

# 5. Verificar arquivos gerados
Write-Host "📁 Verificando arquivos..." -ForegroundColor Yellow
$releasePath = "build\windows\x64\runner\Release"
if (-not (Test-Path "$releasePath\sushigen.exe")) {
    Write-Host "❌ Executável não encontrado!" -ForegroundColor Red
    exit 1
}
$exeSize = (Get-Item "$releasePath\sushigen.exe").Length / 1MB
Write-Host "✅ sushigen.exe: $([math]::Round($exeSize, 2)) MB" -ForegroundColor Green
Write-Host ""

# 6. Criar ZIP
Write-Host "📦 Criando pacote de distribuição..." -ForegroundColor Yellow
$version = "v1.0.2"
$zipName = "sushigen-$version-windows.zip"

# Deletar ZIP anterior se existir
if (Test-Path $zipName) {
    Remove-Item $zipName -Force
}

# Criar novo ZIP
Compress-Archive -Path "$releasePath\*" -DestinationPath $zipName
$zipSize = (Get-Item $zipName).Length / 1MB
Write-Host "✅ ZIP criado: $zipName ($([math]::Round($zipSize, 2)) MB)" -ForegroundColor Green
Write-Host ""

# 7. Resumo
Write-Host "==============================" -ForegroundColor Cyan
Write-Host "✅ BUILD CONCLUÍDO COM SUCESSO!" -ForegroundColor Green
Write-Host "==============================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📦 Arquivo gerado:" -ForegroundColor Yellow
Write-Host "   $zipName" -ForegroundColor White
Write-Host ""
Write-Host "📍 Localização:" -ForegroundColor Yellow
Write-Host "   $(Get-Location)\$zipName" -ForegroundColor White
Write-Host ""
Write-Host "📏 Tamanho:" -ForegroundColor Yellow
Write-Host "   $([math]::Round($zipSize, 2)) MB" -ForegroundColor White
Write-Host ""
Write-Host "🚀 Próximos passos:" -ForegroundColor Cyan
Write-Host "   1. Testar o executável localmente" -ForegroundColor White
Write-Host "   2. Criar release no GitHub:" -ForegroundColor White
Write-Host "      gh release create $version $zipName --title 'SushiGen $version'" -ForegroundColor Gray
Write-Host ""
Write-Host "🍣 Build finalizado!" -ForegroundColor Green
```

---

## 🎯 COMO USAR

### 1. Salvar Script

```powershell
# No PC Windows, na pasta do projeto:
# Criar arquivo: build_windows.ps1
# Copiar conteúdo acima
```

### 2. Permitir Execução (primeira vez)

```powershell
# Abrir PowerShell como Administrador
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Confirmar com: Y
```

### 3. Executar Script

```powershell
# Navegar para pasta do projeto
cd C:\Users\[SEU_USUARIO]\Documents\sushigen

# Executar script
.\build_windows.ps1

# Aguardar conclusão (~5-10 minutos)
```

### 4. Publicar Release

```powershell
# Após script concluir, executar:
gh release create v1.0.2 `
  sushigen-v1.0.2-windows.zip `
  --title "SushiGen v1.0.2 - Windows + macOS" `
  --notes "Release completo com Windows e macOS"
```

---

## 📊 OUTPUT DO SCRIPT

```
🍣 SushiGen - Build Windows
==============================

📋 Verificando Flutter...
✅ Flutter OK

🧹 Limpando builds anteriores...
✅ Limpeza concluída

📦 Instalando dependências...
✅ Dependências instaladas

🔨 Compilando aplicativo...
⏱️  Isso pode levar 5-10 minutos...
✅ Build concluído!

📁 Verificando arquivos...
✅ sushigen.exe: 28.5 MB

📦 Criando pacote de distribuição...
✅ ZIP criado: sushigen-v1.0.2-windows.zip (32.7 MB)

==============================
✅ BUILD CONCLUÍDO COM SUCESSO!
==============================

📦 Arquivo gerado:
   sushigen-v1.0.2-windows.zip

📍 Localização:
   C:\Users\Usuario\Documents\sushigen\sushigen-v1.0.2-windows.zip

📏 Tamanho:
   32.7 MB

🚀 Próximos passos:
   1. Testar o executável localmente
   2. Criar release no GitHub:
      gh release create v1.0.2 sushigen-v1.0.2-windows.zip

🍣 Build finalizado!
```

---

## 🎨 VARIAÇÕES DO SCRIPT

### Script Simples (sem cores)

```powershell
# build_simple.ps1
flutter clean
flutter pub get
flutter build windows --release
Compress-Archive -Path "build\windows\x64\runner\Release\*" -DestinationPath "sushigen-v1.0.2-windows.zip" -Force
Write-Host "Build concluído: sushigen-v1.0.2-windows.zip"
```

### Script com Upload Automático

```powershell
# build_and_release.ps1
# (adicionar ao final do script principal)

Write-Host "📤 Fazendo upload para GitHub..." -ForegroundColor Yellow
gh release create v1.0.2 $zipName `
  --title "SushiGen v1.0.2" `
  --notes "Release automático"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Release publicado!" -ForegroundColor Green
    Write-Host "🔗 https://github.com/dimmesheldon/sushigen/releases/tag/v1.0.2"
} else {
    Write-Host "❌ Erro ao publicar release" -ForegroundColor Red
}
```

---

## 🐛 TROUBLESHOOTING

### Erro: "cannot be loaded because running scripts is disabled"

```powershell
# Executar como Administrador:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Erro: "flutter: The term 'flutter' is not recognized"

```powershell
# Adicionar Flutter ao PATH:
$env:Path += ";C:\src\flutter\bin"

# Ou reiniciar PowerShell após instalação
```

### Build falha no meio

```powershell
# Executar comandos manualmente:
flutter clean
flutter pub get
flutter build windows --release --verbose

# Ver erros detalhados
```

---

## ✅ CHECKLIST DE USO

### Primeira Vez:
- [ ] Flutter instalado e no PATH
- [ ] Visual Studio Build Tools instalado
- [ ] Script salvo como `build_windows.ps1`
- [ ] Execution Policy configurado
- [ ] GitHub CLI instalado (`gh`)

### Toda Vez:
- [ ] Abrir PowerShell
- [ ] Navegar para pasta do projeto
- [ ] Executar `.\build_windows.ps1`
- [ ] Aguardar conclusão
- [ ] Testar ZIP gerado
- [ ] Publicar release

---

## 🚀 BENEFÍCIOS

✅ **Automatizado** - Um comando faz tudo  
✅ **Verificações** - Valida cada etapa  
✅ **Visual** - Cores e emojis claros  
✅ **Rápido** - 5-10 minutos total  
✅ **Confiável** - Para se algo der errado  
✅ **Repetível** - Sempre o mesmo processo  

---

**Salve este script e use sempre que precisar buildar para Windows!** 🎯

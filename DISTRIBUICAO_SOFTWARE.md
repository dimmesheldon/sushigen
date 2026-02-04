# 📦 Distribuição do SushiGen - Guia Completo

**Data**: 2026-02-03  
**Problema**: Como os clientes vão baixar e instalar o sistema?

---

## 🎯 Visão Geral

Precisamos criar **executáveis nativos** para Windows e macOS que os clientes possam baixar e instalar facilmente.

---

## 📱 Plataformas Suportadas

### ✅ Implementação Atual
- **macOS**: App nativo (.app)
- **Windows**: Executável nativo (.exe)

### 🔜 Futuro (Opcional)
- **Linux**: AppImage ou .deb
- **Web**: Progressive Web App (PWA)

---

## 🛠️ Solução 1: Build Manual (Atual)

### Para macOS

```bash
# 1. Build de produção
flutter build macos --release

# 2. Arquivo gerado:
build/macos/Build/Products/Release/sushigen.app

# 3. Criar DMG para distribuição (opcional)
# Instalar create-dmg:
brew install create-dmg

# Criar DMG:
create-dmg \
  --volname "SushiGen Installer" \
  --window-pos 200 120 \
  --window-size 800 400 \
  --icon-size 100 \
  --icon "sushigen.app" 200 190 \
  --hide-extension "sushigen.app" \
  --app-drop-link 600 185 \
  "SushiGen-1.0.0.dmg" \
  "build/macos/Build/Products/Release/sushigen.app"
```

### Para Windows

```bash
# 1. Build de produção (no Windows ou via CI)
flutter build windows --release

# 2. Arquivo gerado:
build/windows/x64/runner/Release/sushigen.exe

# 3. Criar instalador com Inno Setup
# Baixar: https://jrsoftware.org/isdl.php
# Criar script .iss (ver abaixo)
```

#### Script Inno Setup (sushigen_installer.iss)

```iss
[Setup]
AppName=SushiGen
AppVersion=1.0.0
DefaultDirName={pf}\SushiGen
DefaultGroupName=SushiGen
OutputDir=installers
OutputBaseFilename=SushiGen-Setup-1.0.0
Compression=lzma2
SolidCompression=yes
WizardStyle=modern

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs

[Icons]
Name: "{group}\SushiGen"; Filename: "{app}\sushigen.exe"
Name: "{commondesktop}\SushiGen"; Filename: "{app}\sushigen.exe"

[Run]
Filename: "{app}\sushigen.exe"; Description: "Executar SushiGen"; Flags: postinstall nowait skipifsilent
```

---

## 🚀 Solução 2: CI/CD Automatizado (RECOMENDADO)

### Usando GitHub Actions

Crie `.github/workflows/release.yml`:

```yaml
name: Build and Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build-macos:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.38.5'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Build macOS
        run: flutter build macos --release
      
      - name: Create DMG
        run: |
          brew install create-dmg
          create-dmg \
            --volname "SushiGen" \
            --window-pos 200 120 \
            --window-size 800 400 \
            --icon-size 100 \
            --app-drop-link 600 185 \
            "SushiGen-${{ github.ref_name }}-macOS.dmg" \
            "build/macos/Build/Products/Release/sushigen.app"
      
      - name: Upload Release Asset
        uses: actions/upload-artifact@v3
        with:
          name: macos-dmg
          path: SushiGen-*.dmg

  build-windows:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.38.5'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Build Windows
        run: flutter build windows --release
      
      - name: Create Installer
        run: |
          # Usar Inno Setup via CLI
          iscc sushigen_installer.iss
      
      - name: Upload Release Asset
        uses: actions/upload-artifact@v3
        with:
          name: windows-installer
          path: installers/*.exe

  release:
    needs: [build-macos, build-windows]
    runs-on: ubuntu-latest
    steps:
      - name: Download artifacts
        uses: actions/download-artifact@v3
      
      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          files: |
            macos-dmg/*.dmg
            windows-installer/*.exe
          body: |
            ## SushiGen ${{ github.ref_name }}
            
            ### Instruções de Instalação
            
            **macOS:**
            1. Baixe o arquivo .dmg
            2. Abra o arquivo
            3. Arraste o SushiGen para a pasta Aplicativos
            
            **Windows:**
            1. Baixe o instalador .exe
            2. Execute o instalador
            3. Siga as instruções na tela
```

---

## 📥 Solução 3: Distribuição via Site/Landing Page

### Estrutura Recomendada

```
Website SushiGen
│
├── Página Principal (sushigen.com.br)
│   ├── Explicação do produto
│   ├── Funcionalidades
│   ├── Preços
│   └── Botões de Download
│       ├── [Baixar para macOS]
│       └── [Baixar para Windows]
│
├── Página de Download (sushigen.com.br/download)
│   ├── Instruções de instalação
│   ├── Requisitos do sistema
│   ├── Links de download direto
│   └── Vídeo tutorial
│
└── Painel do Cliente (sushigen.com.br/cliente)
    ├── Login com licença
    ├── Downloads disponíveis
    ├── Histórico de versões
    └── Suporte
```

### Hospedagem de Arquivos

#### Opção A: GitHub Releases (Grátis)
```
https://github.com/seu-usuario/sushigen/releases/latest
├── SushiGen-1.0.0-macOS.dmg (50 MB)
└── SushiGen-Setup-1.0.0.exe (40 MB)
```

**Vantagens:**
✅ Grátis  
✅ Confiável  
✅ Versionamento automático  
✅ CDN global  

#### Opção B: Firebase Storage
```
https://firebasestorage.googleapis.com/v0/b/sushigen.appspot.com/o/
├── releases/
│   ├── macos/
│   │   └── SushiGen-1.0.0.dmg
│   └── windows/
│       └── SushiGen-Setup-1.0.0.exe
```

**Vantagens:**
✅ Integração com Firebase já existente  
✅ Controle de acesso  
✅ Analytics de downloads  

#### Opção C: AWS S3 + CloudFront
```
https://downloads.sushigen.com.br/
├── macos/
│   └── SushiGen-1.0.0.dmg
└── windows/
    └── SushiGen-Setup-1.0.0.exe
```

**Vantagens:**
✅ Performance máxima  
✅ Domínio personalizado  
✅ Escalabilidade  

**Custo:** ~R$ 10-30/mês

---

## 📝 Fluxo de Distribuição Completo

### 1. Cliente Entra em Contato
```
Cliente → Contato via WhatsApp/Email
   ↓
Admin → Cadastra cliente no sistema
   ↓
Admin → Gera licença (30/90/365 dias)
   ↓
Admin → Envia credenciais por email
```

### 2. Email Automático para Cliente

```
Assunto: Bem-vindo ao SushiGen! 🍣

Olá [Nome do Cliente],

Sua licença do SushiGen foi ativada com sucesso!

📥 DOWNLOAD DO SISTEMA
• macOS: https://sushigen.com.br/download/macos
• Windows: https://sushigen.com.br/download/windows

🔑 SUAS CREDENCIAIS
• Usuário: [username]
• Senha: [senha]
• Chave de Licença: [licenseKey]

📖 INSTRUÇÕES
1. Baixe o sistema para seu sistema operacional
2. Instale o aplicativo
3. Na tela de login, use as credenciais acima
4. Comece a usar!

📹 VÍDEO TUTORIAL
https://youtube.com/sushigen-tutorial

💬 SUPORTE
WhatsApp: (11) 9999-9999
Email: suporte@sushigen.com.br

Atenciosamente,
Equipe SushiGen
```

### 3. Cliente Baixa e Instala

#### macOS:
1. Baixa o `.dmg`
2. Abre o arquivo
3. Arrasta para Aplicativos
4. Abre o SushiGen
5. Sistema pode pedir para "Abrir de qualquer forma" (segurança do Mac)

#### Windows:
1. Baixa o `.exe`
2. Executa o instalador
3. Clica "Avançar" → "Instalar"
4. Abre o SushiGen do menu iniciar

### 4. Primeiro Acesso
1. Cliente abre o app
2. Vê tela de login
3. Insere: username + senha + chave
4. Sistema valida no banco admin
5. Cria banco local do cliente (`sushigen_[username].db`)
6. Cliente entra no sistema!

---

## 🔧 Implementação Recomendada (Passo a Passo)

### Fase 1: Build Local (1 dia)

```bash
# 1. Criar script de build
mkdir -p scripts
cat > scripts/build_releases.sh << 'EOF'
#!/bin/bash

echo "🚀 Building SushiGen releases..."

# macOS
echo "📱 Building macOS..."
flutter build macos --release
cp -r build/macos/Build/Products/Release/sushigen.app releases/macos/

# Windows (se estiver no Windows)
# flutter build windows --release
# cp -r build/windows/x64/runner/Release releases/windows/

echo "✅ Build complete!"
echo "Files in releases/"
EOF

chmod +x scripts/build_releases.sh

# 2. Executar build
./scripts/build_releases.sh

# 3. Testar instalação
open releases/macos/sushigen.app
```

### Fase 2: Criar Landing Page (2-3 dias)

**Opção A: HTML estático simples**
```html
<!DOCTYPE html>
<html>
<head>
    <title>SushiGen - Sistema de Gestão para Restaurantes</title>
</head>
<body>
    <h1>🍣 SushiGen</h1>
    <p>Sistema completo de gestão para restaurantes de sushi</p>
    
    <div class="downloads">
        <a href="releases/macos/sushigen.dmg" class="btn">
            📥 Baixar para macOS
        </a>
        <a href="releases/windows/sushigen-setup.exe" class="btn">
            📥 Baixar para Windows
        </a>
    </div>
    
    <div class="features">
        <h2>Funcionalidades</h2>
        <ul>
            <li>✅ Lançamento rápido de pedidos</li>
            <li>✅ Gestão de produtos e estoque</li>
            <li>✅ Relatórios e análises</li>
            <li>✅ Fluxo de caixa completo</li>
        </ul>
    </div>
</body>
</html>
```

**Opção B: Next.js + Vercel (Profissional)**
```bash
npx create-next-app@latest sushigen-website
cd sushigen-website
# Desenvolver site
# Deploy: git push → Vercel auto-deploy
```

### Fase 3: Automação com GitHub Actions (1 dia)

1. Criar repositório no GitHub
2. Adicionar workflow de CI/CD (código acima)
3. Criar tag: `git tag v1.0.0 && git push --tags`
4. GitHub Actions gera releases automaticamente
5. Clientes baixam de: `https://github.com/seu-usuario/sushigen/releases`

---

## 💡 Recomendação Final

### Curto Prazo (Agora):
1. ✅ **Build manual** com `flutter build macos/windows`
2. ✅ **Distribuição direta**: Enviar .app/.exe via Google Drive/Dropbox
3. ✅ **Instalação manual**: Tutorial em PDF

### Médio Prazo (1-2 meses):
1. ✅ **Landing page simples** (HTML estático)
2. ✅ **GitHub Releases** para hospedagem
3. ✅ **Email automático** com credenciais

### Longo Prazo (3-6 meses):
1. ✅ **Site profissional** (Next.js)
2. ✅ **CI/CD completo** (GitHub Actions)
3. ✅ **Portal do cliente** (downloads, renovação, suporte)
4. ✅ **Auto-update** no app (verificar novas versões)

---

## 📊 Comparação de Custos

| Solução | Custo Mensal | Complexidade | Tempo Setup |
|---------|--------------|--------------|-------------|
| Build Manual + Google Drive | R$ 0 | Baixa | 1 dia |
| GitHub Releases | R$ 0 | Média | 2 dias |
| Firebase Storage | R$ 0-20 | Média | 3 dias |
| Site + AWS S3 | R$ 50-100 | Alta | 1 semana |
| Solução Completa (CI/CD + Site) | R$ 50-150 | Alta | 2 semanas |

---

## 🎯 Plano de Ação Imediato

### Hoje (3h):
- [ ] Fazer build de produção: `flutter build macos --release`
- [ ] Testar instalação do .app
- [ ] Criar pasta Google Drive: "SushiGen Releases"
- [ ] Upload do .app
- [ ] Criar link compartilhável

### Esta Semana (8h):
- [ ] Criar script de build automatizado
- [ ] Testar build Windows (se tiver acesso a Windows)
- [ ] Criar template de email com instruções
- [ ] Documentar processo de instalação (screenshots)
- [ ] Testar instalação em computador limpo

### Próximas 2 Semanas (20h):
- [ ] Implementar banco multi-tenant (Solução 1)
- [ ] Criar landing page básica
- [ ] Configurar GitHub Releases
- [ ] Automatizar email de boas-vindas
- [ ] Criar vídeo tutorial de instalação

---

**Status**: 📋 Documentado - Pronto para execução

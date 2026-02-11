# ⚠️ Build Windows - Limitação de Plataforma

**Data:** 11 de Fevereiro de 2026  
**Status:** ❌ **NÃO PODE BUILDAR WINDOWS NO macOS**

---

## 🚨 Problema Identificado

### Erro ao executar `flutter build windows --release`:

```
"build windows" only supported on Windows hosts.
```

**Motivo:** Flutter **NÃO permite** compilar para Windows em máquinas macOS/Linux.  
**Causa:** O build Windows usa ferramentas nativas do Windows (MSBuild, MSVC, Windows SDK).

---

## 🎯 Soluções Disponíveis

### ✅ **Opção 1: GitHub Actions (RECOMENDADO - GRÁTIS)**

Configurar CI/CD automatizado que builda Windows na nuvem.

**Vantagens:**
- ✅ **100% Grátis** (2000 minutos/mês)
- ✅ Build automático a cada push/tag
- ✅ Publica no GitHub Releases automaticamente
- ✅ Não precisa ter Windows

**Passos:**
1. Criar arquivo `.github/workflows/build-windows.yml`
2. Push para GitHub
3. GitHub Actions builda automaticamente
4. Cria release com executável

**Tempo de setup:** 10 minutos  
**Custo:** R$ 0,00

---

### ✅ **Opção 2: Máquina Virtual Windows**

Usar VM Windows no seu Mac.

**Ferramentas:**
- **Parallels Desktop** (pago - R$ 400/ano)
- **VMware Fusion** (grátis para uso pessoal)
- **VirtualBox** (grátis - mais lento)

**Requisitos:**
- Windows 10/11 ISO
- 20 GB espaço em disco
- 4 GB RAM alocada

**Passos:**
1. Instalar VM
2. Instalar Windows
3. Instalar Flutter no Windows
4. Copiar projeto
5. Build normal

**Tempo de setup:** 2-3 horas  
**Custo:** R$ 0-400/ano

---

### ✅ **Opção 3: PC Windows Físico**

Se você tiver acesso a um PC Windows.

**Passos:**
1. Instalar Flutter no Windows
2. Clonar repositório
3. `flutter build windows --release`
4. Upload do executável

**Tempo de setup:** 30 minutos (se já tiver PC)  
**Custo:** R$ 0,00

---

### ✅ **Opção 4: Serviço em Nuvem**

Usar máquina Windows na nuvem.

**Serviços:**
- **AWS EC2** (Windows Server)
- **Azure VM** (Windows 10/11)
- **Google Cloud** (Windows Server)

**Custo estimado:** R$ 50-200/mês (pode cancelar depois)

---

## 🎯 Recomendação: GitHub Actions

### Por que GitHub Actions é a melhor opção:

1. ✅ **Grátis** - 2000 minutos/mês
2. ✅ **Automatizado** - Build a cada release
3. ✅ **Profissional** - CI/CD completo
4. ✅ **Multi-plataforma** - Windows + macOS simultaneamente
5. ✅ **Sem instalação** - Tudo na nuvem

---

## 📝 Setup GitHub Actions (10 minutos)

### 1. Criar Workflow File

Criar arquivo: `.github/workflows/build-release.yml`

```yaml
name: Build and Release

on:
  push:
    tags:
      - 'v*'  # Dispara em tags v1.0.0, v1.0.1, etc

jobs:
  build-windows:
    runs-on: windows-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.27.3'
          channel: 'stable'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Build Windows
        run: flutter build windows --release
      
      - name: Create ZIP
        run: |
          cd build/windows/x64/runner/Release
          Compress-Archive -Path * -DestinationPath ../../../../../sushigen-windows.zip
      
      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: windows-build
          path: sushigen-windows.zip
  
  build-macos:
    runs-on: macos-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.27.3'
          channel: 'stable'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Build macOS
        run: flutter build macos --release
      
      - name: Create DMG
        run: ./create_dmg.sh
      
      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: macos-build
          path: SushiGen_v*.dmg
  
  release:
    needs: [build-windows, build-macos]
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Download Windows build
        uses: actions/download-artifact@v4
        with:
          name: windows-build
      
      - name: Download macOS build
        uses: actions/download-artifact@v4
        with:
          name: macos-build
      
      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          files: |
            sushigen-windows.zip
            *.dmg
          body: |
            ## 🍣 SushiGen Release ${{ github.ref_name }}
            
            ### Downloads disponíveis:
            - **Windows**: sushigen-windows.zip
            - **macOS**: SushiGen_v*.dmg
            
            ### Instruções de instalação:
            Ver README.md
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### 2. Fazer Push do Workflow

```bash
git add .github/workflows/build-release.yml
git commit -m "ci: Adiciona GitHub Actions para build automático"
git push origin develop
git push origin main
```

### 3. Criar Tag para Disparar Build

```bash
git tag -a v1.0.2 -m "SushiGen v1.0.2 - Build automático Windows + macOS"
git push origin v1.0.2
```

### 4. Aguardar Build

- Acessar: https://github.com/dimmesheldon/sushigen/actions
- Aguardar build (5-10 minutos)
- Release criado automaticamente com executáveis

---

## ⏱️ Comparação de Tempo

| Opção | Setup | Build | Total |
|-------|-------|-------|-------|
| **GitHub Actions** | 10 min | 5-10 min | **15-20 min** |
| Máquina Virtual | 2-3 horas | 5 min | 2-3 horas |
| PC Windows | 30 min | 5 min | 35 min |
| Nuvem paga | 30 min | 5 min | 35 min |

---

## 💰 Comparação de Custo

| Opção | Custo Mensal | Custo Anual |
|-------|--------------|-------------|
| **GitHub Actions** | **R$ 0** | **R$ 0** |
| Parallels Desktop | R$ 33 | R$ 400 |
| VMware Fusion | R$ 0 | R$ 0 |
| VirtualBox | R$ 0 | R$ 0 |
| PC Windows | R$ 0 | R$ 0 |
| AWS EC2 t3.medium | R$ 150 | R$ 1.800 |

---

## 🎯 Decisão

### Quer que eu configure o GitHub Actions agora?

**Vantagens:**
- ✅ Grátis
- ✅ Rápido (10 min)
- ✅ Automatizado
- ✅ Profissional
- ✅ Builds Windows + macOS simultaneamente

**Resultado:**
→ Fazer push  
→ Criar tag v1.0.2  
→ GitHub builda automaticamente  
→ Release criado com Windows + macOS  

---

## 📋 Alternativa Manual (Se tiver PC Windows)

Se você tiver um PC Windows disponível:

```bash
# No PC Windows:
git clone https://github.com/dimmesheldon/sushigen.git
cd sushigen
flutter pub get
flutter build windows --release

# Criar ZIP:
cd build/windows/x64/runner/Release
Compress-Archive -Path * -DestinationPath sushigen-windows.zip

# Upload manual no GitHub Releases
```

---

## ❓ O que você prefere?

1. **GitHub Actions** (recomendado - grátis e automático)
2. **Máquina Virtual** (se quiser controle total)
3. **PC Windows** (se tiver disponível)
4. **Aguardar** (buildar Windows depois)

**Qual opção você escolhe?** 🎯

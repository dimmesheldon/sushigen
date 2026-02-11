# 🚀 Guia Completo: GitHub Releases para SushiGen

## 📋 CHECKLIST RÁPIDO

### Quando o build terminar:
- [ ] 1. Criar DMG: `./create_dmg.sh`
- [ ] 2. Testar DMG localmente
- [ ] 3. Criar release no GitHub
- [ ] 4. Fazer commit e push
- [ ] 5. Atualizar landing page com link

---

## 🎯 PASSO A PASSO COMPLETO

### Etapa 1: Aguardar Build ⏳

**Status atual:** Build em progresso...

**Aguarde ver:**
```bash
✓ Built build/macos/Build/Products/Release/sushigen.app
```

---

### Etapa 2: Criar o DMG 💿

```bash
./create_dmg.sh
```

**Saída esperada:**
```
✅ INSTALADOR CRIADO COM SUCESSO!
📦 Arquivo: SushiGen_v1.0.1_macOS.dmg
📏 Tamanho: 52M (ou similar)
```

**Verificar tamanho:**
```bash
ls -lh SushiGen_v1.0.1_macOS.dmg
```

✅ Deve ter **50-80 MB** (se tiver apenas 20K, algo deu errado)

---

### Etapa 3: Testar o DMG Localmente 🧪

```bash
# Abrir DMG
open SushiGen_v1.0.1_macOS.dmg

# Verificar conteúdo
# Deve mostrar: sushigen.app + Applications (atalho)

# Testar instalação
# Arrastar sushigen.app para Applications
# Abrir /Applications/sushigen.app
```

**Testes:**
- ✅ App abre corretamente?
- ✅ Login funciona?
- ✅ Dashboard carrega?
- ✅ Pode criar venda?

---

### Etapa 4: Preparar Arquivos 📝

#### A. Criar Release Notes

Crie arquivo `RELEASE_NOTES_v1.0.1.md` (ou use existente):

```markdown
# SushiGen v1.0.1 - 11/02/2026

## ✨ Novidades

### PDF de Fluxo de Caixa
- ✅ Nova coluna "Origem" identificando vendas iFood vs Local
- ✅ Badges coloridos: Vermelho (iFood) e Azul (Local)
- ✅ Fontes otimizadas (~21% redução) para melhor aproveitamento
- ✅ +66% mais dados por página

### Dashboard
- ✅ Botões de Ações Rápidas otimizados
- ✅ Largura máxima de 700px em telas grandes
- ✅ Layout responsivo e proporcional
- ✅ Ícones reduzidos para melhor equilíbrio

### Multi-tenant
- ✅ Isolamento completo de dados entre clientes
- ✅ Estrutura de subcoleções no Firebase
- ✅ Login por customer_id
- ✅ Sincronização segura

## 🐛 Correções
- ✅ Corrigido isolamento de dados multi-tenant
- ✅ Corrigido sincronização Firebase
- ✅ Corrigido menu Fluxo de Caixa
- ✅ Corrigido geração de PDF (sandbox-compliant)

## 📦 Download

### macOS
- **Arquivo:** SushiGen_v1.0.1_macOS.dmg
- **Tamanho:** ~52 MB
- **Requisitos:** macOS 10.15 (Catalina) ou superior
- **Suporte:** Intel e Apple Silicon (M1/M2/M3)

### Instalação
1. Baixe o arquivo DMG
2. Clique duplo para abrir
3. Arraste SushiGen para a pasta Applications
4. Abra o aplicativo

### Primeira execução
Se aparecer aviso de segurança:
1. Vá em **Preferências do Sistema**
2. **Segurança e Privacidade**
3. Clique em **"Abrir mesmo assim"**

## 🔄 Atualizando da v1.0.0
Simplesmente instale a nova versão. Seus dados serão preservados.

## 📖 Documentação
- [README.md](../README.md)
- [Guia de Distribuição](../GUIA_DISTRIBUICAO_MACOS.md)
- [Sistema de Licenciamento](../SISTEMA_LICENCIAMENTO.md)

## 🆘 Suporte
- **Issues:** https://github.com/dimmesheldon/sushigen/issues
- **Email:** suporte@sushigen.com (se tiver)
- **Documentação:** https://github.com/dimmesheldon/sushigen

---

**Checksums:**
- SHA-256: `shasum -a 256 SushiGen_v1.0.1_macOS.dmg`

**Assinado:** Não (v1.0.1)  
**Notarizado:** Não (v1.0.1)

*Nota: Versões futuras incluirão assinatura de código e notarização Apple.*
```

---

### Etapa 5: Commit dos Arquivos 💾

```bash
# Adicionar tudo
git add -A

# Commit
git commit -m "release: v1.0.1 - DMG e documentação de distribuição

- Criado instalador DMG para macOS
- Adicionada documentação completa de distribuição
- Configurado GitHub Releases
- Otimizações PDF e Dashboard incluídas"

# Push
git push origin develop
```

---

### Etapa 6: Merge na Main 🔀

```bash
# Mudar para main
git checkout main

# Merge develop
git merge develop --no-ff -m "Merge v1.0.1: Release com instalador macOS"

# Push main
git push origin main

# Voltar para develop
git checkout develop
```

---

### Etapa 7: Criar Tag de Release 🏷️

```bash
# Criar tag anotada
git tag -a v1.0.1 -m "SushiGen v1.0.1 - Instalador macOS + Otimizações"

# Push tag
git push origin v1.0.1
```

---

### Etapa 8: Criar Release no GitHub 🎉

#### Opção A: Via GitHub CLI (Recomendado)

```bash
# Instalar GitHub CLI (se não tiver)
brew install gh

# Login (primeira vez)
gh auth login

# Criar release
gh release create v1.0.1 \
  SushiGen_v1.0.1_macOS.dmg \
  --title "SushiGen v1.0.1 para macOS" \
  --notes-file RELEASE_NOTES_v1.0.1.md \
  --target main
```

**Pronto!** 🎊

#### Opção B: Via Interface Web

1. **Acesse:** https://github.com/dimmesheldon/sushigen/releases/new

2. **Preencha:**
   - **Tag version:** v1.0.1
   - **Target:** main
   - **Release title:** SushiGen v1.0.1 para macOS
   - **Description:** Cole o conteúdo do RELEASE_NOTES_v1.0.1.md

3. **Upload:**
   - Clique em "Attach binaries"
   - Selecione `SushiGen_v1.0.1_macOS.dmg`
   - Aguarde upload (pode levar 1-2 minutos)

4. **Publicar:**
   - ✅ Marque "Set as the latest release"
   - Clique em "Publish release"

---

### Etapa 9: Obter Link de Download 🔗

Após criar o release, seu link será:

```
https://github.com/dimmesheldon/sushigen/releases/download/v1.0.1/SushiGen_v1.0.1_macOS.dmg
```

**Ou link para última versão (sempre):**
```
https://github.com/dimmesheldon/sushigen/releases/latest/download/SushiGen_v1.0.1_macOS.dmg
```

---

### Etapa 10: Atualizar Landing Page 🌐

#### HTML Simples:

```html
<!-- Botão de Download -->
<div class="download-section">
  <h2>Baixar SushiGen</h2>
  <a href="https://github.com/dimmesheldon/sushigen/releases/download/v1.0.1/SushiGen_v1.0.1_macOS.dmg" 
     class="btn-download">
    <i class="fab fa-apple"></i>
    Baixar para macOS
    <span class="version">v1.0.1 • 52 MB</span>
  </a>
  <p class="requirements">
    Requer macOS 10.15 ou superior
  </p>
</div>
```

#### Com JavaScript (Versão Dinâmica):

```html
<div class="download-section">
  <h2>Baixar SushiGen</h2>
  <a href="#" id="download-link" class="btn-download">
    <i class="fab fa-apple"></i>
    Baixar para macOS
    <span id="version-info">Carregando...</span>
  </a>
  <p class="requirements">
    Requer macOS 10.15 ou superior
  </p>
</div>

<script>
// Buscar última versão automaticamente
fetch('https://api.github.com/repos/dimmesheldon/sushigen/releases/latest')
  .then(response => response.json())
  .then(data => {
    const version = data.tag_name;
    const asset = data.assets[0];
    const size = (asset.size / 1024 / 1024).toFixed(0); // MB
    const downloads = asset.download_count;
    
    // Atualizar link
    document.getElementById('download-link').href = asset.browser_download_url;
    
    // Atualizar info
    document.getElementById('version-info').textContent = 
      `${version} • ${size} MB • ${downloads} downloads`;
  })
  .catch(error => {
    console.error('Erro ao buscar release:', error);
    document.getElementById('version-info').textContent = 'v1.0.1 • 52 MB';
  });
</script>
```

#### Badges:

```markdown
[![GitHub release](https://img.shields.io/github/v/release/dimmesheldon/sushigen)](https://github.com/dimmesheldon/sushigen/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/dimmesheldon/sushigen/total)](https://github.com/dimmesheldon/sushigen/releases)
[![License](https://img.shields.io/badge/license-Proprietário-blue)](LICENSE.md)
```

---

## 🎨 EXTRAS OPCIONAIS

### 1. Adicionar Screenshots

```bash
# Tirar screenshots do app
# macOS: Cmd + Shift + 4

# Upload no release
gh release upload v1.0.1 screenshots/*.png
```

### 2. Adicionar Checksum

```bash
# Gerar SHA-256
shasum -a 256 SushiGen_v1.0.1_macOS.dmg > SushiGen_v1.0.1_macOS.dmg.sha256

# Upload
gh release upload v1.0.1 SushiGen_v1.0.1_macOS.dmg.sha256
```

### 3. Criar Changelog Automático

```bash
# Gerar changelog desde última tag
git log v1.0.0..v1.0.1 --pretty=format:"- %s" > CHANGELOG.md

# Editar e adicionar ao release
```

---

## 📊 VERIFICAR SUCESSO

### Após criar o release:

1. **Acesse:** https://github.com/dimmesheldon/sushigen/releases

2. **Verifique:**
   - ✅ Release v1.0.1 visível
   - ✅ DMG disponível para download
   - ✅ Release notes formatadas
   - ✅ Contador de downloads em 0

3. **Teste o download:**
   ```bash
   # Em outro diretório
   cd ~/Downloads
   curl -L -O https://github.com/dimmesheldon/sushigen/releases/download/v1.0.1/SushiGen_v1.0.1_macOS.dmg
   open SushiGen_v1.0.1_macOS.dmg
   ```

4. **Verifique analytics:**
   - Downloads devem incrementar
   - API deve retornar dados corretos

---

## 🔄 PRÓXIMAS RELEASES

### Para v1.0.2 (futura):

```bash
# 1. Fazer alterações no código
# 2. Atualizar version no pubspec.yaml: 1.0.2+3
# 3. Build
flutter build macos --release

# 4. Criar DMG
./create_dmg.sh  # Vai criar SushiGen_v1.0.2_macOS.dmg

# 5. Commit e push
git add -A
git commit -m "release: v1.0.2"
git push

# 6. Merge e tag
git checkout main
git merge develop
git tag -a v1.0.2 -m "SushiGen v1.0.2"
git push origin main v1.0.2

# 7. Criar release
gh release create v1.0.2 \
  SushiGen_v1.0.2_macOS.dmg \
  --title "SushiGen v1.0.2" \
  --notes "Release notes da v1.0.2"
```

---

## 🆘 PROBLEMAS COMUNS

### "gh: command not found"
```bash
# Instalar GitHub CLI
brew install gh

# Login
gh auth login
```

### "Permission denied"
```bash
# Fazer login novamente
gh auth logout
gh auth login
```

### "Release já existe"
```bash
# Deletar release
gh release delete v1.0.1 --yes

# Deletar tag
git tag -d v1.0.1
git push origin :refs/tags/v1.0.1

# Criar novamente
```

### "Upload falhou"
```bash
# Tentar via web interface
# Ou fazer upload manual depois:
gh release upload v1.0.1 SushiGen_v1.0.1_macOS.dmg
```

---

## ✅ CHECKLIST FINAL

Antes de considerar concluído:

- [ ] Build completado com sucesso
- [ ] DMG criado (50-80 MB)
- [ ] DMG testado localmente
- [ ] Commit e push feitos
- [ ] Merge na main
- [ ] Tag v1.0.1 criada
- [ ] Release publicado no GitHub
- [ ] Link de download funciona
- [ ] Landing page atualizada
- [ ] Release notes claras
- [ ] Screenshots adicionadas (opcional)

---

## 🎉 PRONTO!

Seu instalador está disponível em:
```
https://github.com/dimmesheldon/sushigen/releases/tag/v1.0.1
```

Link direto de download:
```
https://github.com/dimmesheldon/sushigen/releases/download/v1.0.1/SushiGen_v1.0.1_macOS.dmg
```

**Agora é só divulgar! 🚀**

---

**Data:** 11/02/2026  
**Versão:** 1.0.1  
**Método:** GitHub Releases  
**Status:** ✅ Guia completo

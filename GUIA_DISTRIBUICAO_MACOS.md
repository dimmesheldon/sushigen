# 📦 Guia de Distribuição - SushiGen para macOS

## 🎯 Objetivo
Este guia descreve como criar um instalador DMG profissional do SushiGen para distribuição em macOS.

---

## 📋 Pré-requisitos

### 1. Ferramentas Necessárias
- ✅ Flutter SDK instalado
- ✅ Xcode instalado (última versão)
- ✅ Conta Apple Developer (para assinatura de código)
- ✅ Certificado de desenvolvedor macOS

### 2. Verificar Ambiente
```bash
# Verificar Flutter
flutter --version

# Verificar Xcode
xcodebuild -version

# Verificar certificados (opcional para testes)
security find-identity -v -p codesigning
```

---

## 🚀 Processo de Build e Distribuição

### Etapa 1: Limpar Build Anterior
```bash
flutter clean
```

### Etapa 2: Gerar Build de Produção
```bash
flutter build macos --release
```

**Tempo estimado**: 2-5 minutos

**Saída esperada**:
```
✓ Built build/macos/Build/Products/Release/SushiGen.app
```

### Etapa 3: Verificar Build
```bash
ls -la build/macos/Build/Products/Release/
```

Você deve ver:
- `SushiGen.app` (diretório do aplicativo)

### Etapa 4: Testar Localmente
```bash
open build/macos/Build/Products/Release/SushiGen.app
```

---

## 💿 Criando o DMG Instalador

### Opção 1: Script Automático (Recomendado)

#### Executar o script:
```bash
./create_dmg.sh
```

#### O que o script faz:
1. ✅ Verifica se o build existe
2. ✅ Limpa builds anteriores
3. ✅ Cria estrutura temporária
4. ✅ Copia o aplicativo
5. ✅ Cria link para /Applications
6. ✅ Gera DMG temporário
7. ✅ Customiza aparência
8. ✅ Comprime DMG final
9. ✅ Limpa arquivos temporários

#### Saída esperada:
```
✅ INSTALADOR CRIADO COM SUCESSO!
📦 Arquivo: SushiGen_v1.0.1_macOS.dmg
📏 Tamanho: ~50MB
📍 Local: /caminho/para/projeto/SushiGen_v1.0.1_macOS.dmg
```

---

### Opção 2: Manual (Passo a Passo)

#### 1. Criar estrutura:
```bash
mkdir temp_dmg
cp -R build/macos/Build/Products/Release/SushiGen.app temp_dmg/
ln -s /Applications temp_dmg/Applications
```

#### 2. Criar DMG temporário:
```bash
hdiutil create -volname "SushiGen" \
    -srcfolder temp_dmg \
    -ov -format UDRW \
    temp_SushiGen.dmg
```

#### 3. Montar e customizar:
```bash
hdiutil attach -readwrite -noverify -noautoopen temp_SushiGen.dmg
```

#### 4. Desmontar:
```bash
hdiutil detach /Volumes/SushiGen
```

#### 5. Converter para formato final:
```bash
hdiutil convert temp_SushiGen.dmg \
    -format UDZO \
    -o SushiGen_v1.0.1_macOS.dmg
```

#### 6. Limpar:
```bash
rm -rf temp_dmg temp_SushiGen.dmg
```

---

## 🔐 Assinatura de Código (Opcional mas Recomendado)

### Por que assinar?
- ✅ Evita avisos de segurança do macOS
- ✅ Permite distribuição sem Gatekeeper bloqueando
- ✅ Passa por notarização da Apple
- ✅ Profissionalismo e confiança

### Como assinar:

#### 1. Verificar certificados:
```bash
security find-identity -v -p codesigning
```

#### 2. Assinar o app:
```bash
codesign --force --deep --sign "Developer ID Application: Seu Nome" \
    build/macos/Build/Products/Release/SushiGen.app
```

#### 3. Verificar assinatura:
```bash
codesign -dv --verbose=4 build/macos/Build/Products/Release/SushiGen.app
```

#### 4. Assinar o DMG:
```bash
codesign --force --sign "Developer ID Application: Seu Nome" \
    SushiGen_v1.0.1_macOS.dmg
```

---

## 📝 Notarização Apple (Para Distribuição Pública)

### Requisitos:
- Conta Apple Developer paga
- Aplicativo assinado
- Xcode Command Line Tools

### Processo:

#### 1. Criar arquivo zip do app:
```bash
ditto -c -k --keepParent \
    build/macos/Build/Products/Release/SushiGen.app \
    SushiGen.zip
```

#### 2. Enviar para notarização:
```bash
xcrun notarytool submit SushiGen.zip \
    --apple-id "seu@email.com" \
    --team-id "TEAM_ID" \
    --password "app-specific-password" \
    --wait
```

#### 3. Verificar status:
```bash
xcrun notarytool info <submission-id> \
    --apple-id "seu@email.com" \
    --team-id "TEAM_ID" \
    --password "app-specific-password"
```

#### 4. Anexar ticket (stapling):
```bash
xcrun stapler staple build/macos/Build/Products/Release/SushiGen.app
```

---

## 🧪 Testando o Instalador

### 1. Abrir DMG:
```bash
open SushiGen_v1.0.1_macOS.dmg
```

### 2. Verificar conteúdo:
- ✅ Ícone SushiGen.app visível
- ✅ Atalho para Applications visível
- ✅ Layout limpo e profissional

### 3. Instalar:
- Arraste SushiGen.app para Applications
- Aguarde cópia concluir

### 4. Executar:
- Abra Applications
- Clique em SushiGen
- Se não assinado: Sistema > Preferências > Segurança > "Abrir mesmo assim"

---

## 📊 Estrutura do DMG

```
SushiGen.dmg (montado como /Volumes/SushiGen)
├── SushiGen.app         (aplicativo principal)
└── Applications@        (atalho para /Applications)
```

### Experiência do usuário:
1. Usuário abre o DMG
2. Vê janela com:
   - Ícone SushiGen.app à esquerda
   - Ícone Applications à direita
3. Arrasta SushiGen.app para Applications
4. Instalação concluída!

---

## 📦 Tamanhos Esperados

### Build não comprimido:
- **SushiGen.app**: ~80-100 MB

### DMG final:
- **Comprimido**: ~40-60 MB
- **Descomprimido ao montar**: ~80-100 MB

---

## 🚨 Problemas Comuns e Soluções

### 1. "SushiGen.app está danificado"
**Causa**: Aplicativo não assinado

**Solução**:
```bash
xattr -cr build/macos/Build/Products/Release/SushiGen.app
```

### 2. "Não é possível abrir porque é de um desenvolvedor não identificado"
**Causa**: Gatekeeper bloqueando app não assinado

**Solução 1** (temporária):
```bash
sudo spctl --master-disable
```

**Solução 2** (recomendada):
- Sistema > Segurança > "Abrir mesmo assim"

**Solução 3** (definitiva):
- Assinar o aplicativo com certificado Developer ID

### 3. Build falha
**Causa**: Dependências desatualizadas

**Solução**:
```bash
flutter pub get
flutter clean
flutter build macos --release
```

### 4. DMG não abre
**Causa**: Arquivo corrompido

**Solução**:
```bash
rm SushiGen_v1.0.1_macOS.dmg
./create_dmg.sh
```

---

## 🎨 Customização do DMG

### Adicionar imagem de fundo:

1. Criar imagem PNG (600x400px)
2. Montar DMG em modo de edição
3. Copiar imagem para DMG
4. Configurar via Finder:
   - Ver > Mostrar Opções de Visualização
   - Plano de Fundo > Imagem

### Posicionar ícones:

Editar script `create_dmg.sh`:
```applescript
set position of item "SushiGen.app" to {150, 200}
set position of item "Applications" to {450, 200}
```

---

## 📢 Distribuição

### Opções de distribuição:

#### 1. Download direto:
- Upload para servidor web
- Compartilhar link direto
- Usuário baixa e instala

#### 2. GitHub Releases:
```bash
# Criar release
gh release create v1.0.1 \
    SushiGen_v1.0.1_macOS.dmg \
    --title "SushiGen v1.0.1" \
    --notes "Release notes aqui"
```

#### 3. Mac App Store:
- Requer conta Apple Developer ($99/ano)
- Processo de review (1-3 dias)
- Distribuição automática
- Atualizações gerenciadas

#### 4. Distribuição interna:
- Email
- Drive compartilhado
- Servidor interno

---

## 📝 Checklist de Distribuição

### Antes de distribuir:

- [ ] Build em modo release
- [ ] Versão atualizada no pubspec.yaml
- [ ] Ícone do app configurado
- [ ] Testado em macOS limpo
- [ ] Sem dados de desenvolvimento
- [ ] Release notes escritas
- [ ] Screenshots preparados
- [ ] Documentação atualizada

### Opcional (profissional):

- [ ] Código assinado
- [ ] App notarizado
- [ ] Instalador customizado
- [ ] Suporte a múltiplas línguas
- [ ] Analytics configurado
- [ ] Sistema de atualizações

---

## 🔄 Atualizações Futuras

### Versionamento:
- **Patch**: 1.0.1 → 1.0.2 (correções)
- **Minor**: 1.0.x → 1.1.0 (features)
- **Major**: 1.x.x → 2.0.0 (breaking changes)

### Processo de atualização:
1. Atualizar `version` em pubspec.yaml
2. Criar build novo
3. Gerar DMG novo
4. Distribuir
5. Notificar usuários

---

## 📊 Métricas de Sucesso

### Monitorar:
- Número de downloads
- Taxa de instalação
- Crashes reportados
- Feedback dos usuários
- Tempo de uso
- Features mais usadas

---

## 🆘 Suporte

### Recursos:
- 📖 Documentação: README.md
- 🐛 Issues: GitHub Issues
- 💬 Suporte: Email/Chat
- 🎥 Tutorial: Vídeos

---

## ✅ Conclusão

Seguindo este guia, você tem:
- ✅ Build de produção criado
- ✅ DMG instalador profissional
- ✅ Aplicativo testado
- ✅ Pronto para distribuição

**Versão atual**: SushiGen v1.0.1
**Data**: 11/02/2026
**Status**: ✅ Pronto para distribuição

---

## 🚀 Próximos Passos

1. Execute: `./create_dmg.sh`
2. Teste: Abra o DMG e instale
3. Valide: Execute o aplicativo
4. Distribua: Compartilhe com usuários

**Boa sorte com a distribuição do SushiGen! 🍣**

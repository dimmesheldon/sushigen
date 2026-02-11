#!/bin/bash

# Script para criar DMG instalador do SushiGen para macOS
# Autor: SushiGen Team
# Data: 11/02/2026

set -e

echo "🍣 SushiGen - Criador de Instalador macOS"
echo "=========================================="
echo ""

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configurações
APP_NAME="SushiGen"
APP_NAME_LOWER="sushigen"  # Nome real do .app (minúsculo)
VERSION="1.0.1"
BUILD_DIR="build/macos/Build/Products/Release"
APP_PATH="${BUILD_DIR}/${APP_NAME_LOWER}.app"
DMG_NAME="${APP_NAME}_v${VERSION}_macOS"
TEMP_DIR="temp_dmg"
FINAL_DMG="${DMG_NAME}.dmg"

echo -e "${BLUE}📦 Verificando build...${NC}"
if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}❌ Build não encontrado em: $APP_PATH${NC}"
    echo -e "${YELLOW}Execute primeiro: flutter build macos --release${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Build encontrado!${NC}"
echo ""

# Limpar builds anteriores
echo -e "${BLUE}🧹 Limpando builds anteriores...${NC}"
rm -rf "$TEMP_DIR" 2>/dev/null || true
rm -f "$FINAL_DMG" 2>/dev/null || true
echo -e "${GREEN}✅ Limpeza concluída!${NC}"
echo ""

# Criar diretório temporário
echo -e "${BLUE}📁 Criando estrutura temporária...${NC}"
mkdir -p "$TEMP_DIR"
echo -e "${GREEN}✅ Diretório criado!${NC}"
echo ""

# Copiar aplicativo
echo -e "${BLUE}📋 Copiando aplicativo...${NC}"
cp -R "$APP_PATH" "$TEMP_DIR/"
echo -e "${GREEN}✅ Aplicativo copiado!${NC}"
echo ""

# Criar link simbólico para /Applications
echo -e "${BLUE}🔗 Criando atalho para Aplicativos...${NC}"
ln -s /Applications "$TEMP_DIR/Applications"
echo -e "${GREEN}✅ Atalho criado!${NC}"
echo ""

# Criar DMG temporário
echo -e "${BLUE}💿 Criando imagem DMG temporária...${NC}"
TEMP_DMG="temp_${DMG_NAME}.dmg"
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$TEMP_DIR" \
    -ov -format UDRW \
    "$TEMP_DMG"
echo -e "${GREEN}✅ DMG temporário criado!${NC}"
echo ""

# Montar DMG
echo -e "${BLUE}🔧 Montando DMG para customização...${NC}"
DEVICE=$(hdiutil attach -readwrite -noverify -noautoopen "$TEMP_DMG" | \
    egrep '^/dev/' | sed 1q | awk '{print $1}')
echo -e "${GREEN}✅ DMG montado em: $DEVICE${NC}"
echo ""

# Aguardar montagem
sleep 2

# Obter ponto de montagem
MOUNT_POINT="/Volumes/$APP_NAME"

# Customizar aparência (opcional - requer AppleScript)
echo -e "${BLUE}🎨 Customizando aparência...${NC}"
if [ -d "$MOUNT_POINT" ]; then
    # Definir tamanho e posição da janela
    echo '
    tell application "Finder"
        tell disk "'$APP_NAME'"
            open
            set current view of container window to icon view
            set toolbar visible of container window to false
            set statusbar visible of container window to false
            set the bounds of container window to {100, 100, 700, 500}
            set viewOptions to the icon view options of container window
            set arrangement of viewOptions to not arranged
            set icon size of viewOptions to 128
            set position of item "'$APP_NAME_LOWER'.app" of container window to {150, 200}
            set position of item "Applications" of container window to {450, 200}
            close
            open
            update without registering applications
            delay 2
        end tell
    end tell
    ' | osascript || echo -e "${YELLOW}⚠️  Customização visual falhou (opcional)${NC}"
fi
echo -e "${GREEN}✅ Customização concluída!${NC}"
echo ""

# Desmontar
echo -e "${BLUE}💾 Finalizando DMG...${NC}"
hdiutil detach "$DEVICE"
sleep 2
echo -e "${GREEN}✅ DMG desmontado!${NC}"
echo ""

# Converter para DMG final (comprimido e somente leitura)
echo -e "${BLUE}🗜️  Comprimindo DMG final...${NC}"
hdiutil convert "$TEMP_DMG" \
    -format UDZO \
    -o "$FINAL_DMG"
echo -e "${GREEN}✅ DMG comprimido!${NC}"
echo ""

# Limpar temporários
echo -e "${BLUE}🧹 Limpando arquivos temporários...${NC}"
rm -rf "$TEMP_DIR"
rm -f "$TEMP_DMG"
echo -e "${GREEN}✅ Limpeza concluída!${NC}"
echo ""

# Informações finais
DMG_SIZE=$(du -h "$FINAL_DMG" | cut -f1)
echo ""
echo "=========================================="
echo -e "${GREEN}✅ INSTALADOR CRIADO COM SUCESSO!${NC}"
echo "=========================================="
echo ""
echo -e "${BLUE}📦 Arquivo:${NC} $FINAL_DMG"
echo -e "${BLUE}📏 Tamanho:${NC} $DMG_SIZE"
echo -e "${BLUE}📍 Local:${NC} $(pwd)/$FINAL_DMG"
echo ""
echo -e "${YELLOW}📋 PRÓXIMOS PASSOS:${NC}"
echo "1. Teste o instalador: Clique duplo em $FINAL_DMG"
echo "2. Arraste SushiGen.app para a pasta Applications"
echo "3. Abra o aplicativo pela primeira vez"
echo "4. Se necessário, vá em Preferências > Segurança e Privacidade"
echo ""
echo -e "${GREEN}🍣 SushiGen pronto para distribuição!${NC}"
echo ""

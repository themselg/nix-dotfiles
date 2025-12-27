#!/usr/bin/env bash

GITHUB_USER="themselg"
REPO_NAME="nix-dotfiles"
BRANCH="main" 
FILE_URL="https://raw.githubusercontent.com/$GITHUB_USER/$REPO_NAME/$BRANCH/configuration.nix"
LOCAL_DIR="$HOME/.dotfiles"
DEST_FILE="/etc/nixos/configuration.nix"
TARGET_HOSTNAME="asus"

# getopts procesa los argumentos (-l)
while getopts "l" opt; do
  case $opt in
    l)
      TARGET_HOSTNAME="thinkpad"
      echo "Hostname será: $TARGET_HOSTNAME"
      ;;
    \?)
      echo "Opción inválida: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}[1/5] Preparando directorio local...${NC}"
mkdir -p "$LOCAL_DIR"

echo -e "${GREEN}[2/5] Descargando configuration.nix...${NC}"
rm -f $LOCAL_DIR/configuration.nix
if curl -f -L "$FILE_URL" -o "$LOCAL_DIR/configuration.nix"; then
    echo "Descarga exitosa."
else
    echo "Error descargando el archivo."
    exit 1
fi

echo -e "${GREEN}[3/5] Configurando Hostname: ${BLUE}$TARGET_HOSTNAME${NC}..."
sed -i "s/networking.hostName = \".*\";/networking.hostName = \"$TARGET_HOSTNAME\";/" "$LOCAL_DIR/configuration.nix"

echo -e "${GREEN}[4/5] Instalando en /etc/nixos...${NC}"
if [ -f "$DEST_FILE" ]; then
    sudo cp "$DEST_FILE" "$DEST_FILE.bak"
fi
sudo cp "$LOCAL_DIR/configuration.nix" "$DEST_FILE"

echo -e "${GREEN}[5/5] Reconstruyendo sistema (boot)...${NC}"
sudo nixos-rebuild switch

echo -e "${GREEN}Reinicia para ver los cambios.${NC}"

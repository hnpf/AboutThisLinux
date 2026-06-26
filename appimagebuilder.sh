#!/usr/bin/env bash
set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

APP_DIR="AboutThisLinux.AppDir"

echo -e "${BLUE}building AboutThisLinux appimage...${NC}"

# remove old build
echo -e "${YELLOW}cleaning up...${NC}"
rm -rf "$APP_DIR" AboutThisLinux-x86_64.AppImage

# scaffold
echo -e "${YELLOW}setting up AppDir...${NC}"
mkdir -p "$APP_DIR"/{usr/bin,usr/share/applications,usr/share/icons/hicolor/scalable/apps}

# drop in files
echo -e "${YELLOW}copying files...${NC}"
cp about.py macpro.png "$APP_DIR/usr/bin/"
chmod +x "$APP_DIR/usr/bin/about.py"
cp x-office-presentation.svg "$APP_DIR/about-this-linux.svg"
cp x-office-presentation.svg "$APP_DIR/usr/share/icons/hicolor/scalable/apps/about-this-linux.svg"

# entrypoint, uses host python3 so gtk4/pyobject bindings don't break
echo -e "${YELLOW}writing AppRun...${NC}"
cat << 'EOF' > "$APP_DIR/AppRun"
#!/bin/sh
HERE=${0%/*}
export PATH="${HERE}/usr/bin/:${PATH}"
exec python3 "${HERE}/usr/bin/about.py" "$@"
EOF
chmod +x "$APP_DIR/AppRun"

# add desktop entry
echo -e "${YELLOW}writing .desktop...${NC}"
cat << EOF > "$APP_DIR/about-this-linux.desktop"
[Desktop Entry]
Type=Application
Name=About This Linux
Comment=Your own computer, but make it look scarily close to macOS.
Exec=about.py
Icon=about-this-linux
Categories=System;Utility;Settings;
Terminal=false
StartupNotify=true
EOF
cp "$APP_DIR/about-this-linux.desktop" "$APP_DIR/usr/share/applications/"

# get appimagetool if missing
if [ ! -f appimagetool-x86_64.AppImage ]; then
  echo -e "${YELLOW}fetching appimagetool...${NC}"
  curl -sSL -o appimagetool-x86_64.AppImage \
    https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
  chmod +x appimagetool-x86_64.AppImage
fi

# build it!
echo -e "${GREEN}packaging...${NC}"
export ARCH=x86_64
./appimagetool-x86_64.AppImage "$APP_DIR" AboutThisLinux-x86_64.AppImage

echo -e "\n${GREEN}finished! run it with: ${BLUE}./AboutThisLinux-x86_64.AppImage${NC}"
#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# Formatting colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=======================================${NC}"
echo -e "${BLUE}    AboutThisLinux AppImage Builder    ${NC}"
echo -e "${BLUE}=======================================${NC}"

APP_DIR="AboutThisLinux.AppDir"

# Cleanup previous builds
echo -e "${YELLOW}Cleaning up old build files...${NC}"
rm -rf "$APP_DIR"
rm -f AboutThisLinux-x86_64.AppImage

# Create directory structure
echo -e "${YELLOW}Creating AppDir structure...${NC}"
mkdir -p "$APP_DIR/usr/bin"
mkdir -p "$APP_DIR/usr/share/applications"
mkdir -p "$APP_DIR/usr/share/icons/hicolor/scalable/apps"

# Copy application files
echo -e "${YELLOW}Copying source files and assets...${NC}"
cp about.py "$APP_DIR/usr/bin/"
cp macpro.png "$APP_DIR/usr/bin/"
chmod +x "$APP_DIR/usr/bin/about.py"

# Copy icon to root and share
cp macpro.png "$APP_DIR/about-this-linux.png"
cp macpro.png "$APP_DIR/usr/share/icons/hicolor/scalable/apps/about-this-linux.png"

# Create the AppRun entrypoint script
echo -e "${YELLOW}Creating AppRun entrypoint...${NC}"
cat << 'EOF' > "$APP_DIR/AppRun"
#!/bin/sh
SELF=$(readlink -f "$0")
HERE=${SELF%/*}

# Set environment variables if needed
export PATH="${HERE}/usr/bin/:${PATH}"

# Execute the python script using host python3
# Since PyGObject/GTK4 require complex binary introspection bindings,
# running via the host's python3 ensures compatibility with host theme settings,
# Wayland/X11 sockets, and OpenGL drivers.
exec python3 "${HERE}/usr/bin/about.py" "$@"
EOF
chmod +x "$APP_DIR/AppRun"

# Create the desktop file in root (required by AppImage) and usr/share/applications/
echo -e "${YELLOW}Creating desktop files...${NC}"
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

# Download appimagetool if not present
if [ ! -f "appimagetool-x86_64.AppImage" ]; then
    echo -e "${YELLOW}Downloading appimagetool...${NC}"
    curl -sSL -L -o appimagetool-x86_64.AppImage https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
    chmod +x appimagetool-x86_64.AppImage
fi

# Build the AppImage
echo -e "${GREEN}Packaging AppImage...${NC}"
# Disable appimagetool's internal checks for container/docker if running in sandbox environments
export ARCH=x86_64
./appimagetool-x86_64.AppImage "$APP_DIR" AboutThisLinux-x86_64.AppImage

echo -e "\n${GREEN}=======================================${NC}"
echo -e "${GREEN}    AppImage Build Completed!          ${NC}"
echo -e "${GREEN}=======================================${NC}"
echo -e "Your AppImage is ready: ${BLUE}AboutThisLinux-x86_64.AppImage${NC}"
echo -e "You can run it using: ${BLUE}./AboutThisLinux-x86_64.AppImage${NC}"

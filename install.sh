#!/usr/bin/env bash

# if a command exits with a non zero status, exit
set -e

# colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' 

echo -e "${BLUE}---------------------------------------${NC}"
echo -e "${BLUE}      AboutThisLinux Installer         ${NC}"
echo -e "${BLUE}---------------------------------------${NC}"



# distro detect
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

DISTRO=$(detect_distro)

# check if dependencies are already there
check_deps() {
    python3 -c "import gi; gi.require_version('Gtk', '4.0'); gi.require_version('Adw', '1'); from gi.repository import Gtk, Adw" &>/dev/null
}

install_deps() {
    echo -e "${YELLOW}checking and installing dependencies...${NC}"
    if check_deps; then
        echo -e "${GREEN}good news, dependencies are already installed!${NC}"
        return 0
    fi

    echo -e "some dependencies (PyGObject, GTK 4, or Libadwaita) are missing."
    if [ -t 0 ]; then
        read -p "would you like to install them now? (Requires sudo) [Y/n] " -r install_choice
    elif [ -c /dev/tty ]; then
        read -p "would you like to install them now? (Requires sudo) [Y/n] " -r install_choice < /dev/tty
    else
        install_choice="Y"
    fi
    install_choice=${install_choice:-Y}
    if [[ "$install_choice" =~ ^[Yy]$ ]]; then
        case "$DISTRO" in
            ubuntu|debian|pop|mint|elementary)
                echo -e "${BLUE}using apt update and installing packages...${NC}"
                sudo apt-get update
                sudo apt-get install -y python3-gi python3-gi-cairo gir1.2-gtk-4.0 gir1.2-adw-1
                ;;
            arch|manjaro|endeavouros)
                echo -e "${BLUE}using pacman to install packages...${NC}"
                sudo pacman -S --needed --noconfirm python-gobject gtk4 libadwaita
                ;;
            fedora|rhel|centos)
                echo -e "${BLUE}using dnf to install packages...${NC}"
                sudo dnf install -y python3-gobject gtk4 libadwaita
                ;;
            *)
                echo -e "${RED}unsupported distro for automatic dependency installation.${NC}"
                echo -e "please install PyGObject, GTK 4, and Libadwaita manually."
                echo -e "for details, see: https://pygobject.readthedocs.io/en/latest/getting_started.html"
                ;;
        esac
    else
        echo -e "${YELLOW}skipping dependency installation. note: the app will likely not run without them.${NC}"
    fi
}

install_deps

# paths
INSTALL_DIR="$HOME/.local/share/about-this-linux"
BIN_DIR="$HOME/.local/bin"
DESKTOP_DIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons/hicolor/scalable/apps"
PIXMAP_DIR="$HOME/.local/share/pixmaps"

echo -e "${YELLOW}creating installation directories...${NC}"
mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"
mkdir -p "$DESKTOP_DIR"
mkdir -p "$ICON_DIR"
mkdir -p "$PIXMAP_DIR"

# copying files
# if run locally, copy files from current dir. if run via curl, download them.
if [ -f "about.py" ] && [ -f "macpro.png" ] && [ -f "x-office-presentation.svg" ]; then
    echo -e "${YELLOW}Installing from local repository...${NC}"
    cp about.py "$INSTALL_DIR/"
    cp macpro.png "$INSTALL_DIR/"
    cp x-office-presentation.svg "$INSTALL_DIR/"
else
    echo -e "${YELLOW}getting latest release files from GitHub...${NC}"
    curl -sSL "https://raw.githubusercontent.com/hnpf/AboutThisLinux/main/about.py" -o "$INSTALL_DIR/about.py"
    curl -sSL "https://raw.githubusercontent.com/hnpf/AboutThisLinux/main/macpro.png" -o "$INSTALL_DIR/macpro.png"
    curl -sSL "https://raw.githubusercontent.com/hnpf/AboutThisLinux/main/x-office-presentation.svg" -o "$INSTALL_DIR/x-office-presentation.svg"
fi

# set exec perms
chmod +x "$INSTALL_DIR/about.py"

# create a bin wrapper in ~/.local/bin/
echo -e "${YELLOW}creating wrapper...${NC}"
cat << 'EOF' > "$BIN_DIR/about-this-linux"
#!/usr/bin/env bash
exec python3 "$HOME/.local/share/about-this-linux/about.py" "$@"
EOF
chmod +x "$BIN_DIR/about-this-linux"

# copy the icon
rm -f "$PIXMAP_DIR/about-this-linux.png"
rm -f "$ICON_DIR/about-this-linux.png"
cp "$INSTALL_DIR/x-office-presentation.svg" "$PIXMAP_DIR/about-this-linux.svg"
cp "$INSTALL_DIR/x-office-presentation.svg" "$ICON_DIR/about-this-linux.svg"

# make a .desktop file
echo -e "${YELLOW}Creating desktop entry...${NC}"
cat << EOF > "$DESKTOP_DIR/about-this-linux.desktop"
[Desktop Entry]
Type=Application
Name=About This Linux
Comment=Your own computer, but make it look scarily close to macOS.
Exec=$BIN_DIR/about-this-linux
Icon=about-this-linux
Categories=System;Utility;Settings;
Terminal=false
StartupNotify=true
EOF

chmod +x "$DESKTOP_DIR/about-this-linux.desktop"

# try and update the desktop database if it even exists
if command -v update-desktop-database &>/dev/null; then
    update-desktop-database "$DESKTOP_DIR" &>/dev/null || true
fi



echo -e "\n${GREEN}=======================================${NC}"
echo -e "${GREEN}    installation finished successfully!  ${NC}"
echo -e "${GREEN}=======================================${NC}"
echo -e "\nyou can run the application by typing: ${BLUE}about-this-linux${NC} in your terminal,"
echo -e "or, you can look for ${BLUE}About This Linux${NC} in your system's application launcher/menu."
echo -e "\n${YELLOW}note:${NC} make sure ${BLUE}\$HOME/.local/bin${NC} is in your shell's ${BLUE}\$PATH${NC}."
echo -e "if it isn't, add it by appending this line to your ~/.bashrc or ~/.zshrc:"
echo -e "  export PATH=\"\$HOME/.local/bin:\$PATH\""
echo -e "or, if you're using fish, you can do:"
echo -e "fish_add_path ~/.local/bin"
echo -e "and finally, have fun checking your system specs!"
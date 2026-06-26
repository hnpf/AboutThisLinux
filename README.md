# AboutThisLinux

> your own computer, but make it look scarily close to macOS!

`AboutThisLinux` is a lightweight app using user **GTK 4** and **Libadwaita** and mimics macOS'es "About This Mac" window. it queries your hardware and displays system information in a gorgeous, native style popup.

---

## features

- **macOS style:** made with love using GTK4/Libadwaita to get that "About This Mac" feeling interface.
- **hardware detection:** automatically finds and displays:
  - hostname & BIOS date
  - CPU model, cores, and maximum clock speeds
  - GPU hardware details and vram size (where/if available)
  - System memory (RAM) capacity and speed (DDR frequency)
  - Startup/Root disk mount
  - PCI expansion card count
  - OS distribution name & Kernel info
- **more info panel:** Opens an extra preference panel with additional specifications (Kernel, Shell, Desktop Environment, Window Manager, and Uptime).
- **relocatable and packageable:** ready for local installs and `.AppImage` distributions!

---

## system deps

because the app is built using Python bindings for GNOME libraries, you need to have PyGObject, GTK 4, and Libadwaita installed.

select the command for your Linux distro to install these, or look it up online for your specific distro!:

### Debian / Ubuntu / Pop OS / Linux Mint
```bash
sudo apt update
sudo apt install python3-gi python3-gi-cairo gir1.2-gtk-4.0 gir1.2-adw-1
```

### Arch Linux / Manjaro / EndeavourOS
```bash
sudo pacman -S --needed python-gobject gtk4 libadwaita
```

### Fedora / RHEL
```bash
sudo dnf install python3-gobject gtk4 libadwaita
```

---

## installation

you can also install `AboutThisLinux` quickly using the install script! it sets up the script, assets, desktop entry (so it shows up in your applications menu!), and system icon.

### 1. quick one-liner install (using curl)

run the following command in your terminal to automatically check dependencies and install the app locally:

```bash
curl -sSL https://raw.githubusercontent.com/hnpf/AboutThisLinux/main/install.sh | bash
```

### 2. manual installation

if you wish to install it from a local clone of the repository:

1. Clone the repository:
   ```bash
   git clone https://github.com/hnpf/AboutThisLinux.git
   cd AboutThisLinux
   ```
2. Run the installer script:
   ```bash
   ./install.sh
   ```

### 3. verification

once installed, you can launch the app by searching for **About This Linux** in your desktop environment's application search/menu, or by running:

```bash
about-this-linux
```

> [!NOTE]
> make sure `~/.local/bin` is in your shell's `$PATH`. if it isn't, add the following line to your `~/.bashrc` or `~/.zshrc`:
> ```bash
> export PATH="$HOME/.local/bin:$PATH"
> ```
> for fish:
> ```bash
> fish_add_path ~/.local/bin
> ```

---

## packaging as an AppImage

to package `AboutThisLinux` as a portable `.AppImage` file that can run on other systems:

1. make sure you have `curl` installed to download the packaging tools.
2. run the build script:
   ```bash
   ./appimagebuilder.sh
   ```
3. this downloads `appimagetool` and builds `AboutThisLinux-x86_64.AppImage` in the root directory.
4. you can make it executable and run it:
   ```bash
   chmod +x AboutThisLinux-x86_64.AppImage
   ./AboutThisLinux-x86_64.AppImage
   ```

---

## 🄯 license

this project is licensed under the MIT License, see the [LICENSE](file:///home/virex/Projects/AboutThisLinux/LICENSE) file for details.
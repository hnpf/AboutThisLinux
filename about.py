import re
import subprocess
import gi
gi.require_version('Gtk', '4.0')
gi.require_version('Adw', '1')
from gi.repository import Gtk, Adw


def run(cmd):
    try:
        return subprocess.check_output(cmd, shell=True, stderr=subprocess.DEVNULL).decode().strip()
    except: return ""


def get_sys_info():
    info = {
        "hostname":  "localhost",
        "bios":      "Unknown",
        "cpu":       "Unknown CPU",
        "gpu_line1": "Unknown GPU",
        "gpu_line2": "",
        "mem":       "Unknown",
        "disk":      "Unknown",
        "serial":    "Unknown",
        "pci_cards": "Unknown",
        "os":        "Linux",
    }

    try:
        with open("/etc/hostname") as f:
            info["hostname"] = f.read().strip()
    except: pass

    try:
        with open("/sys/class/dmi/id/bios_date") as f:
            m = re.search(r'\d{4}', f.read())
            if m: info["bios"] = m.group(0)
    except: pass

    try:
        cores, model = 0, ""
        with open("/proc/cpuinfo") as f:
            for line in f:
                if "processor" in line: cores += 1
                if "model name" in line and not model:
                    model = line.split(":")[1].strip()

        # grab freq before stripping @ token
        freq = re.search(r'([\d\.]+)\s*GHz', model, re.IGNORECASE)
        if freq:
            freq = freq.group(1)
        else:
            # no GHz in model string (common on newer intel/amd), read max freq from sysfs
            raw = run("cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq")
            freq = f"{int(raw) / 1_000_000:.2f}".rstrip("0").rstrip(".") if raw.isdigit() else "?"

        brand = re.sub(r'\(TM\)|\(R\)|CPU|@.*|with.*', '', model, flags=re.IGNORECASE).strip()
        brand = re.sub(r'\s+', ' ', brand)

        info["cpu"] = f"{freq} GHz {cores}-Core {brand}"
    except: pass

    try:
        lspci = run("lspci")
        for line in lspci.splitlines():
            if re.search(r'VGA|3D|Display', line, re.IGNORECASE):
                gpu = re.sub(r'\s*\(rev [0-9a-f]+\)', '', line)
                # grab the friendly name from brackets first if present
                # e.g. "Navi 21 [Radeon RX 6800/6800 XT / 6900 XT]" -> "Radeon RX 6800"
                m = re.search(r'\[([^\]]+)\]\s*$', gpu)
                if m:
                    gpu = m.group(1).split('/')[0].strip()
                else:
                    # no brackets, strip class label and vendor prefix manually
                    gpu = re.sub(r'^.*:\s*(VGA compatible controller|3D controller|Display controller):\s*', '', gpu, flags=re.IGNORECASE)
                    gpu = re.sub(r'^Advanced Micro Devices,\s*Inc\.\s*(\[AMD/ATI\]\s*)?', 'AMD ', gpu)
                    gpu = re.sub(r'^NVIDIA Corporation\s*', '', gpu)
                    gpu = re.sub(r'^Intel Corporation\s*', 'Intel ', gpu)
                info["gpu_line1"] = gpu.strip()
                break

        # vram from drm if available (works for amd/intel, nvidia is hit or miss)
        vram = run("cat /sys/class/drm/card*/device/mem_info_vram_total 2>/dev/null | head -1")
        if vram and vram.isdigit():
            mb = int(vram) // (1024 ** 2)
            info["gpu_line2"] = f"{mb // 1024} GB" if mb >= 1024 else f"{mb} MB"
    except: pass

    try:
        with open("/proc/meminfo") as f:
            for line in f:
                if line.startswith("MemTotal"):
                    kb = int(line.split()[1])
                    gb = round(kb / (1024 ** 2))
                    info["mem"] = f"{gb} GB"
                    break

        # try to get speed from dmidecode (needs no sudo on most distros via /sys)
        speed = run("cat /sys/devices/system/memory/memory0/../*/speed 2>/dev/null | head -1")
        if not speed:
            speed = run("dmidecode -t memory 2>/dev/null | awk '/Speed:/{print $2\" \"$3; exit}'")
        if speed:
            info["mem"] += f" {speed} MHz DDR4" if "MHz" not in speed else f" {speed}"
    except: pass

    try:
        dev = run("findmnt -no SOURCE /")
        dev = re.sub(r'\[.*?\]', '', dev)  # strip btrfs subvol e.g. [/@]
        if dev: info["disk"] = dev
    except: pass

    try:
        serial = run("dmidecode -s system-serial-number")
        garbage = {"", "Default string", "To be filled by O.E.M.", "None", "Unknown", "Not Specified"}
        if serial and serial not in garbage:
            info["serial"] = serial
    except: pass

    try:
        lspci = run("lspci")
        # only count things that are actual expansion cards like gpu, nic, nvme, wifi, sound
        card_classes = re.compile(
            r'VGA|3D controller|Display|Audio device|Network controller|'
            r'Ethernet|Non-Volatile memory|RAID|Fibre Channel|InfiniBand',
            re.IGNORECASE
        )
        cards = [l for l in lspci.splitlines() if card_classes.search(l)]
        n = len(cards)
        info["pci_cards"] = f"{n} PCI Card{'s' if n != 1 else ''}"
    except: pass

    try:
        with open("/etc/os-release") as f:
            for line in f:
                if line.startswith("PRETTY_NAME"):
                    info["os"] = line.split("=")[1].strip().strip('"')
    except: pass

    return info


def get_more_info():
    rows = {}

    kernel = run("uname -r")
    if kernel: rows["Kernel"] = kernel

    shell = run("basename $SHELL")
    if shell: rows["Shell"] = shell

    # wm detection — check common env vars
    wm = (
        run("echo $HYPRLAND_INSTANCE_SIGNATURE") and "Hyprland" or
        run("echo $SWAYSOCK") and "Sway" or
        run("echo $XDG_CURRENT_DESKTOP") or
        run("echo $DESKTOP_SESSION") or
        "Unknown"
    )
    rows["Window Manager"] = wm

    de = run("echo $XDG_CURRENT_DESKTOP")
    if de: rows["Desktop Environment"] = de

    uptime = run("uptime -p")
    if uptime: rows["Uptime"] = uptime

    return rows


class MoreInfoWindow(Adw.Window):
    def __init__(self, parent):
        super().__init__(transient_for=parent, modal=True)
        self.set_default_size(400, 450)

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        header = Adw.HeaderBar()
        header.set_title_widget(Gtk.Label(label="System Specification Details"))
        box.append(header)

        group = Adw.PreferencesGroup()
        group.set_margin_top(16)
        group.set_margin_start(16)
        group.set_margin_end(16)

        for label, val in get_more_info().items():
            group.add(Adw.ActionRow(title=label, subtitle=val))

        box.append(group)
        self.set_content(box)


class AboutMacWindow(Adw.ApplicationWindow):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.set_default_size(180, 630)
        self.set_resizable(False)

        sys = get_sys_info()
        root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)

        header = Adw.HeaderBar()
        header.set_title_widget(Gtk.Label(label=""))

        # custom button tray, adw likes to eat these otherwise
        btn_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        btn_box.set_margin_start(12)
        header.pack_start(btn_box)
        root.append(header)

        body = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        body.set_margin_bottom(16)
        body.set_margin_start(32)
        body.set_margin_end(32)

        import os
        script_dir = os.path.dirname(os.path.realpath(__file__))
        img_path = os.path.join(script_dir, "macpro.png")
        img = Gtk.Image.new_from_file(img_path)
        img.set_pixel_size(180)
        img.set_margin_bottom(18)
        body.append(img)

        hostname_lbl = Gtk.Label()
        hostname_lbl.set_markup(f"<span size='20000' weight='600'>{sys['hostname']}</span>")
        body.append(hostname_lbl)

        bios_lbl = Gtk.Label()
        bios_lbl.set_markup(f"<span size='9000' foreground='#8c8c8c'>{sys['bios']}</span>")
        bios_lbl.set_margin_bottom(28)
        body.append(bios_lbl)

        grid = Gtk.Grid(column_spacing=10, row_spacing=6)
        grid.set_halign(Gtk.Align.CENTER)

        specs = [
            ("Processor",     sys["cpu"]),
            ("Graphics",      sys["gpu_line1"]),
            ("",              sys["gpu_line2"]),
            ("Memory",        sys["mem"]),
            ("Startup disk",  sys["disk"]),
            ("PCI cards",     sys["pci_cards"]),
            ("OS",            sys["os"]),
        ]
        if sys["serial"] != "Unknown":
            specs.insert(-1, ("Serial number", sys["serial"]))

        for i, (key, val) in enumerate(specs):
            if key:
                klbl = Gtk.Label()
                klbl.set_markup(f"<span weight='600' size='10000'>{key}</span>")
                klbl.set_halign(Gtk.Align.END)
                grid.attach(klbl, 0, i, 1, 1)

            vlbl = Gtk.Label()
            vlbl.set_markup(f"<span size='10000'>{val}</span>")
            vlbl.set_halign(Gtk.Align.START)
            vlbl.set_wrap(True)
            vlbl.set_max_width_chars(28)
            grid.attach(vlbl, 1, i, 1, 1)

        body.append(grid)

        spacer = Gtk.Box()
        spacer.set_vexpand(True)
        body.append(spacer)

        btn = Gtk.Button(label="More Info...")
        btn.set_halign(Gtk.Align.CENTER)
        btn.set_margin_bottom(12)
        btn.connect("clicked", self.on_more_info_clicked)
        body.append(btn)

        footer = Gtk.Label()
        footer.set_markup(
            "<span size='7500' foreground='#6c6c6c'>"
            "™ and © 1991-2026 The Linux Foundation.\n"
            "All Rights Reversed. Copyleft 🄯"
            "</span>"
        )
        footer.set_justify(Gtk.Justification.CENTER)
        body.append(footer)

        root.append(body)
        self.set_content(root)

    def on_more_info_clicked(self, button):
        MoreInfoWindow(self).present()


class AboutApp(Adw.Application):
    def __init__(self):
        super().__init__(application_id="lol.virex.AboutThisLinux")

    def do_activate(self):
        AboutMacWindow(application=self).present()


if __name__ == "__main__":
    AboutApp().run(None)

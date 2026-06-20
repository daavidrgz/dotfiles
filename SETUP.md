# SETUP.md — Full recovery guide for David's ASUS laptop

> **Audience and who does what.** §0–§8 are **human-driven** — Claude Code is not installed yet, so the human follows them by hand on the live Arch ISO using `nano` for any file edits. Starting at **§9 (user creation)** the human installs Claude Code so the agent can pick up §10 onward. Every step marked **CONFIRM** requires explicit human approval regardless.
>
> **Starting assumption.** The laptop is back from ASUS. The human's plan: **wipe the entire disk** (even if a factory Windows image is present) and reinstall both OSes from scratch. The dual-boot, the old Arch install, and all user data on the Windows partition are gone. Recovery codes, GPG keys, SSH keys, certificates, and `~/.claude/` all live on the **USB pendrive** the human prepared before shipping (see [§0](#0--pre-service-backup-reference)).
>
> **Reference machine.** ASUS Zenbook (hostname `AZBOOK14`), Intel CPU + NVIDIA hybrid GPU, **single 953.9 GiB Samsung NVMe** (`/dev/nvme0n1`), UEFI firmware, Secure Boot **disabled**.

---

## Table of contents

0. [Pre-service backup (reference)](#0--pre-service-backup-reference)
1. [From the returned Windows: prepare two install USBs](#1--from-the-returned-windows-prepare-two-install-usbs-human-driven) — *human*
2. [Wipe the disk and clean-install Windows on 440 GiB](#2--wipe-the-disk-and-clean-install-windows-on-440-gib-human-driven) — *human*
3. [Boot the Arch ISO](#3--boot-the-arch-iso-human-driven-still-no-claude-code) — *human*
4. [Partition the disk](#4--partition-the-disk-human-driven) — *human*
5. [Format and mount](#5--format-and-mount-human-driven) — *human*
6. [`pacstrap` base system](#6--pacstrap-base-system) — *human*
7. [Configure the new system inside `arch-chroot`](#7--configure-the-new-system-inside-arch-chroot-human-driven-no-agent-yet) — *human*
8. [Install and configure `systemd-boot`](#8--install-and-configure-systemd-boot-human-driven) — *human*
9. [First reboot, create user, install Claude Code](#9--first-reboot-into-arch-create-the-user-install-claude-code-human-driven-hand-off) — *human → agent hand-off*
10. [Clone dotfiles, install `yay`](#10--clone-dotfiles-install-yay-agent-driven-from-here-on) — *agent*
11. [Restore packages from `.installed_programs`](#11--restore-packages-from-installed_programs)
12. [Symlink configs from the dotfiles repo](#12--symlink-configs-from-the-dotfiles-repo)
13. [System-wide configs (NVIDIA, ASUS, X11, SDDM, services)](#13--system-wide-configs-nvidia-asus-x11-sddm-services)
14. [Restore SSH, GPG, secrets, `~/.claude`, skills, Archy](#14--restore-ssh-gpg-secrets-claude-skills-archy)
15. [Install personal certificates (`.p12`)](#15--install-personal-certificates-p12)
16. [Final reboot and verification](#16--final-reboot-and-verification)
17. [Things to remember after everything works](#17--things-to-remember-after-everything-works)

---

## 0 — Pre-service backup (reference)

This section documents what **must already be on the USB pendrive** before the laptop is handed to ASUS. Re-check this list with the human before assuming anything. Throughout the rest of the guide, `<USB>` means the mount point of that pendrive (e.g. `/run/media/david/MYUSB`).

The pendrive backup should contain:

- `~/.ssh/` (full directory: `id_rsa`, `id_rsa.pub`, `config`, `known_hosts`).
- `~/.gnupg/` (full directory — contains GPG private keys for git signing / decryption).
- `~/.secrets` (small file, ~1 KB, contains plaintext secrets used by shell scripts).
- **`~/private/`** — the single consolidated source-of-truth directory for sensitive files. Permissions `700`. Contains:
  - `private/certificates/` — `.p12` personal certificates (`certificado-salvi.p12`, `certificado-v2.p12`; `certificadoDavid.p12` on the Windows desktop is the same content as `certificado-v2.p12`, no separate backup needed).
  - `private/recovery-codes/` — 2FA / account recovery codes pulled off the Windows partition (currently `github.txt`). Add new ones here as services rotate their codes.

  Back this whole tree up with one `rsync -a ~/private/ <USB>/private/` — the simplest piece of the pendrive backup.
- **The entire `~/.claude/` directory**. This holds *everything* about Claude Code on this machine: installed skills, plugins, MCP server configs (`~/.claude/settings.json`, `~/.claude/settings.local.json`), all project sessions and transcripts (`~/.claude/projects/*/sessions/*.jsonl`), the file-based memory system, keybindings, hooks, and the credentials/token cache. **None of it lives in the cloud.** A single `rsync -a ~/.claude/ <USB>/claude-backup/` (or `tar`) is enough.
- 2FA seeds: if any TOTP is *only* on this laptop (not on the phone authenticator), export the seeds first.
- `~/.config/gtheme/` and `~/.gtheme/` if any custom theme/desktop files were authored locally and not pushed.
- Uncommitted work in every clone under `~/github/*` — run `for d in ~/github/*/; do (cd "$d" && git status -s); done` and resolve every dirty repo *before* the laptop leaves.
- The Windows partition at `/mnt`: anything in `OneDrive` that isn't actually synced (verify with the OneDrive web UI), plus anything under `C:\Users\david\{Music,Videos,Documents,Desktop}` that isn't already in `~/private/`.

`~/.gitconfig`, `~/.config/gh/hosts.yml`, and any other reproducible config are **not** on the pendrive — the dotfiles repo already has `.gitconfig`, and `gh auth login` regenerates the token in §14.

> **CONFIRM with the human** that the pendrive backup is present and verified *before* doing any of the destructive steps in §2 onward. If anything is missing, stop.

---

## 1 — From the returned Windows: prepare two install USBs (human-driven)

> Even if ASUS reinstalled Windows for you, the plan is to **wipe everything**. We still boot into the factory Windows once just to use it as a "build machine" for both install USBs. After this section the disk gets nuked.

You will need **two USB sticks ≥ 8 GB** — one for the Windows installer, one for the Arch installer.

1. Plug in the charger, power on, sign in. Skip the Microsoft-account prompt with `Shift+F10` → `start ms-cxh:localonly` (Windows 11 24H2+) or `oobe\BypassNRO.cmd` (older). A local account named `david` is fine — it's about to be wiped anyway.
2. **Verify the pendrive backup is intact.** Plug it in, open `\private\`, `\claude-backup\`, etc., and spot-check that the files from §0 are there. If anything is missing, stop and re-do §0 before continuing.
3. **Build the Arch installer USB.** Open a browser, download the latest ISO and signature from <https://archlinux.org/download/> (pick a mirror physically close to you). Run [Rufus](https://rufus.ie/) (or the [balenaEtcher](https://etcher.balena.io/) shortcut already on the desktop). Select USB stick 1, pick the Arch ISO, choose **GPT / UEFI**, write in **DD image** mode when prompted. ~5 minutes.
4. **Build the Windows 11 installer USB.** Run the [official Media Creation Tool](https://www.microsoft.com/software-download/windows11) on USB stick 2. Pick "Create installation media".
5. (Optional but recommended) Run any pending Windows Updates + the MyASUS app's firmware updates — this leaves you on the latest UEFI/BIOS firmware before reinstalling.
6. Shut down cleanly.

---

## 2 — Wipe the disk and clean-install Windows on 440 GiB (human-driven)

> **DESTRUCTIVE.** From here on the disk gets wiped. Confirm one more time that the pendrive backup is somewhere safe and *not plugged into this laptop*.

1. Power on with the power button. Tap `F2` repeatedly to enter the BIOS setup. Verify:
   - Secure Boot: **Disabled**
   - Fast Boot: **Disabled**
   - TPM: **Enabled** (Windows 11 requires it)
   - SATA / NVMe mode: **AHCI** (not RAID / Intel RST — Linux can't see the disk under RST).
2. Save & reboot. Tap `Esc` for the one-shot boot menu. Pick the **Windows 11 installer USB** (USB stick 2).
3. At the Windows installer "Where do you want to install Windows?" screen:
   - **Delete every existing partition** on `Drive 0` — including the ASUS recovery and MyASUS partitions. You want the disk to read as one big block of `Unallocated space`.
   - Click **New**, type **`450560`** in the Size field (that's **440 GiB**, leaving the rest unallocated for Arch). Click **Apply**.
   - Windows will create four partitions for itself: **EFI System (~100 MiB)**, **MSR (16 MiB)**, the new **Primary (~440 GiB)**, and a **Recovery (~620 MiB)** at the end.
   - Select the Primary partition, click **Next**, let the install run. The laptop reboots a few times.
4. Finish OOBE: same `start ms-cxh:localonly` trick, local account `david`, decline every telemetry checkbox.
5. Once on the desktop, **disable Fast Startup**: Control Panel → Power Options → "Choose what the power buttons do" → "Change settings that are currently unavailable" → uncheck *Turn on fast startup*. (If Fast Startup is on, `ntfs-3g` can't safely mount `/mnt` from Arch.)
6. **Disable hibernation**: open *Terminal (Admin)* and run `powercfg /h off`.
7. Verify the post-install partition layout in `diskmgmt.msc`. You should see:

   | # | Type | Size | Notes |
   |---|---|---|---|
   | 1 | EFI System Partition (FAT32) | ~100 MiB | Windows ESP — leave alone |
   | 2 | Microsoft Reserved | 16 MiB | MSR — leave alone |
   | 3 | Primary (NTFS, C:) | ~440 GiB | Windows install |
   | 4 | Recovery (NTFS) | ~620 MiB | WinRE — leave alone |
   | — | **Unallocated** | **~513 GiB** | Arch goes here |

8. Reboot. Tap `Esc` again, pick the **Arch installer USB** (USB stick 1).

Arch Wiki on dual-booting: <https://wiki.archlinux.org/title/Dual_boot_with_Windows#Install_Windows>.

---

## 3 — Boot the Arch ISO (human-driven, still no Claude Code)

1. At the Arch ISO boot menu, choose **Arch Linux install medium (x86_64, UEFI)**. You land in a root shell on the live ISO.
2. Verify UEFI: `ls /sys/firmware/efi/efivars` — should list files. (Arch Wiki: <https://wiki.archlinux.org/title/Installation_guide#Verify_the_boot_mode>.)
3. Connect to Wi-Fi with `iwctl`:
   ```text
   iwctl
   [iwd]# device list                  # note the device name, e.g. wlan0
   [iwd]# station wlan0 scan
   [iwd]# station wlan0 get-networks
   [iwd]# station wlan0 connect <SSID>
   [iwd]# exit
   ping -c 3 archlinux.org
   ```
   Arch Wiki: <https://wiki.archlinux.org/title/Iwd#iwctl>.
4. Update the system clock: `timedatectl set-ntp true`.

---

## 4 — Partition the disk (human-driven)

> **DESTRUCTIVE.** Run each command deliberately. If any value looks off, stop and read it again.

Target final layout on the 953.9 GiB disk:

| # | Label | Type | Size (MiB) | Cumulative end | Purpose |
|---|---|---|---|---|---|
| 1 | `EFI System` | FAT32 | ~100 | ~100 | Windows ESP (created in §2) |
| 2 | `MSR` | — | 16 | ~116 | Microsoft Reserved (created in §2) |
| 3 | `Basic Data` | NTFS | 450 560 | ~450 676 | Windows C: (created in §2) |
| 4 | `Recovery` | NTFS | ~620 | ~451 296 | WinRE (created in §2) |
| 5 | `ARCH_ESP` | FAT32 | **1024** | ~452 320 | Arch /boot — new, big enough for systemd-boot + kernel + initramfs |
| 6 | `ARCH_SWAP` | linux-swap | **8192** | ~460 512 | 8 GiB swap |
| 7 | `ARCH_ROOT` | ext4 | **rest** (~516 GiB) | end of disk | Arch / |

1. Identify the disk: `lsblk -f`. It should be `/dev/nvme0n1`. You will see partitions 1–4 from the Windows install and free space after partition 4.
2. Open `parted`:
   ```text
   parted /dev/nvme0n1
   (parted) unit MiB
   (parted) print free
   ```
   The output will list `partition 4` ending around `451296 MiB` and a `Free Space` row showing the unallocated region. Note the **start** of that free space (call it `START`, ≈ `451296`) and the **end of the disk** (call it `END`, ≈ `953869`).
3. Create the three Arch partitions inside the free space:
   ```text
   (parted) mkpart ARCH_ESP   fat32       START          START+1024
   (parted) set    5  esp on
   (parted) mkpart ARCH_SWAP  linux-swap  START+1024     START+1024+8192
   (parted) mkpart ARCH_ROOT  ext4        START+1024+8192   END
   (parted) print
   (parted) quit
   ```
   Plug in the actual numbers — e.g. with `START=451296`:
   ```text
   (parted) mkpart ARCH_ESP   fat32       451296   452320
   (parted) set    5  esp on
   (parted) mkpart ARCH_SWAP  linux-swap  452320   460512
   (parted) mkpart ARCH_ROOT  ext4        460512   953869
   ```
4. Re-run `lsblk -f` — you should now see `nvme0n1p5` (ARCH_ESP), `nvme0n1p6` (ARCH_SWAP), `nvme0n1p7` (ARCH_ROOT).

> **CONFIRM** the new partition numbers. They feed §5 verbatim.

---

## 5 — Format and mount (human-driven)

Assuming the §4 layout (`p5` = Arch ESP, `p6` = swap, `p7` = root):

```bash
mkfs.fat -F32 -n ARCH_ESP /dev/nvme0n1p5
mkswap                    /dev/nvme0n1p6
mkfs.ext4                 /dev/nvme0n1p7

mount /dev/nvme0n1p7 /mnt
mount --mkdir /dev/nvme0n1p5 /mnt/boot
swapon /dev/nvme0n1p6
```

Arch Wiki: <https://wiki.archlinux.org/title/Installation_guide#Format_the_partitions>.

---

## 6 — `pacstrap` base system

```bash
reflector --country "Spain,France,Germany" --age 12 --protocol https --sort rate \
          --save /etc/pacman.d/mirrorlist
pacstrap -K /mnt base base-devel linux linux-firmware linux-headers \
                 intel-ucode networkmanager sudo nano vim git zsh
```

Reference: <https://wiki.archlinux.org/title/Installation_guide#Install_essential_packages>.

Generate fstab:
```bash
genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab    # sanity check
```

---

## 7 — Configure the new system inside `arch-chroot` (human-driven, no agent yet)

> All file edits below use `nano <path>` to keep things simple for a human typing into the live ISO. Save with `Ctrl+O` `Enter`, exit with `Ctrl+X`.

```bash
arch-chroot /mnt
```

Inside the chroot:

```bash
ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime
hwclock --systohc
```

### Locale

```bash
nano /etc/locale.gen
```

Find the line `#en_US.UTF-8 UTF-8`, remove the leading `#`, save & exit. Then:

```bash
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
```

### Console keymap

Intentionally left unset — the Wayland session uses `altgr-intl` directly, not the console keymap. Nothing to do.

### Hostname

```bash
echo 'AZBOOK14' > /etc/hostname
nano /etc/hosts
```

Append these three lines (nothing else; the file may be empty in a fresh install):

```
127.0.0.1    localhost
::1          localhost
127.0.1.1    AZBOOK14.localdomain    AZBOOK14
```

### Root password

```bash
passwd
```

Arch Wiki: <https://wiki.archlinux.org/title/Installation_guide#Configure_the_system>.

### initramfs (NVIDIA early-KMS)

```bash
nano /etc/mkinitcpio.conf
```

Find the line starting with `MODULES=` and replace it with this (keep the parentheses, no trailing comment):

```
MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)
```

Leave `HOOKS=` at its default (reference value, for sanity check only):
```
HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck)
```

Save, exit, then rebuild:

```bash
mkinitcpio -P
```

*Note*: `nvidia-open-dkms` is installed later in §11 — until then `nvidia*` modules just won't load, which is fine, the system still boots on Intel graphics.

---

## 8 — Install and configure `systemd-boot` (human-driven)

Reference: <https://wiki.archlinux.org/title/Systemd-boot#Installation>.

```bash
bootctl install
```

This places `systemd-bootx64.efi` at `/boot/EFI/systemd/` and a fallback at `/boot/EFI/BOOT/BOOTX64.EFI`, and registers a `Linux Boot Manager` entry in NVRAM.

### Loader config

```bash
nano /boot/loader/loader.conf
```

Replace whatever's in the file (it may have placeholder comments) with exactly these three lines:

```
default arch.conf
timeout 5
console-mode max
```

### Arch entry

First, get the root partition UUID and **write it down** — you'll type it into the next file:

```bash
blkid /dev/nvme0n1p7
```

Copy the value after `UUID=` (a long hyphenated string). Then:

```bash
nano /boot/loader/entries/arch.conf
```

File contents — **replace `<ROOT_UUID>` with the UUID you just copied** (everything else verbatim):

```
title Arch Linux
linux /vmlinuz-linux
initrd /intel-ucode.img
initrd /initramfs-linux.img
options root=UUID=<ROOT_UUID>
```

### Windows entry

We'll do the **direct chainload** of `bootmgfw.efi` — it's the shorter, simpler method. It assumes the Windows ESP keeps `bootmgfw.efi` at the standard `/EFI/Microsoft/Boot/` path, which is the default Windows installer layout.

Mount the Windows ESP read-only and copy the Windows boot manager into Arch's ESP so `systemd-boot` can chainload it:

```bash
mkdir -p /mnt/winefi
mount -o ro /dev/nvme0n1p1 /mnt/winefi
mkdir -p /boot/EFI/Microsoft
cp -r /mnt/winefi/EFI/Microsoft/Boot /boot/EFI/Microsoft/Boot
umount /mnt/winefi && rmdir /mnt/winefi
```

Then:

```bash
nano /boot/loader/entries/windows.conf
```

Contents (verbatim):

```
title Windows 11
efi /EFI/Microsoft/Boot/bootmgfw.efi
```

> **Why not the EFI-shell trick from the previous install?** That method (a `shellx64.efi` + `windows.nsh` script that autodetects the FS volume) survives Windows ESP-path changes, but it requires `edk2-shell` (only available *after* §11). The direct chainload above works immediately, fits the "human-driven, no agent yet" constraint, and is the method the [Arch Wiki Systemd-boot Windows section](https://wiki.archlinux.org/title/Dual_boot_with_Windows#Configuring_the_bootloader) documents first. If Windows ever changes its ESP layout and the chainload breaks, fall back to the shell-script method described in `boot/entries/windows.conf` of this repo.

### Enable NetworkManager (still in chroot)

```bash
systemctl enable NetworkManager.service
```

### Leave chroot and reboot

```bash
exit            # leave arch-chroot
umount -R /mnt
swapoff -a
reboot          # pull the Arch installer USB during POST
```

---

## 9 — First reboot into Arch, create the user, install Claude Code (human-driven hand-off)

1. The systemd-boot menu should now offer **Arch Linux** (default) and **Windows 11**. Test both: boot Windows once to confirm the chainload works, then reboot back into Arch.
2. Log in to Arch as `root`.
3. Create the user (UID 1000, default shell `zsh`, primary group `david`):
   ```bash
   useradd -m -G wheel,video,audio,storage,input,network -s /bin/zsh david
   passwd david
   EDITOR=nano visudo    # uncomment "%wheel ALL=(ALL:ALL) ALL"
   ```
4. Log out, log back in as `david` on tty1.
5. Get on the network and install Node.js + Claude Code so the agent can take over from §10:
   ```bash
   sudo nmcli device wifi connect <SSID> password <PASS>
   sudo pacman -Syu
   sudo pacman -S --needed nodejs npm git
   sudo npm install -g @anthropic-ai/claude-code
   claude --version          # sanity check
   ```
6. **Hand-off point.** Launch Claude Code in a working directory and let it drive §10 onward:
   ```bash
   mkdir -p ~/github && cd ~/github
   claude
   # in Claude Code, paste:  "Continue from §10 of ~/github/dotfiles/SETUP.md once
   #                          you've cloned the repo. Stop at every CONFIRM step."
   ```
   The agent will need to run `claude auth login` on first launch (interactive OAuth in the terminal — only the human can complete it).

---

## 10 — Clone dotfiles, install `yay` (agent-driven from here on)

```bash
# Cloned over HTTPS for now (no SSH key yet — we restore that in §14).
cd ~/github
git clone https://github.com/daavidrgz/dotfiles.git
cd dotfiles

# yay (AUR helper) — Arch Wiki: https://wiki.archlinux.org/title/AUR_helpers
sudo pacman -S --needed base-devel git
cd /tmp && git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin
makepkg -si
```

---

## 11 — Restore packages from `.installed_programs`

`yay` resolves both official-repo and AUR packages from the single list at `.installed_programs` (currently ~182 entries). It is regenerated with `pacman -Qqe | sort > .installed_programs`.

```bash
cd ~/github/dotfiles
yay -S --needed --noconfirm - < .installed_programs
```

If `yay` rejects stdin batches (depends on version), fall back to:

```bash
xargs -a .installed_programs -r yay -S --needed --noconfirm
```

If any AUR package fails to build, the agent should: (a) note the package name, (b) attempt `yay -S <pkg> --mflags --skipinteg` only after confirming with the human, (c) move on rather than blocking the whole restore — most AUR failures are upstream-transient.

---

## 12 — Symlink configs from the dotfiles repo

The dotfiles repo is the source of truth for **shell + top-level dotfiles + the archy systemd user unit**. Most of `~/.config/*` (Hyprland, waybar, quickshell, fuzzel, swaync, kitty colors, etc.) is **not** in this repo because [gtheme](https://github.com/daavidrgz/gtheme) installs and themes them when a desktop is applied — see [§12.B](#12b--apply-a-gtheme-desktop) below.

### 12.A  Shell, p10k, scripts, archy user-service, desktop entries, cursor default

Symlink — don't copy — so `git status` keeps working for ongoing edits:

```bash
cd ~/github/dotfiles

# Top-level dotfiles
ln -snf $PWD/.bashrc             ~/.bashrc
ln -snf $PWD/.zshrc              ~/.zshrc
ln -snf $PWD/.zsh_plugins.txt    ~/.zsh_plugins.txt
ln -snf $PWD/.p10k.zsh           ~/.p10k.zsh
ln -snf $PWD/.gitconfig          ~/.gitconfig
ln -snf $PWD/.xprofile           ~/.xprofile
ln -snf $PWD/.installed_programs ~/.installed_programs

# Top-level ~/.config/ files (not managed by gtheme).
# chrome-flags.conf forces Chrome to always expose CDP on port 9222 with a
# dedicated profile, so archy / the chrome-cdp skill can drive the browser
# no matter how it's launched (rofi, terminal, .desktop, hyprctl exec…).
ln -snf $PWD/.config/chrome-flags.conf ~/.config/chrome-flags.conf

# Custom scripts
mkdir -p ~/scripts
for s in "$PWD"/scripts/*; do ln -snf "$s" ~/scripts/$(basename "$s"); done

# systemd user units (archy etc.) — these are NOT managed by gtheme
mkdir -p ~/.config/systemd/user
for u in "$PWD"/.config/systemd/user/*; do
    ln -snf "$u" ~/.config/systemd/user/$(basename "$u")
done
systemctl --user daemon-reload

# Discord per-user override (Wayland Ozone flags — fixes the renderer
# artifacts under Hyprland). Copy, not symlink: this directory is shared
# with desktop entries that other tools (waydroid, gh, etc.) drop in at
# runtime, and we don't want to symlink the whole folder.
mkdir -p ~/.local/share/applications
cp "$PWD"/.local/share/applications/discord.desktop \
   ~/.local/share/applications/discord.desktop

# Cursor "default" symlinks — required for both XCursor (X11/XWayland) and the
# fallback lookup that GTK and Qt do under Wayland. Without these, apps render
# the giant X11 hourglass cursor instead of the configured Bibata theme.
mkdir -p ~/.icons ~/.local/share/icons
ln -snf /usr/share/icons/Bibata-Modern-Ice ~/.icons/default
ln -snf /usr/share/icons/Bibata-Modern-Ice ~/.local/share/icons/default
```

> `bibata-cursor-theme` is in `.installed_programs`, so the target `/usr/share/icons/Bibata-Modern-Ice` will exist after §11. Reference: Arch Wiki "Cursor themes" → <https://wiki.archlinux.org/title/Cursor_themes#XDG_specification>.

> **`~/.xinitrc` is intentionally not in this repo.** The previous one is the upstream Arch `xinitrc` template with no custom edits, and `xinitrc` only runs if you launch the session via `startx` — under SDDM (configured in §13) it is never sourced. Leave it untouched (the system installs a default at `/etc/X11/xinit/xinitrc`).

Bootstrap antidote + powerlevel10k:

```bash
git clone --depth=1 https://github.com/mattmc3/antidote.git ~/.antidote
# .zshrc already sources antidote and .zsh_plugins.txt
exec zsh -l
```

### 12.B  Apply a gtheme desktop

`gtheme` is in `.installed_programs` and was installed in §11. It clones its **desktops** (Hyprland + every related `.config/*` directory) and **themes** from the user's GitHub on first use. Reference: <https://github.com/daavidrgz/gtheme>.

```bash
# First-run sync — pulls gtheme-desktops + gtheme-themes from GitHub
gtheme update            # or: gtheme sync — confirm the exact command name with --help

# Choose and apply a desktop (replicates the previous setup's Hyprland config)
gtheme desktop list
gtheme desktop apply hypr

# Pick the active theme
gtheme theme list
gtheme theme apply <theme-name>
```

After `gtheme desktop apply hypr` the following directories are (re)populated under `~/.config/`: `hypr/`, `quickshell/`, `waybar/`, `swaync/`, `wlogout/`, `fuzzel/`, `rofi/`, `kitty/`, `dunst/`, `easyeffects/`, `btop/`, `yazi/`, `mpv/`, `cava/`, `cmus/`, `picom/`, `polybar/`, `sxhkd/`, `zathura/`, etc. **Do not symlink these from the dotfiles repo first** — gtheme will overwrite them anyway, and having stale symlinks confuses it. Let gtheme own them.

> **CONFIRM with the human** which desktop name to apply. The currently-installed desktop was `hypr`.

---

## 13 — System-wide configs (NVIDIA, ASUS, X11, SDDM, services)

Most of `/etc` is **not symlinked** — it needs root + a clean copy. The dotfiles repo carries the canonical files under `etc/`:

```bash
sudo install -m644 etc/X11/xorg.conf.d/10-serverflags.conf  /etc/X11/xorg.conf.d/
sudo install -m644 etc/X11/xorg.conf.d/30-touchpad.conf     /etc/X11/xorg.conf.d/
sudo install -m644 etc/supergfxd.conf                       /etc/supergfxd.conf
sudo install -m644 etc/asusd/asusd.ron                      /etc/asusd/asusd.ron
sudo install -m644 etc/sddm.conf.d/sddm.conf                /etc/sddm.conf.d/sddm.conf
sudo install -m644 etc/mkinitcpio.conf                      /etc/mkinitcpio.conf
sudo mkinitcpio -P    # rebuild with the dotfiles version
```

### Display manager + greeter theme

The active SDDM theme is **Sugar Candy** ([upstream framagit](https://framagit.org/MarianArlt/sddm-sugar-candy)) — not packaged in pacman/AUR, so dotfiles ships its own copy. The Tokyo-Night colour overrides live in `sddm/theme.conf.user`.

```bash
# Install the bundled theme into the system path SDDM scans
sudo cp -r sddm/themes/sugar-candy /usr/share/sddm/themes/sugar-candy

# Per-user colour/font override (Tokyo-Night palette, GeistMono Nerd Font)
mkdir -p ~/.config/sddm
cp sddm/theme.conf.user ~/.config/sddm/theme.conf.user

# sddm.conf already sets `[Theme] Current=sugar-candy` (installed in the
# earlier `sudo install -m644 etc/sddm.conf.d/sddm.conf …` step), so the
# greeter picks it up on next start.
sudo systemctl enable sddm.service
```

### Services to enable

System-wide (from `services/services-system.txt`):

```bash
sudo systemctl enable bluetooth.service docker.service NetworkManager.service \
                      sddm.service supergfxd.service systemd-timesyncd.service \
                      waydroid-docker-fix.service \
                      nvidia-suspend.service nvidia-resume.service nvidia-hibernate.service
```

> **NVIDIA suspend/resume** — the three `nvidia-*` services above are **required** for a working resume on this hybrid laptop. The driver runs with `PreserveVideoMemoryAllocations=1`, so VRAM must be saved/restored across suspend by `nvidia-suspend`/`nvidia-resume`. If they are disabled, closing and reopening the lid resumes the kernel but leaves the GPU/compositor hung (lock screen flashes, then the display dies and only a hard power-off recovers). They ship **disabled** by default — enabling them is mandatory, not optional.

User-level (from `services/services-user.txt`):

```bash
systemctl --user enable pipewire.socket pipewire-pulse.socket wireplumber.service \
                        xdg-user-dirs.service archy.service
```

### NVIDIA hybrid (Intel + NVIDIA) notes

- `nvidia-open-dkms` was the kernel module flavour in use. With `linux-headers` installed, the DKMS module rebuilds automatically. Verify: `dkms status`.
- `supergfxctl` handles GPU mode switching (Hybrid/Integrated/dGPU). The shipped `supergfxd.conf` already has `mode: Hybrid` and `hotplug_type: Asus`.
- **Suspend/resume**: the `nvidia-suspend`/`nvidia-resume`/`nvidia-hibernate` services must be enabled (see "Services to enable" above) or resume from a lid-close hangs the GPU. They are disabled out of the box.
- Wayland on hybrid NVIDIA: `nvidia_drm.modeset=1` is mandatory. It's set implicitly by adding `nvidia_drm` to `MODULES=` in `mkinitcpio.conf` *with* the `KMS` hook (already configured) — the modeset flag is the default in the open driver. Arch Wiki: <https://wiki.archlinux.org/title/NVIDIA#DRM_kernel_mode_setting>.

### ASUS-specific

```bash
sudo pacman -S --needed asusctl supergfxctl    # already in .installed_programs
```

If `asusctl` is not in the official repos at the time of restore, `yay -S asusctl` builds it from AUR.

---

## 14 — Restore SSH, GPG, secrets, `~/.claude`, skills, Archy

These come from the off-device backup, **never** from this public repo.

```bash
# SSH
mkdir -p ~/.ssh && chmod 700 ~/.ssh
cp /run/media/david/<USB>/ssh-backup/id_rsa     ~/.ssh/id_rsa
cp /run/media/david/<USB>/ssh-backup/id_rsa.pub ~/.ssh/id_rsa.pub
cp /run/media/david/<USB>/ssh-backup/config     ~/.ssh/config
cp /run/media/david/<USB>/ssh-backup/known_hosts ~/.ssh/known_hosts
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub ~/.ssh/config ~/.ssh/known_hosts

# GPG (keys + trustdb)
mkdir -p ~/.gnupg && chmod 700 ~/.gnupg
cp -a /run/media/david/<USB>/gnupg-backup/. ~/.gnupg/
gpg --list-secret-keys     # sanity

# Secrets file used by shell scripts
cp /run/media/david/<USB>/.secrets ~/.secrets
chmod 600 ~/.secrets

# GitHub CLI (re-auth instead of copying token if more than 30 days old)
gh auth login --git-protocol ssh --hostname github.com

# Switch all already-cloned repos to SSH remote
for d in ~/github/*/; do
    cd "$d" && url=$(git remote get-url origin 2>/dev/null) || continue
    case "$url" in
        https://github.com/*) new="git@github.com:${url#https://github.com/}";
            git remote set-url origin "${new%.git}.git" ;;
    esac
done
```

> **CONFIRM with the human** before running anything that touches `~/.gnupg/` — if a previous import already happened, copying over it can corrupt the trustdb.

### Restore `~/.claude/` (sessions, memory, plugins, MCP, credentials)

```bash
# Exclude skills/ from the rsync — the canonical copy comes from the dotfiles
# repo in the next step, and we don't want stale backup state racing with it.
rsync -a --exclude='skills/' /run/media/david/<USB>/claude-backup/ ~/.claude/
chmod 600 ~/.claude/.credentials.json 2>/dev/null
ls ~/.claude/projects/ | head
```

After that, opening `claude` in any of the restored project directories should resume with full memory + session history. Plugins under `~/.claude/plugins/` come back with the same `rsync`.

### Restore skills (`~/.claude/skills/`)

Single flat layout: real skill directories under `~/.claude/skills/`, and one symlink at `~/.config/archy/skills/user` so Archy reads the same library. Nothing nested, no per-skill symlinks.

```bash
mkdir -p ~/.claude/skills
for s in ~/github/dotfiles/skills/*/; do
    cp -r "$s" ~/.claude/skills/
done

# Archy expects two skill pools:
#   - user/  → shared with Claude Code, lives in ~/.claude/skills (symlinked)
#   - agent/ → Archy's own mutable scratch, separate real directory
mkdir -p ~/.config/archy/skills/agent
ln -snf ~/.claude/skills ~/.config/archy/skills/user
ls ~/.claude/skills/ ~/.config/archy/skills/
```

### Restore Archy's CLAUDE.md and `archy.toml`

```bash
mkdir -p ~/.config/archy/memory
ln -snf ~/github/dotfiles/archy/CLAUDE.md  ~/.config/archy/CLAUDE.md
cp        ~/github/dotfiles/archy/archy.toml ~/.config/archy/archy.toml
# memory/ stays local and is restored from the pendrive if it had any notes
```

`CLAUDE.md` is symlinked (so future edits land in this repo); `archy.toml` is copied (it gets edited by `archy` itself when models or paths change, and you don't want those edits leaking into the public repo).

> Once SSH is restored, `ssh hermo.dev whoami` should print `server` immediately — the restored `~/.ssh/id_rsa` is the same key the server already trusts.

---

## 15 — Install personal certificates (`.p12`)

The Spanish FNMT-style `.p12` certificates restored in §0 to `~/private/certificates/` (`certificado-salvi.p12`, `certificado-v2.p12`) need to be imported into the shared Chromium NSS database. They are *not* TLS server certs — they are client/personal certs used to sign documents and authenticate to AEAT, Seguridad Social, DGT, university portals, etc.

> **Never** add a personal `.p12` to the system-wide trust store (`/etc/ca-certificates/trust-source/`). That trust store is for **issuers** of certificates, not for personal end-entity certs. Putting yours there does nothing useful and weakens trust validation.

All Chromium browsers on Linux (Chrome, Brave, Edge, Opera, Vivaldi) share **one** NSS database at `~/.pki/nssdb`. Import once, every Chromium browser sees it.

```bash
mkdir -p ~/.pki/nssdb
certutil -d sql:$HOME/.pki/nssdb -N --empty-password    # first time only
pk12util -i ~/private/certificates/certificado-salvi.p12 -d sql:$HOME/.pki/nssdb
pk12util -i ~/private/certificates/certificado-v2.p12    -d sql:$HOME/.pki/nssdb
certutil -d sql:$HOME/.pki/nssdb -L                      # verify
```

Then in Chrome/Brave: `chrome://settings/certificates` → tab **Your Certificates** — the imported certs are listed.

> **Gotcha**: snap- or flatpak-packaged Chromiums use a sandboxed home and **don't** see `~/.pki`. Install Chromium-family browsers from pacman/AUR so this import path keeps working.

### Tighten permissions

```bash
chmod 700 ~/private ~/private/certificates ~/private/recovery-codes
chmod 600 ~/private/certificates/*.p12 ~/private/recovery-codes/*.txt 2>/dev/null
```

The pendrive backup keeps the canonical copy; the local `~/private/certificates/` is just for the next import after a future re-install.

References: <https://wiki.archlinux.org/title/User:Grawity/Importing_personal_certificates>.

---

## 16 — Final reboot and verification

```bash
sudo reboot
```

Pick **Arch Linux** in the systemd-boot menu. SDDM should appear → log in.

Checklist (the agent runs each, the human eyeballs):

- [ ] `cat /etc/hostname` → `AZBOOK14`
- [ ] `localectl status` → `LANG=en_US.UTF-8`, keymap `(unset)`, X11 layout `us` / variant `altgr-intl`
- [ ] `bootctl status` → current loader is `systemd-boot`, both `arch.conf` and `windows.conf` listed
- [ ] `systemctl is-enabled NetworkManager sddm supergfxd bluetooth docker` → `enabled enabled enabled enabled enabled`
- [ ] `systemctl --user is-enabled archy pipewire wireplumber xdg-user-dirs` → all `enabled`
- [ ] `nvidia-smi` → driver loads, GPU listed
- [ ] `supergfxctl -g` → `Hybrid`
- [ ] `pacman -Qq | wc -l` → ~210 (the original install had 182 explicit + AUR ~50)
- [ ] `ssh hermo.dev whoami` → `server`
- [ ] Hyprland session loads with the previous keybinds (open kitty with Super+Enter or equivalent)
- [ ] caelestia-shell starts at login (it's the user session — check `~/.config/caelestia-shell/`)
- [ ] Reboot once and pick **Windows 11** from the loader — confirm it still boots Windows. Reboot back to Arch.

---

## 17 — Things to remember after everything works

- **Claude Code conversations are local.** `~/.claude/projects/*/sessions/*.jsonl` is the only copy. The file-based memory under `~/.claude/projects/*/memory/` is also local. If they weren't restored from the pendrive in §14, they are gone forever — there is no cloud copy. Anthropic does keep usage telemetry but **not the message contents**.
- **The Windows partition seen at `/mnt` was wiped** when you reinstalled in §2. Anything that was only on Windows and not in the pendrive backup is gone.
- **Re-add the laptop's SSH/GPG key to GitHub** if it isn't already: <https://github.com/settings/keys>.
- **2FA recovery codes**: regenerate them on Github/Google/etc. after first sign-in, and store the new codes on the pendrive (`~/private/recovery-codes/`).

---

### Arch Wiki link index (for the agent's convenience)

- Installation guide: <https://wiki.archlinux.org/title/Installation_guide>
- Dual boot with Windows: <https://wiki.archlinux.org/title/Dual_boot_with_Windows>
- `systemd-boot`: <https://wiki.archlinux.org/title/Systemd-boot>
- EFI system partition: <https://wiki.archlinux.org/title/EFI_system_partition>
- NVIDIA: <https://wiki.archlinux.org/title/NVIDIA>
- NVIDIA Optimus / hybrid graphics: <https://wiki.archlinux.org/title/NVIDIA_Optimus>
- ASUS Linux (G14/Zenbook tooling): <https://wiki.archlinux.org/title/Laptop/ASUS> and <https://asus-linux.org/>
- Hyprland: <https://wiki.archlinux.org/title/Hyprland>
- iwd / `iwctl`: <https://wiki.archlinux.org/title/Iwd>
- AUR helpers: <https://wiki.archlinux.org/title/AUR_helpers>
- SSH keys: <https://wiki.archlinux.org/title/SSH_keys>
- Pacman tips: <https://wiki.archlinux.org/title/Pacman/Tips_and_tricks>

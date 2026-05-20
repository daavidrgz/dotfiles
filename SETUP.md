# SETUP.md — Full recovery guide for David's ASUS laptop

> **Audience.** This document is written for an AI agent (Claude Code or equivalent) working *alongside* the human owner. The agent should treat every numbered step as a checkpoint: read it, confirm prerequisites, execute, and **stop for the human** whenever the step contains the word **CONFIRM**. The human is the only party allowed to type passwords, plug USB sticks, accept BIOS prompts, or do anything destructive without an explicit OK.
>
> **Starting assumption.** The laptop has just come back from ASUS service. The internal NVMe disk has been **fully wiped** (a clean factory image of Windows 11 may or may not be present — assume nothing). The dual-boot configuration, the Arch Linux install, all user data on `/` and on the Windows partition is gone. Recovery codes, GPG keys and SSH keys live on the **off-device backup** the user prepared before sending the laptop (see [§0 Pre-service backup](#0--pre-service-backup-reference)).
>
> **Reference machine.** ASUS Zenbook (hostname `AZBOOK14`), Intel CPU + NVIDIA hybrid GPU, single NVMe disk, UEFI firmware, Secure Boot **disabled**.

---

## Table of contents

0. [Pre-service backup (reference)](#0--pre-service-backup-reference)
1. [Post-service: first boot of the returned laptop](#1--post-service-first-boot-of-the-returned-laptop)
2. [Install / repair Windows 11 and shrink its partition](#2--install--repair-windows-11-and-shrink-its-partition)
3. [Boot the Arch installation media](#3--boot-the-arch-installation-media)
4. [Partition the disk](#4--partition-the-disk)
5. [Format and mount](#5--format-and-mount)
6. [`pacstrap` base system](#6--pacstrap-base-system)
7. [Configure the new system (`arch-chroot`)](#7--configure-the-new-system-arch-chroot)
8. [Install and configure `systemd-boot` (dual boot)](#8--install-and-configure-systemd-boot-dual-boot)
9. [First reboot into Arch and create the user](#9--first-reboot-into-arch-and-create-the-user)
10. [Networking, AUR helper, dotfiles](#10--networking-aur-helper-dotfiles)
11. [Restore packages from `.installed_programs`](#11--restore-packages-from-installed_programs)
12. [Symlink configs from the dotfiles repo](#12--symlink-configs-from-the-dotfiles-repo)
13. [System-wide configs (NVIDIA, ASUS, X11, SDDM, services)](#13--system-wide-configs-nvidia-asus-x11-sddm-services)
14. [Restore SSH, GPG, secrets, browser data, `~/.claude`](#14--restore-ssh-gpg-secrets-browser-data)
15. [Install personal certificates (`.p12`)](#15--install-personal-certificates-p12)
16. [Set up the homeserver SSH key pair (hermo.dev)](#16--set-up-the-homeserver-ssh-key-pair-hermodev)
17. [Final reboot and verification](#17--final-reboot-and-verification)
18. [Things to remember after everything works](#18--things-to-remember-after-everything-works)

---

## 0 — Pre-service backup (reference)

This section documents what **must already exist on an external drive or trusted host** before the laptop is handed to ASUS. Re-check this list with the human before assuming anything.

The off-device backup should contain:

- `~/.ssh/` (full directory: `id_rsa`, `id_rsa.pub`, `config`, `known_hosts`).
- `~/.gnupg/` (full directory — contains GPG private keys for git signing / decryption).
- `~/.secrets` (small file, ~1 KB, contains plaintext secrets used by shell scripts).
- `~/.gitconfig` (top-level `[user]` block — the rest is re-created from this repo).
- `~/.config/gh/hosts.yml` (GitHub CLI token; can also be re-generated with `gh auth login`).
- `~/certificates/` — `.p12` personal certificates (currently `certificado-salvi.p12` and `certificado-v2.p12`). The third certificate, `certificadoDavid.p12`, lives on the Windows desktop (`/mnt/Users/david/Desktop/`) — copy that one to `~/certificates/` too before the laptop ships so the backup is in a single directory.
- **The entire `~/.claude/` directory**. This holds *everything* about Claude Code on this machine: installed skills, plugins, MCP server configs (`~/.claude/settings.json`, `~/.claude/settings.local.json`), all project sessions and transcripts (`~/.claude/projects/*/sessions/*.jsonl`), the file-based memory system (`~/.claude/projects/-home-david-github-dotfiles/memory/*.md` and equivalents for every other project), keybindings, hooks, and the credentials/token cache. **None of it lives in the cloud.** A single `rsync -a ~/.claude/ <external>/claude-backup/` (or `tar`) is enough.
- Browser export: bookmarks + saved passwords from Chrome, Brave, Firefox, Vivaldi, Edge, Opera. Easiest path: ensure each browser is signed in to its sync account *before* sending the laptop, and **screenshot the list of installed extensions** for verification.
- 2FA seeds: if any TOTP is *only* on this laptop (not on the phone authenticator), export the seeds first. The mobile authenticator is the source of truth — if all 2FA already lives there, nothing extra to do.
- `~/.config/gtheme/` and `~/.gtheme/` if any custom theme/desktop files were authored locally and not pushed.
- Uncommitted work in every clone under `~/github/*` — at time of writing the dirty ones were `archy`, `car-finder`, `gtheme`. Run `for d in ~/github/*/; do (cd "$d" && git status -s); done` to confirm what's dirty *before* the laptop leaves.
- The Windows partition at `/mnt`: at minimum `C:\Users\david\Desktop\certificadoDavid.p12`, `C:\Users\david\Documents\github-recovery-codes.txt`, `C:\Users\david\Documents\My Games`, plus anything in `OneDrive` that isn't actually synced (verify with the OneDrive web UI).
- A note of the **laptop owner email** used in `.gitconfig`: `davidrbacelar@gmail.com`.

> **CONFIRM with the human** that the off-device backup is present and verified *before* doing any of the destructive steps in §3–§8. If anything is missing, stop.

---

## 1 — Post-service: first boot of the returned laptop

1. Plug in the charger. Open the lid. Power on with the power button.
2. If the laptop boots straight into the ASUS factory Windows out-of-box experience, follow the OOBE only as far as creating a **local** Windows account named `david`. Skip the Microsoft account screen (`Shift+F10` → `oobe\BypassNRO.cmd` historically; on Windows 11 24H2+ run `start ms-cxh:localonly` from the same console). Disable every telemetry checkbox.
3. If instead the disk is completely empty (no Windows present), skip ahead to [§2.B (clean Windows install)](#2b--clean-install-of-windows-11) below.
4. Once at the Windows desktop, **CONFIRM with the human** that the off-device backup is still around — Windows-only steps are reversible up to this point but Arch installation (§3+) is not.

---

## 2 — Install / repair Windows 11 and shrink its partition

### 2.A  If Windows is already present (recovery image restored)

1. Boot into Windows. Open Settings → Update & Security → run all Windows Updates and ASUS firmware updates (MyASUS app). Reboot until clean.
2. Disable Fast Startup, otherwise `ntfs-3g` cannot mount the NTFS partition read-write from Arch:
   - Control Panel → Power Options → "Choose what the power buttons do" → "Change settings that are currently unavailable" → uncheck **Turn on fast startup**.
3. Disable Hibernation entirely:
   - Open an elevated PowerShell: `powercfg /h off`.
4. **Shrink the Windows partition** to free space for Arch. Open `diskmgmt.msc`, right-click the `C:` partition → *Shrink Volume…* Aim for **~256 GiB free** at the end of the disk for `/` plus a small `swap`. Larger if the user wants more room — current install uses ~73 % of a 350 GiB ext4. If shrink is limited by immovable files, run a defrag and disable the page file/hibernation temporarily, then re-shrink. Arch Wiki: <https://wiki.archlinux.org/title/Dual_boot_with_Windows#Windows_before_Linux>.
5. Power off cleanly: `Shift + Click Restart` is fine; never just hold the power button.

### 2.B  Clean install of Windows 11 (if no Windows present)

Reference: <https://wiki.archlinux.org/title/Dual_boot_with_Windows#Install_Windows>.

1. From another machine, build a Windows 11 install USB with the [official Microsoft Media Creation Tool](https://www.microsoft.com/software-download/windows11). Use a USB ≥ 8 GB.
2. Boot the laptop with `F2` to enter BIOS. Verify: Secure Boot **Disabled**, Fast Boot **Disabled**, TPM **Enabled**, SATA/NVMe mode **AHCI** (not RAID/Intel RST — Linux cannot see the disk in RST mode).
3. Boot from the Windows USB (`Esc` boot menu).
4. On the partitioning screen, **delete every existing partition** and let the Windows installer create its own scheme — it will lay down: ESP (vfat, ~100 MB), MSR, the main NTFS partition, and a small recovery NTFS at the end.
5. **Crucial**: tell the installer to put the C: partition at **~half the disk** rather than filling all space. Easiest way: create a *custom-sized* partition equal to roughly 50 % of the disk; the remaining unallocated space will host Arch. If the installer doesn't let you size it directly, install Windows on the whole disk and shrink afterwards via §2.A step 4.
6. Complete OOBE as in §1 step 2. Then continue with §2.A steps 2–5.

> **CONFIRM with the human** before powering off: the unallocated free space at the end of the disk is *at least* 256 GiB.

---

## 3 — Boot the Arch installation media

1. On another machine, download the latest Arch ISO and verify the signature: <https://archlinux.org/download/>. Write it to a USB with `dd if=archlinux-…iso of=/dev/sdX bs=4M status=progress conv=fsync` (replace `sdX` — get it wrong and you destroy a different drive).
2. Plug the USB in, power on the laptop, press `Esc` (boot menu key for this ASUS) and pick the USB.
3. At the GRUB-ish boot menu, choose **Arch Linux install medium (x86_64, UEFI)**. You land in a root shell on the live ISO.
4. Verify you are in UEFI mode: `ls /sys/firmware/efi/efivars` should list files (Arch Wiki: <https://wiki.archlinux.org/title/Installation_guide#Verify_the_boot_mode>).
5. Connect to Wi-Fi with `iwctl`:
   ```bash
   iwctl
   [iwd]# device list                 # note the device name, e.g. wlan0
   [iwd]# station wlan0 scan
   [iwd]# station wlan0 get-networks
   [iwd]# station wlan0 connect <SSID>
   [iwd]# exit
   ping -c 3 archlinux.org
   ```
   Arch Wiki: <https://wiki.archlinux.org/title/Iwd#iwctl>.
6. Update the system clock: `timedatectl set-ntp true`.

---

## 4 — Partition the disk

> **DESTRUCTIVE.** From here on, mistakes wipe data. **CONFIRM** the disk identity and the off-device backup with the human before each `mklabel`, `mkpart`, or `mkfs` command.

1. Identify the disk: `lsblk -f`. It should be `/dev/nvme0n1`. Confirm the existing Windows ESP (vfat, ~100 MB), MSR, Windows C: (NTFS, large), and unallocated space at the end.
2. Open `parted`:
   ```bash
   parted /dev/nvme0n1
   (parted) unit MiB
   (parted) print
   ```
   Note the **end** of the last Windows partition (call it `WIN_END`) and the **end of the disk** (call it `DISK_END`).
3. Inside the free space, create three new partitions in this order (numbering will continue from whatever Windows used):
   - **`/boot`** — vfat, 1024 MiB, type `EFI System Partition` *(keep the Windows ESP intact — Arch gets its own, much larger ESP so kernel + initramfs fit comfortably and `systemd-boot` can be installed there. Arch Wiki: <https://wiki.archlinux.org/title/EFI_system_partition#Typical_mount_points>)*.
   - **`swap`** — 16 GiB (matches current install: 16 GiB swap partition).
   - **`/`** — ext4, fill the rest.
   ```text
   (parted) mkpart "ARCH_ESP"   fat32  WIN_END         WIN_END+1024
   (parted) set    <N>          esp on
   (parted) mkpart "ARCH_SWAP"  linux-swap WIN_END+1024  WIN_END+1024+16384
   (parted) mkpart "ARCH_ROOT"  ext4   WIN_END+1024+16384  DISK_END
   (parted) print
   (parted) quit
   ```
4. Re-run `lsblk -f` — you should see two more `nvme0n1pX` partitions for `/boot` and `/` plus a swap.

> **CONFIRM** the new partition numbers with the human. They are needed verbatim in §5.

---

## 5 — Format and mount

Substitute the partition numbers from §4 step 4. Below assumes the *new* Arch ESP is `nvme0n1pA`, swap is `nvme0n1pB`, root is `nvme0n1pC`.

```bash
mkfs.fat -F32 -n ARCH_ESP /dev/nvme0n1pA
mkswap                    /dev/nvme0n1pB
mkfs.ext4                 /dev/nvme0n1pC

mount /dev/nvme0n1pC /mnt
mount --mkdir /dev/nvme0n1pA /mnt/boot
swapon /dev/nvme0n1pB
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

## 7 — Configure the new system (`arch-chroot`)

```bash
arch-chroot /mnt
```

Inside the chroot:

```bash
# Time zone
ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime
hwclock --systohc

# Locale — must match the live system exactly
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf

# Console keymap (intentionally left blank — Wayland session uses altgr-intl, not the console keymap)

# Hostname (matches the previous install)
echo 'AZBOOK14' > /etc/hostname
cat >>/etc/hosts <<'EOF'
127.0.0.1    localhost
::1          localhost
127.0.1.1    AZBOOK14.localdomain    AZBOOK14
EOF

# Root password
passwd
```

Arch Wiki: <https://wiki.archlinux.org/title/Installation_guide#Configure_the_system>.

### initramfs

The system uses early-KMS for NVIDIA. Replace `/etc/mkinitcpio.conf` MODULES line and rebuild:

```bash
sed -i 's|^MODULES=.*|MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)|' /etc/mkinitcpio.conf
# Verify HOOKS line (defaults are fine; reference value below):
# HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck)
mkinitcpio -P
```

*Note*: `nvidia-open-dkms` is installed later in §11 — until then `nvidia*` modules just won't load, which is fine, the system still boots on Intel graphics.

---

## 8 — Install and configure `systemd-boot` (dual boot)

Reference: <https://wiki.archlinux.org/title/Systemd-boot#Installation>.

```bash
bootctl install
```

This places `systemd-bootx64.efi` at `/boot/EFI/systemd/` and a fallback at `/boot/EFI/BOOT/BOOTX64.EFI`, and registers a `Linux Boot Manager` entry in NVRAM.

Write the loader config (matches the previous install exactly — see `boot/loader.conf` in this repo):

```bash
cat > /boot/loader/loader.conf <<'EOF'
default arch.conf
timeout 5
console-mode max
EOF
```

Write the Arch entry. **Replace `<ROOT_UUID>` with the UUID of the Arch root partition** (`blkid /dev/nvme0n1pC` — copy the `UUID=` value):

```bash
cat > /boot/loader/entries/arch.conf <<EOF
title Arch Linux
linux /vmlinuz-linux
initrd /intel-ucode.img
initrd /initramfs-linux.img
options root=UUID=<ROOT_UUID>
EOF
```

### Windows entry (the "EFI shell" trick)

The original install boots Windows via a tiny EFI shell script. Reference file: `boot/entries/windows.conf` in this repo. To replicate it you need two extra files on the Arch ESP:

1. The UEFI Shell binary at `/boot/tools/shellx64.efi`. Install via `pacman -S edk2-shell` (added in §11) and then `cp /usr/share/edk2-shell/x64/Shell.efi /boot/tools/shellx64.efi`.
2. A NSH script at `/boot/windows.nsh` that chainloads the Windows boot manager. Minimal content (let the shell autodetect the FS volume number):
   ```nsh
   @echo -off
   for %v in 0 1 2 3 4 5 6 7 8 9 A B C D E F
       if exist FS%v:\EFI\Microsoft\Boot\bootmgfw.efi then
           FS%v:\EFI\Microsoft\Boot\bootmgfw.efi
       endif
   endfor
   echo "Windows boot manager not found."
   ```
3. Write the entry:
   ```bash
   cat > /boot/loader/entries/windows.conf <<'EOF'
   title Windows 11
   efi /tools/shellx64.efi
   options -nointerrupt -noconsolein -noconsoleout windows.nsh
   EOF
   ```

   *Simpler alternative the agent should propose to the human*: skip the shell entirely and chainload Windows directly. Requires mounting the Windows ESP and copying `bootmgfw.efi`. The Arch Wiki "Boot loaders / systemd-boot / Windows" section documents both methods: <https://wiki.archlinux.org/title/Dual_boot_with_Windows#Configuring_the_bootloader>.

> **CONFIRM with the human** which Windows-entry method to use. The shell-script trick is what was working before; the direct-chainload is shorter but assumes the Windows ESP path stays at `/EFI/Microsoft/Boot/bootmgfw.efi`.

### Hostname/services that need to be enabled in chroot

```bash
systemctl enable NetworkManager.service
```

Exit the chroot and reboot:

```bash
exit            # leave arch-chroot
umount -R /mnt
swapoff -a
reboot          # remove the USB during POST
```

---

## 9 — First reboot into Arch and create the user

1. The systemd-boot menu should now offer **Arch Linux** (default) and **Windows 11**. Boot Arch.
2. Log in as `root`.
3. Create the user (UID 1000, default shell `zsh`, primary group `david`):
   ```bash
   useradd -m -G wheel,video,audio,storage,input,network -s /bin/zsh david
   passwd david
   EDITOR=nano visudo    # uncomment %wheel ALL=(ALL:ALL) ALL
   ```
4. Reboot, log in as `david` on tty1.

---

## 10 — Networking, AUR helper, dotfiles

```bash
nmcli device wifi connect <SSID> password <PASS>   # human types
sudo pacman -Syu

# git via SSH won't work yet (no SSH key) — clone over HTTPS for now,
# we will switch the remote to SSH after §14 + §15.
mkdir -p ~/github && cd ~/github
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

```bash
sudo cp -r sddm/themes/* /usr/share/sddm/themes/        # if dotfiles ships themes
sudo systemctl enable sddm.service
```

### Services to enable

System-wide (from `services/services-system.txt`):

```bash
sudo systemctl enable bluetooth.service docker.service NetworkManager.service \
                      sddm.service supergfxd.service systemd-timesyncd.service \
                      waydroid-docker-fix.service
```

User-level (from `services/services-user.txt`):

```bash
systemctl --user enable pipewire.socket pipewire-pulse.socket wireplumber.service \
                        xdg-user-dirs.service archy.service
```

### NVIDIA hybrid (Intel + NVIDIA) notes

- `nvidia-open-dkms` was the kernel module flavour in use. With `linux-headers` installed, the DKMS module rebuilds automatically. Verify: `dkms status`.
- `supergfxctl` handles GPU mode switching (Hybrid/Integrated/dGPU). The shipped `supergfxd.conf` already has `mode: Hybrid` and `hotplug_type: Asus`.
- Wayland on hybrid NVIDIA: `nvidia_drm.modeset=1` is mandatory. It's set implicitly by adding `nvidia_drm` to `MODULES=` in `mkinitcpio.conf` *with* the `KMS` hook (already configured) — the modeset flag is the default in the open driver. Arch Wiki: <https://wiki.archlinux.org/title/NVIDIA#DRM_kernel_mode_setting>.

### ASUS-specific

```bash
sudo pacman -S --needed asusctl supergfxctl    # already in .installed_programs
```

If `asusctl` is not in the official repos at the time of restore, `yay -S asusctl` builds it from AUR.

---

## 14 — Restore SSH, GPG, secrets, browser data

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

### Browser data

For Chrome/Brave/Firefox/Vivaldi/Edge/Opera, the recommended path is to sign in and let cloud sync restore bookmarks, history, and (in browsers that support it) passwords. Then install the extensions from the screenshot taken in §0. **Bitwarden is not installed**: passwords either live in browser sync or in the off-device backup as a Bitwarden export — confirm with the human which one.

### Restore `~/.claude/` (sessions, memory, plugins, MCP, credentials)

```bash
rsync -a /run/media/david/<USB>/claude-backup/ ~/.claude/
# OR: tar -xf claude-backup.tar.zst -C ~/
chmod 600 ~/.claude/.credentials.json 2>/dev/null
ls ~/.claude/projects/ | head
```

After that, opening `claude` in any of the restored project directories should resume with full memory + session history. Plugins under `~/.claude/plugins/` come back with the same `rsync`.

### Restore skills (`~/.claude/skills/`)

The canonical copy of user-authored skills lives in this repo at `skills/`. Restore the same layout that Archy and Claude Code both expect: real directories under `~/.claude/skills/user/`, with a top-level symlink per skill so Claude Code can find them.

```bash
mkdir -p ~/.claude/skills/user ~/.claude/skills/agent
# Copy each skill into the canonical user/ dir
for s in ~/github/dotfiles/skills/*/; do
    name=$(basename "$s")
    cp -r "$s" ~/.claude/skills/user/"$name"
    ln -snf ~/.claude/skills/user/"$name" ~/.claude/skills/"$name"
done
# Make ~/.config/archy/skills share the same library (matches the previous setup)
mkdir -p ~/.config/archy
ln -snf ~/.claude/skills ~/.config/archy/skills
ls ~/.claude/skills/
```

The `~/.claude/skills/agent/` directory is intentionally **not** in the repo — it's Archy's mutable scratch space. Archy will populate it on demand.

### Restore Archy's CLAUDE.md and `archy.toml`

```bash
mkdir -p ~/.config/archy/memory
ln -snf ~/github/dotfiles/archy/CLAUDE.md  ~/.config/archy/CLAUDE.md
cp        ~/github/dotfiles/archy/archy.toml ~/.config/archy/archy.toml
# memory/ stays local and is restored from the off-device backup if it had any notes
```

`CLAUDE.md` is symlinked (so future edits land in this repo); `archy.toml` is copied (it gets edited by `archy` itself when models or paths change, and you don't want those edits leaking into the public repo).

---

## 15 — Install personal certificates (`.p12`)

The Spanish FNMT-style `.p12` certificates restored in §0 to `~/certificates/` (e.g. `certificado-salvi.p12`, `certificado-v2.p12`, `certificadoDavid.p12`) need to be imported into each browser/store that uses them. They are *not* TLS server certs — they are client/personal certs used to sign documents and authenticate to AEAT, Seguridad Social, DGT, university portals, etc. Reference: <https://wiki.archlinux.org/title/User:Grawity/Importing_personal_certificates>.

> **Never** add a personal `.p12` to the system-wide trust store (`/etc/ca-certificates/trust-source/`). That trust store is for **issuers** of certificates, not for personal end-entity certs. Putting yours there does nothing useful and weakens trust validation.

### 15.A  Firefox / Thunderbird (NSS database)

GUI path:

1. Open Firefox → `about:preferences#privacy` → scroll to **Certificates** → **View Certificates…** → tab **Your Certificates** → **Import…**
2. Pick a `.p12` from `~/certificates/`, type the export password (the one set when the cert was originally issued).
3. Repeat for each cert. They appear under the issuer (FNMT-RCM, etc.).

CLI path (`pacman -S nss`):

```bash
certutil -d sql:$HOME/.mozilla/firefox/<profile>.default-release -L      # list
pk12util -i ~/certificates/certificado-salvi.p12 \
         -d sql:$HOME/.mozilla/firefox/<profile>.default-release
```

`pk12util` will prompt for the `.p12` password, then the NSS DB password (Firefox's "Master Password" — leave empty if you never set one).

### 15.B  Chromium-based browsers (Chrome, Brave, Edge, Opera, Vivaldi)

All Chromium browsers on Linux share **one** NSS database at `~/.pki/nssdb`. Import once, every Chromium browser sees it.

```bash
mkdir -p ~/.pki/nssdb
certutil -d sql:$HOME/.pki/nssdb -N --empty-password    # first time only
pk12util -i ~/certificates/certificado-salvi.p12 -d sql:$HOME/.pki/nssdb
pk12util -i ~/certificates/certificado-v2.p12    -d sql:$HOME/.pki/nssdb
pk12util -i ~/certificates/certificadoDavid.p12  -d sql:$HOME/.pki/nssdb
certutil -d sql:$HOME/.pki/nssdb -L                     # verify
```

Then in Chrome/Brave: `chrome://settings/certificates` → tab **Your Certificates** — the imported certs are listed.

> **Gotcha**: snap- or flatpak-packaged Chromiums use a sandboxed home and **don't** see `~/.pki`. Install Chromium-family browsers from pacman/AUR so this import path keeps working.

### 15.C  GUI tools that look at GNOME keyring (Evolution, etc.)

If any GNOME app needs the certs, use Seahorse:

```bash
sudo pacman -S seahorse gnome-keyring
seahorse &       # File → Import… → pick .p12
```

### 15.D  Tighten permissions

```bash
chmod 700 ~/certificates
chmod 600 ~/certificates/*.p12
```

The off-device backup keeps the canonical copy; the local `~/certificates/` is just for the next import after a future re-install.

---

## 16 — Set up the homeserver SSH key pair (hermo.dev)

Goal: be able to `ssh hermo.dev` from this laptop without typing a password. The phone already has a public key registered on the server (mentioned by the human), so the strategy is **generate a new pair on the laptop and add the public half via the phone's existing access**, *not* recover the old `id_rsa` (which already comes back as part of §14 anyway — this section is for setting up a *new* key if the user wants one per device, which is the cleaner pattern).

Skip this entire section if `ssh hermo.dev` already works after §14 — that means the restored `~/.ssh/id_rsa` is the same key the server still trusts.

1. Generate a new key, ed25519, no passphrase if used by scripts (the human decides):
   ```bash
   ssh-keygen -t ed25519 -C "david@azbook14-$(date +%Y%m%d)" -f ~/.ssh/id_ed25519_hermo
   ```
2. Add `~/.ssh/config` block so the new key is picked automatically:
   ```sshconfig
   Host hermo.dev
       HostName hermo.dev
       User server
       Port 45811
       IdentityFile ~/.ssh/id_ed25519_hermo
       IdentitiesOnly yes
   ```
   (Replace the existing `Host hermo.dev` block from the restored `config`. The repo has the canonical block in `.ssh/config` — but since `.ssh/` is *not* in this repo, the human edits it manually.)
3. **From the phone** (which already has access), SSH into the server and append the new pubkey:
   ```bash
   # on the phone, in Termux or equivalent
   cat | ssh -p 45811 server@hermo.dev 'cat >> ~/.ssh/authorized_keys'
   # then paste the contents of id_ed25519_hermo.pub from the laptop (cat'd to screen,
   # transcribed, or shared via a one-shot link)
   ```
   Alternative path if the phone has `scp`: `scp id_ed25519_hermo.pub` to the phone first, then `cat .../id_ed25519_hermo.pub | ssh ... 'cat >> ~/.ssh/authorized_keys'`.
4. Test from the laptop: `ssh hermo.dev whoami` → should print `server` without prompting for a password.
5. Once verified, **optionally** revoke the old key by editing `~/.ssh/authorized_keys` on hermo.dev and removing the `david@Lenovo-Legion`-tagged line (that's the very old laptop's key). Do this *after* both phone and laptop access are confirmed.

References:
- Arch Wiki SSH keys: <https://wiki.archlinux.org/title/SSH_keys>
- `authorized_keys` format: <https://wiki.archlinux.org/title/OpenSSH#authorized_keys>

---

## 17 — Final reboot and verification

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

## 18 — Things to remember after everything works

- **Claude Code conversations are local.** `~/.claude/projects/*/sessions/*.jsonl` is the only copy. Anything saved in `~/.claude/projects/-home-david-github-dotfiles/memory/MEMORY.md` and friends is also local. If they weren't restored from the off-device backup in §14, they are gone forever — there is no cloud copy. Anthropic does keep usage telemetry but **not the message contents**.
- **The Windows partition seen at `/mnt` was wiped** by ASUS. Anything that was only in `/mnt/Users/david/{Desktop,Documents,Pictures,Downloads,OneDrive,Music,Videos}` and not in the off-device backup is gone. Specifically the certificate `certificadoDavid.p12` and `github-recovery-codes.txt` — both flagged in §0.
- **Re-add the new laptop's SSH/GPG key to GitHub**: <https://github.com/settings/keys>. If §14 restored the previous key it's already there; if §15 generated a fresh one for this device, add the new pubkey now.
- **2FA recovery codes**: regenerate them on Github/Google/etc. after first sign-in, and store the new codes off-device.
- **Update Wi-Fi passwords**: `nmcli` configs live at `/etc/NetworkManager/system-connections/` and are *not* in this repo (they contain passwords). The human will re-enter them per network.
- **Reapply gtheme periodically** if you change desktops/themes: `gtheme update && gtheme desktop apply hypr && gtheme theme apply <name>`. The configs under `~/.config/{hypr,waybar,quickshell,…}/` are owned by gtheme and may get rewritten by it.
- **Refresh `.installed_programs` periodically**:
  ```bash
  pacman -Qqe | sort > ~/github/dotfiles/.installed_programs
  ```
  This single list covers both official-repo and AUR packages; `yay` resolves both transparently on restore.
- **Things deliberately NOT in this repo (and never should be)**: `~/.ssh/id_rsa`, `~/.gnupg/`, `~/.secrets`, `~/.config/gh/hosts.yml`, `/etc/NetworkManager/system-connections/`, browser profiles. Keep them in the off-device backup.

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

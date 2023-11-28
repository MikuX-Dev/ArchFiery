#!/usr/bin/env bash

clear

DOT="$SKEL/.dotfiles"
SKEL="/etc/skel"
US="/usr/share"

# RED=$(tput setaf 1)         # Red
# GREEN=$(tput setaf 2)       # Green
# YELLOW=$(tput setaf 3)      # Yellow
# BLUE=$(tput setaf 4)        # Blue
# MAGENTA=$(tput setaf 5)     # Magenta
# CYAN=$(tput setaf 6)        # Cyan
# WHITE=$(tput setaf 7)       # White
# RESET=$(tput sgr0)          # Text reset

# Start
echo -ne "
╭─────── ArchFiery ───────╮
│  Installation starting  │
│       so sit back       │
│         relax           │
│       and enjoy         │
╰─────────────────────────╯
"
echo "Arch Linux Fast Install (ArchFiery) - Version: 2023.11.26 (GPL-3.0)"
sleep 6s
printf "\n"
echo "Installation guide starts now..."
sleep 6s
clear

# install package
echo "Installing needed packages..."
pacman -Syy reflector rsync curl archlinux-keyring --noconfirm
sleep 6s
clear

# Installing fastest mirrors
read -p "Do you want fastest mirrors? [Y/n] " fm
if [[ $fm =~ ^[Yy]$ ]]; then
  echo "Installing fastest mirrorlists"
  printf "\n"
  # Backup mirrorlist
  echo "Backingup mirrorlists"
  cp -r /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
  # Archlinux mirrorlists
  printf "\n"
  echo "Archlinux-mirrorlist setup"
  reflector --verbose -l 22 -f 22 -p https --download-timeout 55 --sort rate --save /etc/pacman.d/mirrorlist
  pacman -Syy
else
  printf "\n"
  echo "Skipping the fastert mirrorlist"
fi
sleep 6s
clear

# Setting up system clock
echo "Ensuring if the system clock is accurate."
timedatectl set-ntp true
sleep 6s
clear

# Function to prompt user for input with default value
function prompt {
  read -p "$1 [$2]: " input
  echo "${input:-$2}"
}

# Display available drives
lsblk
printf "\n"
drive=$(prompt "Enter the drive to install Arch Linux on it. (/dev/...)" "/dev/sda")
sleep 2s
clear

# Choose disk utility tool
echo "Choose a familiar disk utility tool to partition your drive:"
echo "  1. fdisk"
echo "  2. cfdisk"
echo "  3. gdisk"
echo "  4. parted"
read -r partitionutility

case "${partitionutility,,}" in
1 | fdisk)
  partitionutility="fdisk"
  ;;
2 | cfdisk)
  partitionutility="cfdisk"
  ;;
3 | gdisk)
  partitionutility="gdisk"
  ;;
4 | parted)
  partitionutility="parted"
  ;;
*)
  echo "Unknown or unsupported disk utility! Default = cfdisk."
  partitionutility="cfdisk"
  ;;
esac
echo "$partitionutility is the selected disk utility tool for partition."
sleep 3s
clear

# Creating partitions
echo "Getting ready for creating partitions!"
echo "Root and boot partitions are mandatory."
echo "Home and swap partitions are optional but recommended!"
echo "You can also create a separate partition for timeshift backup (optional)!"
echo "Getting ready in 9 seconds"
sleep 9s
"$partitionutility" "$drive"
clear

# Choose filesystem type
echo "Boot partition will be formatted in fat32 file system type."
echo "Choose your Linux file system type for formatting drives:"
echo "  1. ext4"
echo "  2. xfs"
echo "  3. btrfs"
echo "  4. f2fs"
read -r filesystemtype

case "${filesystemtype,,}" in
1 | ext4)
  filesystemtype="ext4"
  ;;
2 | xfs)
  filesystemtype="xfs"
  ;;
3 | btrfs)
  filesystemtype="btrfs"
  ;;
4 | f2fs)
  filesystemtype="f2fs"
  ;;
*)
  echo "Unknown or unsupported filesystem. Default = ext4."
  filesystemtype="ext4"
  ;;
esac
echo "$filesystemtype is the selected file system type."
sleep 3s
clear

# Formatting drives
echo "Getting ready for formatting drives."
sleep 3s
printf "\n"
lsblk
printf "\n"
rootpartition=$(prompt "Enter the root partition (e.g., /dev/sda*): ")
mkfs."$filesystemtype" "$rootpartition"
mount "$rootpartition" /mnt
clear

# Create separate home partition
lsblk
printf "\n"
read -rp "Did you also create a separate home partition? [y/n]: " answerhome
case "${answerhome,,}" in
y | yes)
  homepartition=$(prompt "Enter home partition (e.g., /dev/sda*): ")
  mkfs."$filesystemtype" "$homepartition"
  mkdir /mnt/home
  mount "$homepartition" /mnt/home
  ;;
*)
  echo "Skipping home partition!"
  ;;
esac
clear

# Create swap partition
lsblk
printf "\n"
read -rp "Did you also create a swap partition? [y/n]: " answerswap
case "${answerswap,,}" in
y | yes)
  swappartition=$(prompt "Enter swap partition (e.g., /dev/sda*): ")
  mkswap "$swappartition"
  swapon "$swappartition"
  ;;
*)
  echo "Skipping swap partition!"
  ;;
esac
clear

# Format boot partition
lsblk
printf "\n"
answerefi=$(prompt "Enter the EFI partition. (e.g., /dev/sda*): ")
mkfs.fat -F 32 "$answerefi"
clear

sync
printf "\n"
lsblk
sleep 6s
clear

# Installing base system
pacstrap /mnt base base-devel linux linux-firmware linux-headers grub os-prober efibootmgr
sleep 6s
clear

# Setting boot partition "EFI"
lsblk
printf "\n"
echo "Mounting the EFI partition to '/mnt/boot/efi'"
efidirectory="/mnt/boot/efi/"
if [ ! -d "$efidirectory" ]; then
  mkdir -p "$efidirectory"
fi
mount "$answerefi" "$efidirectory"
sleep 6s
clear

# Install grub
echo "Installing grub bootloader in /boot/efi parttiton with 'os_prober' enabled"
sed -i 's/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/g' /etc/default/grub
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --recheck
grub-mkconfig -o /boot/grub/grub.cfg
os-prober
grub-mkconfig -o /boot/grub/grub.cfg
sleep 6s
clear

# Gen fstab
echo "Generating fstab file"
printf "\n"
genfstab -U /mnt >>/mnt/etc/fstab
cat /mnt/etc/fstab
sleep 6s
clear

# Setup for post-installation
sed '1,/^#part2$/d' test.sh >/mnt/post_install.sh
chmod +x /mnt/post_install.sh
arch-chroot /mnt ./post_install.sh
clear
sleep 6s

# Gen fstab
echo "Generating fstab file"
printf "\n"
genfstab -U /mnt >>/mnt/etc/fstab
cat /mnt/etc/fstab
sleep 6s
clear

# Unmount drives
echo "unmounting all the drives"
printf "\n"
umount -R /mnt
sleep 6s
clear

echo -ne "
╭─────── ArchFiery ───────╮
│       Installation      │
│        completed        │
│    rebooting in 19s     │
╰─────────────────────────╯
"
printf "\n"
echo "Installation Finished. REBOOTING IN 19 SECONDS!!!"
sleep 19s
reboot

#part2

# starting post_install
echo -ne "
╭─────── ArchFiery ───────╮
│      post_install       │
│     starting in 9s      │
╰─────────────────────────╯
"
sleep 9s
clear

# install package
echo "Installing needed packages..."
pacman -Syy reflector rsync curl archlinux-keyring --noconfirm
sleep 6s
clear

# Check if multilib and community repositories are enabled
echo "Enabling multilib and community repositories"
if grep -E '^\[multilib\]|^\[community\]' /etc/pacman.conf; then
  # Repositories are already enabled, remove any commented-out lines
  sed -i '/^\[community\]/,/^\[/ s/^#//' /etc/pacman.conf
  sed -i '/^\[multilib\]/,/^\[/ s/^#//' /etc/pacman.conf
else
  # Repositories are not enabled, add them
  echo -e "\n[community]\nInclude = /etc/pacman.d/mirrorlist\n\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" >>/etc/pacman.conf
fi
sleep 6s
clear

# Setting up pacman
echo "Setting up pacman"
sed -i 's/#Color/Color/g' /etc/pacman.conf
sudo sed -i 's/#ParallelDownloads = 5/#ParallelDownloads = 5\nILoveCandy/' /etc/pacman.conf
sleep 6s
clear

# Installing fastest mirrors
read -p "Do you want fastest mirrors? [Y/n] " fm
if [[ $fm =~ ^[Yy]$ ]]; then
  echo "Installing fastest mirrorlists"
  # Backup mirrorlist
  echo "Backingup mirrorlists"
  cp -r /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
  # Archlinux mirrorlists
  echo "Archlinux-mirrorlist setup"
  reflector --verbose -l 22 -f 22 -p https --download-timeout 55 --sort rate --save /etc/pacman.d/mirrorlist
  pacman -Syy
else
  echo "Skipping the fastert mirrorlist"
fi
sleep 6s
clear

# Replace Asia/kolkata with your timezone
echo "Setting timezone"
ln -sf $US/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc
sleep 6s
clear

# Gen locale
echo "Generating locale"
sed -i "s/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g" /etc/locale.gen
locale-gen
sleep 6s
clear

# Setting lang
echo "Setting LANG variable"
echo "LANG=en_US.UTF-8" >/etc/locale.conf
sleep 6s
clear

# Setting console keyboard
echo "Setting console keyboard layout"
echo 'KEYMAP=us' >/etc/vconsole.conf
sleep 6s
clear

# Setup hostname
echo "Set up your hostname!"
read -p "Enter your computer name: " hostname
echo "$hostname" >/etc/hostname
printf "\n"
echo "Checking hostname (/etc/hostname)"
printf "\n"
cat /etc/hostname
sleep 6s
clear

# Setting up hosts
echo "Setting up hosts file"
printf "\n"
{
  echo "127.0.0.1       localhost"
  echo "::1             localhost"
  echo "127.0.1.1       $hostname.localdomain $hostname"
} >>/etc/hosts
cat /etc/hosts
sleep 6s
clear

# Install pkgs and tools by PACMAN..
echo "Installing pkgs and tools by PACMAN.."
printf "\n"
sleep 6s

# Determine processor type and install microcode
determine_processor_type() {
  local proc_type
  proc_type=$(lscpu)
  if grep -qE "GenuineIntel" <<<"${proc_type}"; then
    echo "Installing Intel microcode"
    package+=(intel-ucode)
  elif grep -qE "AuthenticAMD" <<<"${proc_type}"; then
    echo "Installing AMD microcode"
    package+=(amd-ucode)
  fi
}

# Determine graphics card type and build package list
determine_graphics_card_type() {
  local gpu_type
  gpu_type=$(lspci)
  if grep -qE "NVIDIA|GeForce" <<<"${gpu_type}"; then
    echo "Installing NVIDIA drivers..."
    package+=(nvidia nvidia-utils)
  elif lspci | grep -qE "Radeon|AMD"; then
    echo "Installing AMD drivers..."
    package+=(xf86-video-amdgpu)
  elif grep -qE "Integrated Graphics Controller" <<<"${gpu_type}"; then
    echo "Installing integrated Graphics Controller"
    package+=(libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils libva-mesa-driver mesa lib32-mesa mesa-amber lib32-mesa-amber intel-media-driver)
  elif grep -qE "Intel Corporation UHD" <<<"${gpu_type}"; then
    echo "Installing Intel UHD Graphics"
    package+=(libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils libva-mesa-driver mesa lib32-mesa mesa-amber lib32-mesa-amber intel-media-driver)
  else
    echo "Installing generic drivers..."
    package+=(virtualbox-host-modules-arch xf86-input-vmmouse open-vm-tools xf86-video-vmware virtualbox-guest-utils libvirt virt-manager)
  fi
}

# Main script
package=("ack" "acpi" "adobe-source-sans-pro-fonts" "alacritty" "alsa-utils" "amd-ucode" "android-file-transfer" "android-tools" "apache" "arch-install-scripts" "arch-wiki-docs" "archinstall" "archiso" "atftp" "autoconf" "automake" "autorandr" "avahi" "awesome-terminal-fonts" "b43-fwcutter" "base" "base-devel" "bash" "bash-completion" "bc" "bind" "bind-tools" "bison" "blueman" "bluez" "bluez-libs" "bluez-plugins" "bluez-tools" "bluez-utils" "bolt" "boost" "boost-libs" "bridge-utils" "brightnessctl" "brltty" "broadcom-wl" "btrfs-progs" "bzip2" "bzip3" "cargo" "ccache" "cifs-utils" "clang" "clonezilla" "cloud-init" "cmake" "conky" "cpupower" "crda" "cronie" "cryptsetup" "ctags" "cups" "cups-filters" "cups-pdf" "curl" "darkhttpd" "ddrescue" "devtools" "dex" "dhclient" "dhcpcd" "dialog" "diffutils" "dmidecode" "dmraid" "dnscrypt-proxy" "dnsmasq" "dnsutils" "docker" "docker-buildx" "docker-compose" "docker-machine" "dolphin" "dolphin-plugins" "dosfstools" "e2fsprogs" "edk2-shell" "efibootmgr" "espeakup" "ethtool" "exa" "exfatprogs" "expac" "eza" "f2fs-tools" "fakeroot" "fatresize" "fd" "feh" "ffmpeg" "ffmpegthumbnailer" "firefox" "flameshot" "flex" "foomatic-db" "foomatic-db-engine" "foot-terminfo" "fsarchiver" "fwbuilder" "gammu" "gawk" "gcc" "gcc-libs" "gdb" "ghostscript" "git" "git-lfs" "gnome-keyring" "gnu-netcat" "gnupg" "go" "gpart" "gparted" "gpm" "gptfdisk" "grub" "grub-customizer" "gsfonts" "gst-libav" "gst-plugins-bad" "gst-plugins-good" "gst-plugins-ugly" "gstreamer" "gtk-update-icon-cache" "gufw" "gutenprint" "gvfs" "gvfs-afc" "gvfs-google" "gvfs-gphoto2" "gvfs-mtp" "gvfs-smb" "gzip" "haveged" "hdparm" "helix" "highlight" "htop" "hyperv" "inotify-tools" "intel-ucode" "ipython" "irqbalance" "irssi" "iw" "iwd" "jasper" "jfsutils" "kdeconnect" "kitty-terminfo" "kvantum" "less" "lftp" "libavif" "libde265" "libdv" "libfido2" "libheif" "libmpeg2" "libreoffice-fresh" "libtheora" "libusb-compat" "libvpx" "libwebp" "libx11" "libxext" "libxinerama" "lightdm" "lightdm-gtk-greeter" "lightdm-gtk-greeter-settings" "lightdm-webkit2-greeter" "linux" "linux-atm" "linux-firmware" "linux-firmware-marvell" "linux-headers" "llvm" "logrotate" "lrzip" "lsb-release" "lsof" "lsscsi" "lua" "lvm2" "lynx" "lz4" "lzip" "lzop" "make" "man-db" "man-pages" "mc" "mdadm" "memtest86+" "memtest86+-efi" "menumaker" "mercurial" "mesa" "mkinitcpio" "mkinitcpio-archiso" "mkinitcpio-nfs-utils" "mobile-broadband-provider-info" "modemmanager" "moreutils" "most" "mousepad" "mousetweaks" "mpv" "mtools" "nano" "nbd" "ncdu" "ndisc6" "neovim" "net-tools" "nethogs" "network-manager-applet" "network-manager-sstp" "networkmanager" "networkmanager-l2tp" "networkmanager-openconnect" "networkmanager-openvpn" "networkmanager-pptp" "networkmanager-strongswan" "networkmanager-vpnc" "nfs-utils" "nilfs-utils" "nm-cloud-setup" "nm-connection-editor" "nmap" "npm" "nss-mdns" "ntfs-3g" "ntp" "numlockx" "nvme-cli" "open-iscsi" "openconnect" "openldap" "openpgp-card-tools" "openssh" "openvpn" "os-prober" "otf-libertinus" "p7zip" "pacman-contrib" "parole" "partclone" "parted" "partimage" "patch" "pavucontrol" "pcsclite" "perl" "picom" "pkgconf" "pkgfile" "plocate" "plymouth" "power-profiles-daemon" "powertop" "ppp" "pptpclient" "profile-sync-daemon" "pulseaudio-alsa" "pulseaudio-bluetooth" "pulseaudio-equalizer" "pulsemixer" "python-docker" "qt5-tools" "qt5ct" "ranger" "reflector" "reiserfsprogs" "rfkill" "ristretto" "rofi" "rofi-emoji" "rp-pppoe" "rsync" "rtorrent" "ruby" "rustup" "rxvt-unicode-terminfo" "schroedinger" "screen" "scrot" "sdparm" "sed" "sequoia-sq" "sg3_utils" "smartmontools" "smbclient" "socat" "sof-firmware" "squashfs-tools" "strace" "sudo" "syncthing" "syslinux" "systemd-resolvconf" "tar" "tcpdump" "terminus-font" "testdisk" "tex-gyre-fonts" "thermald" "thunar-archive-plugin" "thunar-media-tags-plugin" "thunar-volman" "thunderbird" "timeshift" "tldr" "tmux" "tor" "tpm2-tools" "tpm2-tss" "traceroute" "trash-cli" "tree" "ttf-fira-code" "ttf-hack-nerd" "ttf-jetbrains-mono-nerd" "ttf-ubuntu-font-family" "tumbler" "udftools" "udisks2" "ueberzug" "ufw" "unace" "unarchiver" "unrar" "unzip" "upower" "usb_modeswitch" "usbmuxd" "usbutils" "vim" "virtualbox" "virtualbox-ext-vnc" "virtualbox-guest-iso" "virtualbox-guest-utils" "virtualbox-host-modules-arch" "vlc" "vpnc" "webkit2gtk" "wezterm-terminfo" "wget" "wireguard-tools" "wireless_tools" "wireless-regdb" "wireplumber" "wpa_supplicant" "wvdial" "x264" "x265" "xarchiver" "xclip" "xcompmgr" "xdg-desktop-portal-gtk" "xdg-desktop-portal-xapp" "xdg-user-dirs" "xdg-user-dirs-gtk" "xdotool" "xfburn" "xfce4" "xfce4-battery-plugin" "xfce4-clipman-plugin" "xfce4-cpufreq-plugin" "xfce4-cpugraph-plugin" "xfce4-dict" "xfce4-diskperf-plugin" "xfce4-eyes-plugin" "xfce4-fsguard-plugin" "xfce4-genmon-plugin" "xfce4-goodies" "xfce4-mount-plugin" "xfce4-mpc-plugin" "xfce4-netload-plugin" "xfce4-notes-plugin" "xfce4-notifyd" "xfce4-power-manager" "xfce4-pulseaudio-plugin" "xfce4-screensaver" "xfce4-screenshooter" "xfce4-sensors-plugin" "xfce4-smartbookmark-plugin" "xfce4-systemload-plugin" "xfce4-taskmanager" "xfce4-time-out-plugin" "xfce4-timer-plugin" "xfce4-verve-plugin" "xfce4-wavelan-plugin" "xfce4-weather-plugin" "xfce4-whiskermenu-plugin" "xfce4-xkb-plugin" "xfsprogs" "xl2tpd" "xmlto" "xorg" "xorg-apps" "xorg-server" "xorg-xinit" "xsensors" "xvidcore" "xz" "yaml-cpp" "zip" "zsh" "zsh-autosuggestions" "zsh-completions" "zsh-history-substring-search" "zsh-syntax-highlighting" "zstd")

determine_processor_type
determine_graphics_card_type

package+=("${package[@]}")

# Install the determined packages
pacman -S --noconfirm --needed "${package[@]}"
sleep 6s
clear

# Install pkgs from yay-bin
echo "Installing pkgs from yay-bin"

aurpackages="airdroid-nativefier android-sdk-platform-tools appmenu-gtk-module-git appmenu-qt4 bluez-firmware brave-bin caffeine-ng dolphin-megasync-bin downgrade eww-x11 fancontrol-gui firebuild gtk3-nocsd-git libdbusmenu-glib libdbusmenu-gtk2 libdbusmenu-gtk3 mkinitcpio-firmware mkinitcpio-numlock mugshot nbfc obsidian-bin ocs-url portmaster-stub-bin repoctl rtl8821ce-dkms-git rtw89-dkms-git stacer-bin tela-icon-theme thunar-extended thunar-megasync-bin thunar-secure-delete thunar-shares-plugin thunar-vcs-plugin universal-android-debloater-bin vala-panel-appmenu-common-git vala-panel-appmenu-registrar-git vala-panel-appmenu-xfce-git visual-studio-code-bin xfce4-docklike-plugin xfce4-panel-profiles zsh-theme-powerlevel10k-git yay-bin"

# for pkgaur in $aurpackages; do
#   echo "Installing $pkgaur"
#   git clone https://aur.archlinux.org/"$pkgaur"
#   cd "$pkgaur" || exit
#   makepkg -si --skippgpcheck --noconfirm --needed
#   cd .. || exit
#   rm -rf "$pkgaur"
# done
# sleep 3s

git clone https://aur.archlinux.org/pikaur.git $SKEL/aur-pkg/pikaur
cd $SKEL/aur-pkg/pikaur || exit
makepkg -fsri --skippgpcheck --noconfirm --needed
cd - || exit

pikaur -S --needed --noconfirm "$aurpackages"

# Setting root user
echo "Enter password for root user: "
passwd
sleep 6s
clear

# Setting regular user
echo "Adding regular user!"
printf "\n"
read -p "Enter username to add a regular user: " username
useradd -m -G wheel -s /bin/zsh "$username"
echo "Enter password for '$username': "
passwd "$username"
sleep 6s
clear

# Adding sudo privileges to the user you created
echo "NOTE: ALWAYS REMEMBER THIS USERNAME AND PASSWORD YOU PUT JUST NOW."
printf "\n"
sleep 6s
echo "Giving sudo access to '$username'!"
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/g' /etc/sudoers
clear
sleep 6s

# Editing sudo
echo 'Defaults env_keep += "HOME"' | tee -a /etc/sudoers
sleep 6s
clear

# Personal dotfiles
echo "Setting up Personal dotfiles"
git clone https://github.com/MikuX-Dev/dotfiles.git "$DOT"
sleep 6s
clear

# Creating folder first
echo "Creating folder's..."
mkdir -p /root/bin/
mkdir -p $SKEL/bin/
mkdir -p $SKEL/.config/
mkdir -p $SKEL/.local/share/
mkdir -p $US/lightdm-webkit/themes/glorious
sleep 6s
clear

printf "\n"
echo "Setting up shell"
# $ROOTUSER
git clone https://github.com/ohmyzsh/ohmyzsh.git /root/.oh-my-zsh
cp -r "$DOT"/shell/zsh/* /root/
cp -r "$DOT"/shell/p-script/* /root/bin/
chsh -s /bin/zsh root

# $user
git clone https://github.com/ohmyzsh/ohmyzsh.git $SKEL/.oh-my-zsh
cp -r "$DOT"/shell/zsh/* $SKEL/
# $user shell changed to zsh
cp -r "$DOT"/shell/p-script/* $SKEL/bin/
# cp -r "$DOT"/shell/
sleep 6s
clear

# Setting up configuration's
echo "Setting up config's"
cp -r "$DOT"/config/* $SKEL/.config/
cp -r "$DOT"/local/share/* $SKEL/.local/share/
sleep 6s
clear

# Setup rofi
echo "Setting up rofi"
git clone https://github.com/adi1090x/rofi.git
cd rofi || exit
chmod +x setup.sh
./setup.sh
cd - || exit

echo "Check https://github.com/adi1090x/rofi.git for more information" >$SKEL/rofi.txt

# Setting up themes
echo "Setting up themes..."
cp -r "$DOT"/themes/themes/* $US/themes/
cp -r "$DOT"/themes/icons/* $US/icons/
cp -r "$DOT"/themes/plymouth/* $US/plymouth/themes/
cp -r "$DOT"/wallpaper/* $US/backgrounds/
# wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf $US/fonts/
# Download and install nerd-fonts
fonts_url="https://github.com/ryanoasis/nerd-fonts/releases/latest"
font_files=("CascadiaCode.tar.xz" "Noto.tar.xz" "JetBrainsMono.tar.xz" "Meslo.tar.xz")
font_file_names=("CascadiaCode" "Noto" "JetBrainsMono" "Meslo")
for ((i = 0; i < ${#font_files[@]}; i++)); do
  font_file=${font_files[i]}
  font_name=${font_file_names[i]}
  font_url=$(curl -sL ${fonts_url} | grep -o -E "https://.*${font_file}")
  # Create a folder with the font name
  mkdir -p "${font_name}"
  # Download and extract the font
  curl -L -o "${font_file}" "${font_url}"
  tar -xvf "${font_file}" -C "${font_name}"
  rm "${font_file}"
  # Move the font folder to /usr/share/fonts/
  mv "${font_name}" $US/fonts/
done
sleep 6s
clear

# Configure plymouth
echo "Configuring plymouth"
sed -i 's/^HOOKS=.*/HOOKS=(base udev plymouth autodetect modconf kms keyboard keymap consolefont block filesystems fsck)/' /etc/mkinitcpio.conf
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet"/GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet splash udev.log_level=3 vt.global_cursor_default=0"/g' /etc/default/grub
mkinitcpio -p linux
grub-mkconfig -o /boot/grub/grub.cfg
plymouth-set-default-theme -R archfiery
grub-mkconfig -o /boot/grub/grub.cfg
sleep 6s
clear

# Lightdm setups
echo "Setting up lightdm"
latest_release_url=$(curl -s https://api.github.com/repos/eromatiya/lightdm-webkit2-theme-glorious/releases/latest | grep "browser_download_url" | cut -d '"' -f 4)
curl -L -o glorious-latest.tar.gz "$latest_release_url"
tar -zxvf glorious-latest.tar.gz -C $US/lightdm-webkit/themes/glorious --strip-components=1
sed -i 's/^\(#?greeter\)-session\s*=\s*\(.*\)/greeter-session = lightdm-webkit2-greeter #\1/ #\2g' /etc/lightdm/lightdm.conf
sed -i 's/^webkit_theme\s*=\s*\(.*\)/webkit_theme = glorious #\1/g' /etc/lightdm/lightdm-webkit2-greeter.conf
sed -i 's/^debug_mode\s*=\s*\(.*\)/debug_mode = true #\1/g' /etc/lightdm/lightdm-webkit2-greeter.conf
sleep 6s
clear

# Installing grub-theme
echo "Installing grub-theme"
cp -r "$DOT"/themes/grub/themes/* $US/grub/themes/
sed -i 's/#GRUB_THEME="/path/to/gfxtheme"/GRUB_THEME="/usr/share/grub/themes/archfiery/theme.txt"/g' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
sleep 6s
clear

# setting up ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow syncthing
ufw limit 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp

# Setting up virtualbox
echo "Setting up virtualbox"
modprobe vboxdrv
gpasswd -a "$username" vboxusers
sleep 6s
clear

# Enable services
echo "Enabling services.."
printf "\n"
enable_services=("irqbalance.service" "udisks2.service" "httpd.service" "cronie.service" "sshd.service" "lightdm-plymouth.service" "NetworkManager.service" "cups.service" "bluetooth" "ntpd.service" "dhcpcd.service" "syncthing@$username" "ufw")
systemctl enable "${enable_services[@]}"
sleep 6s
clear

# Setup blackarch repo
curl -O https://blackarch.org/strap.sh
echo 5ea40d49ecd14c2e024deecf90605426db97ea0c strap.sh | sha1sum -c
chmod +x strap.sh
./strap.sh
pacman -Syyu
rm -rf strap.sh

# Clearcache
echo "Clearing cache..."
pikaur -Scc --noconfirm
sleep 6s
clear

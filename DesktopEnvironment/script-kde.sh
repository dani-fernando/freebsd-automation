#!/bin/sh
init_colors() {
    if [ -t 1 ]; then
        GREEN=$(tput setaf 2)
        BLUE=$(tput setaf 4)
        YELLOW=$(tput setaf 3)
        RED=$(tput setaf 1)
        BOLD=$(tput bold)
        RESET=$(tput sgr0)
    else
        GREEN=''
        BLUE=''
        YELLOW=''
        RED=''
        BOLD=''
        RESET=''
    fi
}

init_colors

# Cek akses root
if [ "$(id -u)" -ne 0 ]; then
    printf "%sError: Script harus dijalankan sebagai root/sudo%s\n" "$RED" "$RESET"
    exit 1
fi

printf "\n%s============================================%s\n" "$YELLOW" "$RESET"
printf "%s==   Script Instalasi KDE untuk FreeBSD    ==%s\n" "$GREEN" "$RESET"
printf "%s============================================%s\n\n" "$YELLOW" "$RESET"

# 1. Update sistem
printf "%s[%s1/6%s] Memperbarui sistem...%s\n" "$BLUE" "$BOLD" "$BLUE" "$RESET"
printf "%sMenjalankan freebsd-update dan pkg update...%s\n\n" "$GREEN" "$RESET"
freebsd-update fetch install
pkg update -y
pkg upgrade -y

printf "\n%sUpdate sistem selesai ✔%s\n" "$GREEN" "$RESET"
printf "----------------------------------------\n"

# 2. Instal paket dasar
printf "\n%s[%s2/6%s] Menginstal paket dasar...%s\n" "$BLUE" "$BOLD" "$BLUE" "$RESET"
printf "%sMenginstal: nano vim xorg kde sddm%s\n\n" "$GREEN" "$RESET"
pkg install -y nano vim xorg plasma6-plasma sddm

printf "\n%sInstalasi paket dasar selesai ✔%s\n" "$GREEN" "$RESET"
printf "----------------------------------------\n"

# 3. Pilih driver VGA
printf "\n%s[%s3/6%s] Pemilihan driver VGA%s\n" "$BLUE" "$BOLD" "$BLUE" "$RESET"
printf "%sPilih driver VGA yang sesuai dengan hardware Anda:%s\n" "$YELLOW" "$RESET"
printf "%s  1. Intel%s\n" "$YELLOW" "$RESET"
printf "%s  2. AMD%s\n" "$YELLOW" "$RESET"
printf "%s  3. NVIDIA%s\n" "$YELLOW" "$RESET"

# Perbaikan input dengan read tanpa opsi -p
printf "%sMasukkan pilihan (1/2/3): %s" "$GREEN" "$RESET"
read choice

case $choice in
    1)
        printf "\n%sMemilih driver Intel...%s\n" "$GREEN" "$RESET"
        pkg install -y drm-kmod
        ;;
    2)
        printf "\n%sMemilih driver AMD...%s\n" "$GREEN" "$RESET"
        pkg install -y drm-kmod
        ;;
    3)
        printf "\n%sMemilih driver NVIDIA...%s\n" "$GREEN" "$RESET"
        pkg install -y nvidia-driver nvidia-settings
        ;;
    *)
        printf "%sPilihan tidak valid!%s\n" "$RED" "$RESET"
        exit 1
        ;;
esac

printf "\n%sDriver VGA terinstal ✔%s\n" "$GREEN" "$RESET"
printf "----------------------------------------\n"

# 4. Konfigurasi fstab
printf "\n%s[%s4/6%s] Memperbarui /etc/fstab...%s\n" "$BLUE" "$BOLD" "$BLUE" "$RESET"
if ! grep -q "procfs" /etc/fstab; then
    echo "proc /proc procfs rw 0 0" >> /etc/fstab
    printf "%sKonfigurasi fstab berhasil ditambahkan ✔%s\n" "$GREEN" "$RESET"
else
    printf "%sKonfigurasi fstab sudah ada, dilewati...%s\n" "$YELLOW" "$RESET"
fi
printf "----------------------------------------\n"

# 5. Aktifkan layanan
printf "\n%s[%s5/6%s] Mengaktifkan layanan sistem...%s\n" "$BLUE" "$BOLD" "$BLUE" "$RESET"
sysrc dbus_enable="YES"
sysrc seatd_enable="YES"
sysrc sddm_enable="YES"
printf "%sLayanan berhasil diaktifkan ✔%s\n" "$GREEN" "$RESET"
printf "----------------------------------------\n"

# 6. Tambahkan konfigurasi sysctl untuk buffer Unix domain socket
printf "\n%s[%s5/6%s] Mengonfigurasi /etc/sysctl.conf untuk performa...%s\n" "$BLUE" "$BOLD" "$BLUE" "$RESET"
if grep -q "net.local.stream.recvspace" /etc/sysctl.conf && grep -q "net.local.stream.sendspace" /etc/sysctl.conf; then
    printf "%sKonfigurasi sysctl sudah ada, lewati...%s\n" "$YELLOW" "$RESET"
else
    echo "net.local.stream.recvspace=65536" >> /etc/sysctl.conf
    echo "net.local.stream.sendspace=65536" >> /etc/sysctl.conf
    printf "%sKonfigurasi sysctl berhasil ditambahkan ✔%s\n" "$GREEN" "$RESET"
fi

printf "%sLayanan berhasil diaktifkan ✔%s\n" "$GREEN" "$RESET"
printf "----------------------------------------\n"


# 7. Konfigurasi rc.conf untuk driver
printf "\n%s[%s6/6%s] Konfigurasi driver VGA...%s\n" "$BLUE" "$BOLD" "$BLUE" "$RESET"
case $choice in
    1)
        sysrc kld_list+=" i915kms"
        printf "%sKonfigurasi Intel (i915kms) berhasil ✔%s\n" "$GREEN" "$RESET"
        ;;
    2)
        sysrc kld_list+=" amdgpu"
        printf "%sKonfigurasi AMD (amdgpu) berhasil ✔%s\n" "$GREEN" "$RESET"
        ;;
    3)
        printf "%sNVIDIA tidak memerlukan konfigurasi tambahan ✔%s\n" "$YELLOW" "$RESET"
        ;;
esac

# Finalisasi
printf "\n%s=================================================%s\n" "$YELLOW" "$RESET"
printf "%sInstalasi KDE selesai! ✔%s\n" "$GREEN" "$RESET"
printf "%s=================================================%s\n\n" "$YELLOW" "$RESET"

# Reboot
printf "%sReboot sekarang? (y/N): %s" "$RED" "$RESET"
read reboot_choice
if [ "$reboot_choice" = "y" ] || [ "$reboot_choice" = "Y" ] || [ "$reboot_choice" = "yes" ]; then
    reboot
else
    printf "\n%sSilakan reboot manual dengan perintah 'reboot'%s\n" "$YELLOW" "$RESET"
fi

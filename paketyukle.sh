#!/usr/bin/env bash

# Install packages from a list.
# Usage:
#   $ ./paketyukle.sh <pkglist.txt>
#
aurcmd="yay"
list=$(grep -oE '^[^(#|[:space:])]*' "$1" | sort -u)
repo=$(cat <(pacman -Slq) <(pacman -Sgq) | sort -u)
packages=$(comm -12 <(echo "$repo") <(echo "$list") | tr '\n' ' ')
aurpackages=$(comm -13 <(echo "$repo") <(echo "$list") | tr '\n' ' ')
setfont iso09.16

check_git() {
    if command -v git > /dev/null 2>&1; then
        echo "[✔]::[Git]: Kurulumu Mevcut!"
    else
        echo "[x]::[Bilgi]: Sistemde Git Kurulumu Bulunamadı."
        echo ""
        echo "[!]::[Lütfen Bekleyin]: Git Yükleniyor..."
        sudo pacman -S git --noconfirm
        echo ""
    fi
    sleep 1
}

check_wget() {
    if command -v wget > /dev/null 2>&1; then
        echo "[✔]::[wget]: Kurulumu Mevcut!"
    else
        echo "[x]::[Bilgi]: Sistemde Wget Kurulumu Bulunamadı."
        echo ""
        echo "[!]::[Lütfen Bekleyin]: Wget Yükleniyor..."
        sudo pacman -S --noconfirm wget
        sleep 2
        echo ""
    fi
    sleep 1
}

check_yay() {
    if command -v yay > /dev/null 2>&1; then
        echo "[✔]::[Yay]: Kuruluma Mevcut!"
    else
        echo "[x]::[Uyarı]: Bu komut dosyası Yay paket yöneticisini gerektirir."
        rm -rf yay
        echo ""
        echo "[!]::[Lütfen Bekleyin]: Yay Paket Yöneticisi Yükleniyor..."
        git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si
        echo ""
    fi
    sleep 1
}

# Initial pacman -Syu
init_pacman_update() {
    echo ""
    echo -e "\033[1m Güncelleme Kontrolleri ..... \e[0m\E[31m| Lütfen güncellemeden önce herhangi bir yükleme işlemi varsa durdurun\e[0m"
    echo ""
    sudo pacman -Syu --noconfirm
    echo "Güncelleme Tamamlandı"
    sleep 1
}

package_install() {
    echo "Pacman Paketleri:"
    echo "$packages"
    echo
    echo "AUR Paketleri:"
    echo "$aurpackages"
    echo

    read -rep "Tüm paketleri yüklensin mi? [e/H] " install
    [ "$install" != "${install#[Ee]}" ] || exit 0

    sudo pacman --noconfirm --needed --ask 4 -S "$packages"
    for aur in $aurpackages; do
        "$aurcmd" -S --noconfirm "$aur"
    done
    show_result
}

graphic_install() {
    printm "Ekran Kartınız Yükleniyor"
    if lspci | grep -E "NVIDIA|GeForce"; then
        printm "Nvidia Kart Tespit Edildi"
        sudo pacman --noconfirm --needed nvidia nvidia-settings
    elif lspci | grep -E "Radeon"; then
        printm "Radeon Kart Tespit Edildi"
        sudo pacman --noconfirm --needed xf86-video-amdgpu
    elif lspci | grep -E "Integrated Graphics Controller"; then
        printm "Entegre Grafik Kartı Tespit Edildi"
        sudo pacman --noconfirm --needed libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils
    fi
}

# Enabling installed services
archer_services() {
    printm 'Yüklü Hizmetleri etkinleştiriliyor (Symlink "hataları" yoksayılabilir)'
    if pacman -Q networkmanager; then
        sudo systemctl enable NetworkManager.service
        sudo systemctl enable NetworkManager-wait-online.service
    elif pacman -Q connman; then
        sudo systemctl enable connman.service
    elif pacman -Q wicd; then
        sudo systemctl enable wicd.service
    elif pacman -Q dhcpcd; then
        sudo systemctl enable dhcpcd.service
    else
        eth=$(basename /sys/class/net/en*)
        wifi=$(basename /sys/class/net/wl*)
        [ -d "/sys/class/net/$eth" ] && printf "[Match]\nName=%s\n\n[Network]\nDHCP=yes\n\n[DHCP]\nRouteMetric=10" "$eth" > /etc/systemd/network/20-wired.network
        [ -d "/sys/class/net/$wifi" ] && printf "[Match]\nName=%s\n\n[Network]\nDHCP=yes\n\n[DHCP]\nRouteMetric=20" "$wifi" > /etc/systemd/network/25-wireless.network
        sudo systemctl enable systemd-networkd.service
        sudo systemctl enable systemd-networkd-wait-online.service
        sudo systemctl enable systemd-resolved.service
        umount /etc/resolv.conf 2>/dev/null
        ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
    fi

    if pacman -Q lightdm; then
        sudo systemctl enable lightdm.service
    elif pacman -Q lxdm; then
        sudo systemctl enable lxdm.service
    elif pacman -Q gdm; then
        sudo systemctl enable gdm.service
    elif pacman -Q sddm; then
        sudo systemctl enable sddm.service
    elif pacman -Q xorg-xdm; then
        sudo systemctl enable xdm.service
    elif pacman -Qs entrance; then
        sudo systemctl enable entrance.service
    fi

    if pacman -Q util-linux; then
        sudo systemctl enable fstrim.timer
    fi

    if pacman -Q bluez; then
        sudo systemctl enable bluetooth.service
    fi

    if pacman -Q modemmanager; then
        sudo systemctl enable ModemManager.service
    fi

    if pacman -Q ufw; then
        sudo systemctl enable ufw.service
    fi

    if pacman -Q libvirt; then
        sudo systemctl enable libvirtd.service
    fi

    if pacman -Q avahi; then
        sudo systemctl enable avahi-daemon.service
    fi

    if pacman -Q cups; then
        sudo systemctl enable cups.service
    fi

    if pacman -Q autorandr; then
        sudo systemctl enable autorandr.service
    fi

    if pacman -Q auto-cpufreq; then
        sudo systemctl enable auto-cpufreq.service
    fi

    if pacman -Q thermald; then
        sudo systemctl enable thermald.service
    fi

    if pacman -Q tlp; then
        sudo systemctl enable tlp.service
    fi

    show_result
}

_s() { "$@" >/dev/null 2>>err.o || err=true; }
_e() { "$@" 2>>err.o || err=true; }

show_result() {
    if [ "$err" ]; then
        printf ' \e[1;31m[HATA]\e[m\n'
        cat err.o 2>/dev/null
        printf '\e[1mYükleyiciden çık? [e/H]\e[m\n'
        read -r exit
        [ "$exit" != "${exit#[Ee]}" ] && exit
    else
        printf ' \e[1;32m[Çıkış Yapıldı]\e[m\n'
    fi
    rm -f err.o
    unset err
}

width=$(($(tput cols)-15))
padding=$(printf '.%.0s' {1..500})
printm() {
    printf "%-${width}.${width}s" "$1 $padding"
}

sleep 1
check_wget
check_yay
check_git
sleep 1
init_pacman_update
clear
package_install
sleep 1
archer_services

if [ ! -r "$1" ]; then
    echo "Kullanım: ${0##*/} <pkglist.txt>"
    exit 1
fi

# vim: set ts=4 sw=4 tw=0 et :

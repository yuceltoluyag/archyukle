#!/usr/bin/env bash

# Install packages from a list.
# Usage:
#   $ ./paketyukle.sh <pkglist.txt>
#
aurcmd="yay"
list="$(cat "$1" | grep -oE '^[^(#|[:space:])]*' | sort -u)"
repo="$(cat <(pacman -Slq) <(pacman -Sgq) | sort -u)"
packages=$(comm -12 <(echo "$repo") <(echo "$list") | tr '\n' ' ')
aurpackages=$(comm -13 <(echo "$repo") <(echo "$list") | tr '\n' ' ')
setfont iso09.16
checkgit(){
    which git > /dev/null 2>&1
    if [ "$?" -eq "0" ]; then
        echo [✔]::[Git]: Kurulumu Mevcut!;
    else
        
        echo [x]::[Bilgi]: Sistemde Git Kurulumu Bulunamadı ;
        echo ""
        echo [!]::[Lütfen Bekleyin]: Git Yükleniyor ..  ;
        pacman -S git --noconfirm
        echo ""
    fi
    sleep 1
}

checkwget(){
    which wget > /dev/null 2>&1
    if [ "$?" -eq "0" ]; then
        echo [✔]::[wget]: Kurulumu Mevcut!;
    else
        
        echo [x]::[Bilgi]:Sistemde Wget Kurulumu Bulunamadı ;
        echo ""
        echo [!]::[Lütfen Bekleyin]: Wget Yükleniyor ;
        pacman -S --noconfirm wget
        echo sleep 2
        echo ""
    fi
    sleep 1
    
}

checkyay(){
    which yay > /dev/null 2>&1
    if [ "$?" -eq "0" ]; then
        echo [✔]::[Yay]: Kuruluma Mevcut!;
    else
        echo [x]::[uyarı]:bu komut dosyası Yay paket yöneticisini gerektirir ;
        echo ""
        echo [!]::[Lütfen Bekleyin]: Yay Paket Yöneticisi Yükleniyor ..  ;
        git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si
        echo ""
    fi
    sleep 1
}

# ROOT User Check
# checkroot(){
#     sleep 1
#     if [[ $(id -u) = 0 ]]; then
#         echo -e " ROOT: ${g}PASSED${endc}"
#     else
#         echo -e " Root Yetkiniz Yok: ${r}FAILED${endc}
#         ${y}Bu scriptin çalışabilmesi için Root Yetkisine İhtiyaç Vardır...${endc}"
#         echo -e " ${b}paketyukle.sh${enda} çıkış yapılıyor"
#         echo
#         sleep 1
#         exit
#     fi
# }

# Initial pacman -Syu
initpacmanupd(){
    echo ""
    echo; echo -e "\033[1m Güncelleme Kontrolleri ..... \e[0m\E[31m| Lütfen güncellemeden önce herhangi bir yükleme işlemi varsa durdurun\e[0m";
    echo
    pacman -Syu --noconfirm;
    echo "Güncelleme Tamamlandı";
    sleep 1;
}

package_install(){
    echo "Paketler Yükleniyor:"
    echo "$packages"
    echo
    echo "AUR paketleri Kurulacak:"
    echo "$aurpackages"
    echo
    
    read -rep "Tüm paketleri yüklensin mi? [e/H] " install
    [ "$install" != "${install#[Ee]}" ] || exit 0
    
    sudo pacman --noconfirm --needed --ask 4 -S $packages
    for aur in $aurpackages; do
        "$aurcmd" -S --noconfirm "$aur"
    done
}

# Enabeling installed services
archer_services() {
    printm 'Enabeling services (Created symlink "errors" can be ignored)'
    # Services: network manager
    if pacman -Q networkmanager &>/dev/null ; then
        _s systemctl enable NetworkManager.service
        _s systemctl enable NetworkManager-wait-online.service
        
        elif pacman -Q connman &>/dev/null ; then
        _s systemctl enable connman.service
        
        elif pacman -Q wicd &>/dev/null ; then
        _s systemctl enable wicd.service
        
        elif pacman -Q dhcpcd &>/dev/null ; then
        _s systemctl enable dhcpcd.service
        
    else
        eth="$(basename /sys/class/net/en*)"
        wifi="$(basename /sys/class/net/wl*)"
        [ -d "/sys/class/net/$eth" ] && \
        printf "[Match]\nName=%s\n\n[Network]\nDHCP=yes\n\n[DHCP]\nRouteMetric=10" "$eth" \
        > /etc/systemd/network/20-wired.network
        [ -d "/sys/class/net/$wifi" ] && \
        printf "[Match]\nName=%s\n\n[Network]\nDHCP=yes\n\n[DHCP]\nRouteMetric=20" "$wifi" \
        > /etc/systemd/network/25-wireless.network
        _s systemctl enable systemd-networkd.service
        _s systemctl enable systemd-networkd-wait-online.service
        _s systemctl enable systemd-resolved.service
        umount /etc/resolv.conf 2>/dev/null
        _s ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
    fi
    
    # Services: display manager
    if pacman -Q lightdm &>/dev/null ; then
        _s systemctl enable lightdm.service
        
        elif pacman -Q lxdm &>/dev/null ; then
        _s systemctl enable lxdm.service
        
        elif pacman -Q gdm &>/dev/null ; then
        _s systemctl enable gdm.service
        
        elif pacman -Q sddm &>/dev/null ; then
        _s systemctl enable sddm.service
        
        elif pacman -Q xorg-xdm &>/dev/null ; then
        _s systemctl enable xdm.service
        
        elif pacman -Qs entrance &>/dev/null ; then
        _s systemctl enable entrance.service
    fi
    
    # Services: other
    if pacman -Q util-linux &>/dev/null ; then
        _s systemctl enable fstrim.timer
    fi
    
    if pacman -Q bluez &>/dev/null ; then
        _s systemctl enable bluetooth.service
    fi
    
    if pacman -Q modemmanager &>/dev/null ; then
        _s systemctl enable ModemManager.service
    fi
    
    if pacman -Q ufw &>/dev/null ; then
        _s systemctl enable ufw.service
    fi
    
    if pacman -Q libvirt &>/dev/null ; then
        _s systemctl enable libvirtd.service
    fi
    
    if pacman -Q avahi &>/dev/null ; then
        _s systemctl enable avahi-daemon.service
    fi
    
    if pacman -Q cups &>/dev/null ; then
        _s systemctl enable cups.service
    fi
    
    if pacman -Q autorandr &>/dev/null ; then
        _s systemctl enable autorandr.service
    fi
    
    if pacman -Q auto-cpufreq &>/dev/null ; then
        _s systemctl enable auto-cpufreq.service
    fi
    showresult
}

# Short function to silent command outputs
_s() { "$@" >/dev/null 2>>err.o || err=true; }
_e() { "$@" 2>>err.o || err=true; }

# Printing OK/ERROR
showresult() {
    if [ "$err" ] ; then
        printf ' \e[1;31m[ERROR]\e[m\n'
        cat err.o 2>/dev/null
        printf '\e[1mExit installer? [y/N]\e[m\n'
        read -r exit
        [ "$exit" != "${exit#[Yy]}" ] && exit
    else
        printf ' \e[1;32m[OK]\e[m\n'
    fi
    rm -f err.o
    unset err
}

# Padding
width=$(($(tput cols)-15))
padding=$(printf '.%.0s' {1..500})
printm() {
    printf "%-${width}.${width}s" "$1 $padding"
}


# Script Initiation
sleep 1
checkwget && checkyay && checkgit && sleep 1
initpacmanupd && clear && package_install && sleep 1
archer_services

if [ ! -r "$1" ]; then
    echo "Kullanim ${0##*/} <pkglist.txt>"
    exit 1
fi

# vim: set ts=4 sw=4 tw=0 et :

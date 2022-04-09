#!/usr/bin/env -S bash -e

# Cleaning the TTY.
clear
setfont iso09.16
#LOG_FILE="arcbaba.log"

print () {
    echo -e "\e[1m\e[93m[ \e[92m•\e[93m ] \e[4m$1\e[0m"
}
error() { printf "%s\n" "$1" >&2; exit 1; }
print "Doğru Disk Adını Seçebilmeniz için Sistemdeki Aygıtlarınız Gösterilecek"
lsblk
sleep 5
# Pretty print (function).


# Source variables
logo(){
    echo -e "${R}
                      /\\
				     /  \\    ${G}Yucel Toluyağ${G}
				    / /\\ \\   ${G}Archlinux İnstaller${G}
				   / /  \\ \\  ${G}github.com/yuceltoluyag${G}
				  / /    \\ \\
				 / / _____\\ \\
    /_/  \`----.\\_\\ ${B}"
    
    print "Arch Linux kurulum sürecini basitleştirmek için yapılmış bir komut dosyası olan Arcyukle'ye hoş geldiniz."
    PS3="Lütfen diskin numarasını seçin.Disk Numarası: "
    select ENTRY in $(lsblk -dpnoNAME|grep -P "/dev/sd|nvme|vd");
    do
        DISK=$ENTRY
        print "Arch Linux'un Kurulacağı Disk:  $DISK."
        break
    done
}



internet_check(){
    ### check internet availability
    print "İnternet Bağlantınız Kontrol Ediliyor...\n"
    if ! curl -Ism 5 https://www.google.com >/dev/null; then
        print "İnternet Bağlantınız Başarız Oldu\n"
        exit
    fi
}

# Sanallaştırma detected...
virt_check () {
    hypervisor=$(systemd-detect-virt)
    case $hypervisor in
        kvm )   print "KVM  Kullandığınız Tespit Edildi."
            print "Gerekli Paketler Otomatik Yüklenecek..."
            pacstrap /mnt qemu-guest-agent >/dev/null
            print "Paketler Etkinleştiriliyor.."
            systemctl enable qemu-guest-agent --root=/mnt &>/dev/null
        ;;
        vmware  )   print "VMWare Workstation Kullandığınız Tespit Edildi."
            print "Gerekli Paketler Otomatik Yüklenecek..."
            pacstrap /mnt open-vm-tools >/dev/null
            print "Paketler Etkinleştiriliyor.."
            systemctl enable vmtoolsd --root=/mnt &>/dev/null
            systemctl enable vmware-vmblock-fuse --root=/mnt &>/dev/null
        ;;
        oracle )    print "VirtualBox Kullandığınız Tespit Edildi."
            print "Gerekli Paketler Otomatik Yüklenecek..."
            pacstrap /mnt virtualbox-guest-utils >/dev/null
            print "Paketler Etkinleştiriliyor.."
            systemctl enable vboxservice --root=/mnt &>/dev/null
        ;;
        microsoft ) print "Hyper-V  Kullandığınız Tespit Edildi."
            print "Gerekli Paketler Otomatik Yüklenecek..."
            pacstrap /mnt hyperv >/dev/null
            print "Paketler Etkinleştiriliyor.."
            systemctl enable hv_fcopy_daemon --root=/mnt &>/dev/null
            systemctl enable hv_kvp_daemon --root=/mnt &>/dev/null
            systemctl enable hv_vss_daemon --root=/mnt &>/dev/null
        ;;
        * ) ;;
    esac
}


# Selecting a kernel to install (function).
kernel_selector () {
    print "Hangi Linux Kernelini Yüklemek İstersiniz:"
    print "1) linux:  Varsayılan Linux çekirdeği"
    print "2) linux-hardened: Güvenlik odaklı bir Linux çekirdeği"
    print "3) LTS: Uzun vadeli destek (LTS) Linux çekirdeği"
    print "4) Zen: Masaüstü kullanımı için optimize edilmiş bir Linux çekirdeği"
    read -r -p "İlgili çekirdeğin numarasını girin: " choice
    case $choice in
        1 ) kernel="linux"
        ;;
        2 ) kernel="linux-hardened"
        ;;
        3 ) kernel="linux-lts"
        ;;
        4 ) kernel="linux-zen"
        ;;
        * ) print "Geçerli bir seçim girmediniz."
            kernel_selector
    esac
}

# Selecting a way to handle internet connection (function).
network_selector () {
    print "Ağ Ayarları:"
    print "1) IWD: Intel tarafından yazılmış Linux için kablosuz bir arka plan programıdır (yalnızca WiFi)"
    print "2) NetworkManager: Tavsiye edilen evrensel ağ yardımcı programı (hem WiFi hem de Ethernet Destekler)"
    print "3) wpa_supplicant: WEP, WPA ve WPA2 desteğine sahip çapraz platform desteğine sahip (yalnızca WiFi, bir DHCP istemcisi de otomatik olarak yüklenir)"
    print "4) dhcpcd: Temel DHCP istemcisi (Yalnızca Ethernet veya VM'ler)"
    print "5) Bunu daha sonra yapacağım (yalnızca ileri düzey kullanıcılar)"
    read -r -p "Yüklemek istediğiniz ağ yardımcısının numarasını girin: " choice
    case $choice in
        1 ) print "IWD Yükleniyor"
            pacstrap /mnt iwd >/dev/null
            print "IWD Etkinleştiriliyor."
            systemctl enable iwd --root=/mnt &>/dev/null
        ;;
        2 ) print "NetworkManager Yükleniyor."
            pacstrap /mnt networkmanager >/dev/null
            print "NetworkManager Etkinleştiriliyor."
            systemctl enable NetworkManager --root=/mnt &>/dev/null
        ;;
        3 ) print "Yükleniyor wpa_supplicant and dhcpcd."
            pacstrap /mnt wpa_supplicant dhcpcd >/dev/null
            print "wpa_supplicant ve dhcpcd Etkinleştiriliyor."
            systemctl enable wpa_supplicant --root=/mnt &>/dev/null
            systemctl enable dhcpcd --root=/mnt &>/dev/null
        ;;
        4 ) print "dhcpcd Yükleniyor ."
            pacstrap /mnt dhcpcd >/dev/null
            print "dhcpcd Etkinleştiriliyor."
            systemctl enable dhcpcd --root=/mnt &>/dev/null
        ;;
        5 ) ;;
        * ) print "Geçerli bir seçim yapmadınız."
            network_selector
    esac
}

# Setting up a password for the user account (function).
userpass_selector () {
    while true; do
        read -r -s -p "$username için bir kullanıcı şifre belirleyin : " userpass
        while [ -z "$userpass" ]; do
            echo
            print "$username için bir şifre girmeniz gerekiyor."
            read -r -s -p "$username için bir kullanıcı şifre belirleyin : " userpass
            [ -n "$userpass" ] && break
        done
        echo
        read -r -s -p "Şifreyi tekrar girin: " userpass2
        echo
        [ "$userpass" = "$userpass2" ] && break
        echo "Şifreler eşleşmiyor, tekrar deneyin."
    done
}

# Setting up a password for the root account (function).
rootpass_selector () {
    while true; do
        read -r -s -p "root için bir şifre belirleyin: " rootpass
        while [ -z "$rootpass" ]; do
            echo
            print "Root Şifrenizi Girin"
            read -r -s -p "root şifresi: " rootpass
            [ -n "$rootpass" ] && break
        done
        echo
        read -r -s -p "Şifre (Tekrar): " rootpass2
        echo
        [ "$rootpass" = "$rootpass2" ] && break
        echo "Şifreler eşleşmiyor, tekrar deneyin."
    done
}


# Microcode detector (function).
microcode_detector () {
    CPU=$(grep vendor_id /proc/cpuinfo)
    if [[ $CPU == *"AuthenticAMD"* ]]; then
        print "Bir AMD CPU algılandı, AMD mikro kodu yüklenecek."
        microcode="amd-ucode"
    else
        print "Bir Intel CPU algılandı, Intel mikro kodu yüklenecek."
        microcode="intel-ucode"
    fi
}

# Setting up the hostname (function).
hostname_selector () {
    read -r -p "Lütfen ana bilgisayar adını girin: " hostname
    if [ -z "$hostname" ]; then
        print "Devam etmek için bir ana bilgisayar adı girmeniz gerekiyor."
        hostname_selector
    fi
    echo "$hostname" > /mnt/etc/hostname
}


# Setting up the locale (function).
locale_selector () {
    read -r -p "Lütfen kullandığınız yerel ayarı girin (biçim: xx_XX ,örneğin tr_TR veya en_US kullanmak için boş girin): " locale
    if [ -z "$locale" ]; then
        print "en_US varsayılan yerel ayar olarak kullanılacaktır."
        locale="en_US"
    fi
    echo "$locale.UTF-8 UTF-8"  > /mnt/etc/locale.gen
    echo "LANG=$locale.UTF-8" > /mnt/etc/locale.conf
}


# Setting up the keyboard layout (function).
keyboard_selector () {
    read -r -p "Lütfen kullandığınız klavye düzenini girin (Türkçe klavye düzenini kullanmak için boş bırakıp enter basın): " kblayout
    if [ -z "$kblayout" ]; then
        print "TR klavye düzeni varsayılan olarak kullanılacaktır."
        kblayout="trq"
    fi
    echo "KEYMAP=$kblayout" > /mnt/etc/vconsole.conf
}


part_disk(){
    # Deleting old partition scheme.
    read -r -p "Bu, $DISK üzerindeki mevcut tüm bölümleri siler. [e/H]'ye onaylıyor musunuz? " response
    response=${response,,}
    if [[ "$response" =~ ^(evet|e)$ ]]; then
        print "Disk bölme işlemi başlıyor. $DISK."
        # setup grub
        if [ -d /sys/firmware/efi/efivars ]; then
            print "$DISK UEFI Sisteme Göre Formatlanıyor"
            parted -s --align optimal $DISK mklabel gpt
            parted -s --align optimal $DISK mkpart primary  ESP fat32 1M 513M
            parted -s --align optimal $DISK set 1 boot on
            parted -s --align optimal $DISK mkpart primary  linux-swap 1G 3G
            parted -s --align optimal $DISK mkpart primary  513M 100%
        else
            print "$DISK MBR&BIOS Sisteme Göre Formatlanıyor"
            parted -s --align optimal $DISK mklabel msdos
            parted -s --align optimal $DISK mkpart primary 0% 512M
            parted -s --align optimal $DISK mkpart primary 1G 3G
            parted -s --align optimal $DISK mkpart primary 3G 100%
        fi
    else
        print "Çıkış Yapıldı."
        exit
    fi
}

format_disk(){
    mkfs.fat -F32 "$DISK"1
    mkswap "$DISK"2
    swapon "$DISK"2
    echo y | mkfs.ext4 "$DISK"3
    echo -e "$R Diskler Sisteme Yerleştiriliyor.          $reset"
    mount "$DISK"3 /mnt
    mkdir -p /mnt/boot
    mount "$DISK"1 /mnt/boot
    lsblk
    print "5 Saniye Bekleyin"
    sleep 5
}


# Workstation

logo
internet_check
part_disk || error "Bir şeyler ters gitti, belki scriptten, belki de senden, kim bilir. :("
format_disk || error "Bir şeyler ters gitti, belki scriptten, belki de senden, kim bilir. :("
kernel_selector || error "Bir şeyler ters gitti, belki scriptten, belki de senden, kim bilir. :("
microcode_detector || error "Bir şeyler ters gitti, belki scriptten, belki de senden, kim bilir. :("
virt_check || error "Bir şeyler ters gitti, belki scriptten, belki de senden, kim bilir. :("
network_selector || error "Bir şeyler ters gitti, belki scriptten, belki de senden, kim bilir. :("

# Pacstrap (setting up a base sytem onto the new root).
print "Temel sistemin kurulması (biraz zaman alabilir)."
pacstrap /mnt --needed base base-devel $kernel $microcode linux-headers linux-firmware grub rsync efibootmgr reflector man vim nano git >/dev/null

hostname_selector || error "Bir şeyler ters gitti, belki scriptten, belki de senden, kim bilir. :("

print "Fstab Oluşturuluyor."
genfstab -U /mnt >> /mnt/etc/fstab

# Setting username.
read -r -p "Lütfen bir kullanıcı hesabı için ad girin: " username
arch-chroot /mnt useradd -m -g users -G optical,storage,wheel,video,audio,users,power,network,log -s /bin/bash "$username"
sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /mnt/etc/sudoers
userpass_selector || error "Bir şeyler ters gitti, belki scriptten, belki de senden, kim bilir. :("
rootpass_selector || error "Bir şeyler ters gitti, belki scriptten, belki de senden, kim bilir. :("
locale_selector || error "Bir şeyler ters gitti, belki scriptten, belki de senden, kim bilir. :("
keyboard_selector || error "Bir şeyler ters gitti, belki scriptten, belki de senden, kim bilir. :("


print "Host Dosyanız Ayarlanıyor."
cat > /mnt/etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $hostname.localdomain   $hostname
EOF


# Configuring the system.
arch-chroot /mnt /bin/bash -e <<EOF

    # Setting up timezone.
    echo "Setting up the timezone."
    ln -sf /usr/share/zoneinfo/$(curl -s http://ip-api.com/line?fields=timezone) /etc/localtime &>/dev/null

    # Setting up clock.
    echo "Setting up the system clock."
    hwclock --systohc

    # Generating locales.
    echo "Generating locales."
    locale-gen &>/dev/null

    # Generating a new initramfs.
    echo "Creating a new initramfs."
    rm -rf /etc/mkinitcpio.d/linux.preset
    pacman -S linux linux-firmware linux-headers --noconfirm
    mkinitcpio -p linux &>/dev/null

    # Installing GRUB.
    echo "Installing GRUB on /boot."
    # Installing grub
if [[ -d /sys/firmware/efi/efivars ]]; then
    echo "+-----------------------------+"
    echo "+ UEFI Sistem Algılandı             +"
    echo "+-----------------------------+"
    grub-install --target=x86_64-efi --efi-directory=/boot/EFI --bootloader-id=GRUB --removable --recheck --debug
else
    echo "+-----------------------------+"
    echo "+ BIOS-MBR Sistem Algılandı             +"
    echo "+-----------------------------+"
    grub-install --target=i386-pc $DISK --recheck --debug
    # Creating grub config file.
    echo "+-----------------------------+"
    echo "+ GRUB Dosyası Oluşturuluyor.  +"
    echo "+-----------------------------+"
    echo "GRUB_DISABLE_OS_PROBER=true" > /etc/default/grub
fi
grub-mkconfig -o /boot/grub/grub.cfg

EOF

print "Root Şifreniz Ayarlanıyor."
echo "root:$rootpass" | arch-chroot /mnt chpasswd

print " $username yetkilendiriliyor"
if [ -n "$username" ]; then
    print " $username kullanıcıya yetki veriliyor"
    arch-chroot /mnt useradd -m -g users -G optical,storage,wheel,video,audio,users,power,network,log -s /bin/bash "$username"
    sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /mnt/etc/sudoers
    print "$username şifresi ayarlanıyor"
    echo "$username:$userpass" | arch-chroot /mnt chpasswd
fi

# Pacman eye-candy features.
print "Pacman'da renk, animasyon ve paralel indirme etkinleştiriliyor."
sed -i 's/#Color/Color\nILoveCandy/;s/^#ParallelDownloads.*$/ParallelDownloads = 10/' /mnt/etc/pacman.conf

# Finishing up.
print "Bitti, şimdi yeniden yeniden başlatabilirsiniz (kullanıcı adı ve şifre girdikten sonra paketleri yüklemeyi unutmayın.)."
exit

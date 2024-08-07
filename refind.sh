#!/usr/bin/env -S bash -e

# Cleaning the TTY.
clear
setfont LatArCyrHeb-19.psfu.gz
#LOG_FILE="arcbaba.log"

# ANSI color codes
R=$(tput setaf 1)
G=$(tput setaf 2)
B=$(tput setaf 4)
reset=$(tput sgr0)

print () {
    echo -e "\e[1m\e[93m[ \e[92m•\e[93m ] \e[4m$1\e[0m"
}
error() { printf "%s\n" "$1"; exit 1; }
print "Doğru Disk Adını Seçebilmeniz için Sistemdeki Aygıtlarınız Gösterilecek"
lsblk
sleep 5

# Pretty print (function).
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
    PS3="Lütfen diskin numarasını seçin: "
    select ENTRY in $(lsblk -dpnoNAME|grep -P "/dev/sd|nvme|vd");
    do
        DISK=$ENTRY
        print "Arch Linux'un Kurulacağı Disk: $DISK."
        break
    done
}

internet_check(){
    ### check internet availability
    print "İnternet Bağlantınız Kontrol Ediliyor...\n"
    if ! curl -Ism 5 https://www.google.com; then
        print "İnternet Bağlantınız Başarısız Oldu\n"
        exit 1
    fi
}

# Sanallaştırma tespiti...
virt_check () {
    hypervisor=$(systemd-detect-virt)
    case $hypervisor in
        kvm )   
            print "KVM Kullandığınız Tespit Edildi."
            print "Gerekli Paketler Otomatik Yüklenecek..."
            pacstrap /mnt qemu-guest-agent
            print "Paketler Etkinleştiriliyor.."
            systemctl enable qemu-guest-agent --root=/mnt
        ;;
        vmware )   
            print "VMWare Workstation Kullandığınız Tespit Edildi."
            print "Gerekli Paketler Otomatik Yüklenecek..."
            pacstrap /mnt open-vm-tools
            print "Paketler Etkinleştiriliyor.."
            systemctl enable vmtoolsd --root=/mnt
            systemctl enable vmware-vmblock-fuse --root=/mnt
        ;;
        oracle )    
            print "VirtualBox Kullandığınız Tespit Edildi."
            print "Gerekli Paketler Otomatik Yüklenecek..."
            pacstrap /mnt virtualbox-guest-utils
            print "Paketler Etkinleştiriliyor.."
            systemctl enable vboxservice --root=/mnt
        ;;
        microsoft ) 
            print "Hyper-V Kullandığınız Tespit Edildi."
            print "Gerekli Paketler Otomatik Yüklenecek..."
            pacstrap /mnt hyperv
            print "Paketler Etkinleştiriliyor.."
            systemctl enable hv_fcopy_daemon --root=/mnt
            systemctl enable hv_kvp_daemon --root=/mnt
            systemctl enable hv_vss_daemon --root=/mnt
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
        * ) 
            print "Geçerli bir seçim girmediniz."
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
        1 ) 
            print "IWD Yükleniyor"
            pacstrap /mnt iwd
            print "IWD Etkinleştiriliyor."
            systemctl enable iwd --root=/mnt
        ;;
        2 ) 
            print "NetworkManager Yükleniyor."
            pacstrap /mnt networkmanager
            print "NetworkManager Etkinleştiriliyor."
            systemctl enable NetworkManager --root=/mnt
        ;;
        3 ) 
            print "Yükleniyor wpa_supplicant ve dhcpcd."
            pacstrap /mnt wpa_supplicant dhcpcd
            print "wpa_supplicant ve dhcpcd Etkinleştiriliyor."
            systemctl enable wpa_supplicant --root=/mnt
            systemctl enable dhcpcd --root=/mnt
        ;;
        4 ) 
            print "dhcpcd Yükleniyor."
            pacstrap /mnt dhcpcd
            print "dhcpcd Etkinleştiriliyor."
            systemctl enable dhcpcd --root=/mnt
        ;;
        5 ) ;;
        * ) 
            print "Geçerli bir seçim yapmadınız."
            network_selector
    esac
}

# Setting up a password for the user account (function).
userpass_selector () {
    while true; do
        read -r -s -p "$username için bir kullanıcı şifre belirleyin: " userpass
        while [ -z "$userpass" ]; do
            echo
            print "$username için bir şifre girmeniz gerekiyor."
            read -r -s -p "$username için bir kullanıcı şifre belirleyin: " userpass
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
    read -r -p "Lütfen kullandığınız yerel ayarı girin (biçim: xx_XX, örneğin tr_TR veya en_US kullanmak için boş girin): " locale
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
            print "$DISK UEFI Sisteme Göre Biçimlendiriliyor"
            print "Siliniyor $DISK."
            wipefs -af "$DISK"
            sgdisk -Zo "$DISK"
            parted -s --align optimal "$DISK" mklabel gpt
            parted -s --align optimal "$DISK" mkpart ESP fat32 1M 513M
            parted -s --align optimal "$DISK" set 1 esp on
            parted -s --align optimal "$DISK" mkpart primary  linux-swap 513M 4G
            parted -s --align optimal "$DISK" mkpart primary  4G 100%
        else
            print "$DISK MBR&BIOS Sisteme Göre Biçimlendiriliyor"
            parted -s --align optimal "$DISK" mklabel msdos
            parted -s --align optimal "$DISK" mkpart primary 1M 513M
            parted -s --align optimal "$DISK" mkpart primary 513M 4G
            parted -s --align optimal "$DISK" mkpart primary 4G 100%
        fi
    else
        print "Çıkış Yapıldı."
        exit
    fi
}

format_disk(){
    if [[ -d /sys/firmware/efi/efivars ]]; then
        print "UEFI Boot Oluşturuluyor $DISK"
        echo y | mkfs.ext4 "${DISK}3"
        mount "${DISK}3" /mnt
        mkfs.fat -F 32 "${DISK}1"
        mkdir -p /mnt/boot/
        mount "${DISK}1" /mnt/boot
    else
        print "BIOS&MBR Bölüm Oluşturuluyor.."
        echo y | mkfs.ext4 "${DISK}3"
        mount "${DISK}3" /mnt
        mkfs.fat -F32 "${DISK}1"
        mkdir -p /mnt/boot
        mount "${DISK}1" /mnt/boot
    fi
    echo -e "${R}Diskler Sisteme Yerleştiriliyor.${reset}"
    mkswap "${DISK}2"
    swapon "${DISK}2"
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

# Pacstrap (setting up a base system onto the new root).
print "Temel sistemin kurulması (biraz zaman alabilir)."
pacstrap /mnt --needed base base-devel "$kernel" "$microcode" linux-headers linux-firmware refind rsync reflector man vim nano git sudo

hostname_selector || error "Bir şeyler ters gitti, belki scriptten, belki de senden, kim bilir. :("

print "Fstab Oluşturuluyor."
genfstab -U /mnt >> /mnt/etc/fstab

# Setting username.
read -r -p "Lütfen bir kullanıcı hesabı için ad girin: " username
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

    echo "Saat Ayarlanıyor."
    ln -sf /usr/share/zoneinfo/Europe/Istanbul /etc/localtime

    echo "Sistem Saati Senkronize Ediliyor."
    hwclock --systohc

    echo "Dil Dosyaları oluşturuluyor."
    locale-gen

    # Generating a new initramfs.
    echo "Creating a new initramfs."
    rm -rf /etc/mkinitcpio.d/linux.preset
    pacman -S linux linux-firmware linux-headers refind --noconfirm
    mkinitcpio -p linux

    # rEFInd installation.
    echo "rEFInd Yükleniyor."
    refind-install

echo "$username adlı kullanıcıya yetki veriliyor"
useradd -m -g users -G optical,storage,wheel,video,audio,users,power,network,log -s /bin/bash "$username"
usermod -aG wheel "$username"
echo "$username şifresi ayarlanıyor"
echo "$username:$userpass" | chpasswd
echo "${username} ALL=(ALL:ALL) ALL" >> /etc/sudoers
echo "%wheel	ALL=(ALL:ALL) ALL" >> /etc/sudoers
echo "%wheel	ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers
EOF

print "Root Şifreniz Ayarlanıyor."
echo "root:$rootpass" | arch-chroot /mnt chpasswd

# Setting up rEFInd.
print "REFInd Boot dosyası ayarlanıyor"
UUID=$(blkid -s PARTUUID -o value "${DISK}3")
rm -rf /mnt/boot/refind_linux.conf
cat > /mnt/boot/EFI/refind/refind.conf <<EOF
timeout 20
use_nvram false
write_systemd_vars true
extra_kernel_version_strings linux-hardened,linux-zen,linux-lts,linux
menuentry "Arch Linux" {
	icon     /EFI/refind/icons/os_arch.png
	volume   "Arch Linux"
	loader   /vmlinuz-$kernel
	initrd   /initramfs-$kernel.img
	options  "root=PARTUUID=$UUID rw add_efi_memmap quiet initrd=\\$microcode.img initrd=\\initramfs-$kernel.img"
	submenuentry "Boot to terminal (rescue mode)" {
	    add_options "systemd.unit=multi-user.target"
	}
}
EOF

# Setting up pacman hooks.
print " /boot Yedeklenmesi Otomatikleştiriliyor"
mkdir /mnt/etc/pacman.d/hooks
cat > /mnt/etc/pacman.d/hooks/50-bootbackup.hook <<EOF
[Trigger]
Operation = Upgrade
Operation = Install
Operation = Remove
Type = Path
Target = usr/lib/modules/*/vmlinuz

[Action]
Depends = rsync
Description = Backing up /boot...
When = PostTransaction
Exec = /usr/bin/rsync -a --delete /boot /.bootbackup
EOF

print "Refind Güncelleme İşlemleri Otomatikleştiriliyor"
cat > /mnt/etc/pacman.d/hooks/refind.hook <<EOF
[Trigger]
Operation = Upgrade
Type = Package
Target = refind

[Action]
Description = Updating rEFInd on ESP
When = PostTransaction
Exec=/usr/bin/refind-install
EOF

# Pacman eye-candy features.
print "Pacman'da renk, animasyon ve paralel indirme etkinleştiriliyor."
sed -i 's/#Color/Color\nILoveCandy/;s/^#ParallelDownloads.*$/ParallelDownloads = 10/' /mnt/etc/pacman.conf

# Finishing up.
print "Bitti, şimdi yeniden başlatabilirsiniz (kullanıcı adı ve şifre girdikten sonra paketleri yüklemeyi unutmayın.)."
exit

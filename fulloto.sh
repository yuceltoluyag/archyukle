#!/usr/bin/env -S bash -e

clear
setfont LatArCyrHeb-19.psfu.gz

print () {
    echo -e "\e[1m\e[93m[ \e[92m•\e[93m ] \e[4m$1\e[0m"
}
error() {
    printf "%s\n" "$1"
    exit 1
}

show_logo() {
    echo -e "${R}
                     		      /\\
				     /  \\    ${G}Yucel Toluyağ${G}
				    / /\\ \\   ${G}Archlinux İnstaller${G}
				   / /  \\ \\  ${G}github.com/yuceltoluyag${G}
				  / /    \\ \\
				 / / _____\\ \\
    				/_/  \`----.\\_\\ ${B}"
    print "Arch Linux kurulum sürecini basitleştirmek için yapılmış bir komut dosyası olan Arcyukle'ye hoş geldiniz."
}

select_disk() {
    PS3="Lütfen diskin numarasını seçin: "
    select ENTRY in $(lsblk -dpnoNAME|grep -P "/dev/sd|nvme|vd"); do
        DISK=$ENTRY
        print "Arch Linux'un Kurulacağı Disk: $DISK."
        break
    done
}

check_internet() {
    print "İnternet Bağlantınız Kontrol Ediliyor...\n"
    if wget -q --spider http://www.archlinux.org; then
        print "İnternet Bağlantısı Başarılı.\n"
    else
        error "İnternet Bağlantınız Başarısız Oldu\n"
    fi
}

detect_virtualization() {
    hypervisor=$(systemd-detect-virt)
    case $hypervisor in
        kvm ) 
            install_package "qemu-guest-agent"
            enable_service "qemu-guest-agent"
            ;;
        vmware ) 
            install_package "open-vm-tools"
            enable_service "vmtoolsd"
            enable_service "vmware-vmblock-fuse"
            ;;
        oracle ) 
            install_package "virtualbox-guest-utils"
            enable_service "vboxservice"
            ;;
        microsoft ) 
            install_package "hyperv"
            enable_service "hv_fcopy_daemon"
            enable_service "hv_kvp_daemon"
            enable_service "hv_vss_daemon"
            ;;
    esac
}

install_package() {
    local package=$1
    print "Gerekli Paketler Yükleniyor: $package..."
    pacstrap /mnt "$package"
}

enable_service() {
    local service=$1
    print "Paket Etkinleştiriliyor: $service..."
    systemctl enable "$service" --root=/mnt
}

select_kernel() {
    print "Hangi Linux Kernelini Yüklemek İstersiniz:"
    print "1) linux:  Varsayılan Linux çekirdeği"
    print "2) linux-hardened: Güvenlik odaklı bir Linux çekirdeği"
    print "3) LTS: Uzun vadeli destek (LTS) Linux çekirdeği"
    print "4) Zen: Masaüstü kullanımı için optimize edilmiş bir Linux çekirdeği"
    read -r -p "İlgili çekirdeğin numarasını girin: " choice
    case $choice in
        1 ) kernel="linux";;
        2 ) kernel="linux-hardened";;
        3 ) kernel="linux-lts";;
        4 ) kernel="linux-zen";;
        * ) print "Geçerli bir seçim girmediniz."
            select_kernel
    esac
}

select_network() {
    print "Ağ Ayarları:"
    print "1) IWD: Intel tarafından yazılmış Linux için kablosuz bir arka plan programıdır (yalnızca WiFi)"
    print "2) NetworkManager: Tavsiye edilen evrensel ağ yardımcı programı (hem WiFi hem de Ethernet Destekler)"
    print "3) wpa_supplicant: WEP, WPA ve WPA2 desteğine sahip çapraz platform desteğine sahip (yalnızca WiFi, bir DHCP istemcisi de otomatik olarak yüklenir)"
    print "4) dhcpcd: Temel DHCP istemcisi (Yalnızca Ethernet veya VM'ler)"
    print "5) Bunu daha sonra yapacağım (yalnızca ileri düzey kullanıcılar)"
    read -r -p "Yüklemek istediğiniz ağ yardımcısının numarasını girin: " choice
    case $choice in
        1 ) 
            install_package "iwd"
            enable_service "iwd"
            ;;
        2 ) 
            install_package "networkmanager"
            enable_service "NetworkManager"
            ;;
        3 ) 
            install_package "wpa_supplicant dhcpcd"
            enable_service "wpa_supplicant"
            enable_service "dhcpcd"
            ;;
        4 ) 
            install_package "dhcpcd"
            enable_service "dhcpcd"
            ;;
        5 ) ;;
        * ) 
            print "Geçerli bir seçim yapmadınız."
            select_network
    esac
}


set_user_and_password() {
    local user=$1
    local pass
    local pass_confirm
    local retry_limit=3
    local attempts=0

    if [ "$user" != "root" ]; then
        # Kullanıcıyı oluştur
        arch-chroot /mnt useradd -m -G wheel -s /bin/bash "$user"
    fi

    while true; do
        read -r -s -p "$user için bir şifre belirleyin: " pass
        echo
        read -r -s -p "Şifreyi tekrar girin: " pass_confirm
        echo
        if [ "$pass" == "$pass_confirm" ]; then
            if echo "$user:$pass" | arch-chroot /mnt chpasswd; then
                break
            else
                echo "Şifre belirlenirken bir hata oluştu. Tekrar deneyin."
            fi
        else
            echo "Şifreler eşleşmiyor, tekrar deneyin."
        fi
        attempts=$((attempts + 1))
        if [ "$attempts" -ge "$retry_limit" ]; then
            echo "Çok fazla başarısız deneme. İşlem iptal ediliyor."
            exit 1
        fi
    done
}


detect_microcode() {
    local cpu
    cpu=$(grep vendor_id /proc/cpuinfo)
    if [[ $cpu == *"AuthenticAMD"* ]]; then
        print "Bir AMD CPU algılandı, AMD mikro kodu yüklenecek."
        microcode="amd-ucode"
    else
        print "Bir Intel CPU algılandı, Intel mikro kodu yüklenecek."
        microcode="intel-ucode"
    fi
}

set_hostname() {
    local hostname
    read -r -p "Lütfen ana bilgisayar adını girin: " hostname
    echo "$hostname" > /mnt/etc/hostname
    cat > /mnt/etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $hostname.localdomain   $hostname
EOF
}

set_locale() {
    local locale
    read -r -p "Lütfen kullandığınız yerel ayarı girin (örneğin tr_TR veya en_US): " locale
    locale=${locale:-en_US}
    echo "$locale.UTF-8 UTF-8" > /mnt/etc/locale.gen
    echo "LANG=$locale.UTF-8" > /mnt/etc/locale.conf
}

set_keyboard_layout() {
    local kblayout
    read -r -p "Lütfen kullandığınız klavye düzenini girin (örneğin trq): " kblayout
    kblayout=${kblayout:-trq}
    echo "KEYMAP=$kblayout" > /mnt/etc/vconsole.conf
}

partition_disk() {
    local disk=$1
    read -r -p "Bu, $disk üzerindeki mevcut tüm bölümleri siler. Onaylıyor musunuz? [e/H]: " response
    response=${response,,}
    if [[ "$response" =~ ^(e|evet)$ ]]; then
        print "Disk bölme işlemi başlıyor: $disk."
        wipefs -af "$disk"
        sgdisk -Zo "$disk"
        if [ -d /sys/firmware/efi/efivars ]; then
            parted -s --align optimal "$disk" mklabel gpt
            parted -s --align optimal "$disk" mkpart ESP fat32 1M 513M
            parted -s --align optimal "$disk" set 1 esp on
            parted -s --align optimal "$disk" mkpart primary linux-swap 513M 4G
            parted -s --align optimal "$disk" mkpart primary 4G 100%
        else
            parted -s --align optimal "$disk" mklabel msdos
            parted -s --align optimal "$disk" mkpart primary 1M 513M
            parted -s --align optimal "$disk" mkpart primary 513M 4G
            parted -s --align optimal "$disk" mkpart primary 4G 100%
        fi
    else
        error "Disk bölme işlemi iptal edildi."
    fi
}

format_disk() {
    local disk=$1
    if [[ -d /sys/firmware/efi/efivars ]]; then
        mkfs.ext4 "${disk}3"
        mount "${disk}3" /mnt
        mkfs.fat -F32 "${disk}1"
        mkdir -p /mnt/boot
        mount "${disk}1" /mnt/boot
    else
        mkfs.ext4 "${disk}3"
        mount "${disk}3" /mnt
        mkfs.fat -F32 "${disk}1"
        mkdir -p /mnt/boot
        mount "${disk}1" /mnt/boot
    fi
    mkswap "${disk}2"
    swapon "${disk}2"
}

check_disk_format() {
    if mount | grep -q "/mnt"; then
        print "Disk zaten biçimlendirilmiş ve monte edilmiş, bu adımlar atlanacak."
        return 0
    else
        return 1
    fi
}

run_arch_chroot() {
    arch-chroot /mnt /bin/bash -e <<EOF
    ln -sf /usr/share/zoneinfo/\$(curl -s http://ip-api.com/line?fields=timezone) /etc/localtime
    hwclock --systohc
    locale-gen
    mkinitcpio -P

    if [ -d /sys/firmware/efi/efivars ]; then
        grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --recheck
    else
        grub-install --target=i386-pc $DISK --recheck --debug
        echo "GRUB_DISABLE_OS_PROBER=true" > /etc/default/grub
    fi
    grub-mkconfig -o /boot/grub/grub.cfg

    useradd -m -g users -G wheel -s /bin/bash "$username"
    echo "${username} ALL=(ALL:ALL) ALL" >> /etc/sudoers
    echo "%wheel	ALL=(ALL:ALL) ALL" >> /etc/sudoers
    echo "%wheel	ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers
EOF
}

main() {
    show_logo
    check_internet
    select_disk
    
    if ! check_disk_format; then
        partition_disk "$DISK"
        format_disk "$DISK"
    fi
    
    select_kernel
    detect_microcode
    detect_virtualization
    select_network

    print "Temel sistem kuruluyor (biraz zaman alabilir)."
    pacstrap /mnt --needed base base-devel "$kernel" "$microcode" linux-headers linux-firmware grub rsync efibootmgr reflector man vim nano git sudo

    set_hostname
    set_locale
    set_keyboard_layout

    print "Fstab Oluşturuluyor."
    genfstab -U /mnt >> /mnt/etc/fstab

    read -r -p "Lütfen bir kullanıcı hesabı için ad girin: " username
    set_user_and_password "$username"
    set_user_and_password "root"

    run_arch_chroot

    print "Pacman'da renk, animasyon ve paralel indirme etkinleştiriliyor."
    sed -i 's/#Color/Color\nILoveCandy/;s/^#ParallelDownloads.*$/ParallelDownloads = 10/' /mnt/etc/pacman.conf

    print "Bitti, şimdi yeniden başlatabilirsiniz (kullanıcı adı ve şifre girdikten sonra paketleri yüklemeyi unutmayın)."
}

main

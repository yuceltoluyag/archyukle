#!/usr/bin/env -S bash -e

clear
setfont LatArCyrHeb-19.psfu.gz

LOGFILE="/var/log/arch_install.log"
exec > >(tee -a $LOGFILE) 2>&1

print () {
    echo -e "\e[1m\e[93m[ \e[92m•\e[93m ] \e[4m$1\e[0m" | tee -a $LOGFILE
}

error() {
    printf "%s\n" "$1" | tee -a $LOGFILE
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
    select ENTRY in $(lsblk -dpnoNAME | grep -E "/dev/sd|nvme|vd"); do
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
    print "Sanallaştırma durumu kontrol edildi, algılanan: $hypervisor"
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
    print "2) LTS: Uzun vadeli destek (LTS) Linux çekirdeği"
    read -r -p "İlgili çekirdeğin numarasını girin: " choice
    case $choice in
        1 )
            kernel="linux"
            kernel_headers="linux-headers"
            additional_packages="linux-firmware"
            ;;
        2 )
            kernel="linux-lts"
            kernel_headers="linux-lts-headers"
            additional_packages="linux-firmware"
            ;;
        * )
            print "Geçerli bir seçim yapmadınız."
            select_kernel
            ;;
    esac
    print "Kernel seçimi tamamlandı, seçilen kernel: $kernel"
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
    print "Ağ yapılandırması seçimi tamamlandı."
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
            # UEFI sistemi için GPT ve EFI bölümlemeleri
            parted -s --align optimal "$disk" mklabel gpt
            parted -s --align optimal "$disk" mkpart ESP fat32 1M 513M
            parted -s --align optimal "$disk" set 1 esp on
            parted -s --align optimal "$disk" mkpart primary linux-swap 513M 4G
            parted -s --align optimal "$disk" mkpart primary 4G 100%
            print "UEFI sistemi için disk bölümlendirme tamamlandı."
        else
            # BIOS sistemi için MBR bölümlemeleri
            parted -s --align optimal "$disk" mklabel msdos
            parted -s --align optimal "$disk" mkpart primary ext4 1M 100M
            parted -s --align optimal "$disk" set 1 boot on
            parted -s --align optimal "$disk" mkpart primary linux-swap 100M 4G
            parted -s --align optimal "$disk" mkpart primary ext4 4G 100%
            print "BIOS sistemi için disk bölümlendirme tamamlandı."
        fi
    else
        error "Disk bölme işlemi iptal edildi."
    fi
}

format_disk() {
    local disk=$1
    if [[ -d /sys/firmware/efi/efivars ]]; then
        # UEFI sistemi
        mkfs.fat -F32 "${disk}1"      # EFI System Partition
        mkfs.ext4 "${disk}3"          # Root partition
        mkdir -p /mnt/boot
        mount "${disk}1" /mnt/boot
        mount "${disk}3" /mnt
        print "UEFI sistemi için disk formatlama ve bağlama tamamlandı."
    else
        # BIOS sistemi
        mkfs.ext4 "${disk}1"          # Boot partition
        mkfs.ext4 "${disk}3"          # Root partition
        mkdir -p /mnt/boot
        mount "${disk}1" /mnt/boot
        mount "${disk}3" /mnt
        print "BIOS sistemi için disk formatlama ve bağlama tamamlandı."
    fi
    
    mkswap "${disk}2"
    swapon "${disk}2"
    print "Swap alanı ayarlandı ve etkinleştirildi."
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
    print "Mikro kod algılama tamamlandı, algılanan: $microcode"
}

run_arch_chroot() {
    local disk=$1
    local hostname=""
    local locale=""
    local kblayout=""
    local username=""

    # Kullanıcıdan gerekli bilgileri al
    while [[ -z "$hostname" ]]; do
        read -r -p "Lütfen ana bilgisayar adını girin (boş bırakılamaz): " hostname
    done

    read -r -p "Lütfen kullandığınız yerel ayarı girin (örneğin tr_TR veya en_US): " locale
    locale=${locale:-en_US}

    read -r -p "Lütfen kullandığınız klavye düzenini girin (örneğin trq): " kblayout
    kblayout=${kblayout:-trq}

    while [[ -z "$username" ]]; do
        read -r -p "Lütfen bir kullanıcı hesabı için ad girin: " username
    done

    local pass=""
    local pass_confirm=""
    while true; do
        read -r -s -p "$username için bir şifre belirleyin: " pass
        echo
        read -r -s -p "Şifreyi tekrar girin: " pass_confirm
        echo
        if [ "$pass" == "$pass_confirm" ]; then
            break
        else
            echo "Şifreler eşleşmiyor, tekrar deneyin."
        fi
    done

    local root_pass=""
    local root_pass_confirm=""
    while true; do
        read -r -s -p "Root kullanıcısı için bir şifre belirleyin: " root_pass
        echo
        read -r -s -p "Şifreyi tekrar girin: " root_pass_confirm
        echo
        if [ "$root_pass" == "$root_pass_confirm" ]; then
            break
        else
            echo "Şifreler eşleşmiyor, tekrar deneyin."
        fi
    done

    # Chroot işlemi başlıyor
    print "Chroot işlemi başlıyor..."
    arch-chroot /mnt /bin/bash -e <<EOF
    ln -sf /usr/share/zoneinfo/Europe/Istanbul /etc/localtime
    hwclock --systohc
    locale-gen

    # Hostname ayarı
    echo "$hostname" > /etc/hostname
    cat > /etc/hosts <<EOL
127.0.0.1   localhost
::1         localhost
127.0.1.1   $hostname.localdomain   $hostname
EOL

    # Locale ayarı
    echo "$locale.UTF-8 UTF-8" > /etc/locale.gen
    echo "LANG=$locale.UTF-8" > /etc/locale.conf
    locale-gen

    # Klavye düzeni ayarı
    echo "KEYMAP=$kblayout" > /etc/vconsole.conf

    # Root şifresini ayarlama
    echo "root:$root_pass" | chpasswd

    # Kullanıcı oluşturma ve şifre ayarı
    if id -u "$username" >/dev/null 2>&1; then
        echo "Kullanıcı $username zaten mevcut. Şifresi güncellenecek."
    else
        useradd -m -G wheel -s /bin/bash "$username"
        echo "Kullanıcı $username oluşturuldu."
    fi
    echo "$username:$pass" | chpasswd

    # Sudoers dosyasını düzenleme
    sed -i '/^root ALL=(ALL:ALL) ALL/a ${username} ALL=(ALL:ALL) ALL' /etc/sudoers
    sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

    # GRUB kurulumu ve yapılandırması
    if [ -d /sys/firmware/efi/efivars ]; then
        grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --recheck
    else
        grub-install --target=i386-pc ${disk} --boot-directory=/boot --recheck --debug
    fi
    grub-mkconfig -o /boot/grub/grub.cfg
    echo "GRUB kurulumu ve yapılandırması tamamlandı."

    # Pacman konfigürasyonunu ayarlıyoruz
    cat > /etc/pacman.conf <<'EOL'
#{{{ General options
    [options]
    HoldPkg      = pacman glibc
    CleanMethod  = KeepInstalled
    Architecture = auto
#}}}

#{{{ Misc options
    UseSyslog
    Color
    ILoveCandy
    CheckSpace
    VerbosePkgLists
#}}}

#{{{ Trust
    SigLevel           = Required DatabaseOptional
    LocalFileSigLevel  = Optional
    RemoteFileSigLevel = Required
#}}}

#{{{ Repositories
    [core]
    Include = /etc/pacman.d/mirrorlist

    [extra]
    Include = /etc/pacman.d/mirrorlist

    [community]
    Include = /etc/pacman.d/mirrorlist

    [multilib]
    Include = /etc/pacman.d/mirrorlist
#}}}

# vim:fdm=marker
EOL
    echo "Pacman yapılandırması tamamlandı."
EOF

    print "Chroot işlemi tamamlandı."
}



main() {
    show_logo
    check_internet
    select_disk

    partition_disk "$DISK"
    format_disk "$DISK"

    select_kernel
    detect_microcode
    detect_virtualization
    select_network

    print "Temel sistem kuruluyor (biraz zaman alabilir)."
   if [[ -n "$additional_packages" ]]; then
    pacstrap /mnt --needed base base-devel "$kernel" "$kernel_headers" "$additional_packages" "$microcode" grub rsync efibootmgr reflector man vim nano git sudo || error "Paket yükleme başarısız oldu."
   else
    pacstrap /mnt --needed base base-devel "$kernel" "$kernel_headers" "$microcode" grub rsync efibootmgr reflector man vim nano git sudo || error "Paket yükleme başarısız oldu."
   fi
    run_arch_chroot "$DISK"

    print "Bitti, şimdi yeniden başlatabilirsiniz (kullanıcı adı ve şifre girdikten sonra paketleri yüklemeyi unutmayın)."
}

main

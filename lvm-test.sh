#!/bin/bash

# Terminus fontunu yükleme ve ayarlama (ilk işlem olarak)
echo "Terminus fontu yükleniyor..."
sudo pacman -S --noconfirm terminus-font

# Biraz daha küçük boyutlu Terminus fontunu ayarlama (28pt)
setfont ter-v28b

# Klavye düzenini yükleme (Türkçe Q)
loadkeys trq

# UEFI ya da BIOS kontrolü
if [ -d /sys/firmware/efi ]; then
    echo "UEFI sistemi tespit edildi. UEFI kurulumu başlatılıyor..."
    BOOT_MODE="UEFI"
else
    echo "MBR (BIOS) sistemi tespit edildi. BIOS kurulumu başlatılıyor..."
    BOOT_MODE="BIOS"
fi

# VirtualBox ortamında olup olmadığını kontrol etme
if grep -q "VirtualBox" /sys/class/dmi/id/product_name; then
    echo "VirtualBox ortamı tespit edildi, Ethernet ile devam ediliyor..."
    CONNECTION_TYPE="2"
else
    # Kullanıcıya bağlantı türünü sorma
    echo "Bağlantı türünü seçin:"
    echo "1) Wi-Fi"
    echo "2) Ethernet"
    read -r CONNECTION_TYPE
fi

if [ "$CONNECTION_TYPE" == "1" ]; then
    # Wi-Fi arayüzü tespit etme
    INTERFACE=$(iw dev | awk '$1=="Interface"{print $2}')

    if [ -z "$INTERFACE" ]; then
        echo "Wi-Fi arayüzü bulunamadı! VirtualBox veya fiziksel cihazda çalıştığınızdan emin olun."
        exit 1
    fi

    # Wi-Fi engellemesini kaldırma
    rfkill unblock wifi

    # Wi-Fi arayüzünü etkinleştirme
    ip link set "$INTERFACE" up

    # Wi-Fi ağına bağlanma
    iwctl <<EOF
      station $INTERFACE scan
      station $INTERFACE get-networks
      echo "Bağlanmak istediğiniz ağın ismini girin (SSID):"
      read -r SSID
      station $INTERFACE connect $SSID
      exit
EOF

elif [ "$CONNECTION_TYPE" == "2" ]; then
    # Ethernet arayüzü tespit etme (enp0s3 gibi)
    INTERFACE=$(ip link | awk -F: '/enp/{print $2}' | head -n 1 | xargs)

    if [ -z "$INTERFACE" ]; then
        echo "Ethernet arayüzü bulunamadı!"
        exit 1
    fi

    # Ethernet arayüzünü etkinleştirme
    ip link set "$INTERFACE" up

    # DHCP ile IP adresi alma
    dhclient "$INTERFACE"
else
    echo "Geçersiz seçim! Lütfen 1 veya 2'yi seçin."
    exit 1
fi

# Bağlantıyı test etme
ping -c3 gnu.org

# Mevcut diskleri gösterme
echo "Mevcut diskler:"
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT

# Kurulum diskini belirleme
echo "Kurulum diskinizi belirleyin (örneğin /dev/sda):"
read -r DISK

# Diskte geçersiz GPT veya MBR hataları varsa düzeltme adımları
echo "Diskteki geçersiz partition tablolarını düzeltmek ister misiniz? (y/n)"
read -r FIX_PARTITIONS
if [ "$FIX_PARTITIONS" == "y" ]; then
    sgdisk -Z "$DISK"
    echo "Geçersiz GPT ve MBR tabloları temizlendi. Yeni bir GPT tablosu oluşturuluyor..."
    sgdisk -o "$DISK"  # Bu komut otomatik olarak yeni GPT tablosu oluşturur.
fi

# UEFI ya da BIOS moduna göre bölümlendirme
if [ "$BOOT_MODE" == "UEFI" ]; then
    # UEFI sistemde EFI ve root bölümleri oluşturma
    sgdisk -n 1:0:+512M -t 1:EF00 "$DISK"  # 512MB EFI bölümünü oluşturma
    sgdisk -n 2:0:0 -t 2:8300 "$DISK"  # Kalan alanı root (Linux) bölümü olarak ayarlama
else
    # BIOS sistemde MBR kullanarak bölümlendirme
    parted "$DISK" mklabel msdos
    parted "$DISK" mkpart primary ext4 1MiB 512MiB  # 512MB boot bölümü
    parted "$DISK" set 1 boot on  # Boot flag ekle
    parted "$DISK" mkpart primary ext4 512MiB 100%  # Kalan alanı root olarak ayarla
fi

# Bölümleri tarama
partprobe "$DISK"

# Bölümü temizleme ve şifrelemeye hazırlama
wipefs -a "${DISK}2"  # Tüm dosya sistemi imzalarını kaldır

# Eğer wipefs yeterli olmazsa, dd ile sıfırlayabilirsiniz
dd if=/dev/zero of="${DISK}2" bs=1M count=200  # İlk 200MB'yi sıfırlama (daha derin temizlik)

# Bölümleri formatlama
if [ "$BOOT_MODE" == "UEFI" ]; then
    mkfs.fat -F32 -n ESP "${DISK}1"
    cryptsetup -s 512 -h sha512 -i 5000 luksFormat "${DISK}2"
    cryptsetup luksOpen "${DISK}2" cryptlvm
else
    mkfs.ext4 -F "${DISK}2"  # Root bölümünü force bayrağıyla formatla
    cryptsetup -s 512 -h sha512 -i 5000 luksFormat "${DISK}2"
    cryptsetup luksOpen "${DISK}2" cryptlvm
fi

# LVM oluşturma
pvcreate /dev/mapper/cryptlvm
vgcreate vg /dev/mapper/cryptlvm

echo "Swap alanı için boyut belirtin (örneğin 8G):"
read -r SWAPSIZE

lvcreate --size "$SWAPSIZE" vg --name swap
lvcreate -l +100%FREE vg --name root

# Dosya sistemlerini formatlama
mkfs.ext4 -L ROOT /dev/vg/root
mkswap -L SWAP /dev/vg/swap

# Dosya sistemlerini bağlama ve swap'ı etkinleştirme
mount /dev/vg/root /mnt
if [ "$BOOT_MODE" == "UEFI" ]; then
    mkdir /mnt/efi
    mount "${DISK}1" /mnt/efi
else
    mount "${DISK}1" /mnt/boot
fi
swapon /dev/vg/swap

# Reflector kontrolü ve kurulumu
if ! command -v reflector &> /dev/null; then
    echo "Reflector yüklü değil. Yükleniyor..."
    pacman -S --noconfirm reflector
fi

# Reflector ile en hızlı mirrorları bulma ve kaydetme
reflector --verbose --country 'Germany' -l 5 --sort rate --save /etc/pacman.d/mirrorlist

# Sistemi kurma (Almanya için)
pacstrap -K /mnt base base-devel linux-zen linux-zen-firmware intel-ucode cryptsetup lvm2 vim git iwd sbctl

# fstab oluşturma
genfstab -U /mnt >> /mnt/etc/fstab

# Sistemi yapılandırmak için chroot ortamına girme
arch-chroot /mnt bash <<CHROOT

# Saat dilimini ayarlama
ln -sf /usr/share/zoneinfo/Europe/Istanbul /etc/localtime
hwclock --systohc

# Dil ayarlarını yapılandırma
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "LC_COLLATE=C" >> /etc/locale.conf

# Kullanıcı ekleme ve gruplara dahil etme
echo "Kullanıcı adınızı girin:"
read -r USERNAME
useradd -mG wheel "$USERNAME"
echo "Kullanıcı için şifre oluşturun:"
passwd "$USERNAME"
echo "Root için şifre oluşturun:"
passwd

# Visudo yapılandırması
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Ağ yapılandırması
echo "Hostname belirleyin:"
read -r HOSTNAME
echo "$HOSTNAME" > /etc/hostname
cat <<EOL > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOL

systemctl enable iwd systemd-networkd systemd-resolved systemd-timesyncd
rm /etc/resolv.conf
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# Ağ ayarları yapılandırması
if [ "$CONNECTION_TYPE" == "1" ]; then
    cat <<EOL > /etc/systemd/network/wifi.network
[Match]
Name=$INTERFACE
[Network]
DHCP=yes
IPv6PrivacyExtensions=true
EOL
else
    cat <<EOL > /etc/systemd/network/ethernet.network
[Match]
Name=$INTERFACE
[Network]
DHCP=yes
IPv6PrivacyExtensions=true
EOL
fi

cat <<EOL > /etc/systemd/resolved.conf
DNS=1.1.1.1#cloudflare-dns.com 1.0.0.1#cloudflare-dns.com
FallbackDNS=9.9.9.9#dns.quad9.net 149.112.112.112#dns.quad9.net
DNSSEC=yes
DNSOverTLS=yes
MulticastDNS=no
EOL

# Zaman sunucusu ayarları (İstanbul için)
mkdir -p /etc/systemd/timesyncd.conf.d
cat <<EOL > /etc/systemd/timesyncd.conf.d/local.conf
[Time]
NTP=0.tr.pool.ntp.org 1.tr.pool.ntp.org 2.tr.pool.ntp.org 3.tr.pool.ntp.org
FallbackNTP=0.arch.pool.ntp.org 1.arch.pool.ntp.org 2.arch.pool.ntp.org 3.arch.pool.ntp.org
EOL

# mkinitcpio yapılandırması
sed -i 's/^HOOKS=.*/HOOKS=(base systemd autodetect modconf block sd-encrypt lvm2 filesystems keyboard fsck)/' /etc/mkinitcpio.conf
mkinitcpio -P

# Secure Boot için sbctl yapılandırması
sbctl create-keys
sbctl enroll-keys -m
sbctl sign -s -o /usr/lib/systemd/boot/efi/linuxx64.efi.stub.signed /usr/lib/systemd/boot/efi/linuxx64.efi.stub
sbctl sign -s /efi/EFI/Linux/arch-linux-zen.efi
sbctl sign -s /efi/EFI/Linux/arch-linux-zen-fallback.efi

# Boot loader kurulumu
if [ "$BOOT_MODE" == "UEFI" ]; then
    bootctl install --esp-path=/efi
else
    grub-install --target=i386-pc --recheck "$DISK"
    grub-mkconfig -o /boot/grub/grub.cfg
fi

# Çıkış ve disk senkronizasyonu
exit
sync
poweroff
CHROOT

echo "Kurulum tamamlandı. Sistemi yeniden başlatabilirsiniz."

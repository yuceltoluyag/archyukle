#!/bin/bash

set -e  # Herhangi bir komut başarısız olursa scripti sonlandır

# Çıktıları renklendirmek için renk tanımları
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
BLUE="\e[34m"
CYAN="\e[36m"
RESET="\e[0m"

# Daha iyi okunabilirlik için çıktı fonksiyonları
info() {
    echo -e "${BLUE}[BİLGİ]${RESET} $1"
}

success() {
    echo -e "${GREEN}[BAŞARILI]${RESET} $1"
}

warning() {
    echo -e "${YELLOW}[UYARI]${RESET} $1"
}

error() {
    echo -e "${RED}[HATA]${RESET} $1" >&2
}

input() {
    echo -e "${CYAN}[GİRİŞ]${RESET} $1"
}

# Scriptin root olarak çalıştırıldığından emin ol
if [ "$(id -u)" -ne 0 ]; then
    error "Bu scripti root olarak çalıştırmalısınız!"
    exit 1
fi

# Türkçe Q klavye düzenini yükle
loadkeys trq

# UEFI sistem kontrolü
if [ ! -d /sys/firmware/efi ]; then
    error "Bu script sadece UEFI sistemler için geçerlidir. Çıkılıyor..."
    exit 1
fi

# Terminus fontunu yükle ve ayarla
info "Terminus fontu yükleniyor..."
pacman -S --noconfirm terminus-font
setfont ter-v28b

# Scriptin VirtualBox ortamında çalışıp çalışmadığını kontrol et ve bağlantı türünü belirle
if grep -q "VirtualBox" /sys/class/dmi/id/product_name; then
    info "VirtualBox tespit edildi, Ethernet bağlantısı seçiliyor..."
    CONNECTION_TYPE="2"
else
    # Kullanıcıdan bağlantı türünü seçmesini iste
    echo -e "${CYAN}Bağlantı türünü seçin:${RESET}"
    echo "1) Wi-Fi"
    echo "2) Ethernet"
    read -r CONNECTION_TYPE
fi

# Seçilen bağlantı türüne göre ağ yapılandırmasını ayarla
setup_network() {
    local interface
    if [ "$CONNECTION_TYPE" == "1" ]; then
        interface=$(iw dev | awk '$1=="Interface"{print $2}')
        if [ -z "$interface" ]; then
            error "Wi-Fi arayüzü bulunamadı! VirtualBox veya uygun donanımda çalıştığınızdan emin olun."
            exit 1
        fi
        rfkill unblock wifi
        ip link set "$interface" up
        iwctl <<EOF
        station $interface scan
        station $interface get-networks
EOF
        echo -e "${CYAN}Bağlanmak istediğiniz ağın ismini girin (SSID):${RESET}"
        read -r ssid
        iwctl station "$interface" connect "$ssid"
    elif [ "$CONNECTION_TYPE" == "2" ]; then
        interface=$(ip link | awk -F: '/enp/{print $2}' | head -n 1 | xargs)
        if [ -z "$interface" ]; then
            error "Ethernet arayüzü bulunamadı!"
            exit 1
        fi
        ip link set "$interface" up
        dhclient "$interface"
    else
        error "Geçersiz seçim! Lütfen 1 veya 2'yi seçin."
        exit 1
    fi
}

setup_network

# Disk seçimi
info "Mevcut diskler:"
lsblk -d -n -o NAME,SIZE,MODEL
input "Kurulum yapmak istediğiniz diski seçin (örnek: /dev/sda): "
read -r DISK

# Disk seçilmemişse çık
if [ -z "$DISK" ]; then
    error "Geçerli bir disk seçilmedi. Çıkılıyor."
    exit 1
fi

# Diskin temizlenmesi için çift onay
input "Bu işlem $DISK üzerindeki mevcut bölüm tablosunu silecek. Onaylıyor musunuz [y/N]?: "
read -r disk_response
if ! [[ "${disk_response,,}" =~ ^(yes|y)$ ]]; then
    error "İşlem iptal edildi."
    exit 1
fi

input "Bu işlem $DISK üzerindeki tüm verileri silecek. Devam etmek istediğinizden emin misiniz [yes/NO]?: "
read -r final_confirmation
if ! [[ "${final_confirmation,,}" =~ ^(yes|y)$ ]]; then
    error "Disk temizleme işlemi iptal edildi."
    exit 1
fi

# Disk temizleme ve bölüm oluşturma işlemleri
info "Disk $DISK temizleniyor."
if ! wipefs -af "$DISK" &>/dev/null; then
    error "Disk temizleme başarısız oldu. Çıkılıyor."
    exit 1
fi

if ! sgdisk -Zo "$DISK" &>/dev/null; then
    error "Yeni GPT bölüm tablosu oluşturma başarısız oldu. Çıkılıyor."
    exit 1
fi

# Yeni bölüm düzeni oluşturma
info "$DISK üzerinde bölümler oluşturuluyor."
if ! parted -s "$DISK" mklabel gpt \
  mkpart ESP fat32 1MiB 512MiB \
  set 1 esp on \
  mkpart ARCH 512MiB 100%; then
  error "Bölüm oluşturma başarısız oldu. Çıkılıyor."
  exit 1
fi

ESP="/dev/disk/by-partlabel/ESP"
ARCH="/dev/disk/by-partlabel/ARCH"

# Kernel’e değişikliklerin bildirilmesi
info "Kernel'e disk değişiklikleri bildiriliyor."
if ! partprobe "$DISK"; then
    error "Kernel'e disk değişiklikleri bildirilemedi. Çıkılıyor."
    exit 1
fi

# EFI bölümü FAT32 olarak biçimlendirme
info "EFI bölümü FAT32 olarak biçimlendiriliyor."
if ! mkfs.fat -F 32 "$ESP" &>/dev/null; then
    error "EFI bölümü FAT32 olarak biçimlendirilemedi. Çıkılıyor."
    exit 1
fi

# Root bölümünü BTRFS olarak biçimlendirme
info "Root bölümü BTRFS olarak biçimlendiriliyor."
if ! mkfs.btrfs -f "$ARCH" &>/dev/null; then
    error "Root bölümü BTRFS olarak biçimlendirilemedi. Çıkılıyor."
    exit 1
fi
mount "$ARCH" /mnt

# BTRFS alt hacimlerinin oluşturulması
info "BTRFS alt hacimleri oluşturuluyor."
subvols=(snapshots var_pkgs var_log home)
for subvol in '' "${subvols[@]}"; do
  if ! btrfs su cr /mnt/@"$subvol" &>/dev/null; then
    error "Alt hacim $subvol oluşturulamadı. Çıkılıyor."
    exit 1
  fi
done

# Yeni oluşturulan alt hacimlerin montajı
umount /mnt
info "Yeni oluşturulan alt hacimler monte ediliyor."
mountopts="ssd,noatime,compress-force=zstd:3,discard=async"
if ! mount -o "$mountopts",subvol=@ "$ARCH" /mnt; then
    error "Root alt hacmi monte edilemedi. Çıkılıyor."
    exit 1
fi
mkdir -p /mnt/{home,.snapshots,var/{log,cache/pacman/pkg},boot/efi}
for subvol in "${subvols[@]:2}"; do
  if ! mount -o "$mountopts",subvol=@"$subvol" "$ARCH" /mnt/"${subvol//_//}"; then
    error "Alt hacim $subvol monte edilemedi. Çıkılıyor."
    exit 1
  fi
done
mount -o "$mountopts",subvol=@snapshots "$ARCH" /mnt/.snapshots
mount -o "$mountopts",subvol=@var_pkgs "$ARCH" /mnt/var/cache/pacman/pkg
chattr +C /mnt/var/log
if ! mount "$ESP" /mnt/boot/efi/; then
    error "EFI bölümü monte edilemedi. Çıkılıyor."
    exit 1
fi

# Temel Sistem Kurulumu
info "Temel sistem kurulumu yapılıyor."
pacstrap /mnt base base-devel linux linux-firmware linux-headers linux-firmware intel-ucode btrfs-progs grub grub-btrfs rsync efibootmgr reflector snapper snap-pac zram-generator sudo git nano vim pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber bluez bluez-utils

# fstab dosyasının oluşturulması
info "fstab dosyası oluşturuluyor."
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot İçine Geçiş ve Sistem Ayarları
arch-chroot /mnt /bin/bash -e <<EOF

# Hostname ve Ağ Yapılandırması
echo -e "${CYAN}Hostname belirleyin:${RESET}"
read -r hostname
echo "\$hostname" > /etc/hostname
cat <<HOSTS > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   \$hostname.localdomain \$hostname
HOSTS

# Ağ yapılandırması (Bağlantı türüne göre)
if [ "$CONNECTION_TYPE" == "1" ]; then
    cat <<NETWORK > /etc/systemd/network/wifi.network
[Match]
Name=$interface
[Network]
DHCP=yes
IPv6PrivacyExtensions=true
NETWORK
else
    cat <<NETWORK > /etc/systemd/network/ethernet.network
[Match]
Name=$interface
[Network]
DHCP=yes
IPv6PrivacyExtensions=true
NETWORK
fi

# DNS ayarları
cat <<RESOLVED > /etc/systemd/resolved.conf
DNS=1.1.1.1#cloudflare-dns.com 1.0.0.1#cloudflare-dns.com
FallbackDNS=9.9.9.9#dns.quad9.net 149.112.112.112#dns.quad9.net
DNSSEC=yes
DNSOverTLS=yes
MulticastDNS=no
RESOLVED

# Zaman senkronizasyonu
mkdir -p /etc/systemd/timesyncd.conf.d
cat <<TIMESYNC > /etc/systemd/timesyncd.conf.d/local.conf
[Time]
NTP=0.tr.pool.ntp.org 1.tr.pool.ntp.org 2.tr.pool.ntp.org 3.tr.pool.ntp.org
FallbackNTP=0.arch.pool.ntp.org 1.arch.pool.ntp.org 2.arch.pool.ntp.org 3.arch.pool.ntp.org
TIMESYNC

# Zaman Dilimi ve Saat Ayarları
ln -sf /usr/share/zoneinfo/$(curl -s http://ip-api.com/line?fields=timezone) /etc/localtime
hwclock --systohc

# Dil Ayarları
locale-gen

# initramfs Oluşturulması
mkinitcpio -P

# Snapper Yapılandırması (Btrfs için)
snapper --no-dbus -c root create-config /
btrfs subvolume delete /.snapshots
mkdir /.snapshots
mount -a
chmod 750 /.snapshots

# PC Speaker Devre Dışı Bırakılması (Beep Sesi Kapatma)
echo -e "blacklist pcspkr\nblacklist snd_pcsp" > /etc/modprobe.d/nobeep.conf

# GRUB Kurulumu ve Yapılandırması
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Reflector Yapılandırması (Son 5 Almanya Yansıması)
mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
reflector -l 5 -c "Germany" -p https --sort rate --save /etc/pacman.d/mirrorlist
cat <<REFLECTOR > /etc/xdg/reflector/reflector.conf
--latest 5
--country Germany
--protocol https
--sort rate
--save /etc/pacman.d/mirrorlist
REFLECTOR

# Pacman Ayarları (Paralel İndirme ve Renkli Çıktı)
sed -Ei 's/^#(Color)$/\1\nILoveCandy/;s/^#(ParallelDownloads).*/\1 = 10/' /etc/pacman.conf

# Root şifresinin ayarlanması
echo -e "${CYAN}Root şifresini belirleyin:${RESET}"
passwd

# Kullanıcı oluşturma ve sudo yetkisi verme
echo -e "${CYAN}Yeni bir kullanıcı adı girin:${RESET}"
read -r username
useradd -m -G wheel -s /bin/bash "\$username"
echo -e "${CYAN}Kullanıcı şifresini belirleyin:${RESET}"
passwd "\$username"
sed -i '/%wheel ALL=(ALL) ALL/s/^#//' /etc/sudoers

# Eksik firmware dosyalarının yüklenmesi
info "Gerekli firmware dosyaları yükleniyor..."
pacman -S --noconfirm linux-firmware

# Konsol fontu ayarlama (opsiyonel)
echo "FONT=ter-v28b" > /etc/vconsole.conf

EOF

# Chroot dışına çıkıldıktan sonra hizmetleri etkinleştirin
info "Chroot işlemi tamamlandı, gerekli hizmetler etkinleştiriliyor..."
arch-chroot /mnt /bin/bash <<EOF
systemctl daemon-reload
systemctl enable NetworkManager
systemctl enable systemd-resolved
systemctl enable reflector.timer
EOF

# Tüm bölümleri kaldır ve scripti sonlandır
umount -R /mnt

success "Kurulum tamamlandı! Şimdi sistemi yeniden başlatabilirsiniz."

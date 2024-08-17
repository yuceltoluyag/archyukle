#!/bin/bash

# Klavye düzenini yükleme (Türkçe Q)
loadkeys trq

# Wi-Fi arayüzü engellemesini kaldırma ve etkinleştirme
rfkill unblock wifi
ip link set wlan0 up

# Wi-Fi bağlantısını ayarlama
iwctl <<EOF
  station wlan0 scan
  station wlan0 get-networks
  station wlan0 connect "SSID_ADINIZ"
  exit
EOF

# Bağlantıyı test etme
ping -c3 gnu.org

# Disk bölümleme ve formatlama (UEFI)
sgdisk -Z /dev/sda
gdisk /dev/sda
# 1. 512MB ESP bölümü oluşturma ve EFI System türü atama (ef00)
# 2. Geriye kalan alanı Linux dm-crypt türü (8308) olarak atama
partprobe -s /dev/sda

# Bölümleri formatlama
mkfs.fat -F32 -n ESP /dev/sda1  # ESP bölümü formatlama
cryptsetup -s 512 -h sha512 -i 5000 luksFormat /dev/sda2  # CRYPT bölümü formatlama
cryptsetup luksOpen /dev/sda2 cryptlvm

# LVM Yapılandırma
pvcreate /dev/mapper/cryptlvm
vgcreate vg /dev/mapper/cryptlvm
lvcreate --size 8G vg --name swap  # Swap alanı oluşturma
lvcreate -l +100%FREE vg --name root  # Kalan alanı root için ayırma

# Dosya sistemlerini formatlama
mkfs.ext4 -L ROOT /dev/vg/root
mkswap -L SWAP /dev/vg/swap

# Dosya sistemlerini bağlama
mount /dev/vg/root /mnt
mkdir /mnt/efi
mount /dev/sda1 /mnt/efi
swapon /dev/vg/swap

# Aynaları güncelleme ve temel sistemi kurma
reflector --country Germany --age 24 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
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
cat <<EOL > /etc/systemd/network/wifi.network
[Match]
Name=wlan0
[Network]
DHCP=yes
IPv6PrivacyExtensions=true
EOL

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
bootctl install --esp-path=/efi

# Çıkış ve disk senkronizasyonu
exit
sync
poweroff
CHROOT

echo "Kurulum tamamlandı. Sistemi yeniden başlatabilirsiniz."

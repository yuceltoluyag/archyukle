#!/bin/bash

green='\033[32m'
red='\033[31m'
reset='\033[0m'
CONSOLE_KEYMAP="trq"
CONSOLE_FONT="iso09.16"

trap 'umount -R /mnt' INT TERM EXIT

function fail {
    echo $@
    exit -1
}

echo hit ctrl-c
sleep 3

echo -e "$red (1/1) >>>>> Bilgisayar(Hostname) Adını Girin $reset"
[ -z "$hn" ] && read hn
[ -z "$hn" ] && fail no hostname
echo -e "$red (1/2) >>>>> Lütfen disk adı giriniz:          $reset sd(x)"
disk=$(ls -1 /dev/vd? /dev/nvme?n? /dev/sd? /dev/hd? | head -n1)
[ -z "$disk" ] && read disk
[ -z "$disk" ] && fail no disk

#[ -z "$ap" ] && read ap # hiç gerek yok paketyukleyicimiz var efenim

fdisk $disk <<EOF || true
o #create new partition table
n # create 128M of swap
p #primary
1

+2G
t
82
n # rest is for root
p # primary
2


p # print
w #write changes
EOF

partprobe $disk

d1=${disk}1
d2=${disk}2

mkswap -L swap $d1
mkfs.ext4 -L root $d2 # -F -F
swapon $d1
mount $d2 /mnt -o data=writeback,relatime
echo -e "$red (1/3) >>>>> Yansılar Ayarlanıyor.              $reset"
sudo pacman -Syy reflector
sudo reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist
echo -e "$red (1/4) >>>>> Temel Sistem paketleri yükleniyor.       $reset"
pacstrap /mnt --noconfirm base base-devel git zsh vim grub openssh
echo -e "$red (1/5) >>>>> Fstab Dosyanız oluşturuluyor.          $reset"
genfstab -L -p /mnt > /mnt/etc/fstab
echo 'en_US.UTF-8 UTF-8' > /mnt/etc/locale.gen
echo LANG=en_US.UTF-8 > /mnt/etc/locale.conf

ln -sf /usr/share/zoneinfo/Europe/Moscow /mnt/etc/localtime
echo "$hn" >>/mnt/etc/hostname
echo "127.0.1.1       $hn.localdomain        $hn" >>/mnt/etc/hosts
echo -e "$green (1/6) >>>>> 'Root girişi yapıldı ayar dosyaları geliyor'       $reset"
arch-chroot /mnt locale-gen
arch-chroot /mnt pacman -Syyu
arch-chroot /mnt timedatectl set-ntp true
arch-chroot /mnt systemctl enable dhcpcd
arch-chroot /mnt systemctl enable sshd
arch-chroot /mnt grub-install --target=i386-pc --recheck $disk
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
arch-chroot /mnt passwd
mkdir -p /mnt/ayar/
mkdir -p /mnt/root/
curl "https://raw.githubusercontent.com/yuceltoluyag/archyukle/master/ayar.sh" -o /mnt/ayar/config.sh
  chmod +x /mnt/ayar/config.sh
   arch-chroot /mnt /ayar/config.sh
umount -R /mnt
read yolo
[ -z "$yolo" ] && reboot

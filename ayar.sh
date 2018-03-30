#!/bin/bash

red='\033[31m'
reset='\033[0m'


zaman() {
  echo -e "$red (1/1) >>>>> Sistem Saati Ayarlanıyor.                           $reset"
  ln -fs /usr/share/zoneinfo/Europe/Istanbul /etc/localtime

  echo -e "$red (2/2) >>>>> Sistem Saati UTC için Güncelleniyor.                $reset"
  hwclock --systohc --utc
}

dil() {
  echo -e "$red (1/2) >>>>> Dil Ayarları Yapılandırılıyor.   $reset"
  echo -e "localectl set-locale LANG=tr_TR.UTF-8 UTF-8"
  sleep 5
  locale-gen

  echo -e "$red (2/2) >>>>> Sistem dili yapılandırılıyor.                           $reset"
  echo "LANG=tr_TR.UTF-8
LC_CTYPE="tr_TR.UTF-8"
LC_NUMERIC="tr_TR.UTF-8"
LC_TIME="tr_TR.UTF-8"
LC_COLLATE="tr_TR.UTF-8"
LC_MONETARY="tr_TR.UTF-8"
LC_MESSAGES=tr_TR.UTF-8
LC_PAPER="tr_TR.UTF-8"
LC_NAME="tr_TR.UTF-8"
LC_ADDRESS="tr_TR.UTF-8"
LC_TELEPHONE="tr_TR.UTF-8"
LC_MEASUREMENT="tr_TR.UTF-8"
LC_IDENTIFICATION="tr_TR.UTF-8"
LC_ALL=" > /etc/locale.conf
}

makine() {
  echo -e "$red (1/3) >>>>> Makine Adı Ayarları.                               $reset"
  echo -e "$red (2/3) >>>>> Lütfen Bir Makine Adı Giriniz:                  $reset"
  read hn
  echo $hn > /etc/hostname

  echo -e "$red (3/3) >>>>> Host Dosyanız Ayarlanıyor.                    $reset"
  echo -e "127.0.0.1 localhost\n::1       localhost" >> /etc/hosts
}

internetayarlari() {
  echo -e "$red (1/2) >>>>> İnternet Ayarlarınız Yapılandırılıyor                 $reset"
  pacman -S --noconfirm iw wpa_supplicant dialog networkmanager

  echo -e "$red (2/2) >>>>> İnternet Ayarlarınız Başlangıç İçin Etkinleştiriliyor. $reset"
 systemctl enable NetworkManager.service
}

kullaniciayarlari() {
  echo -e "$red (1/6) >>>>> Root için bir parola belirleyiniz.                       $reset"
  echo -e "$red (2/6) >>>>> Root parolasını Giriniz:             $reset"
  read pw
  echo -e "$pw\n$pw" | passwd

  echo -e "$red (3/6) >>>>> Kullanıcı oluşturuluyor.                               $reset"
  echo -e "$red (4/6) >>>>> Lütfen kullanıcı adını giriniz:                  $reset"
  read un
  useradd -m -g users -G optical,storage,wheel,video,audio,users,power,network,log -s /bin/bash $un

  echo -e "$red (5/6) >>>>> Oluşturulan Kullanıcı için şifre belirleyiniz:        $reset"
  read upw
  echo -e "$upw\n$upw" | passwd $un

  echo -e "$red (6/6) >>>>>> Kullanıcı yetkilendiriliyor.                          $reset"
  pacman -S --noconfirm sudo
  echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
}

bootayarlari() {
  echo -e "$red (1/2) >>>>> Boot Dosyası yapılandırılıyor.                          $reset"
  pacman -S --noconfirm grub efibootmgr intel-ucode
  grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=grub

  echo -e "$red (2/2) >>>>> Grub Dosyası oluşturuluyor         $reset"
  mkinitcpio -p linux
  sleep 4
  grub-mkconfig -o /boot/grub/grub.cfg
  sleep 3
  pacman -S xorg xorg-server xorg-xinit mesa alsa-lib alsa-utils gamin dbus
}

zaman
dil
makine
internetayarlari
kullaniciayarlari
bootayarlari

exit
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
  echo -e "tr_TR.UTF-8\tr_TR.UTF-8" > /etc/locale.gen
  locale-gen

  echo -e "$red (2/2) >>>>> Sistem dili yapılandırılıyor.                           $reset"
  echo "LANG=tr_TR.UTF-8" > /etc/locale.conf
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
  pacman -S --noconfirm iw wpa_supplicant dialog

  echo -e "$red (2/2) >>>>> İnternet Ayarlarınız Başlangıç İçin Etkinleştiriliyor. $reset"
  systemctl enable dhcpcd
}

kullaniciayarlari() {
  echo -e "$red (1/6) >>>>> Root için bir parola belirleyiniz.                       $reset"
  echo -e "$red (2/6) >>>>> Root parolasını tekrarlayınız:             $reset"
  read pw
  echo -e "$pw\n$pw" | passwd

  echo -e "$red (3/6) >>>>> Bir kullanıcı oluşturulsun.                               $reset"
  echo -e "$red (4/6) >>>>> Lütfen kullanıcı adını giriniz:                  $reset"
  read un
  pacman -S --noconfirm zsh
  useradd -m -g users -G wheel -s /bin/zsh $un

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
  grub-mkconfig -o /boot/grub/grub.cfg
}

zaman
dil
makine
internetayarlari
kullaniciayarlari
bootayarlari

exit
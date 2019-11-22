#!/bin/bash

red='\033[31m'
reset='\033[0m'

#announce
function kontrol {
  >&2 echo -n "$1"
}

#check_fail
function hata_kontrol {
  if [[ $1 -ne 0 ]]; then
    >&2 echo "HATA!"
    exit 1
  else
    >&2 echo "TAMAM!"
  fi
}


zaman() {
  echo -e "$red (1/1) >>>>> Sistem Saati Ayarlanıyor.                           $reset"
  ln -fs /usr/share/zoneinfo/Europe/Istanbul /etc/localtime

  echo -e "$red (2/2) >>>>> Sistem Saati UTC için Güncelleniyor.                $reset"
  hwclock --systohc --utc
}

dil() {
  echo -e "$red (1/2) >>>>> Dil Ayarları Yapılandırılıyor.   $reset"
  echo -e "localectl set-locale LANG=en_US.UTF-8"
  sleep 5
  locale-gen      
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
  sleep 3
  grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=arch_grub

  echo -e "$red (2/2) >>>>> Grub Dosyası oluşturuluyor         $reset"
  pacman -S linux
  mkinitcpio -p linux
  sleep 4
  grub-mkconfig -o /boot/grub/grub.cfg
  sleep 3
 exit
 umount -R /mnt
 sudo systemctl reboot
}

zaman
dil
makine
internetayarlari
kullaniciayarlari
bootayarlari


#!/bin/bash

green='\033[32m'
red='\033[31m'
reset='\033[0m'
CONSOLE_KEYMAP="trq"
CONSOLE_FONT="iso09.16"

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

uyari() {
  echo -e "                                                                                         "
  echo -e "$red (1/3) >>>>> Lütfen Aşağıdaki notları dikkatle okuyunuz:                        $reset"
  echo -e "                                                                                         "
  echo -e "$green ########################################################################### $reset"
  echo -e "$green * İnternet Bağlantınızın Aktifliğini kontrol edin.   $reset"
  echo -e "$green * Cihazın UEFI ayarlarının Aktifliğini kontrol edin.                                     $reset"
  echo -e "$green * Eğer sanal makineye kurulum yapmayacaksanız bilgilerinizi yedeklemeyi unutmayın               $reset"
  echo -e "$green ########################################################################### $reset"
  echo -e "                                                                                         "

  echo -e "$red (2/3) >>>>> Devam edilsin mi?         $reset Evet(any)/Hayır(h)"
  read getContinue
  if [ $getContinue == h ]; then
    echo -e "$green (0/0) >>>>> 'yüklemeden' çıkıldı.        $reset"
    exit
  fi

  echo -e "$red (3/3) >>>>> Disk bilgileriniz Gösterilsin mi?        $Rest Evet(e)/Hayır(any)"
  read ddi
  if [ $ddi == e ]; then
    fdisk -l
  fi
}

diskayarlari() {
  echo -e "$red (1/5) >>>>> Sistem saatini güncelleniyor.         $Reset"
  timedatectl set-ntp true

  echo -e "$red (2/5) >>>>> Lütfen disk adı giriniz:          $reset sd(x)"
  read diskname
  
  echo -e "$red (3/5) >>>>> Diskleri bölme işlemi başlıyor.             $reset"
  parted -s --align optimal /dev/$diskname mklabel gpt
  parted -s --align optimal /dev/$diskname mkpart primary 0% 512M
  parted -s --align optimal /dev/$diskname mkpart primary 512M 4G
  parted -s --align optimal /dev/$diskname mkpart primary 4G  20G
  parted -s --align optimal /dev/$diskname mkpart primary 20G 100%

  echo -e "$red (4/5) >>>>> Diskler Formatlanıyor.           $reset"
  mkfs.fat -F32 /dev/"$diskname"1
  mkswap /dev/"$diskname"2
  swapon /dev/"$diskname"2
  echo y | mkfs.ext4 /dev/"$diskname"3
  echo y | mkfs.ext4 /dev/"$diskname"4

  echo -e "$red (5/5) >>>>> Diskler Sisteme Yerleştiriliyor.          $reset"
  mount /dev/"$diskname"3 /mnt
  mkdir -p /mnt/boot
  mount /dev/"$diskname"1 /mnt/boot
  mkdir -p /mnt/home
  mount /dev/"$diskname"4 /mnt/home
  lsblk
  sleep 5
}

yukleyici() {
  echo -e "$red (1/2) >>>>> Yansılar Ayarlanıyor.              $reset"
  echo -e "Server = http://ftp.linux.org.tr/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist
  echo -e "\nServer = http://ftp.linux.org.tr/archlinux/\$repo/os/\$arch" >> /etc/pacman.d/mirrorlist

  echo -e "$red (2/2) >>>>> Temel Sistem paketleri yükleniyor.       $reset"
  pacstrap -i /mnt base base-devel
  pacstrap /mnt grub os-prober
}

sistemkonfigure() {
  echo -e "$red (1/2) >>>>> Fstab Dosyanız oluşturuluyor.          $reset"
  genfstab -L -p /mnt >> /mnt/etc/fstab
  sleep 3
   arch-chroot /mnt /bin/bash
}


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

kontrol "$red >>>>>   Sistem dili yapılandırılıyor.... "
cat <<EOF > /mnt/etc/locale.conf
LANG=tr_TR.UTF-8
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
LC_ALL=" 
EOF
hata_kontrol $?
          
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
  grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=arch_grub

  echo -e "$red (2/2) >>>>> Grub Dosyası oluşturuluyor         $reset"
  mkinitcpio -p linux
  sleep 4
  grub-mkconfig -o /boot/grub/grub.cfg
  sleep 3

}

 
 


if [ "$(stat -c %d:%i /)" != "$(stat -c %d:%i /proc/1/root/.)" ]; then
zaman
dil
makine
internetayarlari
kullaniciayarlari
bootayarlari
else
uyari
diskayarlari
yukleyici
sistemkonfigure
fi

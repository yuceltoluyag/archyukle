#!/bin/bash

green='\033[32m'
red='\033[31m'
reset='\033[0m'
CONSOLE_KEYMAP="trq"
CONSOLE_FONT="iso09.16"
sudo pacman -Syy
setfont iso02-12x22
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
  parted -s --align optimal /dev/$diskname mklabel msdos
  parted -s --align optimal /dev/$diskname mkpart primary 0% 512M
  parted -s --align optimal /dev/$diskname mkpart primary 1G 3G
  parted -s --align optimal /dev/$diskname mkpart primary 3G 100%

  echo -e "$red (4/5) >>>>> Diskler Formatlanıyor.           $reset"
  mkfs.fat -F32 /dev/"$diskname"1
  mkswap /dev/"$diskname"2
  swapon /dev/"$diskname"2
  echo y | mkfs.ext4 /dev/"$diskname"3
  echo y | mkfs.ext4 /dev/"$diskname"4

  echo -e "$red (5/5) >>>>> Diskler Sisteme Yerleştiriliyor.          $reset"
  mount /dev/"$diskname"3 /mnt
  mkdir -p /mnt/boot
  mkdir -p /mnt/ayar
  mount /dev/"$diskname"1 /mnt/boot
  lsblk
  sleep 5
}

yukleyici() {
  echo -e "$red (1/2) >>>>> Yansılar Ayarlanıyor.              $reset"
  sudo pacman -Syy
  sudo pacman -S reflector
  sudo reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist
  echo -e "$red (2/2) >>>>> Temel Sistem paketleri yükleniyor.       $reset"
  pacstrap -i /mnt base base-devel
  pacstrap /mnt grub os-prober
}

sistemkonfigure() {
  echo -e "$red (1/2) >>>>> Fstab Dosyanız oluşturuluyor.          $reset"
  genfstab -U -p /mnt >> /mnt/etc/fstab
curl "https://raw.githubusercontent.com/yuceltoluyag/archyukle/master/legacy/ayar.sh" -o /mnt/ayar/config.sh
  chmod +x /mnt/ayar/config.sh
   arch-chroot /mnt /ayar/config.sh
}

if [ "$(stat -c %d:%i /)" != "$(stat -c %d:%i /proc/1/root/.)" ]; then
 echo -e "$green (2/3) >>>>> 'Root girişi yapıldı ayar dosyaları geliyor'       $reset"
else
uyari
diskayarlari
yukleyici
sistemkonfigure
fi

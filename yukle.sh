#!/bin/bash

green='\033[32m'
red='\033[31m'
reset='\033[0m'

uyari() {
  echo -e "                                                                                         "
  echo -e "$red (1/3) >>>>> Please read the following notes carefully:                        $reset"
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
  parted -s --align optimal /dev/$diskname mkpart primary 0% 256M
  parted -s --align optimal /dev/$diskname mkpart primary 256M 4G
  parted -s --align optimal /dev/$diskname mkpart primary 256M 20G
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
  mount /dev/"$diskname"4 /mnt/boot
}
/$repo/os/$arch

yukleyici() {
  echo -e "$red (1/2) >>>>> Yansılar Ayarlanıyor.              $reset"
  echo -e "Server = http://ftp.linux.org.tr/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist
  echo -e "\nServer = http://ftp.linux.org.tr/archlinux/\$repo/os/\$arch" >> /etc/pacman.d/mirrorlist

  echo -e "$red (2/2) >>>>> Temel Sistem paketleri yükleniyor.       $reset"
  pacstrap /mnt base base-devel
}

sistemkonfigure() {
  echo -e "$red (1/2) >>>>> Fstab Dosyanız oluşturuluyor.          $reset"
  genfstab -U /mnt >> /mnt/etc/fstab

  echo -e "$red (2/2) >>>>> Ayar Dosyalarınız Getiriliyor. $reset"
  curl "https://raw.githubusercontent.com/yuceltoluyag/ayar.sh" -o /mnt/root/ayar.sh
  chmod +x /mnt/root/ayar.sh
  arch-chroot /mnt /root/ayar.sh
  rm -rf /mnt/root/ayar.sh
}

uyari
diskayarlari
yukleyici
sistemkonfigure


echo -e "$green (0/0) >>>>> 'Yükleme Tamamlandı.            $reset"
exit
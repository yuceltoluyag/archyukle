# Kolay Arch Linux Kurulumu # archyukle!

Merhaba ! kolay arch linux kurulumu ile kurulum otomatik olarak tamamlanacaktır **Test**. Aşamasındandır geliştirmeye devam ediyorum.
  

# Sanal makinede başlangıçta yeterli sanal disk alanı oluşturma
 - Normal boot -> tab -> cow_spacesize=2G  
 - Uefi Boot -> mount -o remount,size=2G /run/archiso/cowspace  
 - sudo pacman -Syy git curl
 
 - sh -c "$(curl -sL  git.io/vxouh)" #yukle dosyası
 -  sh -c "$(curl -sL git.io/vx1cT)" #ayar dosyası

# Kapatıp açtıktan sonra virtualboxun uefi diski yerleştirmeme sorunu çözümü

 fs0: edit startup.nsh
\EFI\arch_grub\grubx64.efi
ctrl-s <basın>
<enter>
ctrl-q <basın>
reset

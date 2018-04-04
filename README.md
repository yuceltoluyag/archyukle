# Kolay Arch Linux Kurulumu # archyukle!

Merhaba ! kolay arch linux kurulumu ile kurulum otomatik olarak tamamlanacaktır **Test**. Aşamasındandır geliştirmeye devam ediyorum. Şu an için başarılı şekilde kurulum yapabiliyor ancak yinede sanal makine harici denemeyiniz.
  

# Sanal makinede başlangıçta yeterli sanal disk alanı oluşturma
 - Normal boot -> tab -> cow_spacesize=2G  
 - Uefi Boot -> mount -o remount,size=2G /run/archiso/cowspace  
 - sudo pacman -Syy git curl
 
 - sh -c "$(curl -sL  git.io/vxouh)" #yukle dosyası
 -  sh -c "$(curl -sL git.io/vx1cT)" #ayar dosyası

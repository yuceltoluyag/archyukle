# archyukle
arch script denemelerim lütfen sanal makine harici denemeyin.

normal boot -> tab -> cow_spacesize=2G
Uefi   Boot -> mount -o remount,size=2G /run/archiso/cowspace
sudo pacman -Syy git curl

sh -c "$(curl -sL git.io/vxouh)" #yukle dosyası
sh -c "$(curl -sL git.io/vxouN)" #ayar dosyası
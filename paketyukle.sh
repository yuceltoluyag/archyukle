echo "exec i3" >> ~/.xinitrc
echo "[archlinuxfr]
SigLevel = Never
Server = http://repo.archlinux.fr/$arch" >> /etc/pacman.conf

#ne vereyim abime
packages+=( yaourt ) # madirfakir uykum geldi yatacam :D
packages+=( cairo fontconfig freetype2 ttf-anonymous-pro ttf-dejavu ttf-liberation ttf-inconsolata ttf-ubuntu-font-family ttf-croscore ttf-droid ttf-roboto adobe-source-code-pro-fonts adobe-source-sans-pro-fonts adobe-source-serif-pro-fonts) # fontlar
packages+=( xorg xorg-server xorg-xinit lxdm) # sistem dosyaları
packages+=( a52dec faac faad2 flac jasper lame libdca libdv libmad libmpeg2 libtheora libvorbis libxv wavpack x264 xvidcore gstreamer0.10-plugins  ) # Kodekler
packages+=( vlc gimp kdenlive git curl wget filezilla) # madirfakir uykum geldi yatacam :D
packages+=( p7zip unrar file-roller wget gvfs networkmanager-openconnect networkmanager-openvpn networkmanager-pptp networkmanager-vpnc pulseaudio-alsa pavucontrol xfce4-pulseaudio-plugin  ) # madirfakir uykum geldi yatacam :D
packages+=( i3 dmenu xorg xorg-xinit feh ) # masaüstü
pacman --noconfirm --needed -S  ${packages[@]}

# Git ayarları
read -p "Github ayarlarınızı yapalım mı (e/h): " gitsec
if [ "$gitsec" == "e" ] || [ "$gitsec" == "e" ]
then
  read -p "github adınız: " githubadi
  read -p "github mailiniz: " githubmail
fi
# Github Yapılandırma
if [ "$gitsec" == "e" ] || [ "$gitsec" == "e" ]
then
  git config --global user.name $githubadi
  git config --global user.email $githubmail
fi

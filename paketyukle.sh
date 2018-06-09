#!/usr/bin/env bash
echo "================================================"
echo "Yetkili bir abi olduğunuzdan emin olun"
echo "Aurman ve diğer kurulumlar birazdan başlıyor."
echo "================================================"
echo ""
echo -n "paketler yüklenecek hazır mısınız? [E/h] " #winzort sorusu gibi oldu :D
read evet
#ne vereyim abime

bilgi() {
    echo ">> $(tput setaf 2) $@$(tput sgr0)" >&2
}

hata() {
    echo "$(tput bold; tput setaf 5)$@$(tput sgr0)" >&2
}

calis() {
    echo "# $(tput setaf 6)$@$(tput sgr0)" >&2
    "$@"
    code=$?
    if (( code > 0 ))
    then
        hata "hata işlem yapılamadı hata sebebi getiriliyor $code:"
        hata "$@"
        exit $code
    fi
}

if which aurman >/dev/null; then
    bilgi "Aurman  Zaten Yüklü"
    
else
    base=$(pacman -Qs base-devel)
    sudo pacman -Syy
sudo pacman -S git base-devel --noconfirm
git clone  https://aur.archlinux.org/aurman.git 
cd aurman
makepkg -sri
cd ..
rm aurman -rf
    echo "Tamam!"
fi

if [[ $evet == "E" || $evet == "e" || $evet == "" ]]; then
  aurman
else
  echo "Çıkış yapılıyor ..."
  exit 1
fi


# Başlangıçta hangi paketleri kurmak istiyoruz?
ana_paketler=(
fontconfig
freetype2 
ttf-anonymous-pro 
ttf-dejavu 
ttf-liberation 
ttf-inconsolata 
ttf-ubuntu-font-family 
ttf-croscore 
ttf-droid 
ttf-roboto 
adobe-source-code-pro-fonts 
adobe-source-sans-pro-fonts 
adobe-source-serif-pro-fonts
xorg
xorg-server 
xorg-xinit 
lightdm
lightdm-gtk-greeter
vlc 
gimp 
kdenlive 
git 
curl 
wget 
filezilla
p7zip 
unrar 
file-roller 
wget 
networkmanager-openconnect 
networkmanager-openvpn 
networkmanager-pptp 
networkmanager-vpnc 
pulseaudio-alsa 
pavucontrol 
xfce4-pulseaudio-plugin
)

ana_paketleri=(
redshift
htop
bash-completion
gcc
patch
zlib
readline
libxml2
libxslt
bison
autoconf
automake
diffutils
make
libtool
dbus
sudo
wget
)

ana_paketlerin=(
openssh
tar
gzip
unzip
unrar
git
gvim
gvfs
ntfs-3g
gvfs-afc
alsa-oss
alsa-lib
alsa-utils
thunar-volman
zsh
nvidia
lib32-nvidia-utils
lib32-nvidia-libgl
lib32-mesa-demos
libva-vdpau-driver
)

masa_ust=(
    xfce4        # Pencere yöneticisi
    xfce4-goodies     # Durum komutu
    polkit       # PolicyKit
    xorg-xrandr  # Grafik yapılandırmaları
)
 
aur_paket=(
    # program
	libc++
    dropbox
	steam
	steam-fonts 
	telegram-desktop
	whatsapp-web-desktop
	skypeforlinux-stable-bin
	google-chrome
	xarchiver
	ocs-url
    # Font
    otf-vollkorn
    otf-fira-code
    fontawesome.sty
    powerline-fonts-git
    ttf-google-fonts-git
	
)
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

bilgi "Ana Paketleri Yükleniyor"
calis sudo pacman --noconfirm --sync --needed "${ana_paketler[@]}"
bilgi "Ana Paketleri Yükleniyor"
calis sudo pacman --noconfirm --sync --needed "${ana_paketleri[@]}"
bilgi "Ana Paketleri Yükleniyor"
calis sudo pacman --noconfirm --sync --needed "${ana_paketlerin[@]}"
bilgi "Aur Paketleri Yükleniyor"
calis aurman --noconfirm --sync --needed "${aur_paket[@]}"
bilgi "Masaüstünüz Ayalarlanıyor"
calis aurman --noconfirm --sync --needed  "${masa_ust[@]}"
calis sudo systemctl enable lightdm.service
calis sudo systemctl enable nvidia-persistenced.service
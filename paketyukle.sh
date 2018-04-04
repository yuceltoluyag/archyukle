echo "exec i3" >> ~/.xinitrc

echo "================================================"
echo "Yetkili bir abi olduğunuzdan emin olun"
echo "yaourt ve diğer kurulumlar birazdan başlıyor."
echo "================================================"
echo ""
echo -n "paketler yüklenecek hazır mısınız? [E/h] " #winzort sorusu gibi oldu :D
read evet


function yaourt {
  base=$(pacman -Qs base-devel)
  if [[ $base == "" ]]; then
    echo "base-devel paketleriniz gözden geçiriliyor."
    echo '"pacman -S base-devel" komutu getiriliyor'
    exit 1
  else
sudo pacman -Syy
sudo pacman -S git base-devel --noconfirm
mkdir yaourt && cd yaourt
git clone https://aur.archlinux.org/package-query.git
git clone https://aur.archlinux.org/yaourt.git
cd package-query
makepkg -sri
cd ..
cd yaourt
makepkg -sri
cd ../..
rm yaourt -rf
    echo "Tamam!"
  fi  
}

if [[ $evet == "E" || $evet == "e" || $evet == "" ]]; then
  yaourt
else
  echo "Çıkış yapılıyor ..."
  exit 1
fi

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
lxdm
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
redshift
htop
bash-completion
)

masa_ust=(
    i3-wm        # Pencere yöneticisi
    i3status     # Durum komutu
    i3lock       # Kilit ekranı
    rofi         # Uygulama başlatıcısı
    rxvt-unicode # terminal
    polkit       # PolicyKit
    xorg-xrandr  # Grafik yapılandırmaları
    dunst        # Bildirim
)
 
aur_paket=(
    # program
	libc++
    urxvt-resize-font-git
    dropbox
	steam
	discord
	telegram-desktop
	whatsapp-desktop
	skype
	google-chrome
    # Font
    otf-vollkorn
    otf-fira-code
    fontawesome.sty
    powerline-fonts-git
	
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
bilgi "Aur Paketleri Yükleniyor"
calis yaourt --noconfirm --sync --needed "${aur_paket[@]}"
bilgi "Masaüstünüz Ayalarlanıyor"
calis sudo -u "$USER" --sync --needed "${masa_ust[@]}"
calis systemctl enable lxdm

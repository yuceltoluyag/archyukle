#!/usr/bin/env bash
echo "================================================"
echo "Yetkili bir abi olduğunuzdan emin olun"
echo "BABA Linux Gururla Sunar"
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


# Başlangıçta hangi paketleri kurmak istiyoruz?
ana_paketler=(
	xorg-fonts
	webkit2gtk
)

ana_paketleri=(

arandr
calcurse
xcompmgr
libnotify
dbus
dunst
sxiv
xwallpaper
ffmpeg
neovim
mpd
mpc
mpv
)

ana_paketlerin=(
mpv
ncmpcpp
newsboat
noto-fonts-emoji
alsa-utils
htop
maim
socat
unrar
unzip
w3m
xcape
xclip
xdotool
xorg-xdpyinfo
youtube-dl
zathura
zathura-djvu
zathura-pdf-mupdf
poppler
mediainfo
atool
fzf
highlight
gst-libav
sxhkd
xorg-setxkbmap
xorg-xmodmap
xorg-xsetroot
xorg-xset
)


 
aur_paket=(
libx11
libxft
webkit2gtk
fontconfig-git
xorg-xwininfo
xorg-xinit
otf-inconsolata-dz
ttf-linux-libertine
lf
xorg-xprop
gst-plugins-good
ts
simple-mtpfs
sc-im
ttf-symbola
unclutter-xfixes-git
	)


bilgi "Ana Paketleri Yükleniyor"
calis sudo pacman --noconfirm --sync --needed "${ana_paketler[@]}"
bilgi "Ana Paketleri Yükleniyor"
calis sudo pacman --noconfirm --sync --needed "${ana_paketleri[@]}"
bilgi "Ana Paketleri Yükleniyor"
calis sudo pacman --noconfirm --sync --needed "${ana_paketlerin[@]}"
bilgi "Aur Paketleri Yükleniyor"
calis aurman --noconfirm --sync --needed "${aur_paket[@]}"
bilgi "İşlem Tamam"
exit

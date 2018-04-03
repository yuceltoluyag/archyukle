#ne vereyim abime
packages+=( cairo fontconfig freetype2 ttf-anonymous-pro ttf-dejavu ttf-liberation ttf-inconsolata ttf-ubuntu-font-family ttf-croscore ttf-droid ttf-roboto adobe-source-code-pro-fonts adobe-source-sans-pro-fonts adobe-source-serif-pro-fonts) # fontlar
packages+=(  ) # sistem dosyaları
packages+=(  ) # programlar
packages+=(  ) # madirfakir uykum geldi yatacam :D

packages+=( i3 dmenu xorg xorg-xinit feh ) # masaüstü

pacman --noconfirm --needed -S  ${packages[@]}

echo "exec i3" >> ~/.xinitrc

#!/bin/bash

# Gerekli paketleri yükleme
install_packages() {
    sudo pacman -S --needed pacman-contrib
}

# Gereksiz paketleri kaldırma
remove_unused_packages() {
    local base_packages
    local all_packages
    local unused_packages

    base_packages=$(for i in $(pacman -Qqg base); do pactree -ul "$i"; done | sort -u)
    all_packages=$(pacman -Qq | sort)
    unused_packages=$(comm -23 <(echo "$all_packages") <(echo "$base_packages"))

    sudo pacman -Rns --noconfirm "$unused_packages"
}

main() {
    install_packages
    remove_unused_packages
}

main

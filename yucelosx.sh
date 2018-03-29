#!/bin/bash

lsblk
echo -en "\nKök olarak kullanılacak bir bölüm seçin (örn: / dev / sdaX): "
read part
part=$(echo "$part" | grep -o "sd.*")
part_selected=$(lsblk | grep "$part")

if [ -n "$part_selected" ]; then
	echo -e "\nSeçtiniğiniz Bölüm:\n$part_selected"
	echo -en "\nBu doğru mu? [e/h]: "
	read input
else
	echo "\nHATA: Böyle bir $part Bölüm Bulunamadı"
	exit 1
fi

case "$input" in
	e|E|evet)	if (df | grep "$part" &>/dev/null); then
					echo -e "\nHATA: $part Bölüm zaten mount edilmiş.Lütfen Tekrar Deneyin"
					exit 1
				fi
	;;
	h|H|hayır)	echo -e "\nÇıkış Lütfen Tekrar Deneyin"
			exit
	;;
	*)	echo -e "\nHATA: Geçersiz Seçim. Çıkılıyor."
		exit 1
	;;
esac

echo -en "\nYeni ext4 dosya sistemi oluşturulsun mu: $part? [e/h]: "
read input

case "$input" in
	e|E|evet)	mkfs.ext4 /dev/$part
	;;
	h|H|hayır) echo -e "\nDosya sistemi oluşturmadan devam edilecek."
	;;
	*)	echo -e "\nHATA: Geçersiz Seçim. Çıkılıyor."
		exit 1
	;;
esac

echo -e "\nBelirtilen $part disk girişi /mnt"
mount /dev/$part /mnt

if [ "$?" -gt "0" ]; then
	echo -e "\nDisk girişi $part. Başarısız oldu..."
	exit 1
fi

echo -e "\nArch Linux Kurulum işlemi başlıyor /dev/$part\n"
pacstrap /mnt base base-devel grub

if [ "$?" -gt "0" ]; then
	echo -e "\nYükleme Başarısz oldu çıkılıyor..."
	exit 1
fi

echo -e "\nfstab yazılıyor..."
genfstab -U -p /mnt >> /mnt/etc/fstab

grub_part=$(echo "$part" | grep -o "sd.")
echo -e "\ngrub yükleniyor..."
arch-chroot /mnt grub-install --recheck /dev/$grub_part
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

echo -e "\nDil ayarları yapılıyor"
echo "LANG=tr_TR.UTF-8" > /mnt/etc/locale.conf
echo "tr_TR.UTF-8 UTF-8" >> /mnt/etc/locale.gen
arch-chroot /mnt locale-gen

echo -e "\nSaat ayarları yapılıyor"
arch-chroot /mnt ln -sf /usr/share/zoneinfo/Europe/Istanbul /etc/localtime

echo -en "\nMakine adı giriniz: "
read hostname
echo "$hostname" > /mnt/etc/hostname

while (true) ; do
	echo -en "\nRoot için bir şifre belirleyiniz: "
	read -s password
	echo
	echo -en "Root paralonızı tekrar giriniz: "
	read -s password_confirm

	if [ "$password" != "$password_confirm" ]; then
		echo -e "\nHATA: Parolalar uyuşmuyor. Tekrar deneyin..."
	else
		printf "$password\n$password_confirm" | arch-chroot /mnt passwd &>/dev/null
		unset password password_confirm
		break
	fi
done

echo
echo -en "Sisteminiz için bir kullanıcı adı giriniz: "
read username
arch-chroot /mnt useradd -m -g users -G wheel,power,audio,video,storage -s /bin/bash "$username"

while (true) ; do
	echo -en "\n Kullanıcı için bir şifre belirleyin $username: "
	read -s password
	echo
	echo -en "Parolanızı $username tekrarlayınız: "
	read -s password_confirm

	if [ "$password" != "$password_confirm" ]; then
		echo -e "\nHATA: Parolalar uyuşmuyor. Tekrar deneyin..."
	else
		printf "$password\n$password_confirm" | arch-chroot /mnt passwd "$username" &>/dev/null
		unset password password_confirm
		break
	fi
done

echo -e "\nOluşturulan kullanıcı yetkilendiriliyor $username..."
sed -i '/%wheel ALL=(ALL) ALL/s/^#//' /mnt/etc/sudoers

echo -e "\nİnternetiniz aktif ediliyor..."
arch-chroot /mnt systemctl enable dhcpcd

echo -e "\nKurulum tamamlandı disk çıkarılıyor"
umount -R /mnt

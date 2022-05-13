# Kolay Arch Linux Kurulumu # archyukle!

Merhaba ! kolay arch linux kurulumu ile kurulum otomatik olarak tamamlanacaktır **Test**. Aşamasındandır geliştirmeye devam ediyorum.

[![VIDEO](https://i.ytimg.com/vi/wqs69m9ZDjo/hqdefault.jpg)](https://youtu.be/wqs69m9ZDjo)

```bash
pacman -Sy git
git clone https://github.com/yuceltoluyag/archyukle.git
cd archyukle
chmod +x *.sh
./fulloto.sh
```

Kurulum tamamlandıktan sonra :

```bash
./paketyukle.sh pkglist.txt
```

```diff
+ Pkglist dosyasını kendinize göre düzenlemeyi unutmayın. Mutlaka blog yazımı okuyunuz.
```

## Refind Bootloader

Grub Yerine Refind Kurmak istiyorsanız

```bash
pacman -Sy git
git clone https://github.com/yuceltoluyag/archyukle.git
cd archyukle
chmod +x *.sh
./refind.sh
```

```diff
- Refind sadece uefi sistemleri destekler.
```

![Refind](refind.png "The rEFInd Boot Manager")


# Baba.log
Bu projedeki tüm önemli değişiklikler bu dosyada belgelenecektir.

### Fixed
 
## [0.0.2] - 09-04-2022
  
0.0.2 güncellemesiyle birlikte tüm sorunlar giderilmiştir. 
 
### Özellik
* [Uefi Desteği](https://github.com/yuceltoluyag/archyukle/blob/master/fulloto.sh#L245)
* [Refind](https://github.com/yuceltoluyag/archyukle/blob/master/refind.sh) 
* [Terminal fontu](https://github.com/yuceltoluyag/archyukle/blob/master/fulloto.sh#L5) daha büyük hale getirildi
* Bazı paketler eklendi, unutmayın [pklist.txt](https://github.com/yuceltoluyag/archyukle/blob/master/pkglist.txt) kendinize göre özelleştirmelisiniz.
5. Otomatik ekran kartı tespit edicisi ekledim ama bazı sistemlerde eski tip sürücüler olduğu için aktifleştirmedim.  Onada bir çözüm bulacağım :)  [Ekran Kartı Tespit](https://github.com/yuceltoluyag/archyukle/blob/96db8592d840f0ad4c0cfcc709952602f377f52b/paketyukle.sh#L103)
 
 
### Fixed
 * Sudoers Problemi Giderildi [sudoers dosyası düzenlenmiyor  #1](https://github.com/yuceltoluyag/archyukle/issues/1)
 * Refind için oluştulan hook dosyaları düzeltiltidi [pacman hooku düzelt](https://github.com/yuceltoluyag/archyukle/issues/4)
 



# 2 Yıl Sonra gelen Güncelleme

Detaylar Muhteşem Blogumda :D [Kalitenin Bir Numaralı Adresine Hoşgeldiniz](https://yuceltoluyag.github.io/) 😅 😂 🤣

## Bir Kaç Bilgi!

**Gerek yok** ama illa ki kullanacağım diyorsanız :

`pacman -Syu` komutunu **kullanmak** isterseniz.

- Sanal makinede başlangıçta yeterli sanal disk alanı oluşturma

* Normal boot -> tab -> cow_spacesize=2G
* Uefi Boot -> mount -o remount,size=2G /run/archiso/cowspace

## virtualboxta UEFI Disk Sorunu ile Karşılaşırsanız

Virtualboxun uefi diski yerleştirmeme sorunu çözümü

- Sanal Makinenizi Başlatın.
- Karşınıza gelen ekrana şu komutları yazın :

```bash

    fs0: edit startup.nsh
    \EFI\arch_grub\grubx64.efi
    ctrl-s <basın>
    <enter>
    ctrl-q <basın>
    reset
```

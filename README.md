
# Kolay Arch Linux Kurulumu: **archyukle**

[![ShellCheck](https://github.com/yuceltoluyag/archyukle/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/yuceltoluyag/archyukle/actions/workflows/shellcheck.yml)

Merhaba! Kolay Arch Linux kurulumu ile kurulum otomatik olarak tamamlanacaktır. **Test** aşamasındadır ve geliştirmeye devam ediyorum. Detaylar muhteşem blogumda :D [Kalitenin Bir Numaralı Adresine Hoşgeldiniz](https://yuceltoluyag.github.io/) 😅 😂 🤣

## İçindekiler

- [Scriptin İşlevleri](#scriptin-i̇şlevleri)
- [Kurulum Adımları](#kurulum-adımları)
  - [Adım 1: Git ve Scriptlerin İndirilmesi](#adım-1-git-ve-scriptlerin-i̇ndirilmesi)
  - [Adım 2: Paketlerin Yüklenmesi](#adım-2-paketlerin-yüklenmesi)
- [Refind Bootloader](#refind-bootloader)
- [Baba.log](#babalog)
  - [0.0.3 - 2023-10-10](#003---2023-10-10)
  - [0.0.2 - 2022-09-04](#002---2022-09-04)
- [Birkaç Bilgi](#birkaç-bilgi)
- [VirtualBox'ta UEFI Disk Sorunu ile Karşılaşırsanız](#virtualboxta-uefi-disk-sorunu-ile-karşılaşırsanız)

## Scriptin İşlevleri

Bu script, Arch Linux kurulumunu kolaylaştırmak için tasarlanmıştır ve aşağıdaki adımları otomatikleştirir:

1. **Disk Seçimi ve Bölümlendirme**: Sistemdeki mevcut disklerin listesini gösterir ve kullanıcıdan kurulumu yapmak istediği diski seçmesini ister. Seçilen diski UEFI veya BIOS/MBR sistemine göre bölümlendirir.
2. **İnternet Bağlantısı Kontrolü**: İnternet bağlantısının mevcut olup olmadığını kontrol eder.
3. **Sanallaştırma Tespiti ve Gerekli Paketlerin Yüklenmesi**: Kullanılan sanallaştırma platformunu tespit eder (KVM, VMware, VirtualBox, Hyper-V) ve ilgili paketleri yükler.
4. **Kernel Seçimi**: Kullanıcıdan yüklemek istediği Linux çekirdeğini seçmesini ister (varsayılan, hardened, LTS, Zen).
5. **Ağ Bağlantısı Yönetim Yardımcı Programı Seçimi**: Kullanıcıdan ağ bağlantısını yönetmek için kullanmak istediği yardımcı programı seçmesini ister (IWD, NetworkManager, wpa_supplicant, dhcpcd).
6. **Kullanıcı ve Root Şifre Belirleme**: Kullanıcı ve root hesabı için şifre belirler.
7. **Mikro Kod Tespiti ve Yüklenmesi**: Sistem CPU'sunu tespit eder (AMD veya Intel) ve ilgili mikro kodu yükler.
8. **Hostname, Locale ve Klavye Düzeni Ayarları**: Kullanıcıdan sistem hostname, locale ve klavye düzeni ayarlarını yapmasını ister.
9. **Temel Sistem Kurulumu**: Temel Arch Linux sistemini, seçilen çekirdeği ve gerekli paketleri yükler.
10. **rEFInd Bootloader Kurulumu ve Yapılandırılması**: rEFInd bootloader'ı kurar ve yapılandırır.
11. **Pacman Konfigürasyonu**: Pacman paket yöneticisinde renk, animasyon ve paralel indirme özelliklerini etkinleştirir.
12. **Pacman Hooks**: /boot yedeklemesi ve rEFInd güncellemelerini otomatikleştirir.

[![Click to Watch the Video](https://raw.githubusercontent.com/yuceltoluyag/archyukle/main/youtube.webp)](https://youtu.be/wqs69m9ZDjo "Easy Arch Linux Installer Bash Script")

## Kurulum Adımları

### Adım 1: Git ve Scriptlerin İndirilmesi

```bash
pacman -Sy git
git clone https://github.com/yuceltoluyag/archyukle.git
cd archyukle
chmod +x *.sh
./fulloto.sh
```

### Adım 2: Paketlerin Yüklenmesi

Kurulum tamamlandıktan sonra:

```bash
./paketyukle.sh pkglist.txt
```

> **Not:** Pkglist dosyasını kendinize göre düzenlemeyi unutmayın. Detaylar için blog yazımı okuyunuz.

## Refind Bootloader

Grub yerine Refind kurmak istiyorsanız:

```bash
pacman -Sy git
git clone https://github.com/yuceltoluyag/archyukle.git
cd archyukle
chmod +x *.sh
./refind.sh
```

> **Dikkat:** Refind sadece UEFI sistemleri destekler.

![Refind](refind.png "The rEFInd Boot Manager")

## Baba.log

Bu projedeki tüm önemli değişiklikler bu dosyada belgelenecektir.

### [0.0.3] - 2023-10-10

#### Özellikler

- **Yedekleme Sistemi**: /boot yedeklemesi için otomatik bir sistem eklendi.
- **Yeni Ağ Yardımcı Programı**: NetworkManager yerine IWD'yi seçme seçeneği eklendi.
- **Paket Yükleme İyileştirmeleri**: Paket yükleme sürecinde hata yönetimi geliştirildi.

#### Düzeltmeler

- **Grub Kurulum Hatası**: Grub kurulumunda yaşanan bir hata giderildi.
- **Pacman Hookları**: Pacman hookları için yapılan iyileştirmeler ve hatalar düzeltildi.

### [0.0.2] - 2022-09-04

#### Özellikler

- [Uefi Desteği](https://github.com/yuceltoluyag/archyukle/blob/master/fulloto.sh#L245)
- [Refind](https://github.com/yuceltoluyag/archyukle/blob/master/refind.sh)
- [Terminal fontu](https://github.com/yuceltoluyag/archyukle/blob/master/fulloto.sh#L5) daha büyük hale getirildi.
- Bazı paketler eklendi, unutmayın [pkglist.txt](https://github.com/yuceltoluyag/archyukle/blob/master/pkglist.txt) dosyasını kendinize göre özelleştirmelisiniz.
- Otomatik ekran kartı tespit edicisi eklendi fakat bazı sistemlerde eski tip sürücüler olduğu için aktifleştirilmedi. Onun için bir çözüm bulacağım :) [Ekran Kartı Tespit](https://github.com/yuceltoluyag/archyukle/blob/96db8592d840f0ad4c0cfcc709952602f377f52b/paketyukle.sh#L103)

#### Düzeltmeler

- Sudoers problemi giderildi [sudoers dosyası düzenlenmiyor #1](https://github.com/yuceltoluyag/archyukle/issues/1)
- Refind için oluşturulan hook dosyaları düzeltildi [pacman hooku düzelt](https://github.com/yuceltoluyag/archyukle/issues/4)

## Birkaç Bilgi!

**Gerek yok** ama illa ki kullanacağım diyorsanız `pacman -Syu` komutunu **kullanmak** isterseniz:

- Sanal makinede başlangıçta yeterli sanal disk alanı oluşturma:
  - Normal boot -> `tab` -> `cow_spacesize=2G`
  - UEFI Boot -> `mount -o remount,size=2G /run/archiso/cowspace`

## VirtualBox'ta UEFI Disk Sorunu ile Karşılaşırsanız

VirtualBox'un UEFI diski yerleştirmeme sorunu çözümü:

- Sanal Makinenizi Başlatın.
- Karşınıza gelen ekrana şu komutları yazın:

```bash
fs0: edit startup.nsh
\EFIrch_grub\grubx64.efi
ctrl-s <basın>
<enter>
ctrl-q <basın>
reset
```

Bu düzenlemelerle README dosyanız daha bilgilendirici, kullanıcı dostu ve kolay gezilebilir hale gelecektir.

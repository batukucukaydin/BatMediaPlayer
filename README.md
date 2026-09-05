<div align="center">

<img src="baticon.png" alt="BatMediaPlayer logosu" width="128" />

# BatMediaPlayer

**MacOS için modern, sade ve güçlü bir medya oynatıcı.**

Ses ve video dosyalarınızı tek bir oynatma listesinde yönetin; albüm kapaklarını, metadata bilgilerini ve oynatma kontrollerini şık bir arayüzde kullanın.

</div>

## Özellikler

- Ses ve video dosyalarını oynatma
- Albüm kapağı ve metadata gösterimi
- Oynatma listesi, kuyruk ve son kullanılan dosyalar
- Arama, sürükle-bırak ve dosya menüsü desteği
- Oynatma hızı ve ses seviyesi kontrolü
- Tekrar, karıştırma ve A/B döngü noktası
- Altyazı ve ses kanalı seçimi
- Picture-in-Picture video oynatma
- Mini Player modu
- Güncel macOS görünümüne uygun koyu arayüz
- Türkçe ve İngilizce yerelleştirme

## Gereksinimler

- macOS 14 veya üzeri
- Xcode Command Line Tools veya Xcode
- Apple Silicon Mac için hazırlanmıştır

## Çalıştırma

Projeyi klonladıktan sonra proje klasöründe:

```bash
swift run
```

## Uygulama paketi oluşturma

Kurulabilir `.app` paketi oluşturmak için:

```bash
./build.sh
```

Oluşturulan uygulama:

```text
build/BatMediaPlayer.app
```

Uygulamayı `/Applications` klasörüne kopyalamak için:

```bash
cp -R "build/BatMediaPlayer.app" /Applications/
```

## Kısayollar

| Kısayol | İşlev |
| --- | --- |
| `⌘ O` | Dosya aç |
| `⌘ ⇧ O` | Oynatma listesine dosya ekle |
| `Space` | Oynat / duraklat |
| `⌘ ←` | Önceki parça |
| `⌘ →` | Sonraki parça |
| `⌥ ⌘ P` | Picture-in-Picture |
| `⌘ M` | Mini Player |
| `⌘ S` | Video karesi yakala |

## Proje yapısı

```text
Sources/BatMediaPlayer/
├── Models/       # Medya veri modelleri
├── Services/     # Metadata, playlist ve dosya servisleri
├── ViewModels/   # Oynatma durumu ve iş mantığı
└── Views/        # SwiftUI arayüz bileşenleri
```

## Lisans

Bu proje kişisel kullanım ve geliştirme amacıyla hazırlanmıştır.

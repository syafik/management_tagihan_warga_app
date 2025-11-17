# PWA Icons

Generate PWA icons dari logo Anda menggunakan tools berikut:

## Option 1: Online Tools (Recommended - Fastest)

### PWA Asset Generator
https://www.pwabuilder.com/imageGenerator

1. Upload logo (512x512 PNG recommended)
2. Download semua icon sizes
3. Extract ke folder ini

### Favicon Generator
https://realfavicongenerator.net/

1. Upload logo
2. Pilih platform: iOS, Android, Windows
3. Download package
4. Extract ke folder ini

## Option 2: Manual dengan ImageMagick

```bash
# Install ImageMagick
brew install imagemagick  # macOS
# or
sudo apt-get install imagemagick  # Linux

# Generate icons dari base icon
convert logo-512.png -resize 72x72 icon-72x72.png
convert logo-512.png -resize 96x96 icon-96x96.png
convert logo-512.png -resize 128x128 icon-128x128.png
convert logo-512.png -resize 144x144 icon-144x144.png
convert logo-512.png -resize 152x152 icon-152x152.png
convert logo-512.png -resize 192x192 icon-192x192.png
convert logo-512.png -resize 384x384 icon-384x384.png
convert logo-512.png -resize 512x512 icon-512x512.png
```

## Required Icon Sizes

- ✅ 72x72 - Android launcher (small)
- ✅ 96x96 - Android launcher
- ✅ 128x128 - Windows tile
- ✅ 144x144 - Windows tile
- ✅ 152x152 - iOS home screen
- ✅ 192x192 - Android launcher (standard)
- ✅ 384x384 - Splash screen
- ✅ 512x512 - Android launcher (large), Splash screen

## Current Status

⚠️ **Icons belum di-generate**

Silakan generate icons menggunakan salah satu method di atas, lalu paste ke folder ini.

Untuk sementara, app akan gunakan default browser icon.

## Quick Start

1. Siapkan logo format PNG (512x512px minimum)
2. Kunjungi https://www.pwabuilder.com/imageGenerator
3. Upload logo
4. Download zip file
5. Extract semua file ke `/public/pwa-icons/`
6. Refresh app dan check manifest

## Verification

Setelah icons ready, verify dengan:
- Chrome DevTools → Application → Manifest
- Check semua icons loaded
- Test install app di Android/iOS

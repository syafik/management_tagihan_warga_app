# Puri Ayana Landing Page

Landing page profesional untuk website Puri Ayana yang dibangun dengan Astro.

## Features

- ✨ Desain modern dan responsif
- 📱 Mobile-friendly
- 🚀 Super cepat (static site)
- 📥 Download link untuk APK Android
- 🌐 Link ke web app untuk iOS/browser
- 💡 Clean dan profesional

## Development

### Prerequisites

- Node.js 18+
- npm atau pnpm

### Setup

```bash
# Install dependencies
npm install

# Run development server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview
```

## Deployment ke VPS

### 1. Setup Server (First Time Only)

Di VPS, jalankan script setup:

```bash
./setup-server.sh
```

Script ini akan:
- Membuat direktori `/var/www/puriayana-info`
- Membuat folder `/var/www/puriayana-info/downloads` untuk APK
- Setup nginx configs
- Setup SSL dengan certbot

### 2. Deploy Landing Page

Setiap kali ada update pada landing page:

```bash
./deploy-landing.sh
```

Script ini akan:
- Build Astro site
- Deploy ke `/var/www/puriayana-info`
- Set permissions yang benar

### 3. Upload APK

Upload file APK Android ke VPS:

```bash
# Di VPS
sudo cp /path/to/puriayana.apk /var/www/puriayana-info/downloads/puriayana.apk
sudo chmod 644 /var/www/puriayana-info/downloads/puriayana.apk
```

Atau menggunakan scp dari local:

```bash
# Dari local machine
scp puriayana.apk user@your-vps:/tmp/
ssh user@your-vps "sudo mv /tmp/puriayana.apk /var/www/puriayana-info/downloads/ && sudo chmod 644 /var/www/puriayana-info/downloads/puriayana.apk"
```

## File Structure

```
puriayana-landing/
├── src/
│   └── pages/
│       └── index.astro       # Main landing page
├── public/                    # Static assets
├── package.json
└── astro.config.mjs
```

## Customization

Edit [`src/pages/index.astro`](src/pages/index.astro) untuk mengubah:
- Konten teks
- Warna tema (CSS variables di `:root`)
- Fitur-fitur yang ditampilkan
- Link dan URLs

## Production URLs

- **Landing Page**: https://puriayana.com
- **Web App**: https://app.puriayana.com
- **APK Download**: https://puriayana.com/downloads/puriayana.apk

## Tech Stack

- **Astro**: Modern static site generator
- **Pure CSS**: No frameworks, lightweight
- **Responsive Design**: Mobile-first approach
- **SEO Optimized**: Meta tags dan semantic HTML

#!/bin/bash

# Deploy Astro Landing Page to VPS
# This script builds the Astro site and deploys it to /var/www/puriayana-info

set -e  # Exit on error

echo "🚀 Deploying Puri Ayana Landing Page..."
echo ""

# Check if we're in the right directory
if [ ! -d "puriayana-landing" ]; then
    echo "❌ Error: puriayana-landing directory not found!"
    echo "Please run this script from the project root directory."
    exit 1
fi

# Navigate to landing page directory
cd puriayana-landing

# Install dependencies if node_modules doesn't exist
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
    echo ""
fi

# Build the Astro site
echo "🔨 Building Astro site..."
npm run build
echo ""

# Check if build was successful
if [ ! -d "dist" ]; then
    echo "❌ Error: Build failed! dist directory not found."
    exit 1
fi

echo "✅ Build completed successfully!"
echo ""

# Deploy to VPS
echo "📤 Deploying to /var/www/puriayana-info..."

# Remove old files (except downloads folder)
sudo find /var/www/puriayana-info -mindepth 1 -not -name 'downloads' -not -path '*/downloads/*' -delete

# Copy new build files
sudo cp -r dist/* /var/www/puriayana-info/

# Set proper permissions
sudo chown -R $USER:$USER /var/www/puriayana-info
sudo chmod -R 755 /var/www/puriayana-info

echo ""
echo "✅ Deployment completed successfully!"
echo ""
echo "🌐 Your site is now live at: https://puriayana.com"
echo ""
# echo "📱 To upload APK file:"
# echo "   sudo cp /path/to/your-app.apk /var/www/puriayana-info/downloads/puriayana.apk"
# echo ""
# echo "📋 Next steps:"
# echo "   1. Upload your Android APK to /var/www/puriayana-info/downloads/"
# echo "   2. Test the download link at https://puriayana.com"
# echo "   3. Share the URL with your residents!"

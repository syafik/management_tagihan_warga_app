#!/bin/bash
# scripts/deploy.sh - Simple deployment script

set -e

APP_DIR="/home/deploy/management_tagihan_warga_app"
cd $APP_DIR

echo "🚀 Starting deployment..."

# Pull latest code
echo "📥 Pulling latest code..."
git pull origin main

# Install dependencies
echo "📦 Installing dependencies..."
bundle install --deployment --without development test
npm install

# Run database migrations
echo "🗄️ Running database migrations..."
RAILS_ENV=production bundle exec rails db:migrate

# Precompile assets
echo "🎨 Precompiling assets..."
RAILS_ENV=production bundle exec rails assets:precompile

# Restart services
echo "🔄 Restarting services..."
sudo systemctl restart puma
sudo systemctl restart delayed-job

echo "✅ Deployment completed successfully!"

# Show status
echo "📊 Service status:"
sudo systemctl status puma --no-pager -l
sudo systemctl status delayed-job --no-pager -l
#!/bin/bash

# Simple Deploy Script - Run from LOCAL machine
# No sudo required for basic deployment

set -e

# Prompt for VPS connection details
read -p "Enter VPS IP address(103.160.62.145): " VPS_IP
if [ -z "$VPS_IP" ]; then
    echo "Error: VPS IP address is required"
    exit 1
fi

read -p "Enter VPS username: " VPS_USER
if [ -z "$VPS_USER" ]; then
    echo "Error: VPS username is required"
    exit 1
fi

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"
}

log "=== Simple Deployment ==="
echo -e "${BLUE}VPS:${NC} $VPS_USER@$VPS_IP"

ssh $VPS_USER@$VPS_IP << ENDSSH
cd /var/www/puriayana-app

echo "[REMOTE] Pulling latest code..."
git checkout master
git pull origin master

echo "[REMOTE] Installing Ruby gems..."
/home/$VPS_USER/.rbenv/shims/bundle install --deployment --without development test

echo "[REMOTE] Installing Node dependencies (if needed)..."
if [ -f "package.json" ]; then
    npm install --production
fi

echo "[REMOTE] Compiling assets..."
RAILS_ENV=production /home/$VPS_USER/.rbenv/shims/bundle exec rails assets:precompile

echo "[REMOTE] Running database migrations..."
RAILS_ENV=production /home/$VPS_USER/.rbenv/shims/bundle exec rails db:migrate

echo "[REMOTE] Clearing Rails cache..."
RAILS_ENV=production /home/$VPS_USER/.rbenv/shims/bundle exec rails tmp:clear
RAILS_ENV=production /home/$VPS_USER/.rbenv/shims/bundle exec rails tmp:create

echo "[REMOTE] Basic deployment completed!"

ENDSSH

log "✅ Deployment completed!"
log "🔄 Restarting services..."

# Ask for sudo password once
echo -n "Enter sudo password for $VPS_USER@$VPS_IP: "
read -s SUDO_PASSWORD
echo

# Restart puma service
log "Restarting puma service..."
echo "$SUDO_PASSWORD" | ssh $VPS_USER@$VPS_IP 'sudo -S systemctl restart puma.service'

# Reload systemd daemon and restart solid_queue
log "Reloading systemd daemon..."
echo "$SUDO_PASSWORD" | ssh $VPS_USER@$VPS_IP 'sudo -S systemctl daemon-reload'

log "Restarting solid_queue service..."
echo "$SUDO_PASSWORD" | ssh $VPS_USER@$VPS_IP 'sudo -S systemctl restart solid_queue.service'

log "Checking solid_queue status..."
ssh $VPS_USER@$VPS_IP 'systemctl is-active solid_queue.service && echo "✅ Solid Queue is running" || echo "⚠️  Solid Queue failed to start"'

# Clear password from memory
unset SUDO_PASSWORD

log "🎉 Deployment and service restart completed!"
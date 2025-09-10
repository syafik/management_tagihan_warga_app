# 📋 Installation Guide - PuriAyana Management System

This guide provides step-by-step instructions for installing and deploying the PuriAyana Management System (Residential Billing Management Application).

## 📑 Table of Contents

1. [System Requirements](#system-requirements)
2. [Development Environment Setup](#development-environment-setup)
3. [Production Deployment](#production-deployment)
4. [Configuration](#configuration)
5. [Troubleshooting](#troubleshooting)
6. [Maintenance](#maintenance)

---

## 🖥️ System Requirements

### Minimum Requirements
- **OS**: Ubuntu 20.04+ / CentOS 8+ / macOS 10.15+
- **RAM**: 2GB minimum, 4GB recommended
- **Storage**: 20GB free space
- **CPU**: 2 cores minimum

### Software Dependencies
- **Ruby**: 3.2.1
- **Node.js**: 18.x LTS
- **PostgreSQL**: 13+
- **Redis**: 6+
- **Nginx**: 1.18+ (production only)

---

## 🛠️ Development Environment Setup

### 1. Prerequisites Installation

#### On Ubuntu/Debian:
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install essential packages
sudo apt install -y curl wget git build-essential libssl-dev libreadline-dev zlib1g-dev \
    libpq-dev libffi-dev libyaml-dev libgdbm-dev libncurses5-dev libffi-dev \
    imagemagick libvips42 redis-server

# Install PostgreSQL
sudo apt install -y postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

#### On macOS:
```bash
# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install dependencies
brew install postgresql redis imagemagick libvips node rbenv ruby-build
brew services start postgresql
brew services start redis
```

### 2. Ruby Installation

```bash
# Install rbenv
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash

# Add to shell profile
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
source ~/.bashrc

# Install Ruby 3.2.1
rbenv install 3.2.1
rbenv global 3.2.1

# Verify installation
ruby -v
# Should output: ruby 3.2.1
```

### 3. Node.js Installation

```bash
# Install Node.js 18.x
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Verify installation
node -v  # Should output: v18.x.x
npm -v   # Should output: 9.x.x
```

### 4. Database Setup

```bash
# Create PostgreSQL user
sudo -u postgres createuser -s $USER
sudo -u postgres psql -c "ALTER USER $USER PASSWORD 'your_password';"

# Create databases
createdb management_tagihan_warga_development
createdb management_tagihan_warga_test
```

### 5. Application Setup

```bash
# Clone repository
git clone https://github.com/yourusername/management_tagihan_warga_app.git
cd management_tagihan_warga_app

# Install Ruby gems
gem install bundler
bundle install

# Install Node packages
npm install

# Setup environment variables
cp .env.local.example .env.local
```

### 6. Environment Configuration

Edit `.env.local` file:
```bash
# Database
DATABASE_URL=postgresql://username:password@localhost/management_tagihan_warga_development

# Rails
RAILS_ENV=development
SECRET_KEY_BASE=run_bundle_exec_rails_secret_to_generate

# Google Drive (optional for development)
# GDRIVE_CONFIG=your_service_account_json

# WhatsApp API (optional for development)
# WHATSAPP_API_URL=your_whatsapp_api_url
# WHATSAPP_API_TOKEN=your_api_token
```

### 7. Database Migration & Seed

```bash
# Run migrations
bundle exec rails db:migrate

# Seed initial data
bundle exec rails db:seed

# Create admin user (optional)
bundle exec rails console
User.create!(
  name: "Admin",
  email: "admin@puriayana.com",
  password: "admin123",
  phone_number: "+6281234567890",
  role: 2
)
```

### 8. Start Development Server

```bash
# Start Rails server
bundle exec rails server

# In another terminal, start background jobs
bundle exec rake jobs:work

# In another terminal, start Vite dev server (if using Vite)
npm run dev
```

**Access the application at:** `http://localhost:3000`

---

## 🚀 Production Deployment

### 1. Server Preparation

#### VPS Setup (Ubuntu 20.04+):
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Create deploy user
sudo adduser deploy
sudo usermod -aG sudo deploy

# Switch to deploy user
sudo su - deploy

# Setup SSH keys
mkdir -p ~/.ssh
echo "your_ssh_public_key" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh
```

### 2. Install Dependencies

```bash
# Install system dependencies
sudo apt install -y curl wget gnupg2 software-properties-common apt-transport-https ca-certificates \
    git build-essential libssl-dev libreadline-dev zlib1g-dev libpq-dev libffi-dev libyaml-dev \
    libgdbm-dev libncurses5-dev imagemagick libvips42 nginx redis-server

# Install PostgreSQL
sudo apt install -y postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Install Ruby via rbenv
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
source ~/.bashrc
rbenv install 3.2.1
rbenv global 3.2.1

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs
```

### 3. Database Setup

```bash
# Create database user
sudo -u postgres createuser -s deploy
sudo -u postgres psql -c "ALTER USER deploy PASSWORD 'secure_production_password';"

# Create production database
sudo -u postgres createdb puriayana_production -O deploy
```

### 4. Application Deployment

```bash
# Clone repository
cd /home/deploy
git clone https://github.com/yourusername/management_tagihan_warga_app.git
cd management_tagihan_warga_app

# Install dependencies
gem install bundler
bundle install --deployment --without development test
npm install

# Setup environment
cp .env.local.example .env.local
nano .env.local
```

**Production Environment Variables:**
```bash
RAILS_ENV=production
DATABASE_URL=postgresql://deploy:secure_production_password@localhost/puriayana_production
SECRET_KEY_BASE=generate_with_rails_secret_command
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true

# Production domain
APP_URL=https://your-domain.com

# Google Drive API (required for features)
GDRIVE_CONFIG=your_service_account_json_config

# WhatsApp API (required for notifications)
WHATSAPP_API_URL=your_whatsapp_api_endpoint
WHATSAPP_API_TOKEN=your_whatsapp_api_token

# Email configuration (SendInBlue)
SENDINBLUE_API_KEY=your_sendinblue_api_key
```

### 5. Database & Assets

```bash
# Generate secret key
bundle exec rails secret

# Run migrations
RAILS_ENV=production bundle exec rails db:migrate

# Precompile assets
RAILS_ENV=production bundle exec rails assets:precompile

# Create required directories
mkdir -p tmp/pids log tmp/sockets
```

### 6. Nginx Configuration

```bash
# Create Nginx config
sudo nano /etc/nginx/sites-available/puriayana
```

```nginx
upstream puma {
  server unix:///home/deploy/management_tagihan_warga_app/tmp/sockets/puma.sock;
}

server {
  listen 80;
  server_name your-domain.com www.your-domain.com;

  root /home/deploy/management_tagihan_warga_app/public;
  access_log /var/log/nginx/puriayana_access.log;
  error_log /var/log/nginx/puriayana_error.log info;

  location ^~ /assets/ {
    gzip_static on;
    expires 1y;
    add_header Cache-Control public;
    add_header Last-Modified "";
    add_header ETag "";
    break;
  }

  location / {
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header Host $http_host;
    proxy_redirect off;
    try_files $uri @puma;
  }

  location @puma {
    proxy_pass http://puma;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header Host $http_host;
    proxy_redirect off;
  }

  error_page 500 502 503 504 /500.html;
  client_max_body_size 10M;
  keepalive_timeout 10;
}
```

```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/puriayana /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
```

### 7. Systemd Services

#### Puma Service:
```bash
sudo nano /etc/systemd/system/puma.service
```

```ini
[Unit]
Description=Puma HTTP Server
After=network.target

[Service]
Type=notify
User=deploy
Group=deploy
WorkingDirectory=/home/deploy/management_tagihan_warga_app
Environment=RAILS_ENV=production
Environment=BUNDLE_GEMFILE=/home/deploy/management_tagihan_warga_app/Gemfile
ExecStart=/home/deploy/.rbenv/shims/bundle exec puma -C /home/deploy/management_tagihan_warga_app/config/puma_production.rb
ExecReload=/bin/kill -USR1 $MAINPID
Restart=always
RestartSec=1
SyslogIdentifier=puma

[Install]
WantedBy=multi-user.target
```

#### Delayed Job Service:
```bash
sudo nano /etc/systemd/system/delayed-job.service
```

```ini
[Unit]
Description=Delayed Job Workers
After=network.target

[Service]
Type=simple
User=deploy
Group=deploy
WorkingDirectory=/home/deploy/management_tagihan_warga_app
Environment=RAILS_ENV=production
Environment=BUNDLE_GEMFILE=/home/deploy/management_tagihan_warga_app/Gemfile
ExecStart=/home/deploy/.rbenv/shims/bundle exec rake jobs:work
Restart=always

[Install]
WantedBy=multi-user.target
```

```bash
# Enable and start services
sudo systemctl daemon-reload
sudo systemctl enable puma delayed-job
sudo systemctl start puma delayed-job
```

### 8. SSL Certificate

```bash
# Install Certbot
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot

# Generate SSL certificate
sudo certbot --nginx -d your-domain.com -d www.your-domain.com

# Verify auto-renewal
sudo systemctl status snap.certbot.renew.timer
```

---

## ⚙️ Configuration

### Important Configuration Files

1. **`config/database.yml`** - Database configuration
2. **`config/routes.rb`** - Application routing
3. **`config/puma_production.rb`** - Puma server configuration
4. **`.env.local`** - Environment variables
5. **`CLAUDE.md`** - Project-specific instructions

### Key Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `DATABASE_URL` | PostgreSQL connection string | Yes |
| `SECRET_KEY_BASE` | Rails secret key | Yes |
| `RAILS_ENV` | Environment (development/production) | Yes |
| `GDRIVE_CONFIG` | Google Drive service account JSON | For import features |
| `WHATSAPP_API_URL` | WhatsApp API endpoint | For notifications |
| `WHATSAPP_API_TOKEN` | WhatsApp API token | For notifications |
| `APP_URL` | Application URL | For links in notifications |

---

## 🔧 Troubleshooting

### Common Issues

#### 1. Database Connection Error
```bash
# Check PostgreSQL status
sudo systemctl status postgresql

# Check database exists
psql -d puriayana_production -c "SELECT 1;"

# Verify credentials in .env.local
```

#### 2. Asset Compilation Failed
```bash
# Clear assets
bundle exec rails assets:clobber

# Recompile
RAILS_ENV=production bundle exec rails assets:precompile
```

#### 3. Puma Won't Start
```bash
# Check logs
sudo journalctl -u puma -f

# Check socket permissions
ls -la /home/deploy/management_tagihan_warga_app/tmp/sockets/

# Restart service
sudo systemctl restart puma
```

#### 4. Nginx 502 Bad Gateway
```bash
# Check Puma is running
sudo systemctl status puma

# Check socket file exists
ls -la /home/deploy/management_tagihan_warga_app/tmp/sockets/puma.sock

# Check Nginx error logs
tail -f /var/log/nginx/puriayana_error.log
```

#### 5. Background Jobs Not Working
```bash
# Check delayed job service
sudo systemctl status delayed-job

# Check job queue
bundle exec rails console
> Delayed::Job.count

# Restart delayed job
sudo systemctl restart delayed-job
```

### Log Locations

- **Rails logs**: `/home/deploy/management_tagihan_warga_app/log/production.log`
- **Puma logs**: `sudo journalctl -u puma -f`
- **Delayed Job logs**: `sudo journalctl -u delayed-job -f`
- **Nginx access logs**: `/var/log/nginx/puriayana_access.log`
- **Nginx error logs**: `/var/log/nginx/puriayana_error.log`

---

## 🔄 Maintenance

### Regular Maintenance Tasks

#### 1. Application Updates
```bash
# Use the deployment script
cd /home/deploy/management_tagihan_warga_app
./scripts/deploy.sh
```

#### 2. Database Backup
```bash
# Create backup
pg_dump puriayana_production > backup_$(date +%Y%m%d_%H%M%S).sql

# Restore from backup
psql puriayana_production < backup_20240101_120000.sql
```

#### 3. Log Rotation
```bash
# Rails logs
sudo logrotate -f /etc/logrotate.d/rails

# Or manually compress old logs
gzip /home/deploy/management_tagihan_warga_app/log/production.log.1
```

#### 4. Monitoring Commands
```bash
# Check all services
sudo systemctl status nginx puma delayed-job postgresql redis

# Check disk usage
df -h

# Check memory usage
free -h

# Check active connections
ss -tuln | grep :80
```

### Automated Monitoring Script
```bash
#!/bin/bash
# Place in /home/deploy/scripts/health_check.sh

echo "=== System Health Check ==="
echo "Date: $(date)"
echo

echo "Services Status:"
sudo systemctl is-active nginx puma delayed-job postgresql redis

echo -e "\nDisk Usage:"
df -h /

echo -e "\nMemory Usage:"
free -h

echo -e "\nDatabase Connection:"
psql puriayana_production -c "SELECT 1;" > /dev/null 2>&1 && echo "OK" || echo "FAILED"

echo -e "\nRecent Errors (last 10):"
tail -10 /home/deploy/management_tagihan_warga_app/log/production.log | grep ERROR || echo "No recent errors"
```

### Performance Optimization

1. **Database Indexing**: Regularly check and add indexes for slow queries
2. **Asset Optimization**: Ensure assets are properly minified and gzipped
3. **Database Cleanup**: Regularly clean old delayed job records
4. **Log Management**: Implement proper log rotation

---

## 📞 Support

For technical support and issues:

1. Check this installation guide first
2. Review application logs for error details
3. Check the [CLAUDE.md](./CLAUDE.md) file for project-specific guidance
4. Refer to the Rails documentation for framework-related issues

---

**Last Updated:** January 2025
**Version:** 1.0.0
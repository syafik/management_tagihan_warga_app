#!/bin/bash

# Setup Server untuk 2 Website di VPS
echo "Setting up server directories and nginx configs..."

# 1. Create directories for both websites
sudo mkdir -p /var/www/puriayana-info
sudo mkdir -p /var/www/puriayana-app
sudo mkdir -p /var/www/puriayana-app/tmp/sockets
sudo mkdir -p /var/www/puriayana-app/tmp/pids
sudo mkdir -p /var/www/puriayana-app/log

# 2. Set permissions
sudo chown -R $USER:$USER /var/www/puriayana-info
sudo chown -R $USER:$USER /var/www/puriayana-app

# 3. Copy nginx configs
sudo cp nginx-configs/puriayana.com /etc/nginx/sites-available/
sudo cp nginx-configs/app.puriayana.com /etc/nginx/sites-available/

# 4. Enable sites
sudo ln -sf /etc/nginx/sites-available/puriayana.com /etc/nginx/sites-enabled/
sudo ln -sf /etc/nginx/sites-available/app.puriayana.com /etc/nginx/sites-enabled/

# 5. Remove default nginx site
sudo rm -f /etc/nginx/sites-enabled/default

# 6. Test nginx config
sudo nginx -t

# 7. Restart nginx
sudo systemctl restart nginx

# 8. Create sample index.html for main site
cat > /var/www/puriayana-info/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Puri Ayana - Housing Complex</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
        .container { max-width: 800px; margin: 0 auto; }
        .btn { display: inline-block; padding: 10px 20px; background: #007bff; color: white; text-decoration: none; border-radius: 5px; margin: 10px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Selamat Datang di Puri Ayana</h1>
        <p>Kompleks Perumahan Modern dengan Fasilitas Lengkap</p>
        
        <h2>Akses Aplikasi</h2>
        <a href="https://app.puriayana.com" class="btn">Login ke Sistem Tagihan</a>
        
        <h2>Informasi Kompleks</h2>
        <p>Puri Ayana adalah kompleks perumahan modern dengan 5 blok (A, B, C, D, F) yang dilengkapi dengan fasilitas lengkap dan sistem manajemen tagihan digital.</p>
    </div>
</body>
</html>
EOF

echo "Setup completed!"
echo ""
echo "Next steps:"
echo "1. Setup DNS A records:"
echo "   - puriayana.com → your VPS IP"
echo "   - app.puriayana.com → your VPS IP"
echo "   - www.puriayana.com → your VPS IP"
echo ""
echo "2. Wait for DNS propagation"
echo ""
echo "3. Get SSL certificates:"
echo "   sudo certbot --nginx -d puriayana.com -d www.puriayana.com -d app.puriayana.com"
echo ""
echo "4. Deploy Rails app to /var/www/puriayana-app/"
echo ""
echo "5. Configure Puma to use socket: /var/www/puriayana-app/tmp/sockets/puma.sock"
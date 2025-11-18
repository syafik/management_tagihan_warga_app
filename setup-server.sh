#!/bin/bash

# Setup Server untuk 2 Website di VPS
echo "Setting up server directories and nginx configs..."

# 1. Create directories for both websites
sudo mkdir -p /var/www/puriayana-info
sudo mkdir -p /var/www/puriayana-info/downloads
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

echo "Server directories created!"
echo ""
echo "NOTE: The old simple HTML has been replaced with Astro landing page."
echo "Please run './deploy-landing.sh' to build and deploy the new Astro site."

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
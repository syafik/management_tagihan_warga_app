server {
    listen 80;
    listen [::]:80;
    
    server_name puriayana.com www.puriayana.com;
    root /var/www/puriayana-info;
    index index.html index.htm index.nginx-debian.html;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/javascript
        application/xml+rss
        application/json;

    # Main location block
    location / {
        try_files $uri $uri/ =404;
    }

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files $uri =404;
    }

    # Redirect www to non-www
    if ($host = www.puriayana.com) {
        return 301 https://puriayana.com$request_uri;
    }

    # Security - deny access to hidden files
    location ~ /\. {
        deny all;
    }

    # Logs
    access_log /var/log/nginx/puriayana.com.access.log;
    error_log /var/log/nginx/puriayana.com.error.log;
}
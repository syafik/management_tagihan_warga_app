upstream puma_app {
    server unix:///var/www/puriayana-app/tmp/sockets/puma.sock fail_timeout=0;
    keepalive 32;
}

server {
    listen 80;
    listen [::]:80;
    
    server_name app.puriayana.com;
    root /var/www/puriayana-app/public;
    
    # Performance optimizations
    client_max_body_size 100M;
    client_body_timeout 30;
    client_header_timeout 30;
    send_timeout 30;
    keepalive_timeout 65;
    keepalive_requests 1000;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline';" always;

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

    # Asset caching
    location ~* ^/assets/ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files $uri =404;
    }

    # Serve static files directly
    location ~* \.(png|jpg|jpeg|gif|ico|svg|css|js|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files $uri =404;
    }

    # Handle uploads
    location /uploads {
        alias /var/www/puriayana-app/public/uploads;
        expires 30d;
        add_header Cache-Control "public";
    }

    # Main application
    location / {
        try_files $uri @puma;
    }

    # Proxy to Puma with optimizations
    location @puma {
        proxy_pass http://puma_app;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Host $http_host;
        proxy_redirect off;
        
        # Optimized timeouts
        proxy_read_timeout 60;
        proxy_connect_timeout 10;
        proxy_send_timeout 60;
        
        # Connection reuse
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        
        # Buffer optimizations
        proxy_buffering on;
        proxy_buffer_size 8k;
        proxy_buffers 16 8k;
        proxy_busy_buffers_size 16k;
    }

    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }

    # Security - deny access to hidden files
    location ~ /\. {
        deny all;
    }

    # Block access to sensitive files
    location ~ /(config|db|log|tmp|spec|test|vendor\/bundle)/ {
        deny all;
    }

    # Logs
    access_log /var/log/nginx/app.puriayana.com.access.log;
    error_log /var/log/nginx/app.puriayana.com.error.log;
}
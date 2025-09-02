# SSL/TLS Certificate setup script for Let's Encrypt
# Run this script on your VPS after deployment to set up SSL certificates

#!/bin/bash

set -e

echo "🔐 Setting up SSL certificates with Let's Encrypt..."

# Check if domain is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <your-domain.com>"
    exit 1
fi

DOMAIN=$1
EMAIL="admin@$DOMAIN"  # Change this to your actual email

echo "Domain: $DOMAIN"
echo "Email: $EMAIL"

# Install Certbot
echo "📦 Installing Certbot..."
sudo apt update
sudo apt install -y certbot python3-certbot-nginx

# Stop nginx temporarily
echo "⏹️ Stopping nginx temporarily..."
docker-compose -f /opt/missionary_platform/docker-compose.production.yml stop nginx

# Generate certificates
echo "🔑 Generating SSL certificates..."
sudo certbot certonly --standalone \
    --preferred-challenges http \
    --email $EMAIL \
    --agree-tos \
    --no-eff-email \
    -d $DOMAIN \
    -d www.$DOMAIN

# Create nginx SSL configuration
echo "⚙️ Creating SSL nginx configuration..."
sudo tee /opt/missionary_platform/config/nginx-ssl.conf > /dev/null <<EOF
worker_processes auto;
worker_rlimit_nofile 65535;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    # Logging
    log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                    '\$status \$body_bytes_sent "\$http_referer" '
                    '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;
    error_log /var/log/nginx/error.log;

    # Basic Settings
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;

    # Gzip Settings
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;

    # Rate limiting
    limit_req_zone \$binary_remote_addr zone=login:10m rate=5r/m;
    limit_req_zone \$binary_remote_addr zone=api:10m rate=20r/m;

    # SSL Configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    upstream rails_app {
        server web:3000 fail_timeout=0;
    }

    # Redirect HTTP to HTTPS
    server {
        listen 80;
        server_name $DOMAIN www.$DOMAIN;
        return 301 https://\$server_name\$request_uri;
    }

    # HTTPS server
    server {
        listen 443 ssl http2;
        server_name $DOMAIN www.$DOMAIN;
        root /app/public;

        # SSL certificates
        ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

        # Security headers
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
        add_header X-Frame-Options DENY;
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";
        add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self'; connect-src 'self'";

        # Static file serving
        location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
            try_files \$uri @rails;
        }

        # Rate limiting for auth endpoints
        location ~ ^/(users/sign_in|users/sign_up|users/password) {
            limit_req zone=login burst=3 nodelay;
            try_files \$uri @rails;
        }

        # API rate limiting
        location /api/ {
            limit_req zone=api burst=10 nodelay;
            try_files \$uri @rails;
        }

        # Health check
        location /health {
            access_log off;
            try_files \$uri @rails;
        }

        # Main application
        location / {
            try_files \$uri @rails;
        }

        location @rails {
            proxy_pass http://rails_app;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            proxy_redirect off;

            # Timeouts
            proxy_connect_timeout 5s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;

            # Buffer settings
            proxy_buffering on;
            proxy_buffer_size 4k;
            proxy_buffers 8 4k;
        }

        # Error pages
        error_page 404 /404.html;
        error_page 500 502 503 504 /500.html;
        location = /404.html {
            internal;
        }
        location = /500.html {
            internal;
        }
    }
}
EOF

# Update docker-compose to use SSL configuration and mount certificates
echo "🐳 Updating docker-compose for SSL..."
sudo tee -a /opt/missionary_platform/docker-compose.production.yml > /dev/null <<EOF

# SSL volumes for nginx
volumes:
  letsencrypt:
    driver: local
    driver_opts:
      type: none
      device: /etc/letsencrypt
      o: bind
EOF

# Update nginx service in docker-compose
sudo sed -i '/nginx:/,/networks:/ {
  /volumes:/a\
      - letsencrypt:/etc/letsencrypt:ro
  /config\/nginx.conf/c\
      - ./config/nginx-ssl.conf:/etc/nginx/nginx.conf:ro
}' /opt/missionary_platform/docker-compose.production.yml

# Start nginx with SSL configuration
echo "🚀 Starting nginx with SSL..."
docker-compose -f /opt/missionary_platform/docker-compose.production.yml up -d nginx

# Set up automatic certificate renewal
echo "🔄 Setting up automatic certificate renewal..."
sudo tee /etc/cron.d/certbot-renew > /dev/null <<EOF
0 12 * * * root certbot renew --quiet --deploy-hook "docker-compose -f /opt/missionary_platform/docker-compose.production.yml restart nginx"
EOF

# Test SSL configuration
echo "🧪 Testing SSL configuration..."
sleep 10
curl -I https://$DOMAIN || echo "SSL test failed - check your DNS and firewall settings"

echo "✅ SSL setup completed!"
echo ""
echo "📋 SSL Certificate Information:"
echo "- Domain: $DOMAIN"
echo "- Certificate location: /etc/letsencrypt/live/$DOMAIN/"
echo "- Auto-renewal: Configured (runs daily at 12:00)"
echo ""
echo "🔧 Next steps:"
echo "1. Test your site: https://$DOMAIN"
echo "2. Update your .env.production file to use HTTPS URLs"
echo "3. Configure DNS records to point to this server"
echo ""
echo "📊 SSL Grade Test:"
echo "Test your SSL configuration at: https://www.ssllabs.com/ssltest/analyze.html?d=$DOMAIN"
EOF

#!/bin/bash

# VPS Deployment Script for Missionary Platform
# This script sets up the production environment on a VPS with 2 CPUs and 8GB RAM

set -e

echo "🚀 Starting VPS deployment for Missionary Platform..."

# Check system resources
echo "📊 Checking system resources..."
free -h
nproc
df -h

# Update system
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Docker and Docker Compose
echo "🐳 Installing Docker and Docker Compose..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
fi

if ! command -v docker-compose &> /dev/null; then
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Create application directory
echo "📁 Creating application directory..."
sudo mkdir -p /opt/missionary_platform
cd /opt/missionary_platform

# Set up environment file
echo "⚙️ Setting up environment configuration..."
if [ ! -f .env.production ]; then
    echo "Please copy .env.production.template to .env.production and configure your values"
    echo "Required variables:"
    echo "- SECRET_KEY_BASE (generate with: openssl rand -hex 64)"
    echo "- Database credentials"
    echo "- Email provider settings"
    echo "- Domain configuration"
    exit 1
fi

# Create necessary directories
echo "📁 Creating necessary directories..."
sudo mkdir -p logs
sudo mkdir -p storage
sudo mkdir -p tmp/pids
sudo mkdir -p public/uploads

# Set permissions
echo "🔐 Setting up permissions..."
sudo chown -R $USER:$USER /opt/missionary_platform

# Pull and build images
echo "🔨 Building application..."
docker-compose -f docker-compose.production.yml build --no-cache

# Start services
echo "🚀 Starting services..."
docker-compose -f docker-compose.production.yml up -d

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 30

# Run database migrations
echo "🗄️ Running database migrations..."
docker-compose -f docker-compose.production.yml exec -T web bundle exec rails db:create db:migrate

# Check service health
echo "🏥 Checking service health..."
docker-compose -f docker-compose.production.yml ps

# Set up log rotation
echo "📝 Setting up log rotation..."
sudo tee /etc/logrotate.d/missionary_platform > /dev/null <<EOF
/opt/missionary_platform/logs/*.log {
    daily
    missingok
    rotate 14
    compress
    notifempty
    create 644 root root
    postrotate
        docker-compose -f /opt/missionary_platform/docker-compose.production.yml restart web sidekiq
    endscript
}
EOF

# Set up backup script
echo "💾 Setting up backup script..."
sudo tee /opt/missionary_platform/backup.sh > /dev/null <<'EOF'
#!/bin/bash
BACKUP_DIR="/opt/backups/missionary_platform"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Database backup
docker-compose -f /opt/missionary_platform/docker-compose.production.yml exec -T db pg_dump -U missionary_user missionary_platform_production > $BACKUP_DIR/db_backup_$DATE.sql

# File storage backup
tar -czf $BACKUP_DIR/storage_backup_$DATE.tar.gz /opt/missionary_platform/storage

# Clean old backups (keep 7 days)
find $BACKUP_DIR -name "*backup*" -mtime +7 -delete

echo "Backup completed: $DATE"
EOF

sudo chmod +x /opt/missionary_platform/backup.sh

# Set up cron for backups
echo "⏰ Setting up backup cron job..."
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/missionary_platform/backup.sh >> /var/log/missionary_backup.log 2>&1") | crontab -

# Set up monitoring script
echo "📊 Setting up monitoring..."
sudo tee /opt/missionary_platform/monitor.sh > /dev/null <<'EOF'
#!/bin/bash
cd /opt/missionary_platform

# Check if services are running
services=("web" "db" "redis" "sidekiq" "nginx")

for service in "${services[@]}"; do
    if ! docker-compose -f docker-compose.production.yml ps | grep -q "$service.*Up"; then
        echo "Service $service is down, restarting..."
        docker-compose -f docker-compose.production.yml restart $service
    fi
done

# Check memory usage
memory_usage=$(free | grep Mem | awk '{printf "%.2f", $3/$2 * 100.0}')
if (( $(echo "$memory_usage > 90" | bc -l) )); then
    echo "High memory usage: ${memory_usage}%"
    # Restart services if memory usage is too high
    docker-compose -f docker-compose.production.yml restart
fi
EOF

sudo chmod +x /opt/missionary_platform/monitor.sh

# Set up monitoring cron
(crontab -l 2>/dev/null; echo "*/5 * * * * /opt/missionary_platform/monitor.sh >> /var/log/missionary_monitor.log 2>&1") | crontab -

# Configure firewall
echo "🔥 Configuring firewall..."
sudo ufw allow 22    # SSH
sudo ufw allow 80    # HTTP
sudo ufw allow 443   # HTTPS
sudo ufw --force enable

# Create systemd service for auto-start
echo "🔄 Setting up auto-start service..."
sudo tee /etc/systemd/system/missionary-platform.service > /dev/null <<EOF
[Unit]
Description=Missionary Platform
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/missionary_platform
ExecStart=/usr/local/bin/docker-compose -f docker-compose.production.yml up -d
ExecStop=/usr/local/bin/docker-compose -f docker-compose.production.yml down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable missionary-platform.service

echo "✅ VPS deployment completed successfully!"
echo ""
echo "📝 Next steps:"
echo "1. Configure your .env.production file with actual values"
echo "2. Set up SSL certificates (Let's Encrypt recommended)"
echo "3. Configure your domain DNS to point to this server"
echo "4. Test the application at http://your-domain.com"
echo ""
echo "📊 Service URLs:"
echo "- Application: http://localhost"
echo "- Sidekiq Web UI: http://localhost/sidekiq (admin only)"
echo ""
echo "🔧 Management commands:"
echo "- Start: docker-compose -f docker-compose.production.yml up -d"
echo "- Stop: docker-compose -f docker-compose.production.yml down"
echo "- Logs: docker-compose -f docker-compose.production.yml logs -f"
echo "- Console: docker-compose -f docker-compose.production.yml exec web bundle exec rails console"
echo ""
echo "📈 Monitoring:"
echo "- System resources: htop, free -h, df -h"
echo "- Application logs: tail -f logs/*.log"
echo "- Service status: docker-compose -f docker-compose.production.yml ps"

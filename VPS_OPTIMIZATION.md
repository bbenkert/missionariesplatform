# VPS Optimization README

This guide provides comprehensive instructions for optimizing the Missionary Platform for deployment on a VPS with 2 CPUs and 8GB RAM.

## 🚀 Quick Start

1. **Copy files to your VPS:**
   ```bash
   scp -r . user@your-vps:/opt/missionary_platform/
   ```

2. **Configure environment:**
   ```bash
   cd /opt/missionary_platform
   cp .env.production.template .env.production
   # Edit .env.production with your actual values
   ```

3. **Run deployment:**
   ```bash
   chmod +x deploy.sh
   ./deploy.sh
   ```

4. **Set up SSL (optional but recommended):**
   ```bash
   chmod +x setup-ssl.sh
   ./setup-ssl.sh your-domain.com
   ```

## 📊 Resource Allocation

The configuration is optimized for 8GB RAM and 2 CPU cores:

- **PostgreSQL**: 3GB RAM (768MB shared_buffers)
- **Redis**: 1GB RAM (LRU eviction)
- **Rails (Puma)**: ~3GB RAM (2 workers, 5 threads each)
- **Sidekiq**: ~512MB RAM (10 concurrent jobs)
- **Nginx**: ~256MB RAM
- **System/OS**: ~768MB RAM

## 🔧 Configuration Files

### Core Files
- `docker-compose.production.yml` - Main production orchestration
- `Dockerfile.production` - Optimized production image
- `.env.production.template` - Environment configuration template

### Service Configurations
- `config/puma/production.rb` - Web server optimization
- `config/postgresql.conf` - Database tuning
- `config/redis.conf` - Caching and session store
- `config/sidekiq.yml` - Background job processing
- `config/nginx.conf` - Reverse proxy and static files

### Scripts
- `deploy.sh` - Automated deployment script
- `setup-ssl.sh` - SSL certificate setup with Let's Encrypt

## 🏗️ Architecture

```
Internet → Nginx (80/443) → Puma (3000) → Rails App
                         ↓
                    PostgreSQL (5432)
                         ↓
                    Redis (6379) ← Sidekiq
```

## 📈 Performance Features

### Caching Strategy
- Redis for Rails cache store
- Redis for session storage
- Nginx static file serving with long expiry
- Database query caching enabled

### Background Jobs
- Sidekiq with Redis backend
- 10 concurrent workers optimized for 2 CPU cores
- Memory-based worker killer (300MB limit)
- Job queues with priorities

### Database Optimization
- Connection pooling (50 max connections)
- Optimized PostgreSQL settings for 3GB allocation
- Query performance monitoring enabled
- Automatic vacuum tuning

### Memory Management
- Puma worker killer at 300MB per worker
- Redis LRU eviction policy
- PostgreSQL shared buffers optimization
- Background job memory limits

## 🔒 Security Features

- SSL/TLS termination at Nginx
- Rate limiting for auth endpoints
- Security headers (HSTS, CSP, etc.)
- Firewall configuration
- Secure session management
- CORS protection

## 📊 Monitoring

### Health Checks
- Application health endpoint (`/health`)
- Service-level health checks in Docker
- Automated monitoring script (runs every 5 minutes)

### Logging
- Centralized logging to stdout
- Log rotation configured
- Nginx access and error logs
- Application and background job logs

### Alerts
- Memory usage monitoring (restart at 90%)
- Service availability checks
- Automatic service restart on failure

## 🔄 Maintenance

### Backups
- Automated daily database backups
- File storage backups
- 7-day retention policy
- Backup verification

### Updates
```bash
# Application updates
cd /opt/missionary_platform
git pull
docker-compose -f docker-compose.production.yml build --no-cache
docker-compose -f docker-compose.production.yml up -d

# System updates
sudo apt update && sudo apt upgrade -y
```

### Scaling Options
If you need more performance:

1. **Vertical Scaling** (upgrade VPS):
   - Update memory allocations in configs
   - Increase worker counts proportionally

2. **Horizontal Scaling** (multiple servers):
   - Separate database server
   - Load balancer with multiple app servers
   - Shared Redis instance

## 🐛 Troubleshooting

### Common Issues

1. **High Memory Usage**
   ```bash
   # Check memory usage
   free -h
   docker stats
   
   # Restart services if needed
   docker-compose -f docker-compose.production.yml restart
   ```

2. **Slow Database Queries**
   ```bash
   # Check PostgreSQL logs
   docker-compose -f docker-compose.production.yml logs db
   
   # Monitor slow queries
   docker-compose -f docker-compose.production.yml exec db psql -U missionary_user -d missionary_platform_production -c "SELECT query, calls, total_time, mean_time FROM pg_stat_statements ORDER BY total_time DESC LIMIT 10;"
   ```

3. **Background Job Issues**
   ```bash
   # Check Sidekiq status
   docker-compose -f docker-compose.production.yml logs sidekiq
   
   # Access Sidekiq web UI
   https://your-domain.com/sidekiq
   ```

### Performance Monitoring
```bash
# System resources
htop
iotop
netstat -tulpn

# Application metrics
docker-compose -f docker-compose.production.yml exec web bundle exec rails console
> Rails.cache.stats
> Sidekiq::Stats.new
```

## 📞 Support

For issues or questions:
1. Check logs: `docker-compose -f docker-compose.production.yml logs`
2. Monitor resources: `htop`, `free -h`, `df -h`
3. Review configuration files for tuning opportunities
4. Consider upgrading VPS resources if consistently hitting limits

## 🎯 Optimization Checklist

- [ ] Environment variables configured
- [ ] SSL certificates installed
- [ ] DNS records pointing to server
- [ ] Firewall configured (ports 22, 80, 443)
- [ ] Backups scheduled and tested
- [ ] Monitoring alerts configured
- [ ] Log rotation set up
- [ ] Performance baseline established

## 📊 Expected Performance

On a 2 CPU / 8GB RAM VPS, you can expect:
- **Concurrent Users**: 100-200 active users
- **Response Time**: < 200ms for cached pages
- **Database**: 1000+ queries/second
- **Background Jobs**: 10 jobs/second processing
- **Uptime**: 99.9% with proper monitoring

This configuration provides excellent performance for small to medium-sized missionary organizations while maintaining cost efficiency.

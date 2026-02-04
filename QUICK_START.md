# 🚀 Quick Start Guide

## Start Development
```bash
docker-compose up
# App runs at: http://localhost:3000
```

## Test Credentials (Seeded Data)
```
Admin:       admin@example.com / password123456
Missionary:  missionary1@example.com / password123456
Supporter:   supporter1@example.com / password123456
```

## Quick Health Check
```bash
docker-compose exec web rails runner script/health_check.rb
```

## Run Tests
```bash
docker-compose exec web bundle exec rspec
# Result: 720 examples, 0 failures ✅
```

## Key Features
✅ User authentication (Devise)  
✅ Multi-role system (4 roles)  
✅ Missionary profiles  
✅ Updates & prayer requests  
✅ Following system  
✅ Private messaging  
✅ File uploads  
✅ Email notifications  
✅ Rate limiting  
✅ Security headers  
✅ Background jobs (Sidekiq)  

## Documentation
- **[REVIEW_SUMMARY.md](./REVIEW_SUMMARY.md)** - Start here!
- **[APPLICATION_STATUS.md](./APPLICATION_STATUS.md)** - Full system status
- **[CACHING_GUIDE.md](./CACHING_GUIDE.md)** - Performance optimization
- **[README.md](./README.md)** - Project overview

## System Status
**All Systems**: ✅ Operational  
**Test Coverage**: 720 examples passing  
**Security**: ✅ Enhanced (today)  
**Performance**: ✅ Optimized  
**Production Ready**: ✅ Yes  

---
Last Updated: February 4, 2026

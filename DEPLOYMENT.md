# Deployment Kılavuzu

## Ön Hazırlık

### Gereksinimler

- Node.js 18.x veya üzeri
- npm 9.x veya üzeri
- Docker (opsiyonel, containerized deployment için)
- Supabase hesabı ve proje

## Supabase Kurulumu

### 1. Supabase Projesi

Proje zaten hazır ve yapılandırılmış durumda:
- Database migration'ları çalıştırılmış
- Edge Function'lar deploy edilmiş
- RLS politikaları aktif

### 2. Environment Variables

`.env` dosyası zaten yapılandırılmış:
```env
VITE_SUPABASE_URL=https://0ec90b57d6e95fcbda19832f.supabase.co
VITE_SUPABASE_ANON_KEY=[configured]
```

Production için kendi değerlerinizi kullanın.

## Local Development

### 1. Bağımlılıkları Yükle

```bash
npm install
```

### 2. Development Server Başlat

```bash
npm run dev
```

Uygulama `http://localhost:5173` adresinde çalışacak.

### 3. Build Test

```bash
npm run build
npm run preview
```

## Production Deployment

### Yöntem 1: Static Hosting (Önerilen)

#### Vercel Deployment

```bash
# Vercel CLI kur
npm i -g vercel

# Deploy et
vercel

# Production deploy
vercel --prod
```

Environment variables'ı Vercel dashboard'dan ekle.

#### Netlify Deployment

```bash
# Netlify CLI kur
npm i -g netlify-cli

# Deploy et
netlify deploy

# Production deploy
netlify deploy --prod
```

`netlify.toml` dosyası:
```toml
[build]
  command = "npm run build"
  publish = "dist"

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
```

### Yöntem 2: Docker Deployment

#### Docker Build

```bash
# Image oluştur
docker build -t hrms-app:latest .

# Container çalıştır
docker run -p 80:80 hrms-app:latest
```

#### Docker Compose

`docker-compose.yml`:
```yaml
version: '3.8'
services:
  app:
    build: .
    ports:
      - "80:80"
    environment:
      - NODE_ENV=production
    restart: unless-stopped
```

Çalıştır:
```bash
docker-compose up -d
```

### Yöntem 3: Geleneksel Server

#### Nginx Deployment

1. Build oluştur:
```bash
npm run build
```

2. `dist/` klasörünü server'a kopyala:
```bash
scp -r dist/* user@server:/var/www/hrms
```

3. Nginx config:
```nginx
server {
    listen 80;
    server_name your-domain.com;
    root /var/www/hrms;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml;
}
```

4. Nginx restart:
```bash
sudo systemctl restart nginx
```

## SSL/HTTPS Kurulumu

### Let's Encrypt (Certbot)

```bash
# Certbot kur
sudo apt-get install certbot python3-certbot-nginx

# SSL sertifikası al
sudo certbot --nginx -d your-domain.com

# Auto-renewal test
sudo certbot renew --dry-run
```

## Environment Configuration

### Production Environment Variables

```env
# Supabase
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your_production_anon_key

# Optional
VITE_APP_VERSION=1.0.0
VITE_ENVIRONMENT=production
```

### Security Checklist

- [ ] HTTPS aktif
- [ ] Environment variables güvenli
- [ ] CORS yapılandırılmış
- [ ] Rate limiting aktif
- [ ] Error logging yapılandırılmış
- [ ] Backup stratejisi hazır

## Database Migration

Migration'lar zaten uygulanmış durumda. Yeni bir ortamda kurulum için:

```bash
# Supabase CLI ile
supabase db push

# Veya manuel olarak Supabase Dashboard'dan
# SQL Editor'de migration dosyalarını çalıştır
```

## Edge Functions

Edge function'lar deploy edilmiş durumda:

- `bordro-hesapla`: Bordro hesaplama
- `izin-hakki-hesapla`: İzin hakkı hesaplama

Yeni deployment gerekirse:

```bash
# Manuel deployment (eğer gerekirse)
# Supabase Dashboard > Edge Functions > Deploy
```

## Monitoring & Logging

### Supabase Dashboard

- Database performansı: [Dashboard > Database]
- API kullanımı: [Dashboard > API]
- Edge Function logs: [Dashboard > Edge Functions]
- Auth metrics: [Dashboard > Authentication]

### Error Tracking

Sentry entegrasyonu için:

```bash
npm install @sentry/react
```

`main.tsx`:
```typescript
import * as Sentry from "@sentry/react";

Sentry.init({
  dsn: "your-sentry-dsn",
  environment: "production",
});
```

## Performance Optimization

### CDN Configuration

Static asset'leri CDN üzerinden servis et:

```nginx
# Nginx cache headers
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

### Compression

```nginx
# Gzip compression
gzip on;
gzip_vary on;
gzip_min_length 1000;
gzip_types text/plain text/css application/json application/javascript text/xml application/xml;
```

## Backup Strategy

### Database Backup

Supabase otomatik backup sağlar, ancak manuel backup için:

```bash
# PostgreSQL dump
pg_dump -h db.your-project.supabase.co -U postgres your_db > backup.sql

# Restore
psql -h db.your-project.supabase.co -U postgres your_db < backup.sql
```

### Scheduled Backups

Cron job örneği:
```bash
0 2 * * * /usr/local/bin/backup-db.sh
```

## Rollback Procedure

Sorun durumunda eski versiyona dönüş:

1. **Docker**: Önceki image'ı çalıştır
```bash
docker run -p 80:80 hrms-app:previous-tag
```

2. **Vercel/Netlify**: Dashboard'dan önceki deployment'ı aktifleştir

3. **Manual**: Önceki build'i deploy et
```bash
git checkout previous-tag
npm run build
# Deploy new build
```

## Health Checks

### Application Health

`/` endpoint'i kontrol et:
```bash
curl https://your-domain.com
```

### API Health

Supabase connection test:
```bash
curl https://your-project.supabase.co/rest/v1/
```

## Troubleshooting

### Build Hataları

```bash
# Cache temizle
rm -rf node_modules package-lock.json
npm install

# Type check
npm run build
```

### Runtime Hataları

1. Browser console'u kontrol et
2. Network tab'ı kontrol et
3. Supabase logs'u kontrol et

### Database Issues

1. Supabase Dashboard > Database > Logs
2. RLS politikalarını kontrol et
3. Connection string'i doğrula

## Maintenance Mode

Bakım modu için basit HTML:

`maintenance.html`:
```html
<!DOCTYPE html>
<html>
<head>
    <title>Bakım Modu</title>
</head>
<body>
    <h1>Sistem Bakımda</h1>
    <p>Kısa süre içinde hizmete dönüyoruz.</p>
</body>
</html>
```

Nginx config:
```nginx
if (-f /var/www/maintenance.html) {
    return 503;
}

error_page 503 @maintenance;
location @maintenance {
    root /var/www;
    rewrite ^(.*)$ /maintenance.html break;
}
```

## Production Checklist

Yayına almadan önce:

- [ ] Build başarılı
- [ ] Environment variables set
- [ ] Database migration'ları çalıştı
- [ ] Edge Functions deploy edildi
- [ ] HTTPS aktif
- [ ] Domain yapılandırıldı
- [ ] Monitoring kuruldu
- [ ] Backup stratejisi hazır
- [ ] Error tracking aktif
- [ ] Performance test yapıldı
- [ ] Security audit tamamlandı
- [ ] Documentation güncel

## Support

Sorun durumunda:
1. ARCHITECTURE.md dosyasını incele
2. Supabase documentation: https://supabase.com/docs
3. GitHub Issues

---

**Not**: Bu proje production-ready durumda. Database schema, RLS politikaları ve Edge Functions deploy edilmiş durumda.

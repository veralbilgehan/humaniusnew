# İnsan Kaynakları Yönetim Sistemi - Teknik Mimari Dokümantasyonu

## Proje Özeti

Bu proje, modern web teknolojileri kullanılarak geliştirilmiş kapsamlı bir İnsan Kaynakları Yönetim Sistemi (HRMS)'dir. Türkiye İş Kanunu ve SGK mevzuatına uygun olarak personel yönetimi, izin takibi, bordro hesaplama ve raporlama özellikleri sunar.

## Teknoloji Stack'i

### Frontend
- **Framework**: React 18.3.1 + TypeScript 5.5.3
- **Build Tool**: Vite 5.4.2
- **Styling**: Tailwind CSS 3.4.1
- **Icons**: Lucide React 0.344.0
- **State Management**: React Context API

### Backend & Database
- **Database**: Supabase (PostgreSQL)
- **Auth**: Supabase Authentication
- **API**: Supabase Edge Functions (Deno)
- **Real-time**: Supabase Realtime

### DevOps
- **Container**: Docker
- **Web Server**: Nginx (production)
- **Version Control**: Git

## Proje Yapısı

```
project/
├── src/
│   ├── components/          # React bileşenleri
│   │   ├── BordroCalculator.tsx
│   │   ├── BordroList.tsx
│   │   ├── EmployeeTable.tsx
│   │   ├── IzinYonetimi.tsx
│   │   └── ...
│   ├── contexts/           # React Context'ler
│   │   ├── AuthContext.tsx
│   │   └── LanguageContext.tsx
│   ├── services/           # API servis katmanı
│   │   ├── employeeService.ts
│   │   ├── izinService.ts
│   │   ├── bordroService.ts
│   │   └── companyService.ts
│   ├── lib/               # Kütüphane yapılandırmaları
│   │   ├── supabase.ts
│   │   └── database.types.ts
│   ├── types/             # TypeScript tip tanımlamaları
│   │   ├── bordro.ts
│   │   ├── izin.ts
│   │   └── sistemAyarlari.ts
│   ├── utils/             # Yardımcı fonksiyonlar
│   │   ├── bordroCalculations.ts
│   │   ├── izinCalculations.ts
│   │   └── excelUtils.ts
│   ├── data/              # Statik veri
│   └── hooks/             # Custom React hooks
├── supabase/
│   └── functions/         # Edge Functions
│       ├── bordro-hesapla/
│       └── izin-hakki-hesapla/
├── public/                # Statik dosyalar
└── dist/                  # Production build çıktısı
```

## Database Mimarisi

### Temel Tablolar

#### 1. companies
Şirket bilgilerini saklar. Multi-tenant yapı için temel tablo.

```sql
- id (uuid, PK)
- name (text)
- address, tax_number, sgk_sicil_no
- phone, email, city
- logo_url
- created_at, updated_at
```

#### 2. profiles
Kullanıcı profil bilgileri (auth.users ile ilişkili)

```sql
- id (uuid, PK, FK -> auth.users)
- email, full_name
- company_id (FK -> companies)
- role (admin|manager|employee|hr)
- avatar_url
- created_at, updated_at
```

#### 3. employees
Personel bilgileri

```sql
- id (uuid, PK)
- company_id (FK -> companies)
- name, tc_no, sicil_no
- department, position, level
- salary, status
- join_date, address
- skills[], medeni_durum, cocuk_sayisi
- created_at, updated_at
```

#### 4. izin_talepleri
İzin talepleri ve onay süreçleri

```sql
- id (uuid, PK)
- company_id, employee_id
- izin_turu, baslangic_tarihi, bitis_tarihi
- gun_sayisi, aciklama
- yol_izni_talep, seyahat_yeri
- durum (beklemede|onaylandi|reddedildi)
- onaylayan_id, onay_tarihi
- created_at, updated_at
```

#### 5. izin_haklari
Yıllık izin hakları

```sql
- id (uuid, PK)
- company_id, employee_id
- yil, toplam_hak, kullanilan_izin, kalan_izin
- calisma_yili, ise_giris_tarihi
- created_at, updated_at
```

#### 6. bordro_items
Bordro kayıtları

```sql
- id (uuid, PK)
- company_id, employee_id
- period (YYYY-MM)
- brut_maas, medeni_durum, cocuk_sayisi
- Kazançlar: temel_kazanc, yol_parasi, gida_yardimi, etc.
- Kesintiler: gelir_vergisi, damga_vergisi, sgk_isci_payi, etc.
- Hesaplananlar: toplam_kazanc, toplam_kesinti, net_maas
- İşveren payları: sgk_isveren_payi, etc.
- created_at, updated_at
```

#### 7. bordro_calculation_rates
Bordro hesaplama oranları (yıllık)

```sql
- id (uuid, PK)
- company_id, yil
- gelir_vergisi_dilimleri (jsonb)
- sgk ve vergi oranları
- asgari_ucret, sgk_tavani
- created_at, updated_at
```

#### 8. takvim_gunleri
Resmi tatiller ve özel günler

```sql
- id (uuid, PK)
- company_id (nullable - ulusal tatiller için)
- tarih, ad, tur
- calisma_gunu_mu, yil
- created_at, updated_at
```

#### 9. bildirimler
Sistem bildirimleri

```sql
- id (uuid, PK)
- company_id, user_id
- baslik, mesaj, tur
- oncelik, okundu_mu
- created_at, updated_at
```

#### 10. aktivite_loglari
Audit trail

```sql
- id (uuid, PK)
- company_id, user_id
- aksiyon, tablo, kayit_id
- onceki_deger, yeni_deger (jsonb)
- ip_adresi, user_agent
- created_at
```

### Row Level Security (RLS)

Tüm tablolarda RLS aktiftir. Temel kurallar:

1. **Company Isolation**: Kullanıcılar sadece kendi şirketlerinin verilerine erişebilir
2. **Role-Based Access**:
   - `admin`: Tam yetki
   - `hr`: Personel ve bordro yönetimi
   - `manager`: Departman bazlı yetki
   - `employee`: Sadece kendi verileri
3. **Secure by Default**: Yeni tablolar varsayılan olarak kilitlidir

## API Mimarisi

### Supabase Client Services

Frontend'de Supabase ile iletişim için servis katmanı:

```typescript
// employeeService.ts
- getAll(companyId): Tüm personelleri getir
- getById(id): ID'ye göre personel
- create(employee): Yeni personel ekle
- update(id, updates): Personel güncelle
- delete(id): Personel sil
- search(companyId, term): Arama
- getStats(companyId): İstatistikler

// izinService.ts
- getAllTalepler(companyId): Tüm izin talepleri
- createTalep(talep): Yeni talep
- approveTalep(id): Talebi onayla
- rejectTalep(id, neden): Talebi reddet
- getEmployeeHakki(employeeId, yil): İzin hakkı
- calculateIzinHakki(iseGirisTarihi): Hesapla

// bordroService.ts
- getAll(companyId): Tüm bordrolar
- getByPeriod(companyId, period): Dönem bazlı
- create(bordro): Yeni bordro
- update(id, updates): Bordro güncelle
- calculateYillikTotals(companyId, employeeId, yil): Yıllık toplam
```

### Edge Functions

Deno runtime üzerinde çalışan serverless fonksiyonlar:

#### 1. bordro-hesapla
Bordro hesaplamalarını yapar.

**Endpoint**: `/functions/v1/bordro-hesapla`

**Request**:
```json
{
  "brutMaas": 22104,
  "medeniDurum": "bekar",
  "cocukSayisi": 0,
  "engelliDurumu": "yok",
  "fazlaMesaiSaat50": 10,
  "fazlaMesaiSaat100": 5,
  "yillikKumulatifMatrah": 0
}
```

**Response**:
```json
{
  "toplamKazanc": 24500.50,
  "gelirVergisi": 3200.00,
  "damgaVergisi": 185.00,
  "sgkIsciPayi": 3100.00,
  "issizlikSigortasi": 221.04,
  "toplamKesinti": 6706.04,
  "netMaas": 17794.46,
  "sgkIsverenPayi": 4520.00,
  "issizlikIsverenPayi": 442.08
}
```

#### 2. izin-hakki-hesapla
İzin hakkı hesaplar.

**Endpoint**: `/functions/v1/izin-hakki-hesapla`

**Request**:
```json
{
  "iseGirisTarihi": "2020-01-15",
  "dogumTarihi": "1975-06-10"
}
```

**Response**:
```json
{
  "calismaYili": 5,
  "toplamHak": 20,
  "yasiEkHak": 0,
  "aciklama": "5-15 yıl arası: 20 gün"
}
```

## Authentication & Authorization

### Authentication Flow

1. **Kullanıcı Kaydı**:
   ```typescript
   signUp(email, password, fullName)
   → Supabase Auth user oluşturur
   → profiles tablosuna kayıt ekler
   → Default role: 'employee'
   ```

2. **Giriş**:
   ```typescript
   signIn(email, password)
   → Session oluşturur
   → Profile bilgilerini yükler
   → AuthContext'e kaydeder
   ```

3. **Session Yönetimi**:
   - Auto refresh token
   - Persistent session (localStorage)
   - onAuthStateChange listener

### Authorization

RLS politikaları ile veri seviyesinde yetkilendirme:

```sql
-- Örnek: Personeller sadece kendi şirketlerini görebilir
CREATE POLICY "Users can view employees in their company"
  ON employees FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles WHERE id = auth.uid()
    )
  );
```

## Frontend Mimarisi

### Component Yapısı

1. **Container Components**: İş mantığı ve state yönetimi
2. **Presentational Components**: Sadece UI render
3. **Context Providers**: Global state yönetimi

### State Management

- **AuthContext**: Kullanıcı oturumu ve profil
- **LanguageContext**: Çoklu dil desteği
- **Local State**: Component bazlı state (useState)

### Data Flow

```
User Action
  ↓
Component Event Handler
  ↓
Service Layer (API call)
  ↓
Supabase Client
  ↓
Supabase API (RLS check)
  ↓
PostgreSQL Database
  ↓
Response
  ↓
State Update
  ↓
UI Re-render
```

## Güvenlik

### Database Security

1. **Row Level Security (RLS)**: Her tabloda aktif
2. **Company Isolation**: Multi-tenant güvenlik
3. **Role-Based Access**: Rol bazlı erişim kontrolü
4. **Audit Trail**: Tüm değişiklikler loglanır

### API Security

1. **JWT Authentication**: Her istekte token doğrulama
2. **CORS Headers**: Sadece izinli domainler
3. **Input Validation**: Edge function'larda validasyon
4. **SQL Injection Protection**: Supabase client otomatik koruma

### Frontend Security

1. **Environment Variables**: Hassas bilgiler .env'de
2. **No Secrets in Code**: API key'ler client-safe
3. **XSS Protection**: React otomatik escape
4. **HTTPS Only**: Production'da zorunlu

## Performans Optimizasyonları

### Database

1. **Indexes**: Sık kullanılan kolonlarda index
2. **Triggers**: Otomatik hesaplamalar
3. **JSONB**: Esnek veri yapıları için
4. **Connection Pooling**: Supabase otomatik yönetir

### Frontend

1. **Code Splitting**: Vite otomatik
2. **Lazy Loading**: Route bazlı
3. **Memoization**: React.memo, useMemo
4. **Virtual Scrolling**: Büyük listeler için

### API

1. **Edge Functions**: Global CDN
2. **Caching**: Response caching
3. **Batch Operations**: Toplu işlemler

## Deployment Stratejisi

### Production Build

```bash
npm run build
```

Çıktı: `dist/` klasörü

### Docker Deployment

```dockerfile
# Multi-stage build
FROM node:18 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### Environment Variables

Production için `.env`:
```
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your_anon_key
```

### CI/CD Pipeline

1. **Build**: `npm run build`
2. **Test**: Unit ve integration testler
3. **Docker**: Container oluşturma
4. **Deploy**: Container registry'ye push
5. **Update**: Production güncelleme

## Monitoring & Logging

### Supabase Dashboard

- Real-time API kullanımı
- Database performansı
- Edge function logs
- Auth analytics

### Aktivite Logları

`aktivite_loglari` tablosunda:
- Kullanıcı işlemleri
- Veri değişiklikleri
- IP adresi ve user agent
- Timestamp

## Scaling Stratejisi

### Vertical Scaling

- Database instance upgrade
- More CPU/RAM

### Horizontal Scaling

- Read replicas
- Edge function auto-scaling
- CDN caching

### Database Partitioning

Period bazlı partitioning (bordro için):
```sql
-- Yıllık partitionlar
CREATE TABLE bordro_items_2025 PARTITION OF bordro_items
  FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');
```

## Bakım ve Güncelleme

### Düzenli Görevler

1. **Yıllık**:
   - Vergi oranlarını güncelle
   - Asgari ücreti güncelle
   - Resmi tatilleri ekle

2. **Aylık**:
   - Database backup
   - Log temizliği
   - Performans analizi

3. **Haftalık**:
   - Security güncellemeleri
   - Dependency güncellemeleri

### Migration Stratejisi

```sql
-- Her migration için:
-- 1. Detaylı açıklama
-- 2. IF NOT EXISTS kullan
-- 3. Test ortamında dene
-- 4. Rollback planı hazırla
```

## Troubleshooting

### Yaygın Sorunlar

1. **RLS Error**: Policy eksik veya yanlış
2. **Auth Error**: Token expire
3. **CORS Error**: Headers eksik
4. **Slow Query**: Index eksik

### Debug Araçları

- Supabase Dashboard
- Browser DevTools
- PostgreSQL EXPLAIN ANALYZE
- Edge Function Logs

## Gelecek Geliştirmeler

1. **Mobil Uygulama**: React Native
2. **Raporlama**: Advanced analytics
3. **AI/ML**: Tahmin ve öneriler
4. **Integration**: Muhasebe yazılımları
5. **Multi-Language**: İngilizce desteği
6. **Dark Mode**: Tema desteği

---

**Son Güncelleme**: 2025-02-14
**Versiyon**: 1.0.0
**Geliştirici**: HRMS Development Team

# Backend ve Database Kurulum Rehberi

Bu dokuman projedeki Supabase backend ve PostgreSQL veritabanini hem local hem remote ortamda hazirlamak icindir.

## 1) Hazirlananlar

Bu repoda asagidaki altyapi hazirlandi:

- Supabase config dosyasi: [supabase/config.toml](supabase/config.toml)
- Seed dosyasi: [supabase/seed.sql](supabase/seed.sql)
- RLS duzeltme migrationi: [supabase/migrations/20260412121000_allow_manager_insert_employees.sql](supabase/migrations/20260412121000_allow_manager_insert_employees.sql)
- Supabase yonetim scriptleri: [package.json](package.json)

## 2) NPM Scriptleri

Asagidaki komutlar eklendi:

- npm run supabase:start
- npm run supabase:stop
- npm run supabase:status
- npm run supabase:reset
- npm run supabase:push
- npm run supabase:link
- npm run supabase:functions:deploy
- npm run supabase:types

## 3) Local Backend + DB (Docker ile)

Gereksinim: Docker Desktop calisiyor olmali.

1. Docker Desktop'i acin.
2. Backendi kaldirin:
   - npm run supabase:start
3. Durumu ve keyleri alin:
   - npm run supabase:status
4. Frontend env degerlerini locale cekin:
   - VITE_SUPABASE_URL=http://127.0.0.1:54321
   - VITE_SUPABASE_ANON_KEY=<status komutundan anon key>
5. Frontendi baslatin:
   - npm run dev

Not: Tum migrationlar local veritabanina otomatik uygulanir.

## 4) Remote Backend + DB (Supabase Cloud)

Docker yoksa bu yol kullanilir.

1. Supabase dashboardda bir proje olusturun.
2. Projeyi CLI'a baglayin:
   - npm run supabase:link
3. Migrationlari uzak DB'ye uygulayin:
   - npm run supabase:push
4. Edge functionlari deploy edin:
   - npm run supabase:functions:deploy
5. .env dosyaniza remote degerleri yazin:
   - VITE_SUPABASE_URL=https://<project-ref>.supabase.co
   - VITE_SUPABASE_ANON_KEY=<anon-key>

### Docker yoksa tek seferde DB olusturma (SQL Editor)

Tum migrationlar tek dosyada birlestirildi:

- [supabase/sql/bootstrap_all_migrations.sql](supabase/sql/bootstrap_all_migrations.sql)

Adimlar:

1. Supabase Dashboard > SQL Editor acin.
2. Dosya icerigini SQL Editor'e yapistirin.
3. Run diyerek tum schema, policy ve function'lari olusturun.
4. Ardindan migration takibi icin yine de `npm run supabase:link` ve `npm run supabase:push` kullanmaniz onerilir.

## 5) Kritik Not (Cozulen Hata)

Personel kaydi olusturulamadi hatasinin bir nedeni, manager rolunun employees INSERT RLS politikasinda olmamasiydi.
Bu durum [supabase/migrations/20260412121000_allow_manager_insert_employees.sql](supabase/migrations/20260412121000_allow_manager_insert_employees.sql) ile duzeltildi.

## 6) Hizli Dogrulama

Migration uygulandiktan sonra su akislari test edin:

1. Kullanici yonetiminden bir kullaniciya onay sifresi kaydetme
2. Ayni kullaniciyi tekrar acip sifrenin yuklenmesi
3. Personel kaydi yoksa otomatik olusmasi

## 7) Sorun Giderme

- Docker hatasi alirsaniz: Docker Desktop'i acin, sonra npm run supabase:start
- project ref hatasi alirsaniz: once npm run supabase:link
- RLS hatasi devam ederse: migrationlarin dashboardda "applied" oldugunu kontrol edin

/*
  # Profiles RLS Sonsuz Döngü Düzeltmesi
  
  ## Sorun
  Profiles tablosundaki "Users can view profiles in their company" politikası,
  profiles tablosunu profiles tablosundan sorgulayarak sonsuz döngüye giriyor.
  
  ## Çözüm
  1. Eski politikayı kaldır
  2. Kullanıcının kendi profilini görmesine izin ver
  3. Aynı şirketteki profilleri görmek için yeni politika ekle (company_id doğrudan kontrol)
  
  ## Değişiklikler
  - Eski "Users can view profiles in their company" politikası kaldırıldı
  - "Users can view own profile" politikası eklendi
  - "Users can view profiles in same company" politikası eklendi
*/

-- Eski politikayı kaldır
DROP POLICY IF EXISTS "Users can view profiles in their company" ON profiles;

-- Kullanıcılar kendi profillerini görebilir
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  TO authenticated
  USING (id = auth.uid());

-- Kullanıcılar aynı şirketteki profilleri görebilir
CREATE POLICY "Users can view profiles in same company"
  ON profiles FOR SELECT
  TO authenticated
  USING (
    company_id = (
      SELECT company_id FROM profiles WHERE id = auth.uid() LIMIT 1
    )
  );

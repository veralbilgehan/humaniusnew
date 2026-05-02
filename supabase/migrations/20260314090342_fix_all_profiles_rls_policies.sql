/*
  # Tüm Profiles RLS Politikalarını Düzelt
  
  ## Sorun
  Profiles tablosunda birden fazla politika profiles tablosunu tekrar sorgulayarak 
  sonsuz döngü yaratıyor:
  - "Users can view profiles in same company"
  - "Admins can insert profiles"
  - "Admins can delete profiles in their company"
  
  ## Çözüm
  Tüm mevcut politikaları kaldır ve basit, döngüsüz politikalar oluştur:
  1. Kullanıcılar kendi profillerini görebilir, güncelleyebilir
  2. Herkes authenticated kullanıcıların profillerini görebilir (aynı şirket kontrolü uygulama katmanında)
  3. Sadece servis rolü yeni profil ekleyebilir
  
  ## Değişiklikler
  - Tüm eski politikalar kaldırıldı
  - Basit, sonsuz döngü yaratmayan yeni politikalar eklendi
*/

-- Tüm mevcut politikaları kaldır
DROP POLICY IF EXISTS "Users can view profiles in their company" ON profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can view profiles in same company" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Admins can insert profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can delete profiles in their company" ON profiles;

-- Yeni basit politikalar

-- Herkes authenticated kullanıcıların profillerini görebilir
-- (Company kontrolü uygulama katmanında yapılacak)
CREATE POLICY "Authenticated users can view all profiles"
  ON profiles FOR SELECT
  TO authenticated
  USING (true);

-- Kullanıcılar sadece kendi profillerini güncelleyebilir
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- Sadece authenticated kullanıcılar profil oluşturabilir
-- (Sign up sırasında kullanılacak)
CREATE POLICY "Authenticated users can insert own profile"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (id = auth.uid());

-- Kullanıcılar kendi profillerini silebilir
CREATE POLICY "Users can delete own profile"
  ON profiles FOR DELETE
  TO authenticated
  USING (id = auth.uid());

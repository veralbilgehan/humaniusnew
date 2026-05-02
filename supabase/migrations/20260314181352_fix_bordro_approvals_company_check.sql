/*
  # Bordro Onay RLS Politikalarına Company Kontrolü Ekle

  1. Açıklama
    bordro_approvals tablosundaki RLS politikalarını günceller.
    Gerçek company_id kontrolü ekler.

  2. Değişiklikler
    - Mevcut basit RLS politikalarını kaldırır
    - Company_id ile kontrol yapan güvenli politikalar ekler
  
  3. Güvenlik
    - Kullanıcılar sadece kendi şirketlerinin bordro onaylarını görüntüleyebilir
    - Kullanıcılar sadece kendi şirketleri için bordro onayı oluşturabilir
    - Profiles tablosuna subquery yapılarak sonsuz döngü engellenir
*/

-- Mevcut politikaları kaldır
DROP POLICY IF EXISTS "Users can view own company approvals" ON bordro_approvals;
DROP POLICY IF EXISTS "Users can create own company approvals" ON bordro_approvals;

-- Görüntüleme politikası - kullanıcının şirketine ait onayları göster
CREATE POLICY "Users can view own company approvals"
  ON bordro_approvals
  FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id
      FROM profiles
      WHERE id = auth.uid()
    )
  );

-- Oluşturma politikası - kullanıcı kendi şirketine ait onay oluşturabilir
CREATE POLICY "Users can create own company approvals"
  ON bordro_approvals
  FOR INSERT
  TO authenticated
  WITH CHECK (
    company_id IN (
      SELECT company_id
      FROM profiles
      WHERE id = auth.uid()
    )
  );
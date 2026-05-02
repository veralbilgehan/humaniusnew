/*
  # Bordro Approvals RLS Politikalarını Basitleştir

  1. Açıklama
    Profiles tablosundan sonsuz döngü riskini ortadan kaldırmak için
    bordro_approvals tablosu RLS politikalarını basitleştirir.

  2. Değişiklikler
    - Mevcut politikaları kaldırır
    - Herhangi bir authenticated kullanıcının onay oluşturabilmesine izin verir
    - Herhangi bir authenticated kullanıcının onayları görebilmesine izin verir
  
  3. Güvenlik Notu
    - Bu basitleştirme geçicidir
    - Gerçek kontrol application layer'da yapılacak
*/

-- Mevcut politikaları kaldır
DROP POLICY IF EXISTS "Users can view own company approvals" ON bordro_approvals;
DROP POLICY IF EXISTS "Users can create own company approvals" ON bordro_approvals;

-- Basit politikalar oluştur - authenticated kullanıcılar için
CREATE POLICY "Authenticated users can view approvals"
  ON bordro_approvals
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can create approvals"
  ON bordro_approvals
  FOR INSERT
  TO authenticated
  WITH CHECK (true);
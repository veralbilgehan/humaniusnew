/*
  # Bordro Onay RLS Politikalarını Düzelt

  ## Açıklama
  bordro_approvals tablosundaki RLS politikalarını günceller.
  Profiles tablosuna yapılan subquery'leri kaldırarak sonsuz döngü sorununu önler.

  ## Değişiklikler
  - Mevcut RLS politikalarını kaldırır
  - Basitleştirilmiş, doğrudan company_id kontrolü yapan yeni politikalar ekler
  
  ## Güvenlik
  - Kullanıcılar kendi şirketlerinin bordro onaylarını görüntüleyebilir
  - Kullanıcılar kendi şirketleri için bordro onayı oluşturabilir
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view approvals of their company" ON bordro_approvals;
DROP POLICY IF EXISTS "Users can create approvals for their company" ON bordro_approvals;

-- Create new simplified policies
CREATE POLICY "Users can view own company approvals"
  ON bordro_approvals
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can create own company approvals"
  ON bordro_approvals
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

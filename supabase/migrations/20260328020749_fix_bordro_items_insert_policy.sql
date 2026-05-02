/*
  # Bordro Items INSERT Politikası Düzeltmesi

  ## Açıklama
  Bordro kaydetme sorunu düzeltiliyor. Mevcut politika sadece 'admin' ve 'hr' 
  rolüne izin veriyor, ancak tüm authenticated kullanıcıların kendi şirketleri 
  için bordro oluşturabilmesi gerekiyor.

  ## Değişiklikler
  1. Eski kısıtlayıcı politika kaldırılıyor
  2. Tüm authenticated kullanıcıların kendi şirketleri için bordro oluşturmasına izin veriliyor

  ## Güvenlik
  - RLS aktif kalıyor
  - Kullanıcılar sadece kendi şirketleri için bordro oluşturabilir
  - company_id kontrolü ile güvenlik sağlanıyor
*/

-- Drop restrictive INSERT policy
DROP POLICY IF EXISTS "HR can create bordro items" ON bordro_items;

-- Create new INSERT policy allowing all authenticated users for their company
CREATE POLICY "Users can create bordro items for their company"
  ON bordro_items
  FOR INSERT
  TO authenticated
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM profiles WHERE id = auth.uid()
    )
  );

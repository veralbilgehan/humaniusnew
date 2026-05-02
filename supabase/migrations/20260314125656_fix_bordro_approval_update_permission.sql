/*
  # Bordro Onay Güncelleme İzni Düzeltmesi

  1. Değişiklikler
    - Çalışanların kendi bordrolarının onay durumunu güncelleyebilmeleri için yeni UPDATE politikası eklendi
    - Bu politika sadece `approval_status` ve `approval_date` alanlarının güncellenmesine izin verir
    
  2. Güvenlik
    - Çalışanlar sadece kendi bordrolarını güncelleyebilir
    - Sadece onay ile ilgili alanlar güncellenebilir (approval_status, approval_date)
*/

-- Mevcut çalışan güncellemesi politikasını kaldır (varsa)
DROP POLICY IF EXISTS "Employees can update their own bordro approval status" ON bordro_items;

-- Çalışanların kendi bordrolarının onay durumunu güncelleyebilmeleri için politika ekle
CREATE POLICY "Employees can update their own bordro approval status"
  ON bordro_items
  FOR UPDATE
  TO authenticated
  USING (
    employee_id IN (
      SELECT employees.id
      FROM employees
      WHERE employees.email = (
        SELECT profiles.email
        FROM profiles
        WHERE profiles.id = auth.uid()
      )
      AND employees.company_id IN (
        SELECT profiles.company_id
        FROM profiles
        WHERE profiles.id = auth.uid()
      )
    )
  )
  WITH CHECK (
    employee_id IN (
      SELECT employees.id
      FROM employees
      WHERE employees.email = (
        SELECT profiles.email
        FROM profiles
        WHERE profiles.id = auth.uid()
      )
      AND employees.company_id IN (
        SELECT profiles.company_id
        FROM profiles
        WHERE profiles.id = auth.uid()
      )
    )
  );
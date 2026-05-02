/*
  # Personel Onay Şifresi Kolonu Ekleme

  ## Değişiklikler
  1. Employees Tablosu
    - `approval_passcode` (text) kolonu eklendi - Görev tanımı onayı için kullanılacak şifre
  
  ## Notlar
  - Bu kolon, çalışanların görev tanımı belgelerini onaylarken kullanacakları güvenlik şifresini saklar
  - Şifre yöneticiler tarafından oluşturulup çalışanlara iletilir
  - Şifre null olabilir (opsiyonel)
*/

-- Employees tablosuna approval_passcode kolonu ekle
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'employees' AND column_name = 'approval_passcode'
  ) THEN
    ALTER TABLE employees ADD COLUMN approval_passcode text;
  END IF;
END $$;
/*
  # Personel Tipi Kolonu Ekleme

  ## Değişiklikler
  1. Employees Tablosu
    - `employee_type` (text) kolonu eklendi - Çalışan tipi (normal, emekli)
  
  ## Notlar
  - Bu kolon, çalışanın normal çalışan mı yoksa emekli mi olduğunu belirtir
  - Bordro hesaplamalarında farklı işlemler için kullanılır
  - Varsayılan değer 'normal'
*/

-- Employees tablosuna employee_type kolonu ekle
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'employees' AND column_name = 'employee_type'
  ) THEN
    ALTER TABLE employees ADD COLUMN employee_type text DEFAULT 'normal' CHECK (employee_type IN ('normal', 'emekli'));
  END IF;
END $$;
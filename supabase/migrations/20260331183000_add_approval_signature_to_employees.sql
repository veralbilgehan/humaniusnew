/*
  # Employees tablosuna imza alanı ekle

  Kullanıcı bazlı imza ve onay şifresi işlemlerinde
  dijital imza verisini employees tablosunda saklamak için alan eklenir.
*/

ALTER TABLE employees
ADD COLUMN IF NOT EXISTS approval_signature text;

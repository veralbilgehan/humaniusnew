/*
  # Bordro Onay Sistemi (Payroll Approval System)

  ## Açıklama
  Bu migrasyon, bordro kayıtları için çok faktörlü onay sistemi ekler.
  Çalışanlar bordrolarını dijital imza, kimlik belgesi veya şifre ile onaylayabilir.

  ## Yeni Tablolar

  ### `bordro_approvals`
  Bordro onay kayıtlarını saklar:
  - `id` (uuid, primary key) - Benzersiz onay kaydı ID
  - `bordro_id` (uuid, foreign key) - İlgili bordro kaydı
  - `company_id` (uuid, foreign key) - Şirket ID
  - `employee_id` (uuid, foreign key) - Çalışan ID
  - `employee_name` (text) - Çalışan adı (denormalize)
  - `verification_method` (text) - Doğrulama yöntemi: 'signature', 'id_document', 'passcode'
  - `signature_data` (text, nullable) - Base64 dijital imza verisi
  - `id_document_data` (text, nullable) - Base64 kimlik belgesi verisi
  - `passcode_hash` (text, nullable) - Hash'lenmiş şifre
  - `approval_status` (text) - Onay durumu: 'onaylandi', 'reddedildi'
  - `ip_address` (text, nullable) - Onay yapan IP adresi
  - `user_agent` (text, nullable) - Onay yapan tarayıcı bilgisi
  - `timestamp` (timestamptz) - Onay zamanı

  ## Güvenlik
  - RLS etkinleştirildi
  - Kullanıcılar sadece kendi şirketlerinin onaylarını görebilir
  - Onay oluşturma yetkilendirilmiş kullanıcılarla sınırlı
  - IP adresi ve user agent bilgisi güvenlik denetimi için saklanır

  ## Değişiklikler
  - `bordro_items` tablosuna `approval_status` ve `approval_date` alanları eklenir
*/

-- Add approval fields to bordro_items table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'bordro_items' AND column_name = 'approval_status'
  ) THEN
    ALTER TABLE bordro_items ADD COLUMN approval_status text DEFAULT 'beklemede';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'bordro_items' AND column_name = 'approval_date'
  ) THEN
    ALTER TABLE bordro_items ADD COLUMN approval_date timestamptz;
  END IF;
END $$;

-- Create bordro approvals table
CREATE TABLE IF NOT EXISTS bordro_approvals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  bordro_id uuid NOT NULL REFERENCES bordro_items(id) ON DELETE CASCADE,
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  employee_id uuid NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  employee_name text NOT NULL,
  verification_method text NOT NULL CHECK (verification_method IN ('signature', 'id_document', 'passcode')),
  signature_data text,
  id_document_data text,
  passcode_hash text,
  approval_status text NOT NULL CHECK (approval_status IN ('onaylandi', 'reddedildi')),
  ip_address text,
  user_agent text,
  timestamp timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE bordro_approvals ENABLE ROW LEVEL SECURITY;

-- RLS Policies for bordro_approvals
CREATE POLICY "Users can view approvals of their company"
  ON bordro_approvals
  FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "Users can create approvals for their company"
  ON bordro_approvals
  FOR INSERT
  TO authenticated
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM profiles WHERE id = auth.uid()
    )
  );

-- Index for performance
CREATE INDEX IF NOT EXISTS idx_bordro_approvals_bordro_id ON bordro_approvals(bordro_id);
CREATE INDEX IF NOT EXISTS idx_bordro_approvals_employee_id ON bordro_approvals(employee_id);
CREATE INDEX IF NOT EXISTS idx_bordro_approvals_company_id ON bordro_approvals(company_id);

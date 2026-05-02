/*
  # Görev Tanımı Onay Sistemi

  1. Yeni Tablolar
    - `gorev_tanimlari`
      - `id` (uuid, primary key)
      - `company_id` (uuid, foreign key to companies)
      - `employee_id` (uuid, foreign key to employees)
      - `employee_name` (text)
      - `gorev_adi` (text)
      - `gorev_aciklama` (text)
      - `sorumluluklar` (text[])
      - `yetki_ve_sorumluluklar` (text[])
      - `calismalar` (text[])
      - `performans_kriterleri` (text[])
      - `bagli_oldugu_pozisyon` (text)
      - `is_birimi` (text)
      - `olusturma_tarihi` (timestamptz)
      - `onay_durumu` (text) - 'beklemede', 'onaylandi', 'reddedildi'
      - `onay_tarihi` (timestamptz)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

    - `gorev_tanimi_approvals`
      - `id` (uuid, primary key)
      - `gorev_tanimi_id` (uuid, foreign key to gorev_tanimlari)
      - `employee_id` (uuid, foreign key to employees)
      - `employee_name` (text)
      - `verification_method` (text) - 'signature', 'id_document', 'passcode'
      - `signature_data` (text)
      - `id_document_data` (text)
      - `passcode_hash` (text)
      - `approval_status` (text) - 'onaylandi', 'reddedildi'
      - `ip_address` (text)
      - `user_agent` (text)
      - `timestamp` (timestamptz)
      - `created_at` (timestamptz)

    - `employee_passcodes`
      - `id` (uuid, primary key)
      - `employee_id` (uuid, foreign key to employees)
      - `passcode_hash` (text) - bcrypt hash of passcode
      - `created_at` (timestamptz)
      - `expires_at` (timestamptz)

  2. Güvenlik
    - RLS aktif
    - Şirket bazlı erişim kontrolü
    - Personelin sadece kendi görev tanımlarını görebilmesi
*/

-- Görev Tanımları Tablosu
CREATE TABLE IF NOT EXISTS gorev_tanimlari (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid REFERENCES companies(id) ON DELETE CASCADE NOT NULL,
  employee_id uuid REFERENCES employees(id) ON DELETE CASCADE NOT NULL,
  employee_name text NOT NULL,
  gorev_adi text NOT NULL,
  gorev_aciklama text DEFAULT '',
  sorumluluklar text[] DEFAULT '{}',
  yetki_ve_sorumluluklar text[] DEFAULT '{}',
  calismalar text[] DEFAULT '{}',
  performans_kriterleri text[] DEFAULT '{}',
  bagli_oldugu_pozisyon text DEFAULT '',
  is_birimi text DEFAULT '',
  olusturma_tarihi timestamptz DEFAULT now(),
  onay_durumu text DEFAULT 'beklemede' CHECK (onay_durumu IN ('beklemede', 'onaylandi', 'reddedildi')),
  onay_tarihi timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Görev Tanımı Onayları Tablosu
CREATE TABLE IF NOT EXISTS gorev_tanimi_approvals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  gorev_tanimi_id uuid REFERENCES gorev_tanimlari(id) ON DELETE CASCADE NOT NULL,
  employee_id uuid REFERENCES employees(id) ON DELETE CASCADE NOT NULL,
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

-- Personel Şifreleri Tablosu
CREATE TABLE IF NOT EXISTS employee_passcodes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id uuid REFERENCES employees(id) ON DELETE CASCADE NOT NULL UNIQUE,
  passcode_hash text NOT NULL,
  created_at timestamptz DEFAULT now(),
  expires_at timestamptz
);

-- İndeksler
CREATE INDEX IF NOT EXISTS idx_gorev_tanimlari_company ON gorev_tanimlari(company_id);
CREATE INDEX IF NOT EXISTS idx_gorev_tanimlari_employee ON gorev_tanimlari(employee_id);
CREATE INDEX IF NOT EXISTS idx_gorev_tanimlari_onay_durumu ON gorev_tanimlari(onay_durumu);
CREATE INDEX IF NOT EXISTS idx_gorev_tanimi_approvals_gorev ON gorev_tanimi_approvals(gorev_tanimi_id);
CREATE INDEX IF NOT EXISTS idx_gorev_tanimi_approvals_employee ON gorev_tanimi_approvals(employee_id);
CREATE INDEX IF NOT EXISTS idx_employee_passcodes_employee ON employee_passcodes(employee_id);

-- RLS Politikaları
ALTER TABLE gorev_tanimlari ENABLE ROW LEVEL SECURITY;
ALTER TABLE gorev_tanimi_approvals ENABLE ROW LEVEL SECURITY;
ALTER TABLE employee_passcodes ENABLE ROW LEVEL SECURITY;

-- Görev Tanımları Politikaları
CREATE POLICY "Users can view gorev tanimlari from their company"
  ON gorev_tanimlari FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "Users can create gorev tanimlari for their company"
  ON gorev_tanimlari FOR INSERT
  TO authenticated
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "Users can update gorev tanimlari from their company"
  ON gorev_tanimlari FOR UPDATE
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles WHERE id = auth.uid()
    )
  )
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "Users can delete gorev tanimlari from their company"
  ON gorev_tanimlari FOR DELETE
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles WHERE id = auth.uid()
    )
  );

-- Onay Kayıtları Politikaları
CREATE POLICY "Users can view approval records from their company"
  ON gorev_tanimi_approvals FOR SELECT
  TO authenticated
  USING (
    employee_id IN (
      SELECT id FROM employees WHERE company_id IN (
        SELECT company_id FROM profiles WHERE id = auth.uid()
      )
    )
  );

CREATE POLICY "Users can create approval records"
  ON gorev_tanimi_approvals FOR INSERT
  TO authenticated
  WITH CHECK (
    employee_id IN (
      SELECT id FROM employees WHERE company_id IN (
        SELECT company_id FROM profiles WHERE id = auth.uid()
      )
    )
  );

-- Personel Şifreleri Politikaları
CREATE POLICY "Users can view passcodes from their company"
  ON employee_passcodes FOR SELECT
  TO authenticated
  USING (
    employee_id IN (
      SELECT id FROM employees WHERE company_id IN (
        SELECT company_id FROM profiles WHERE id = auth.uid()
      )
    )
  );

CREATE POLICY "Admins can manage passcodes"
  ON employee_passcodes FOR ALL
  TO authenticated
  USING (
    employee_id IN (
      SELECT e.id FROM employees e
      JOIN profiles p ON p.company_id = e.company_id
      WHERE p.id = auth.uid() AND p.role IN ('admin', 'hr')
    )
  )
  WITH CHECK (
    employee_id IN (
      SELECT e.id FROM employees e
      JOIN profiles p ON p.company_id = e.company_id
      WHERE p.id = auth.uid() AND p.role IN ('admin', 'hr')
    )
  );

-- Trigger: Updated At
CREATE OR REPLACE FUNCTION update_gorev_tanimlari_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_update_gorev_tanimlari_updated_at'
  ) THEN
    CREATE TRIGGER trigger_update_gorev_tanimlari_updated_at
      BEFORE UPDATE ON gorev_tanimlari
      FOR EACH ROW
      EXECUTE FUNCTION update_gorev_tanimlari_updated_at();
  END IF;
END $$;
/*
  # Emekli Bordrosu Modülü
  
  ## Genel Bakış
  Bu migration, emekli personel bordro hesaplama sisteminin veritabanı yapısını ekler.
  Brüt-Net ve Net-Brüt hesaplama parametreleri ile emekli maaş bordrosu yönetimini sağlar.
  
  ## Oluşturulan Tablolar
  
  ### 1. `emekli_bordro_items`
  Emekli personel bordro kayıtları
  - `id` (uuid, PK)
  - `company_id` (uuid, FK) - Şirket
  - `employee_id` (uuid, FK) - Personel
  - `period` (text) - Dönem (YYYY-MM)
  - `sicil_no` (text) - Sicil no
  - `tc_no` (text) - TC no
  - Temel Bilgiler: brut_maas, medeni_durum, cocuk_sayisi
  - Kazançlar: normal_calisma_brut, fazla_mesai_50, yol_yemek_yardimi
  - Kesintiler: sgk_isci_payi, issizlik_sigortasi_isci, gelir_vergisi, damga_vergisi
  - Hesaplanan: toplam_kazanc, toplam_kesinti, net_maas, gelir_vergisi_matrahi
  - Kümülatif değerler: kumulatif_vergi_matrahi
  
  ### 2. `emekli_hesaplama_parametreleri`
  Emekli bordro hesaplama parametreleri (Excel'deki parametreler)
  - `id` (uuid, PK)
  - `company_id` (uuid, FK)
  - `kod` (text) - Parametre kodu (B3, C3, E10, vb.)
  - `ad` (text) - Parametre adı
  - `oran` (text) - Oran/Birim bilgisi
  - `tutar` (numeric) - Tutar
  - `tip` (text) - kazanc, kesinti, bilgi
  - `aktif` (boolean) - Aktif mi
  
  ## Güvenlik
  - Tüm tablolarda RLS aktif
  - Bordro bilgileri hassas veri olarak korunur
  - Sadece HR ve admin rolleri emekli bordro oluşturabilir ve güncelleyebilir
  
  ## Notlar
  - Excel dosyasındaki parametrik yapı database'e taşındı
  - Brüt-Net ve Net-Brüt hesaplama desteklenir
  - Parametreler şirket bazlı yapılandırılabilir
*/

-- Emekli bordro kayıtları tablosu
CREATE TABLE IF NOT EXISTS emekli_bordro_items (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  employee_id uuid NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  period text NOT NULL,
  sicil_no text DEFAULT '',
  tc_no text DEFAULT '',
  
  -- Temel Bilgiler
  brut_maas numeric(12, 2) DEFAULT 0,
  medeni_durum text DEFAULT 'bekar' CHECK (medeni_durum IN ('bekar', 'evli')),
  cocuk_sayisi integer DEFAULT 0,
  
  -- Kazançlar (Excel parametreleri: B3, C3, D3)
  normal_calisma_brut numeric(12, 2) DEFAULT 0,
  normal_calisma_gun integer DEFAULT 30,
  fazla_mesai_50 numeric(12, 2) DEFAULT 0,
  fazla_mesai_50_saat numeric(8, 2) DEFAULT 0,
  yol_yemek_yardimi numeric(12, 2) DEFAULT 0,
  diger_kazanclar numeric(12, 2) DEFAULT 0,
  
  -- Kesintiler (Excel parametreleri: E10, F10, H15, U18)
  sgk_isci_payi numeric(12, 2) DEFAULT 0,
  sgk_isci_payi_oran numeric(5, 4) DEFAULT 0.14,
  issizlik_sigortasi_isci numeric(12, 2) DEFAULT 0,
  issizlik_sigortasi_isci_oran numeric(5, 4) DEFAULT 0.01,
  gelir_vergisi numeric(12, 2) DEFAULT 0,
  gelir_vergisi_oran numeric(5, 4) DEFAULT 0.15,
  damga_vergisi numeric(12, 2) DEFAULT 0,
  damga_vergisi_oran numeric(5, 4) DEFAULT 0.00759,
  
  -- Ara Hesaplamalar (Excel parametresi: G12)
  gelir_vergisi_matrahi numeric(12, 2) DEFAULT 0,
  kumulatif_vergi_matrahi numeric(12, 2) DEFAULT 0,
  
  -- İşveren Payları
  sgk_isveren_payi numeric(12, 2) DEFAULT 0,
  sgk_isveren_payi_oran numeric(5, 4) DEFAULT 0.205,
  issizlik_isveren_payi numeric(12, 2) DEFAULT 0,
  issizlik_isveren_payi_oran numeric(5, 4) DEFAULT 0.02,
  
  -- Hesaplanan Değerler
  toplam_kazanc numeric(12, 2) DEFAULT 0,
  toplam_kesinti numeric(12, 2) DEFAULT 0,
  net_maas numeric(12, 2) DEFAULT 0,
  
  -- Notlar
  aciklama text DEFAULT '',
  
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  
  UNIQUE(employee_id, period)
);

-- Emekli hesaplama parametreleri tablosu
CREATE TABLE IF NOT EXISTS emekli_hesaplama_parametreleri (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  kod text NOT NULL,
  ad text NOT NULL,
  oran text DEFAULT '',
  tutar numeric(12, 2) DEFAULT 0,
  tip text NOT NULL DEFAULT 'kazanc' CHECK (tip IN ('kazanc', 'kesinti', 'bilgi')),
  aktif boolean DEFAULT true,
  sira integer DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(company_id, kod)
);

-- Varsayılan parametreleri her şirket için ekle (Excel'deki örnekten)
INSERT INTO emekli_hesaplama_parametreleri (company_id, kod, ad, oran, tutar, tip, sira)
SELECT 
  id as company_id,
  'B3' as kod,
  'Normal Çalışma Brüt' as ad,
  '30 Gün' as oran,
  45000.00 as tutar,
  'kazanc' as tip,
  1 as sira
FROM companies
UNION ALL
SELECT id, 'C3', 'Fazla Mesai (%50)', '10 Saat', 3250.00, 'kazanc', 2 FROM companies
UNION ALL
SELECT id, 'D3', 'Yol ve Yemek Yardımı', 'Sabit', 5500.00, 'kazanc', 3 FROM companies
UNION ALL
SELECT id, 'E10', 'SGK İşçi Payı', '%14', 6300.00, 'kesinti', 4 FROM companies
UNION ALL
SELECT id, 'F10', 'İşsizlik Sigortası İşçi', '%1', 450.00, 'kesinti', 5 FROM companies
UNION ALL
SELECT id, 'G12', 'Gelir Vergisi Matrahı', 'Kümülatif', 38250.00, 'bilgi', 6 FROM companies
UNION ALL
SELECT id, 'H15', 'Hesaplanan Gelir Vergisi', '%15', 5737.50, 'kesinti', 7 FROM companies
UNION ALL
SELECT id, 'U18', 'Damga Vergisi', '0.00759', 341.55, 'kesinti', 8 FROM companies
ON CONFLICT (company_id, kod) DO NOTHING;

-- Trigger'ları oluştur
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_emekli_bordro_items_updated_at') THEN
    CREATE TRIGGER update_emekli_bordro_items_updated_at
      BEFORE UPDATE ON emekli_bordro_items
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_emekli_hesaplama_parametreleri_updated_at') THEN
    CREATE TRIGGER update_emekli_hesaplama_parametreleri_updated_at
      BEFORE UPDATE ON emekli_hesaplama_parametreleri
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;
END $$;

-- İndeksler
CREATE INDEX IF NOT EXISTS idx_emekli_bordro_items_company_id ON emekli_bordro_items(company_id);
CREATE INDEX IF NOT EXISTS idx_emekli_bordro_items_employee_id ON emekli_bordro_items(employee_id);
CREATE INDEX IF NOT EXISTS idx_emekli_bordro_items_period ON emekli_bordro_items(period);
CREATE INDEX IF NOT EXISTS idx_emekli_hesaplama_parametreleri_company_id ON emekli_hesaplama_parametreleri(company_id);
CREATE INDEX IF NOT EXISTS idx_emekli_hesaplama_parametreleri_tip ON emekli_hesaplama_parametreleri(tip);

-- RLS Aktifleştirme
ALTER TABLE emekli_bordro_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE emekli_hesaplama_parametreleri ENABLE ROW LEVEL SECURITY;

-- Emekli bordro items RLS politikaları
CREATE POLICY "HR can view all emekli bordro items in their company"
  ON emekli_bordro_items FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles 
      WHERE id = auth.uid() 
      AND role IN ('admin', 'hr', 'manager')
    )
  );

CREATE POLICY "Employees can view their own emekli bordro"
  ON emekli_bordro_items FOR SELECT
  TO authenticated
  USING (
    employee_id IN (
      SELECT id FROM employees 
      WHERE email = (SELECT email FROM profiles WHERE id = auth.uid())
      AND company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())
    )
  );

CREATE POLICY "HR can create emekli bordro items"
  ON emekli_bordro_items FOR INSERT
  TO authenticated
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM profiles 
      WHERE id = auth.uid() 
      AND role IN ('admin', 'hr')
    )
  );

CREATE POLICY "HR can update emekli bordro items"
  ON emekli_bordro_items FOR UPDATE
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles 
      WHERE id = auth.uid() 
      AND role IN ('admin', 'hr')
    )
  )
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM profiles 
      WHERE id = auth.uid() 
      AND role IN ('admin', 'hr')
    )
  );

CREATE POLICY "HR can delete emekli bordro items"
  ON emekli_bordro_items FOR DELETE
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles 
      WHERE id = auth.uid() 
      AND role IN ('admin', 'hr')
    )
  );

-- Emekli hesaplama parametreleri RLS politikaları
CREATE POLICY "Users can view emekli parameters in their company"
  ON emekli_hesaplama_parametreleri FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "HR can manage emekli parameters"
  ON emekli_hesaplama_parametreleri FOR ALL
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles 
      WHERE id = auth.uid() 
      AND role IN ('admin', 'hr')
    )
  )
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM profiles 
      WHERE id = auth.uid() 
      AND role IN ('admin', 'hr')
    )
  );
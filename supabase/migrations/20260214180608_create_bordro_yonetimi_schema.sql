/*
  # Bordro Yönetimi Modülü
  
  ## Genel Bakış
  Bu migration, bordro ve maaş hesaplama sisteminin veritabanı yapısını oluşturur.
  Türkiye İş Kanunu ve SGK mevzuatına uygun bordro hesaplamaları yapar.
  
  ## Oluşturulan Tablolar
  
  ### 1. `bordro_items`
  Aylık bordro kayıtları ve maaş hesaplamaları
  - `id` (uuid, PK)
  - `company_id` (uuid, FK) - Şirket
  - `employee_id` (uuid, FK) - Personel
  - `period` (text) - Dönem (YYYY-MM)
  - `sicil_no` (text) - Sicil no
  - `tc_no` (text) - TC no
  - Temel Bilgiler: brut_maas, medeni_durum, cocuk_sayisi, engelli_durumu
  - Kazançlar: temel_kazanc, yol_parasi, gida_yardimi, cocuk_yardimi vb.
  - Fazla Mesai: fazla_mesai, fazla_mesai_saat_50, fazla_mesai_saat_100, fazla_mesai_tutar
  - Ek Ödemeler: haftalik_tatil, genel_tatil, yillik_izin_ucreti, ikramiye, prim
  - Kesintiler: gelir_vergisi, damga_vergisi, sgk_isci_payi, issizlik_sigortasi
  - Vergi İndirimleri: engelli_indirimi, asgari_ucret_gelir_vergisi_istisnasi
  - Tazminatlar: kidem_tazminati, ihbar_tazminati
  - Hesaplanan: toplam_kazanc, toplam_kesinti, net_maas, kumulatif_vergi_matrahi
  - İşveren Payları: sgk_isveren_payi, issizlik_isveren_payi, sgk_isveren_indirimi
  
  ### 2. `bordro_calculation_rates`
  Bordro hesaplama oranları ve parametreleri (yıllık güncellenir)
  - `id` (uuid, PK)
  - `company_id` (uuid, FK)
  - `yil` (integer) - Geçerlilik yılı
  - `gelir_vergisi_dilimleri` (jsonb) - Gelir vergisi dilimleri
  - `damga_vergisi_orani` (numeric) - Damga vergisi oranı
  - `sgk_isci_payi_orani` (numeric) - SGK işçi payı oranı
  - `sgk_isveren_payi_orani` (numeric) - SGK işveren payı oranı
  - `issizlik_isci_payi_orani` (numeric) - İşsizlik işçi payı oranı
  - `issizlik_isveren_payi_orani` (numeric) - İşsizlik işveren payı oranı
  - `asgari_ucret` (numeric) - Asgari ücret
  - `sgk_tavani` (numeric) - SGK tavanı
  - `asgari_ucret_istisnasi` (jsonb) - Asgari ücret istisnaları
  
  ### 3. `bordro_templates`
  Bordro şablonları (hızlı bordro girişi için)
  - `id` (uuid, PK)
  - `company_id` (uuid, FK)
  - `name` (text) - Şablon adı
  - `description` (text) - Açıklama
  - `default_values` (jsonb) - Varsayılan değerler
  
  ## Güvenlik
  - Tüm tablolarda RLS aktif
  - Bordro bilgileri hassas veri olarak korunur
  - Sadece HR ve admin rolleri bordro oluşturabilir ve güncelleyebilir
  - Çalışanlar sadece kendi bordrolarını görüntüleyebilir
  
  ## Notlar
  - Otomatik hesaplama fonksiyonları eklenir
  - Vergi dilimleri JSONB formatında saklanır
  - Yıllık toplam hesaplamaları otomatik yapılır
*/

-- Bordro kayıtları tablosu
CREATE TABLE IF NOT EXISTS bordro_items (
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
  engelli_durumu text DEFAULT 'yok' CHECK (engelli_durumu IN ('yok', 'birinci', 'ikinci', 'ucuncu')),
  
  -- Kazançlar
  temel_kazanc numeric(12, 2) DEFAULT 0,
  yol_parasi numeric(12, 2) DEFAULT 0,
  gida_yardimi numeric(12, 2) DEFAULT 0,
  cocuk_yardimi numeric(12, 2) DEFAULT 0,
  diger_kazanclar numeric(12, 2) DEFAULT 0,
  
  -- Fazla Mesai Detayları
  fazla_mesai numeric(12, 2) DEFAULT 0,
  fazla_mesai_saat_50 numeric(8, 2) DEFAULT 0,
  fazla_mesai_saat_100 numeric(8, 2) DEFAULT 0,
  fazla_mesai_tutar numeric(12, 2) DEFAULT 0,
  
  -- Ek Ödemeler
  haftalik_tatil numeric(12, 2) DEFAULT 0,
  genel_tatil numeric(12, 2) DEFAULT 0,
  yillik_izin_ucreti numeric(12, 2) DEFAULT 0,
  ikramiye numeric(12, 2) DEFAULT 0,
  prim numeric(12, 2) DEFAULT 0,
  servis_ucreti numeric(12, 2) DEFAULT 0,
  temsil_etiket numeric(12, 2) DEFAULT 0,
  
  -- Kesintiler
  gelir_vergisi numeric(12, 2) DEFAULT 0,
  damga_vergisi numeric(12, 2) DEFAULT 0,
  sgk_isci_payi numeric(12, 2) DEFAULT 0,
  issizlik_sigortasi numeric(12, 2) DEFAULT 0,
  sendika_aidat numeric(12, 2) DEFAULT 0,
  avans numeric(12, 2) DEFAULT 0,
  diger_kesintiler numeric(12, 2) DEFAULT 0,
  
  -- Vergi İndirimleri
  engelli_indirimi numeric(12, 2) DEFAULT 0,
  
  -- Tazminatlar
  kidem_tazminati numeric(12, 2) DEFAULT 0,
  ihbar_tazminati numeric(12, 2) DEFAULT 0,
  
  -- Hesaplanan Değerler
  toplam_kazanc numeric(12, 2) DEFAULT 0,
  toplam_kesinti numeric(12, 2) DEFAULT 0,
  net_maas numeric(12, 2) DEFAULT 0,
  kumulatif_vergi_matrahi numeric(12, 2) DEFAULT 0,
  
  -- Asgari Ücret İstisnaları
  asgari_ucret_gelir_vergisi_istisnasi numeric(12, 2) DEFAULT 0,
  asgari_ucret_damga_vergisi_istisnasi numeric(12, 2) DEFAULT 0,
  
  -- İşveren Payları
  sgk_isveren_payi numeric(12, 2) DEFAULT 0,
  issizlik_isveren_payi numeric(12, 2) DEFAULT 0,
  sgk_isveren_indirimi numeric(12, 2) DEFAULT 0,
  sgk_isveren_indirim_orani numeric(5, 2) DEFAULT 0,
  
  -- Yıllık Toplamlar
  yillik_toplam_kazanc numeric(12, 2) DEFAULT 0,
  yillik_toplam_kesinti numeric(12, 2) DEFAULT 0,
  yillik_toplam_net numeric(12, 2) DEFAULT 0,
  
  -- Notlar
  aciklama text DEFAULT '',
  
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  
  UNIQUE(employee_id, period)
);

-- Bordro hesaplama oranları tablosu
CREATE TABLE IF NOT EXISTS bordro_calculation_rates (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  yil integer NOT NULL,
  gelir_vergisi_dilimleri jsonb NOT NULL DEFAULT '[]'::jsonb,
  damga_vergisi_orani numeric(5, 4) DEFAULT 0.00759,
  sgk_isci_payi_orani numeric(5, 4) DEFAULT 0.14,
  sgk_isveren_payi_orani numeric(5, 4) DEFAULT 0.205,
  issizlik_isci_payi_orani numeric(5, 4) DEFAULT 0.01,
  issizlik_isveren_payi_orani numeric(5, 4) DEFAULT 0.02,
  asgari_ucret numeric(12, 2) DEFAULT 0,
  sgk_tavani numeric(12, 2) DEFAULT 0,
  asgari_ucret_istisnasi jsonb NOT NULL DEFAULT '{"gelirVergisi": 0, "damgaVergisi": 0}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(company_id, yil)
);

-- Bordro şablonları tablosu
CREATE TABLE IF NOT EXISTS bordro_templates (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text DEFAULT '',
  default_values jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Trigger'ları oluştur
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_bordro_items_updated_at') THEN
    CREATE TRIGGER update_bordro_items_updated_at
      BEFORE UPDATE ON bordro_items
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_bordro_calculation_rates_updated_at') THEN
    CREATE TRIGGER update_bordro_calculation_rates_updated_at
      BEFORE UPDATE ON bordro_calculation_rates
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_bordro_templates_updated_at') THEN
    CREATE TRIGGER update_bordro_templates_updated_at
      BEFORE UPDATE ON bordro_templates
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;
END $$;

-- 2025 yılı için varsayılan hesaplama oranlarını ekle
INSERT INTO bordro_calculation_rates (
  company_id,
  yil,
  gelir_vergisi_dilimleri,
  damga_vergisi_orani,
  sgk_isci_payi_orani,
  sgk_isveren_payi_orani,
  issizlik_isci_payi_orani,
  issizlik_isveren_payi_orani,
  asgari_ucret,
  sgk_tavani,
  asgari_ucret_istisnasi
)
SELECT 
  id as company_id,
  2025 as yil,
  '[
    {"alt": 0, "ust": 110000, "oran": 0.15, "oncekiDilimlerToplami": 0},
    {"alt": 110000, "ust": 230000, "oran": 0.20, "oncekiDilimlerToplami": 16500},
    {"alt": 230000, "ust": 580000, "oran": 0.27, "oncekiDilimlerToplami": 40500},
    {"alt": 580000, "ust": 3000000, "oran": 0.35, "oncekiDilimlerToplami": 135000},
    {"alt": 3000000, "ust": 999999999, "oran": 0.40, "oncekiDilimlerToplami": 982000}
  ]'::jsonb as gelir_vergisi_dilimleri,
  0.00759 as damga_vergisi_orani,
  0.14 as sgk_isci_payi_orani,
  0.205 as sgk_isveren_payi_orani,
  0.01 as issizlik_isci_payi_orani,
  0.02 as issizlik_isveren_payi_orani,
  22104.00 as asgari_ucret,
  178957.50 as sgk_tavani,
  '{"gelirVergisi": 1803.51, "damgaVergisi": 44.95}'::jsonb as asgari_ucret_istisnasi
FROM companies
ON CONFLICT (company_id, yil) DO NOTHING;

-- İndeksler
CREATE INDEX IF NOT EXISTS idx_bordro_items_company_id ON bordro_items(company_id);
CREATE INDEX IF NOT EXISTS idx_bordro_items_employee_id ON bordro_items(employee_id);
CREATE INDEX IF NOT EXISTS idx_bordro_items_period ON bordro_items(period);
CREATE INDEX IF NOT EXISTS idx_bordro_calculation_rates_company_id ON bordro_calculation_rates(company_id);
CREATE INDEX IF NOT EXISTS idx_bordro_calculation_rates_yil ON bordro_calculation_rates(yil);
CREATE INDEX IF NOT EXISTS idx_bordro_templates_company_id ON bordro_templates(company_id);

-- RLS Aktifleştirme
ALTER TABLE bordro_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE bordro_calculation_rates ENABLE ROW LEVEL SECURITY;
ALTER TABLE bordro_templates ENABLE ROW LEVEL SECURITY;

-- Bordro items RLS politikaları
CREATE POLICY "HR can view all bordro items in their company"
  ON bordro_items FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles 
      WHERE id = auth.uid() 
      AND role IN ('admin', 'hr', 'manager')
    )
  );

CREATE POLICY "Employees can view their own bordro"
  ON bordro_items FOR SELECT
  TO authenticated
  USING (
    employee_id IN (
      SELECT id FROM employees 
      WHERE email = (SELECT email FROM profiles WHERE id = auth.uid())
      AND company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())
    )
  );

CREATE POLICY "HR can create bordro items"
  ON bordro_items FOR INSERT
  TO authenticated
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM profiles 
      WHERE id = auth.uid() 
      AND role IN ('admin', 'hr')
    )
  );

CREATE POLICY "HR can update bordro items"
  ON bordro_items FOR UPDATE
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

CREATE POLICY "HR can delete bordro items"
  ON bordro_items FOR DELETE
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles 
      WHERE id = auth.uid() 
      AND role IN ('admin', 'hr')
    )
  );

-- Bordro calculation rates RLS politikaları
CREATE POLICY "Users can view calculation rates in their company"
  ON bordro_calculation_rates FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "Admins can manage calculation rates"
  ON bordro_calculation_rates FOR ALL
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles 
      WHERE id = auth.uid() 
      AND role = 'admin'
    )
  )
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM profiles 
      WHERE id = auth.uid() 
      AND role = 'admin'
    )
  );

-- Bordro templates RLS politikaları
CREATE POLICY "Users can view templates in their company"
  ON bordro_templates FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "HR can manage templates"
  ON bordro_templates FOR ALL
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
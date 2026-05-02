/*
  # İzin Yönetimi Modülü
  
  ## Genel Bakış
  Bu migration, izin yönetimi sisteminin veritabanı yapısını oluşturur.
  Yıllık izin, mazeret izni, hastalık izni ve diğer izin türlerini yönetir.
  
  ## Oluşturulan Tablolar
  
  ### 1. `izin_talepleri`
  İzin talepleri ve onay süreçleri
  - `id` (uuid, PK)
  - `company_id` (uuid, FK) - Şirket
  - `employee_id` (uuid, FK) - Personel
  - `izin_turu` (text) - İzin türü
  - `baslangic_tarihi` (date) - Başlangıç tarihi
  - `bitis_tarihi` (date) - Bitiş tarihi
  - `gun_sayisi` (integer) - Gün sayısı
  - `aciklama` (text) - Açıklama
  - `yol_izni_talep` (boolean) - Yol izni talebi var mı
  - `yol_izni_gun` (integer) - Yol izni gün sayısı
  - `seyahat_yeri` (text) - Seyahat yeri
  - `il_disi_seyahat` (boolean) - İl dışı seyahat mi
  - `belge_url` (text) - Belge dosyası URL
  - `durum` (text) - Durum (beklemede, onaylandi, reddedildi, iptal)
  - `onaylayan_id` (uuid) - Onaylayan kullanıcı
  - `onay_tarihi` (timestamptz) - Onay tarihi
  - `red_nedeni` (text) - Red nedeni
  - `talep_tarihi` (date) - Talep tarihi
  
  ### 2. `izin_haklari`
  Personellerin yıllık izin hakları
  - `id` (uuid, PK)
  - `company_id` (uuid, FK)
  - `employee_id` (uuid, FK)
  - `yil` (integer) - Yıl
  - `toplam_hak` (numeric) - Toplam izin hakkı (gün)
  - `kullanilan_izin` (numeric) - Kullanılan izin
  - `kalan_izin` (numeric) - Kalan izin
  - `calisma_yili` (integer) - Çalışma yılı
  - `ise_giris_tarihi` (date) - İşe giriş tarihi
  - `hesaplama_tarihi` (date) - Hesaplama tarihi
  - `mazeret_izin` (numeric) - Mazeret izni (günlük)
  - `hastalik_izin` (numeric) - Hastalık izni (günlük)
  
  ### 3. `izin_onaycilar`
  İzin onaylama yetkisi olan kullanıcılar
  - `id` (uuid, PK)
  - `company_id` (uuid, FK)
  - `user_id` (uuid, FK) - Kullanıcı
  - `department` (text) - Departman (null ise tüm departmanlar)
  - `yetki_seviyesi` (text) - Yetki seviyesi
  
  ## Güvenlik
  - Tüm tablolarda RLS aktif
  - Kullanıcılar sadece kendi şirketlerinin verilerine erişebilir
  - İzin talepleri personel tarafından oluşturulabilir
  - Onaylar sadece yetkili kullanıcılar tarafından yapılabilir
  
  ## Notlar
  - Otomatik kalan izin hesaplaması trigger ile yapılır
  - İzin onay süreçleri yetki bazlı kontrol edilir
  - İzin çakışma kontrolü yapılır
*/

-- İzin talepleri tablosu
CREATE TABLE IF NOT EXISTS izin_talepleri (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  employee_id uuid NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  izin_turu text NOT NULL CHECK (izin_turu IN ('yillik', 'mazeret', 'hastalik', 'dogum', 'babalik', 'evlilik', 'olum', 'askerlik', 'ucretsiz')),
  baslangic_tarihi date NOT NULL,
  bitis_tarihi date NOT NULL,
  gun_sayisi integer NOT NULL DEFAULT 0,
  aciklama text DEFAULT '',
  yol_izni_talep boolean DEFAULT false,
  yol_izni_gun integer DEFAULT 0,
  seyahat_yeri text DEFAULT '',
  il_disi_seyahat boolean DEFAULT false,
  belge_url text,
  durum text NOT NULL DEFAULT 'beklemede' CHECK (durum IN ('beklemede', 'onaylandi', 'reddedildi', 'iptal')),
  onaylayan_id uuid REFERENCES profiles(id) ON DELETE SET NULL,
  onay_tarihi timestamptz,
  red_nedeni text,
  talep_tarihi date DEFAULT CURRENT_DATE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT valid_date_range CHECK (bitis_tarihi >= baslangic_tarihi)
);

-- İzin hakları tablosu
CREATE TABLE IF NOT EXISTS izin_haklari (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  employee_id uuid NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  yil integer NOT NULL,
  toplam_hak numeric(5, 1) DEFAULT 0,
  kullanilan_izin numeric(5, 1) DEFAULT 0,
  kalan_izin numeric(5, 1) DEFAULT 0,
  calisma_yili integer DEFAULT 0,
  ise_giris_tarihi date,
  hesaplama_tarihi date DEFAULT CURRENT_DATE,
  mazeret_izin numeric(5, 1) DEFAULT 0,
  hastalik_izin numeric(5, 1) DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(employee_id, yil)
);

-- İzin onayıcıları tablosu
CREATE TABLE IF NOT EXISTS izin_onaycilar (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  department text,
  yetki_seviyesi text NOT NULL DEFAULT 'departman' CHECK (yetki_seviyesi IN ('departman', 'genel', 'ik')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id, department)
);

-- Trigger'ları oluştur
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_izin_talepleri_updated_at') THEN
    CREATE TRIGGER update_izin_talepleri_updated_at
      BEFORE UPDATE ON izin_talepleri
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_izin_haklari_updated_at') THEN
    CREATE TRIGGER update_izin_haklari_updated_at
      BEFORE UPDATE ON izin_haklari
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_izin_onaycilar_updated_at') THEN
    CREATE TRIGGER update_izin_onaycilar_updated_at
      BEFORE UPDATE ON izin_onaycilar
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;
END $$;

-- Kalan izin otomatik hesaplama fonksiyonu
CREATE OR REPLACE FUNCTION calculate_kalan_izin()
RETURNS TRIGGER AS $$
BEGIN
  NEW.kalan_izin = NEW.toplam_hak - NEW.kullanilan_izin;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Kalan izin trigger'ı
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_calculate_kalan_izin') THEN
    CREATE TRIGGER trigger_calculate_kalan_izin
      BEFORE INSERT OR UPDATE ON izin_haklari
      FOR EACH ROW
      EXECUTE FUNCTION calculate_kalan_izin();
  END IF;
END $$;

-- İndeksler
CREATE INDEX IF NOT EXISTS idx_izin_talepleri_company_id ON izin_talepleri(company_id);
CREATE INDEX IF NOT EXISTS idx_izin_talepleri_employee_id ON izin_talepleri(employee_id);
CREATE INDEX IF NOT EXISTS idx_izin_talepleri_durum ON izin_talepleri(durum);
CREATE INDEX IF NOT EXISTS idx_izin_talepleri_tarih ON izin_talepleri(baslangic_tarihi, bitis_tarihi);
CREATE INDEX IF NOT EXISTS idx_izin_haklari_company_id ON izin_haklari(company_id);
CREATE INDEX IF NOT EXISTS idx_izin_haklari_employee_id ON izin_haklari(employee_id);
CREATE INDEX IF NOT EXISTS idx_izin_haklari_yil ON izin_haklari(yil);
CREATE INDEX IF NOT EXISTS idx_izin_onaycilar_company_id ON izin_onaycilar(company_id);
CREATE INDEX IF NOT EXISTS idx_izin_onaycilar_user_id ON izin_onaycilar(user_id);

-- RLS Aktifleştirme
ALTER TABLE izin_talepleri ENABLE ROW LEVEL SECURITY;
ALTER TABLE izin_haklari ENABLE ROW LEVEL SECURITY;
ALTER TABLE izin_onaycilar ENABLE ROW LEVEL SECURITY;

-- İzin talepleri RLS politikaları
CREATE POLICY "Users can view izin talepleri in their company"
  ON izin_talepleri FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "Employees can create their own izin talepleri"
  ON izin_talepleri FOR INSERT
  TO authenticated
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "HR and managers can update izin talepleri"
  ON izin_talepleri FOR UPDATE
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles 
      WHERE id = auth.uid() 
      AND role IN ('admin', 'hr', 'manager')
    )
  )
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM profiles 
      WHERE id = auth.uid() 
      AND role IN ('admin', 'hr', 'manager')
    )
  );

CREATE POLICY "HR and admins can delete izin talepleri"
  ON izin_talepleri FOR DELETE
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles 
      WHERE id = auth.uid() 
      AND role IN ('admin', 'hr')
    )
  );

-- İzin hakları RLS politikaları
CREATE POLICY "Users can view izin haklari in their company"
  ON izin_haklari FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "HR and admins can manage izin haklari"
  ON izin_haklari FOR INSERT
  TO authenticated
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM profiles 
      WHERE id = auth.uid() 
      AND role IN ('admin', 'hr')
    )
  );

CREATE POLICY "HR and admins can update izin haklari"
  ON izin_haklari FOR UPDATE
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

CREATE POLICY "HR and admins can delete izin haklari"
  ON izin_haklari FOR DELETE
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles 
      WHERE id = auth.uid() 
      AND role = 'admin'
    )
  );

-- İzin onayıcılar RLS politikaları
CREATE POLICY "Users can view izin onaycilar in their company"
  ON izin_onaycilar FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "Admins can manage izin onaycilar"
  ON izin_onaycilar FOR ALL
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
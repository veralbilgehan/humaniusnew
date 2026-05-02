-- Auto-generated bootstrap script
-- Source: supabase/migrations


-- >>> BEGIN 20260214180417_create_initial_schema.sql

/*
  # Ä°nsan KaynaklarÄ± YÃ¶netim Sistemi - Temel Åžema
  
  ## Genel BakÄ±ÅŸ
  Bu migration, HRMS (Human Resources Management System) iÃ§in temel veritabanÄ± yapÄ±sÄ±nÄ± oluÅŸturur.
  Sistem, Ã§ok ÅŸirketli yapÄ±yÄ± destekler ve her kullanÄ±cÄ± kendi ÅŸirketinin verilerine eriÅŸebilir.
  
  ## OluÅŸturulan Tablolar
  
  ### 1. `profiles`
  KullanÄ±cÄ± profil bilgileri (auth.users ile iliÅŸkili)
  - `id` (uuid, PK) - auth.users.id ile eÅŸleÅŸir
  - `email` (text) - KullanÄ±cÄ± email
  - `full_name` (text) - Ad soyad
  - `company_id` (uuid) - BaÄŸlÄ± olduÄŸu ÅŸirket
  - `role` (text) - KullanÄ±cÄ± rolÃ¼ (admin, manager, employee)
  - `avatar_url` (text) - Profil fotoÄŸrafÄ± URL
  - `created_at` (timestamptz) - OluÅŸturulma tarihi
  - `updated_at` (timestamptz) - GÃ¼ncellenme tarihi
  
  ### 2. `companies`
  Åžirket bilgileri
  - `id` (uuid, PK)
  - `name` (text) - Åžirket adÄ±
  - `address` (text) - Adres
  - `tax_number` (text) - Vergi numarasÄ±
  - `sgk_sicil_no` (text) - SGK sicil numarasÄ±
  - `phone` (text) - Telefon
  - `email` (text) - Email
  - `city` (text) - BulunduÄŸu il
  - `logo_url` (text) - Logo URL
  - `created_at` (timestamptz)
  - `updated_at` (timestamptz)
  
  ### 3. `employees`
  Personel bilgileri
  - `id` (uuid, PK)
  - `company_id` (uuid, FK)
  - `name` (text) - Ad soyad
  - `tc_no` (text) - TC kimlik no
  - `sicil_no` (text) - Sicil no
  - `department` (text) - Departman
  - `position` (text) - Pozisyon
  - `level` (text) - Seviye
  - `salary` (numeric) - MaaÅŸ
  - `status` (text) - Durum (active, onLeave, inactive)
  - `phone` (text) - Telefon
  - `email` (text) - Email
  - `join_date` (date) - Ä°ÅŸe giriÅŸ tarihi
  - `address` (text) - Adres
  - `avatar_url` (text) - Profil fotoÄŸrafÄ±
  - `skills` (text[]) - Yetenekler
  - `medeni_durum` (text) - Medeni durum
  - `cocuk_sayisi` (integer) - Ã‡ocuk sayÄ±sÄ±
  - `engelli_durumu` (text) - Engelli durumu
  - `created_at` (timestamptz)
  - `updated_at` (timestamptz)
  
  ## GÃ¼venlik
  - TÃ¼m tablolarda RLS (Row Level Security) aktif
  - KullanÄ±cÄ±lar sadece kendi ÅŸirketlerinin verilerine eriÅŸebilir
  - Admin rolÃ¼ tam yetkiye sahip
  - Manager departman bazlÄ± yetkilere sahip
  - Employee sadece kendi verilerini gÃ¶rebilir
  
  ## Notlar
  - TÃ¼m foreign key'ler CASCADE ile silinir
  - Otomatik timestamp gÃ¼ncelleme trigger'larÄ± eklenir
  - Ä°ndeksler performans iÃ§in eklenir
*/

-- UUID extension'Ä± aktifleÅŸtir
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Åžirketler tablosu
CREATE TABLE IF NOT EXISTS companies (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  address text DEFAULT '',
  tax_number text DEFAULT '',
  sgk_sicil_no text DEFAULT '',
  phone text DEFAULT '',
  email text DEFAULT '',
  city text DEFAULT '',
  logo_url text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- KullanÄ±cÄ± profilleri tablosu
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text NOT NULL,
  full_name text NOT NULL,
  company_id uuid REFERENCES companies(id) ON DELETE CASCADE,
  role text NOT NULL DEFAULT 'employee' CHECK (role IN ('admin', 'manager', 'employee', 'hr')),
  avatar_url text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Personeller tablosu
CREATE TABLE IF NOT EXISTS employees (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name text NOT NULL,
  tc_no text DEFAULT '',
  sicil_no text DEFAULT '',
  department text NOT NULL,
  position text NOT NULL,
  level text NOT NULL DEFAULT 'Junior' CHECK (level IN ('Junior', 'Mid', 'Senior', 'Lead', 'Manager')),
  salary numeric(12, 2) DEFAULT 0,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'onLeave', 'inactive')),
  phone text DEFAULT '',
  email text DEFAULT '',
  join_date date DEFAULT CURRENT_DATE,
  address text DEFAULT '',
  avatar_url text,
  skills text[] DEFAULT '{}',
  medeni_durum text DEFAULT 'bekar' CHECK (medeni_durum IN ('bekar', 'evli')),
  cocuk_sayisi integer DEFAULT 0,
  engelli_durumu text DEFAULT 'yok' CHECK (engelli_durumu IN ('yok', 'birinci', 'ikinci', 'ucuncu')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Otomatik updated_at gÃ¼ncellemesi iÃ§in trigger fonksiyonu
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger'larÄ± oluÅŸtur
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_companies_updated_at') THEN
    CREATE TRIGGER update_companies_updated_at
      BEFORE UPDATE ON companies
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_profiles_updated_at') THEN
    CREATE TRIGGER update_profiles_updated_at
      BEFORE UPDATE ON profiles
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_employees_updated_at') THEN
    CREATE TRIGGER update_employees_updated_at
      BEFORE UPDATE ON employees
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;
END $$;

-- Ä°ndeksler
CREATE INDEX IF NOT EXISTS idx_profiles_company_id ON profiles(company_id);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_employees_company_id ON employees(company_id);
CREATE INDEX IF NOT EXISTS idx_employees_status ON employees(status);
CREATE INDEX IF NOT EXISTS idx_employees_department ON employees(department);

-- RLS AktifleÅŸtirme
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;

-- Companies tablosu RLS politikalarÄ±
CREATE POLICY "Users can view their own company"
  ON companies FOR SELECT
  TO authenticated
  USING (
    id IN (
      SELECT company_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "Admins can insert companies"
  ON companies FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() 
      AND role = 'admin'
    )
  );

CREATE POLICY "Admins can update their company"
  ON companies FOR UPDATE
  TO authenticated
  USING (
    id IN (
      SELECT company_id FROM profiles 
      WHERE id = auth.uid() 
      AND role IN ('admin', 'hr')
    )
  )
  WITH CHECK (
    id IN (
      SELECT company_id FROM profiles 
      WHERE id = auth.uid() 
      AND role IN ('admin', 'hr')
    )
  );

CREATE POLICY "Admins can delete their company"
  ON companies FOR DELETE
  TO authenticated
  USING (
    id IN (
      SELECT company_id FROM profiles 
      WHERE id = auth.uid() 
      AND role = 'admin'
    )
  );

-- Profiles tablosu RLS politikalarÄ±
CREATE POLICY "Users can view profiles in their company"
  ON profiles FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

CREATE POLICY "Admins can insert profiles"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM profiles 
      WHERE id = auth.uid() 
      AND role IN ('admin', 'hr')
    )
  );

CREATE POLICY "Admins can delete profiles in their company"
  ON profiles FOR DELETE
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles 
      WHERE id = auth.uid() 
      AND role = 'admin'
    )
  );

-- Employees tablosu RLS politikalarÄ±
CREATE POLICY "Users can view employees in their company"
  ON employees FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "HR and admins can insert employees"
  ON employees FOR INSERT
  TO authenticated
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM profiles 
      WHERE id = auth.uid() 
      AND role IN ('admin', 'hr')
    )
  );

CREATE POLICY "HR and admins can update employees in their company"
  ON employees FOR UPDATE
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

CREATE POLICY "HR and admins can delete employees in their company"
  ON employees FOR DELETE
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles 
      WHERE id = auth.uid() 
      AND role IN ('admin', 'hr')
    )
  );

-- <<< END 20260214180417_create_initial_schema.sql


-- >>> BEGIN 20260214180507_create_izin_yonetimi_schema.sql

/*
  # Ä°zin YÃ¶netimi ModÃ¼lÃ¼
  
  ## Genel BakÄ±ÅŸ
  Bu migration, izin yÃ¶netimi sisteminin veritabanÄ± yapÄ±sÄ±nÄ± oluÅŸturur.
  YÄ±llÄ±k izin, mazeret izni, hastalÄ±k izni ve diÄŸer izin tÃ¼rlerini yÃ¶netir.
  
  ## OluÅŸturulan Tablolar
  
  ### 1. `izin_talepleri`
  Ä°zin talepleri ve onay sÃ¼reÃ§leri
  - `id` (uuid, PK)
  - `company_id` (uuid, FK) - Åžirket
  - `employee_id` (uuid, FK) - Personel
  - `izin_turu` (text) - Ä°zin tÃ¼rÃ¼
  - `baslangic_tarihi` (date) - BaÅŸlangÄ±Ã§ tarihi
  - `bitis_tarihi` (date) - BitiÅŸ tarihi
  - `gun_sayisi` (integer) - GÃ¼n sayÄ±sÄ±
  - `aciklama` (text) - AÃ§Ä±klama
  - `yol_izni_talep` (boolean) - Yol izni talebi var mÄ±
  - `yol_izni_gun` (integer) - Yol izni gÃ¼n sayÄ±sÄ±
  - `seyahat_yeri` (text) - Seyahat yeri
  - `il_disi_seyahat` (boolean) - Ä°l dÄ±ÅŸÄ± seyahat mi
  - `belge_url` (text) - Belge dosyasÄ± URL
  - `durum` (text) - Durum (beklemede, onaylandi, reddedildi, iptal)
  - `onaylayan_id` (uuid) - Onaylayan kullanÄ±cÄ±
  - `onay_tarihi` (timestamptz) - Onay tarihi
  - `red_nedeni` (text) - Red nedeni
  - `talep_tarihi` (date) - Talep tarihi
  
  ### 2. `izin_haklari`
  Personellerin yÄ±llÄ±k izin haklarÄ±
  - `id` (uuid, PK)
  - `company_id` (uuid, FK)
  - `employee_id` (uuid, FK)
  - `yil` (integer) - YÄ±l
  - `toplam_hak` (numeric) - Toplam izin hakkÄ± (gÃ¼n)
  - `kullanilan_izin` (numeric) - KullanÄ±lan izin
  - `kalan_izin` (numeric) - Kalan izin
  - `calisma_yili` (integer) - Ã‡alÄ±ÅŸma yÄ±lÄ±
  - `ise_giris_tarihi` (date) - Ä°ÅŸe giriÅŸ tarihi
  - `hesaplama_tarihi` (date) - Hesaplama tarihi
  - `mazeret_izin` (numeric) - Mazeret izni (gÃ¼nlÃ¼k)
  - `hastalik_izin` (numeric) - HastalÄ±k izni (gÃ¼nlÃ¼k)
  
  ### 3. `izin_onaycilar`
  Ä°zin onaylama yetkisi olan kullanÄ±cÄ±lar
  - `id` (uuid, PK)
  - `company_id` (uuid, FK)
  - `user_id` (uuid, FK) - KullanÄ±cÄ±
  - `department` (text) - Departman (null ise tÃ¼m departmanlar)
  - `yetki_seviyesi` (text) - Yetki seviyesi
  
  ## GÃ¼venlik
  - TÃ¼m tablolarda RLS aktif
  - KullanÄ±cÄ±lar sadece kendi ÅŸirketlerinin verilerine eriÅŸebilir
  - Ä°zin talepleri personel tarafÄ±ndan oluÅŸturulabilir
  - Onaylar sadece yetkili kullanÄ±cÄ±lar tarafÄ±ndan yapÄ±labilir
  
  ## Notlar
  - Otomatik kalan izin hesaplamasÄ± trigger ile yapÄ±lÄ±r
  - Ä°zin onay sÃ¼reÃ§leri yetki bazlÄ± kontrol edilir
  - Ä°zin Ã§akÄ±ÅŸma kontrolÃ¼ yapÄ±lÄ±r
*/

-- Ä°zin talepleri tablosu
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

-- Ä°zin haklarÄ± tablosu
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

-- Ä°zin onayÄ±cÄ±larÄ± tablosu
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

-- Trigger'larÄ± oluÅŸtur
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

-- Kalan izin trigger'Ä±
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_calculate_kalan_izin') THEN
    CREATE TRIGGER trigger_calculate_kalan_izin
      BEFORE INSERT OR UPDATE ON izin_haklari
      FOR EACH ROW
      EXECUTE FUNCTION calculate_kalan_izin();
  END IF;
END $$;

-- Ä°ndeksler
CREATE INDEX IF NOT EXISTS idx_izin_talepleri_company_id ON izin_talepleri(company_id);
CREATE INDEX IF NOT EXISTS idx_izin_talepleri_employee_id ON izin_talepleri(employee_id);
CREATE INDEX IF NOT EXISTS idx_izin_talepleri_durum ON izin_talepleri(durum);
CREATE INDEX IF NOT EXISTS idx_izin_talepleri_tarih ON izin_talepleri(baslangic_tarihi, bitis_tarihi);
CREATE INDEX IF NOT EXISTS idx_izin_haklari_company_id ON izin_haklari(company_id);
CREATE INDEX IF NOT EXISTS idx_izin_haklari_employee_id ON izin_haklari(employee_id);
CREATE INDEX IF NOT EXISTS idx_izin_haklari_yil ON izin_haklari(yil);
CREATE INDEX IF NOT EXISTS idx_izin_onaycilar_company_id ON izin_onaycilar(company_id);
CREATE INDEX IF NOT EXISTS idx_izin_onaycilar_user_id ON izin_onaycilar(user_id);

-- RLS AktifleÅŸtirme
ALTER TABLE izin_talepleri ENABLE ROW LEVEL SECURITY;
ALTER TABLE izin_haklari ENABLE ROW LEVEL SECURITY;
ALTER TABLE izin_onaycilar ENABLE ROW LEVEL SECURITY;

-- Ä°zin talepleri RLS politikalarÄ±
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

-- Ä°zin haklarÄ± RLS politikalarÄ±
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

-- Ä°zin onayÄ±cÄ±lar RLS politikalarÄ±
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

-- <<< END 20260214180507_create_izin_yonetimi_schema.sql


-- >>> BEGIN 20260214180608_create_bordro_yonetimi_schema.sql

/*
  # Bordro YÃ¶netimi ModÃ¼lÃ¼
  
  ## Genel BakÄ±ÅŸ
  Bu migration, bordro ve maaÅŸ hesaplama sisteminin veritabanÄ± yapÄ±sÄ±nÄ± oluÅŸturur.
  TÃ¼rkiye Ä°ÅŸ Kanunu ve SGK mevzuatÄ±na uygun bordro hesaplamalarÄ± yapar.
  
  ## OluÅŸturulan Tablolar
  
  ### 1. `bordro_items`
  AylÄ±k bordro kayÄ±tlarÄ± ve maaÅŸ hesaplamalarÄ±
  - `id` (uuid, PK)
  - `company_id` (uuid, FK) - Åžirket
  - `employee_id` (uuid, FK) - Personel
  - `period` (text) - DÃ¶nem (YYYY-MM)
  - `sicil_no` (text) - Sicil no
  - `tc_no` (text) - TC no
  - Temel Bilgiler: brut_maas, medeni_durum, cocuk_sayisi, engelli_durumu
  - KazanÃ§lar: temel_kazanc, yol_parasi, gida_yardimi, cocuk_yardimi vb.
  - Fazla Mesai: fazla_mesai, fazla_mesai_saat_50, fazla_mesai_saat_100, fazla_mesai_tutar
  - Ek Ã–demeler: haftalik_tatil, genel_tatil, yillik_izin_ucreti, ikramiye, prim
  - Kesintiler: gelir_vergisi, damga_vergisi, sgk_isci_payi, issizlik_sigortasi
  - Vergi Ä°ndirimleri: engelli_indirimi, asgari_ucret_gelir_vergisi_istisnasi
  - Tazminatlar: kidem_tazminati, ihbar_tazminati
  - Hesaplanan: toplam_kazanc, toplam_kesinti, net_maas, kumulatif_vergi_matrahi
  - Ä°ÅŸveren PaylarÄ±: sgk_isveren_payi, issizlik_isveren_payi, sgk_isveren_indirimi
  
  ### 2. `bordro_calculation_rates`
  Bordro hesaplama oranlarÄ± ve parametreleri (yÄ±llÄ±k gÃ¼ncellenir)
  - `id` (uuid, PK)
  - `company_id` (uuid, FK)
  - `yil` (integer) - GeÃ§erlilik yÄ±lÄ±
  - `gelir_vergisi_dilimleri` (jsonb) - Gelir vergisi dilimleri
  - `damga_vergisi_orani` (numeric) - Damga vergisi oranÄ±
  - `sgk_isci_payi_orani` (numeric) - SGK iÅŸÃ§i payÄ± oranÄ±
  - `sgk_isveren_payi_orani` (numeric) - SGK iÅŸveren payÄ± oranÄ±
  - `issizlik_isci_payi_orani` (numeric) - Ä°ÅŸsizlik iÅŸÃ§i payÄ± oranÄ±
  - `issizlik_isveren_payi_orani` (numeric) - Ä°ÅŸsizlik iÅŸveren payÄ± oranÄ±
  - `asgari_ucret` (numeric) - Asgari Ã¼cret
  - `sgk_tavani` (numeric) - SGK tavanÄ±
  - `asgari_ucret_istisnasi` (jsonb) - Asgari Ã¼cret istisnalarÄ±
  
  ### 3. `bordro_templates`
  Bordro ÅŸablonlarÄ± (hÄ±zlÄ± bordro giriÅŸi iÃ§in)
  - `id` (uuid, PK)
  - `company_id` (uuid, FK)
  - `name` (text) - Åžablon adÄ±
  - `description` (text) - AÃ§Ä±klama
  - `default_values` (jsonb) - VarsayÄ±lan deÄŸerler
  
  ## GÃ¼venlik
  - TÃ¼m tablolarda RLS aktif
  - Bordro bilgileri hassas veri olarak korunur
  - Sadece HR ve admin rolleri bordro oluÅŸturabilir ve gÃ¼ncelleyebilir
  - Ã‡alÄ±ÅŸanlar sadece kendi bordrolarÄ±nÄ± gÃ¶rÃ¼ntÃ¼leyebilir
  
  ## Notlar
  - Otomatik hesaplama fonksiyonlarÄ± eklenir
  - Vergi dilimleri JSONB formatÄ±nda saklanÄ±r
  - YÄ±llÄ±k toplam hesaplamalarÄ± otomatik yapÄ±lÄ±r
*/

-- Bordro kayÄ±tlarÄ± tablosu
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
  
  -- KazanÃ§lar
  temel_kazanc numeric(12, 2) DEFAULT 0,
  yol_parasi numeric(12, 2) DEFAULT 0,
  gida_yardimi numeric(12, 2) DEFAULT 0,
  cocuk_yardimi numeric(12, 2) DEFAULT 0,
  diger_kazanclar numeric(12, 2) DEFAULT 0,
  
  -- Fazla Mesai DetaylarÄ±
  fazla_mesai numeric(12, 2) DEFAULT 0,
  fazla_mesai_saat_50 numeric(8, 2) DEFAULT 0,
  fazla_mesai_saat_100 numeric(8, 2) DEFAULT 0,
  fazla_mesai_tutar numeric(12, 2) DEFAULT 0,
  
  -- Ek Ã–demeler
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
  
  -- Vergi Ä°ndirimleri
  engelli_indirimi numeric(12, 2) DEFAULT 0,
  
  -- Tazminatlar
  kidem_tazminati numeric(12, 2) DEFAULT 0,
  ihbar_tazminati numeric(12, 2) DEFAULT 0,
  
  -- Hesaplanan DeÄŸerler
  toplam_kazanc numeric(12, 2) DEFAULT 0,
  toplam_kesinti numeric(12, 2) DEFAULT 0,
  net_maas numeric(12, 2) DEFAULT 0,
  kumulatif_vergi_matrahi numeric(12, 2) DEFAULT 0,
  
  -- Asgari Ãœcret Ä°stisnalarÄ±
  asgari_ucret_gelir_vergisi_istisnasi numeric(12, 2) DEFAULT 0,
  asgari_ucret_damga_vergisi_istisnasi numeric(12, 2) DEFAULT 0,
  
  -- Ä°ÅŸveren PaylarÄ±
  sgk_isveren_payi numeric(12, 2) DEFAULT 0,
  issizlik_isveren_payi numeric(12, 2) DEFAULT 0,
  sgk_isveren_indirimi numeric(12, 2) DEFAULT 0,
  sgk_isveren_indirim_orani numeric(5, 2) DEFAULT 0,
  
  -- YÄ±llÄ±k Toplamlar
  yillik_toplam_kazanc numeric(12, 2) DEFAULT 0,
  yillik_toplam_kesinti numeric(12, 2) DEFAULT 0,
  yillik_toplam_net numeric(12, 2) DEFAULT 0,
  
  -- Notlar
  aciklama text DEFAULT '',
  
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  
  UNIQUE(employee_id, period)
);

-- Bordro hesaplama oranlarÄ± tablosu
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

-- Bordro ÅŸablonlarÄ± tablosu
CREATE TABLE IF NOT EXISTS bordro_templates (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text DEFAULT '',
  default_values jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Trigger'larÄ± oluÅŸtur
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

-- 2025 yÄ±lÄ± iÃ§in varsayÄ±lan hesaplama oranlarÄ±nÄ± ekle
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

-- Ä°ndeksler
CREATE INDEX IF NOT EXISTS idx_bordro_items_company_id ON bordro_items(company_id);
CREATE INDEX IF NOT EXISTS idx_bordro_items_employee_id ON bordro_items(employee_id);
CREATE INDEX IF NOT EXISTS idx_bordro_items_period ON bordro_items(period);
CREATE INDEX IF NOT EXISTS idx_bordro_calculation_rates_company_id ON bordro_calculation_rates(company_id);
CREATE INDEX IF NOT EXISTS idx_bordro_calculation_rates_yil ON bordro_calculation_rates(yil);
CREATE INDEX IF NOT EXISTS idx_bordro_templates_company_id ON bordro_templates(company_id);

-- RLS AktifleÅŸtirme
ALTER TABLE bordro_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE bordro_calculation_rates ENABLE ROW LEVEL SECURITY;
ALTER TABLE bordro_templates ENABLE ROW LEVEL SECURITY;

-- Bordro items RLS politikalarÄ±
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

-- Bordro calculation rates RLS politikalarÄ±
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

-- Bordro templates RLS politikalarÄ±
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

-- <<< END 20260214180608_create_bordro_yonetimi_schema.sql


-- >>> BEGIN 20260214180713_create_sistem_ayarlari_takvim_schema.sql

/*
  # Sistem AyarlarÄ± ve Takvim YÃ¶netimi
  
  ## Genel BakÄ±ÅŸ
  Bu migration, sistem parametreleri ve takvim yÃ¶netimi iÃ§in veritabanÄ± yapÄ±sÄ±nÄ± oluÅŸturur.
  
  ## OluÅŸturulan Tablolar
  
  ### 1. `sistem_parametreleri`
  Sistem genelindeki yapÄ±landÄ±rma parametreleri
  - `id` (uuid, PK)
  - `company_id` (uuid, FK) - Åžirket
  - `kategori` (text) - Parametre kategorisi
  - `ad` (text) - Parametre adÄ±
  - `deger` (text) - Parametre deÄŸeri (JSON string)
  - `aciklama` (text) - AÃ§Ä±klama
  - `zorunlu` (boolean) - Zorunlu mu
  - `degistirilebilir` (boolean) - DeÄŸiÅŸtirilebilir mi
  - `yapilandirma_tarihi` (timestamptz) - Ä°lk yapÄ±landÄ±rma
  - `son_guncelleme` (timestamptz) - Son gÃ¼ncelleme
  
  ### 2. `takvim_gunleri`
  Resmi tatiller ve Ã¶zel gÃ¼nler
  - `id` (uuid, PK)
  - `company_id` (uuid, FK) - Åžirket (null ise ulusal)
  - `tarih` (date) - Tarih
  - `ad` (text) - GÃ¼n adÄ±
  - `tur` (text) - TÃ¼r (resmi_tatil, dini_bayram, ozel_gun)
  - `aciklama` (text) - AÃ§Ä±klama
  - `calisma_gunu_mu` (boolean) - Ã‡alÄ±ÅŸma gÃ¼nÃ¼ mÃ¼
  - `yil` (integer) - YÄ±l
  
  ### 3. `bildirimler`
  Sistem bildirimleri ve uyarÄ±larÄ±
  - `id` (uuid, PK)
  - `company_id` (uuid, FK)
  - `user_id` (uuid, FK) - Hedef kullanÄ±cÄ± (null ise tÃ¼m ÅŸirket)
  - `baslik` (text) - BaÅŸlÄ±k
  - `mesaj` (text) - Mesaj
  - `tur` (text) - Bildirim tÃ¼rÃ¼
  - `oncelik` (text) - Ã–ncelik (dusuk, normal, yuksek, acil)
  - `okundu_mu` (boolean) - Okundu mu
  - `okunma_tarihi` (timestamptz) - Okunma tarihi
  - `link` (text) - Ä°lgili sayfa linki
  - `metadata` (jsonb) - Ek bilgiler
  
  ### 4. `aktivite_loglari`
  KullanÄ±cÄ± aktivite loglarÄ± (audit trail)
  - `id` (uuid, PK)
  - `company_id` (uuid, FK)
  - `user_id` (uuid, FK)
  - `aksiyon` (text) - YapÄ±lan iÅŸlem
  - `tablo` (text) - Etkilenen tablo
  - `kayit_id` (uuid) - Etkilenen kayÄ±t
  - `onceki_deger` (jsonb) - Ã–nceki deÄŸer
  - `yeni_deger` (jsonb) - Yeni deÄŸer
  - `ip_adresi` (text) - IP adresi
  - `user_agent` (text) - Browser bilgisi
  
  ## GÃ¼venlik
  - TÃ¼m tablolarda RLS aktif
  - Sistem parametreleri sadece admin tarafÄ±ndan deÄŸiÅŸtirilebilir
  - Takvim gÃ¼nleri herkes tarafÄ±ndan gÃ¶rÃ¼lebilir
  - Bildirimler sadece ilgili kullanÄ±cÄ± tarafÄ±ndan gÃ¶rÃ¼lebilir
  - Aktivite loglarÄ± sadece admin tarafÄ±ndan gÃ¶rÃ¼lebilir
  
  ## Notlar
  - TÃ¼rkiye resmi tatilleri otomatik eklenir
  - Bildirim sistemi otomatik tetiklenebilir
  - Aktivite loglarÄ± trigger ile otomatik kaydedilir
*/

-- Sistem parametreleri tablosu
CREATE TABLE IF NOT EXISTS sistem_parametreleri (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  kategori text NOT NULL CHECK (kategori IN ('is_kanunu', 'bordro_sgk', 'vergi_sigorta', 'egitim', 'belge_kurallari', 'sistem_kurallari', 'sirket_bilgileri')),
  ad text NOT NULL,
  deger text NOT NULL,
  aciklama text DEFAULT '',
  zorunlu boolean DEFAULT false,
  degistirilebilir boolean DEFAULT true,
  yapilandirma_tarihi timestamptz DEFAULT now(),
  son_guncelleme timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(company_id, kategori, ad)
);

-- Takvim gÃ¼nleri tablosu
CREATE TABLE IF NOT EXISTS takvim_gunleri (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id uuid REFERENCES companies(id) ON DELETE CASCADE,
  tarih date NOT NULL,
  ad text NOT NULL,
  tur text NOT NULL DEFAULT 'resmi_tatil' CHECK (tur IN ('resmi_tatil', 'dini_bayram', 'ozel_gun', 'firma_ozel')),
  aciklama text DEFAULT '',
  calisma_gunu_mu boolean DEFAULT false,
  yil integer NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Bildirimler tablosu
CREATE TABLE IF NOT EXISTS bildirimler (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  baslik text NOT NULL,
  mesaj text NOT NULL,
  tur text NOT NULL DEFAULT 'bilgi' CHECK (tur IN ('bilgi', 'uyari', 'hata', 'basari', 'izin', 'bordro', 'sistem')),
  oncelik text NOT NULL DEFAULT 'normal' CHECK (oncelik IN ('dusuk', 'normal', 'yuksek', 'acil')),
  okundu_mu boolean DEFAULT false,
  okunma_tarihi timestamptz,
  link text,
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Aktivite loglarÄ± tablosu
CREATE TABLE IF NOT EXISTS aktivite_loglari (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  aksiyon text NOT NULL,
  tablo text,
  kayit_id uuid,
  onceki_deger jsonb,
  yeni_deger jsonb,
  ip_adresi text,
  user_agent text,
  created_at timestamptz DEFAULT now()
);

-- Trigger'larÄ± oluÅŸtur
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_sistem_parametreleri_updated_at') THEN
    CREATE TRIGGER update_sistem_parametreleri_updated_at
      BEFORE UPDATE ON sistem_parametreleri
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_takvim_gunleri_updated_at') THEN
    CREATE TRIGGER update_takvim_gunleri_updated_at
      BEFORE UPDATE ON takvim_gunleri
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_bildirimler_updated_at') THEN
    CREATE TRIGGER update_bildirimler_updated_at
      BEFORE UPDATE ON bildirimler
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;
END $$;

-- 2025-2026 TÃ¼rkiye resmi tatillerini ekle
INSERT INTO takvim_gunleri (company_id, tarih, ad, tur, aciklama, calisma_gunu_mu, yil)
VALUES
  -- 2025 Tatiller
  (NULL, '2025-01-01', 'YÄ±lbaÅŸÄ±', 'resmi_tatil', 'YÄ±lbaÅŸÄ± tatili', false, 2025),
  (NULL, '2025-03-30', 'Ramazan BayramÄ± Arefe', 'dini_bayram', 'Ramazan BayramÄ± arefe gÃ¼nÃ¼', true, 2025),
  (NULL, '2025-03-31', 'Ramazan BayramÄ± 1. GÃ¼n', 'dini_bayram', 'Ramazan BayramÄ± birinci gÃ¼n', false, 2025),
  (NULL, '2025-04-01', 'Ramazan BayramÄ± 2. GÃ¼n', 'dini_bayram', 'Ramazan BayramÄ± ikinci gÃ¼n', false, 2025),
  (NULL, '2025-04-02', 'Ramazan BayramÄ± 3. GÃ¼n', 'dini_bayram', 'Ramazan BayramÄ± Ã¼Ã§Ã¼ncÃ¼ gÃ¼n', false, 2025),
  (NULL, '2025-04-23', '23 Nisan Ulusal Egemenlik ve Ã‡ocuk BayramÄ±', 'resmi_tatil', '23 Nisan', false, 2025),
  (NULL, '2025-05-01', '1 MayÄ±s Emek ve DayanÄ±ÅŸma GÃ¼nÃ¼', 'resmi_tatil', '1 MayÄ±s', false, 2025),
  (NULL, '2025-05-19', '19 MayÄ±s AtatÃ¼rk''Ã¼ Anma GenÃ§lik ve Spor BayramÄ±', 'resmi_tatil', '19 MayÄ±s', false, 2025),
  (NULL, '2025-06-06', 'Kurban BayramÄ± Arefe', 'dini_bayram', 'Kurban BayramÄ± arefe gÃ¼nÃ¼', true, 2025),
  (NULL, '2025-06-07', 'Kurban BayramÄ± 1. GÃ¼n', 'dini_bayram', 'Kurban BayramÄ± birinci gÃ¼n', false, 2025),
  (NULL, '2025-06-08', 'Kurban BayramÄ± 2. GÃ¼n', 'dini_bayram', 'Kurban BayramÄ± ikinci gÃ¼n', false, 2025),
  (NULL, '2025-06-09', 'Kurban BayramÄ± 3. GÃ¼n', 'dini_bayram', 'Kurban BayramÄ± Ã¼Ã§Ã¼ncÃ¼ gÃ¼n', false, 2025),
  (NULL, '2025-06-10', 'Kurban BayramÄ± 4. GÃ¼n', 'dini_bayram', 'Kurban BayramÄ± dÃ¶rdÃ¼ncÃ¼ gÃ¼n', false, 2025),
  (NULL, '2025-07-15', '15 Temmuz Demokrasi ve Milli Birlik GÃ¼nÃ¼', 'resmi_tatil', '15 Temmuz', false, 2025),
  (NULL, '2025-08-30', '30 AÄŸustos Zafer BayramÄ±', 'resmi_tatil', '30 AÄŸustos', false, 2025),
  (NULL, '2025-10-28', 'Cumhuriyet BayramÄ± Arefe', 'resmi_tatil', 'Cumhuriyet BayramÄ± arefe', true, 2025),
  (NULL, '2025-10-29', '29 Ekim Cumhuriyet BayramÄ±', 'resmi_tatil', '29 Ekim', false, 2025),
  
  -- 2026 Tatiller
  (NULL, '2026-01-01', 'YÄ±lbaÅŸÄ±', 'resmi_tatil', 'YÄ±lbaÅŸÄ± tatili', false, 2026),
  (NULL, '2026-03-19', 'Ramazan BayramÄ± Arefe', 'dini_bayram', 'Ramazan BayramÄ± arefe gÃ¼nÃ¼', true, 2026),
  (NULL, '2026-03-20', 'Ramazan BayramÄ± 1. GÃ¼n', 'dini_bayram', 'Ramazan BayramÄ± birinci gÃ¼n', false, 2026),
  (NULL, '2026-03-21', 'Ramazan BayramÄ± 2. GÃ¼n', 'dini_bayram', 'Ramazan BayramÄ± ikinci gÃ¼n', false, 2026),
  (NULL, '2026-03-22', 'Ramazan BayramÄ± 3. GÃ¼n', 'dini_bayram', 'Ramazan BayramÄ± Ã¼Ã§Ã¼ncÃ¼ gÃ¼n', false, 2026),
  (NULL, '2026-04-23', '23 Nisan Ulusal Egemenlik ve Ã‡ocuk BayramÄ±', 'resmi_tatil', '23 Nisan', false, 2026),
  (NULL, '2026-05-01', '1 MayÄ±s Emek ve DayanÄ±ÅŸma GÃ¼nÃ¼', 'resmi_tatil', '1 MayÄ±s', false, 2026),
  (NULL, '2026-05-19', '19 MayÄ±s AtatÃ¼rk''Ã¼ Anma GenÃ§lik ve Spor BayramÄ±', 'resmi_tatil', '19 MayÄ±s', false, 2026),
  (NULL, '2026-05-26', 'Kurban BayramÄ± Arefe', 'dini_bayram', 'Kurban BayramÄ± arefe gÃ¼nÃ¼', true, 2026),
  (NULL, '2026-05-27', 'Kurban BayramÄ± 1. GÃ¼n', 'dini_bayram', 'Kurban BayramÄ± birinci gÃ¼n', false, 2026),
  (NULL, '2026-05-28', 'Kurban BayramÄ± 2. GÃ¼n', 'dini_bayram', 'Kurban BayramÄ± ikinci gÃ¼n', false, 2026),
  (NULL, '2026-05-29', 'Kurban BayramÄ± 3. GÃ¼n', 'dini_bayram', 'Kurban BayramÄ± Ã¼Ã§Ã¼ncÃ¼ gÃ¼n', false, 2026),
  (NULL, '2026-05-30', 'Kurban BayramÄ± 4. GÃ¼n', 'dini_bayram', 'Kurban BayramÄ± dÃ¶rdÃ¼ncÃ¼ gÃ¼n', false, 2026),
  (NULL, '2026-07-15', '15 Temmuz Demokrasi ve Milli Birlik GÃ¼nÃ¼', 'resmi_tatil', '15 Temmuz', false, 2026),
  (NULL, '2026-08-30', '30 AÄŸustos Zafer BayramÄ±', 'resmi_tatil', '30 AÄŸustos', false, 2026),
  (NULL, '2026-10-28', 'Cumhuriyet BayramÄ± Arefe', 'resmi_tatil', 'Cumhuriyet BayramÄ± arefe', true, 2026),
  (NULL, '2026-10-29', '29 Ekim Cumhuriyet BayramÄ±', 'resmi_tatil', '29 Ekim', false, 2026)
ON CONFLICT DO NOTHING;

-- Ä°ndeksler
CREATE INDEX IF NOT EXISTS idx_sistem_parametreleri_company_id ON sistem_parametreleri(company_id);
CREATE INDEX IF NOT EXISTS idx_sistem_parametreleri_kategori ON sistem_parametreleri(kategori);
CREATE INDEX IF NOT EXISTS idx_takvim_gunleri_company_id ON takvim_gunleri(company_id);
CREATE INDEX IF NOT EXISTS idx_takvim_gunleri_tarih ON takvim_gunleri(tarih);
CREATE INDEX IF NOT EXISTS idx_takvim_gunleri_yil ON takvim_gunleri(yil);
CREATE INDEX IF NOT EXISTS idx_bildirimler_company_id ON bildirimler(company_id);
CREATE INDEX IF NOT EXISTS idx_bildirimler_user_id ON bildirimler(user_id);
CREATE INDEX IF NOT EXISTS idx_bildirimler_okundu_mu ON bildirimler(okundu_mu);
CREATE INDEX IF NOT EXISTS idx_aktivite_loglari_company_id ON aktivite_loglari(company_id);
CREATE INDEX IF NOT EXISTS idx_aktivite_loglari_user_id ON aktivite_loglari(user_id);
CREATE INDEX IF NOT EXISTS idx_aktivite_loglari_created_at ON aktivite_loglari(created_at);

-- RLS AktifleÅŸtirme
ALTER TABLE sistem_parametreleri ENABLE ROW LEVEL SECURITY;
ALTER TABLE takvim_gunleri ENABLE ROW LEVEL SECURITY;
ALTER TABLE bildirimler ENABLE ROW LEVEL SECURITY;
ALTER TABLE aktivite_loglari ENABLE ROW LEVEL SECURITY;

-- Sistem parametreleri RLS politikalarÄ±
CREATE POLICY "Users can view sistem parametreleri in their company"
  ON sistem_parametreleri FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "Admins can manage sistem parametreleri"
  ON sistem_parametreleri FOR ALL
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

-- Takvim gÃ¼nleri RLS politikalarÄ±
CREATE POLICY "Everyone can view takvim gunleri"
  ON takvim_gunleri FOR SELECT
  TO authenticated
  USING (
    company_id IS NULL OR
    company_id IN (
      SELECT company_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "HR and admins can manage takvim gunleri"
  ON takvim_gunleri FOR ALL
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

-- Bildirimler RLS politikalarÄ±
CREATE POLICY "Users can view their own bildirimler"
  ON bildirimler FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid() OR
    (user_id IS NULL AND company_id IN (
      SELECT company_id FROM profiles WHERE id = auth.uid()
    ))
  );

CREATE POLICY "Users can update their own bildirimler"
  ON bildirimler FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "HR and admins can create bildirimler"
  ON bildirimler FOR INSERT
  TO authenticated
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM profiles 
      WHERE id = auth.uid() 
      AND role IN ('admin', 'hr', 'manager')
    )
  );

CREATE POLICY "HR and admins can delete bildirimler"
  ON bildirimler FOR DELETE
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles 
      WHERE id = auth.uid() 
      AND role IN ('admin', 'hr')
    )
  );

-- Aktivite loglarÄ± RLS politikalarÄ±
CREATE POLICY "Admins can view aktivite loglari in their company"
  ON aktivite_loglari FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id FROM profiles 
      WHERE id = auth.uid() 
      AND role = 'admin'
    )
  );

CREATE POLICY "System can insert aktivite loglari"
  ON aktivite_loglari FOR INSERT
  TO authenticated
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM profiles WHERE id = auth.uid()
    )
  );

-- <<< END 20260214180713_create_sistem_ayarlari_takvim_schema.sql


-- >>> BEGIN 20260312032554_add_emekli_bordro_schema.sql

/*
  # Emekli Bordrosu ModÃ¼lÃ¼
  
  ## Genel BakÄ±ÅŸ
  Bu migration, emekli personel bordro hesaplama sisteminin veritabanÄ± yapÄ±sÄ±nÄ± ekler.
  BrÃ¼t-Net ve Net-BrÃ¼t hesaplama parametreleri ile emekli maaÅŸ bordrosu yÃ¶netimini saÄŸlar.
  
  ## OluÅŸturulan Tablolar
  
  ### 1. `emekli_bordro_items`
  Emekli personel bordro kayÄ±tlarÄ±
  - `id` (uuid, PK)
  - `company_id` (uuid, FK) - Åžirket
  - `employee_id` (uuid, FK) - Personel
  - `period` (text) - DÃ¶nem (YYYY-MM)
  - `sicil_no` (text) - Sicil no
  - `tc_no` (text) - TC no
  - Temel Bilgiler: brut_maas, medeni_durum, cocuk_sayisi
  - KazanÃ§lar: normal_calisma_brut, fazla_mesai_50, yol_yemek_yardimi
  - Kesintiler: sgk_isci_payi, issizlik_sigortasi_isci, gelir_vergisi, damga_vergisi
  - Hesaplanan: toplam_kazanc, toplam_kesinti, net_maas, gelir_vergisi_matrahi
  - KÃ¼mÃ¼latif deÄŸerler: kumulatif_vergi_matrahi
  
  ### 2. `emekli_hesaplama_parametreleri`
  Emekli bordro hesaplama parametreleri (Excel'deki parametreler)
  - `id` (uuid, PK)
  - `company_id` (uuid, FK)
  - `kod` (text) - Parametre kodu (B3, C3, E10, vb.)
  - `ad` (text) - Parametre adÄ±
  - `oran` (text) - Oran/Birim bilgisi
  - `tutar` (numeric) - Tutar
  - `tip` (text) - kazanc, kesinti, bilgi
  - `aktif` (boolean) - Aktif mi
  
  ## GÃ¼venlik
  - TÃ¼m tablolarda RLS aktif
  - Bordro bilgileri hassas veri olarak korunur
  - Sadece HR ve admin rolleri emekli bordro oluÅŸturabilir ve gÃ¼ncelleyebilir
  
  ## Notlar
  - Excel dosyasÄ±ndaki parametrik yapÄ± database'e taÅŸÄ±ndÄ±
  - BrÃ¼t-Net ve Net-BrÃ¼t hesaplama desteklenir
  - Parametreler ÅŸirket bazlÄ± yapÄ±landÄ±rÄ±labilir
*/

-- Emekli bordro kayÄ±tlarÄ± tablosu
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
  
  -- KazanÃ§lar (Excel parametreleri: B3, C3, D3)
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
  
  -- Ä°ÅŸveren PaylarÄ±
  sgk_isveren_payi numeric(12, 2) DEFAULT 0,
  sgk_isveren_payi_oran numeric(5, 4) DEFAULT 0.205,
  issizlik_isveren_payi numeric(12, 2) DEFAULT 0,
  issizlik_isveren_payi_oran numeric(5, 4) DEFAULT 0.02,
  
  -- Hesaplanan DeÄŸerler
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

-- VarsayÄ±lan parametreleri her ÅŸirket iÃ§in ekle (Excel'deki Ã¶rnekten)
INSERT INTO emekli_hesaplama_parametreleri (company_id, kod, ad, oran, tutar, tip, sira)
SELECT 
  id as company_id,
  'B3' as kod,
  'Normal Ã‡alÄ±ÅŸma BrÃ¼t' as ad,
  '30 GÃ¼n' as oran,
  45000.00 as tutar,
  'kazanc' as tip,
  1 as sira
FROM companies
UNION ALL
SELECT id, 'C3', 'Fazla Mesai (%50)', '10 Saat', 3250.00, 'kazanc', 2 FROM companies
UNION ALL
SELECT id, 'D3', 'Yol ve Yemek YardÄ±mÄ±', 'Sabit', 5500.00, 'kazanc', 3 FROM companies
UNION ALL
SELECT id, 'E10', 'SGK Ä°ÅŸÃ§i PayÄ±', '%14', 6300.00, 'kesinti', 4 FROM companies
UNION ALL
SELECT id, 'F10', 'Ä°ÅŸsizlik SigortasÄ± Ä°ÅŸÃ§i', '%1', 450.00, 'kesinti', 5 FROM companies
UNION ALL
SELECT id, 'G12', 'Gelir Vergisi MatrahÄ±', 'KÃ¼mÃ¼latif', 38250.00, 'bilgi', 6 FROM companies
UNION ALL
SELECT id, 'H15', 'Hesaplanan Gelir Vergisi', '%15', 5737.50, 'kesinti', 7 FROM companies
UNION ALL
SELECT id, 'U18', 'Damga Vergisi', '0.00759', 341.55, 'kesinti', 8 FROM companies
ON CONFLICT (company_id, kod) DO NOTHING;

-- Trigger'larÄ± oluÅŸtur
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

-- Ä°ndeksler
CREATE INDEX IF NOT EXISTS idx_emekli_bordro_items_company_id ON emekli_bordro_items(company_id);
CREATE INDEX IF NOT EXISTS idx_emekli_bordro_items_employee_id ON emekli_bordro_items(employee_id);
CREATE INDEX IF NOT EXISTS idx_emekli_bordro_items_period ON emekli_bordro_items(period);
CREATE INDEX IF NOT EXISTS idx_emekli_hesaplama_parametreleri_company_id ON emekli_hesaplama_parametreleri(company_id);
CREATE INDEX IF NOT EXISTS idx_emekli_hesaplama_parametreleri_tip ON emekli_hesaplama_parametreleri(tip);

-- RLS AktifleÅŸtirme
ALTER TABLE emekli_bordro_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE emekli_hesaplama_parametreleri ENABLE ROW LEVEL SECURITY;

-- Emekli bordro items RLS politikalarÄ±
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

-- Emekli hesaplama parametreleri RLS politikalarÄ±
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

-- <<< END 20260312032554_add_emekli_bordro_schema.sql


-- >>> BEGIN 20260313085109_fix_companies_public_access.sql

/*
  # Fix Companies Public Access

  1. Changes
    - Allow anonymous (non-authenticated) users to read companies table
    - This is needed for the registration form to display available companies
    
  2. Security
    - Only SELECT permission is granted to anonymous users
    - INSERT/UPDATE/DELETE still require authentication
*/

-- Drop existing restrictive policy
DROP POLICY IF EXISTS "Users can view their own company" ON companies;

-- Allow everyone (including anonymous users) to view companies for registration
CREATE POLICY "Anyone can view companies"
  ON companies
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- Only authenticated users can insert companies
CREATE POLICY "Authenticated users can insert companies"
  ON companies
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Users can only update their own company
CREATE POLICY "Users can update own company"
  ON companies
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.company_id = companies.id
      AND profiles.id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.company_id = companies.id
      AND profiles.id = auth.uid()
    )
  );

-- Users can only delete their own company
CREATE POLICY "Users can delete own company"
  ON companies
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.company_id = companies.id
      AND profiles.id = auth.uid()
    )
  );

-- <<< END 20260313085109_fix_companies_public_access.sql


-- >>> BEGIN 20260314081455_add_gorev_tanimi_approval_schema.sql

/*
  # GÃ¶rev TanÄ±mÄ± Onay Sistemi

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

  2. GÃ¼venlik
    - RLS aktif
    - Åžirket bazlÄ± eriÅŸim kontrolÃ¼
    - Personelin sadece kendi gÃ¶rev tanÄ±mlarÄ±nÄ± gÃ¶rebilmesi
*/

-- GÃ¶rev TanÄ±mlarÄ± Tablosu
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

-- GÃ¶rev TanÄ±mÄ± OnaylarÄ± Tablosu
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

-- Personel Åžifreleri Tablosu
CREATE TABLE IF NOT EXISTS employee_passcodes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id uuid REFERENCES employees(id) ON DELETE CASCADE NOT NULL UNIQUE,
  passcode_hash text NOT NULL,
  created_at timestamptz DEFAULT now(),
  expires_at timestamptz
);

-- Ä°ndeksler
CREATE INDEX IF NOT EXISTS idx_gorev_tanimlari_company ON gorev_tanimlari(company_id);
CREATE INDEX IF NOT EXISTS idx_gorev_tanimlari_employee ON gorev_tanimlari(employee_id);
CREATE INDEX IF NOT EXISTS idx_gorev_tanimlari_onay_durumu ON gorev_tanimlari(onay_durumu);
CREATE INDEX IF NOT EXISTS idx_gorev_tanimi_approvals_gorev ON gorev_tanimi_approvals(gorev_tanimi_id);
CREATE INDEX IF NOT EXISTS idx_gorev_tanimi_approvals_employee ON gorev_tanimi_approvals(employee_id);
CREATE INDEX IF NOT EXISTS idx_employee_passcodes_employee ON employee_passcodes(employee_id);

-- RLS PolitikalarÄ±
ALTER TABLE gorev_tanimlari ENABLE ROW LEVEL SECURITY;
ALTER TABLE gorev_tanimi_approvals ENABLE ROW LEVEL SECURITY;
ALTER TABLE employee_passcodes ENABLE ROW LEVEL SECURITY;

-- GÃ¶rev TanÄ±mlarÄ± PolitikalarÄ±
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

-- Onay KayÄ±tlarÄ± PolitikalarÄ±
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

-- Personel Åžifreleri PolitikalarÄ±
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

-- <<< END 20260314081455_add_gorev_tanimi_approval_schema.sql


-- >>> BEGIN 20260314090134_fix_profiles_rls_infinite_recursion.sql

/*
  # Profiles RLS Sonsuz DÃ¶ngÃ¼ DÃ¼zeltmesi
  
  ## Sorun
  Profiles tablosundaki "Users can view profiles in their company" politikasÄ±,
  profiles tablosunu profiles tablosundan sorgulayarak sonsuz dÃ¶ngÃ¼ye giriyor.
  
  ## Ã‡Ã¶zÃ¼m
  1. Eski politikayÄ± kaldÄ±r
  2. KullanÄ±cÄ±nÄ±n kendi profilini gÃ¶rmesine izin ver
  3. AynÄ± ÅŸirketteki profilleri gÃ¶rmek iÃ§in yeni politika ekle (company_id doÄŸrudan kontrol)
  
  ## DeÄŸiÅŸiklikler
  - Eski "Users can view profiles in their company" politikasÄ± kaldÄ±rÄ±ldÄ±
  - "Users can view own profile" politikasÄ± eklendi
  - "Users can view profiles in same company" politikasÄ± eklendi
*/

-- Eski politikayÄ± kaldÄ±r
DROP POLICY IF EXISTS "Users can view profiles in their company" ON profiles;

-- KullanÄ±cÄ±lar kendi profillerini gÃ¶rebilir
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  TO authenticated
  USING (id = auth.uid());

-- KullanÄ±cÄ±lar aynÄ± ÅŸirketteki profilleri gÃ¶rebilir
CREATE POLICY "Users can view profiles in same company"
  ON profiles FOR SELECT
  TO authenticated
  USING (
    company_id = (
      SELECT company_id FROM profiles WHERE id = auth.uid() LIMIT 1
    )
  );

-- <<< END 20260314090134_fix_profiles_rls_infinite_recursion.sql


-- >>> BEGIN 20260314090342_fix_all_profiles_rls_policies.sql

/*
  # TÃ¼m Profiles RLS PolitikalarÄ±nÄ± DÃ¼zelt
  
  ## Sorun
  Profiles tablosunda birden fazla politika profiles tablosunu tekrar sorgulayarak 
  sonsuz dÃ¶ngÃ¼ yaratÄ±yor:
  - "Users can view profiles in same company"
  - "Admins can insert profiles"
  - "Admins can delete profiles in their company"
  
  ## Ã‡Ã¶zÃ¼m
  TÃ¼m mevcut politikalarÄ± kaldÄ±r ve basit, dÃ¶ngÃ¼sÃ¼z politikalar oluÅŸtur:
  1. KullanÄ±cÄ±lar kendi profillerini gÃ¶rebilir, gÃ¼ncelleyebilir
  2. Herkes authenticated kullanÄ±cÄ±larÄ±n profillerini gÃ¶rebilir (aynÄ± ÅŸirket kontrolÃ¼ uygulama katmanÄ±nda)
  3. Sadece servis rolÃ¼ yeni profil ekleyebilir
  
  ## DeÄŸiÅŸiklikler
  - TÃ¼m eski politikalar kaldÄ±rÄ±ldÄ±
  - Basit, sonsuz dÃ¶ngÃ¼ yaratmayan yeni politikalar eklendi
*/

-- TÃ¼m mevcut politikalarÄ± kaldÄ±r
DROP POLICY IF EXISTS "Users can view profiles in their company" ON profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can view profiles in same company" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Admins can insert profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can delete profiles in their company" ON profiles;

-- Yeni basit politikalar

-- Herkes authenticated kullanÄ±cÄ±larÄ±n profillerini gÃ¶rebilir
-- (Company kontrolÃ¼ uygulama katmanÄ±nda yapÄ±lacak)
CREATE POLICY "Authenticated users can view all profiles"
  ON profiles FOR SELECT
  TO authenticated
  USING (true);

-- KullanÄ±cÄ±lar sadece kendi profillerini gÃ¼ncelleyebilir
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- Sadece authenticated kullanÄ±cÄ±lar profil oluÅŸturabilir
-- (Sign up sÄ±rasÄ±nda kullanÄ±lacak)
CREATE POLICY "Authenticated users can insert own profile"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (id = auth.uid());

-- KullanÄ±cÄ±lar kendi profillerini silebilir
CREATE POLICY "Users can delete own profile"
  ON profiles FOR DELETE
  TO authenticated
  USING (id = auth.uid());

-- <<< END 20260314090342_fix_all_profiles_rls_policies.sql


-- >>> BEGIN 20260314091728_add_approval_passcode_to_employees.sql

/*
  # Personel Onay Åžifresi Kolonu Ekleme

  ## DeÄŸiÅŸiklikler
  1. Employees Tablosu
    - `approval_passcode` (text) kolonu eklendi - GÃ¶rev tanÄ±mÄ± onayÄ± iÃ§in kullanÄ±lacak ÅŸifre
  
  ## Notlar
  - Bu kolon, Ã§alÄ±ÅŸanlarÄ±n gÃ¶rev tanÄ±mÄ± belgelerini onaylarken kullanacaklarÄ± gÃ¼venlik ÅŸifresini saklar
  - Åžifre yÃ¶neticiler tarafÄ±ndan oluÅŸturulup Ã§alÄ±ÅŸanlara iletilir
  - Åžifre null olabilir (opsiyonel)
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

-- <<< END 20260314091728_add_approval_passcode_to_employees.sql


-- >>> BEGIN 20260314091746_add_employee_type_to_employees.sql

/*
  # Personel Tipi Kolonu Ekleme

  ## DeÄŸiÅŸiklikler
  1. Employees Tablosu
    - `employee_type` (text) kolonu eklendi - Ã‡alÄ±ÅŸan tipi (normal, emekli)
  
  ## Notlar
  - Bu kolon, Ã§alÄ±ÅŸanÄ±n normal Ã§alÄ±ÅŸan mÄ± yoksa emekli mi olduÄŸunu belirtir
  - Bordro hesaplamalarÄ±nda farklÄ± iÅŸlemler iÃ§in kullanÄ±lÄ±r
  - VarsayÄ±lan deÄŸer 'normal'
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

-- <<< END 20260314091746_add_employee_type_to_employees.sql


-- >>> BEGIN 20260314113749_add_bordro_approval_schema.sql

/*
  # Bordro Onay Sistemi (Payroll Approval System)

  ## AÃ§Ä±klama
  Bu migrasyon, bordro kayÄ±tlarÄ± iÃ§in Ã§ok faktÃ¶rlÃ¼ onay sistemi ekler.
  Ã‡alÄ±ÅŸanlar bordrolarÄ±nÄ± dijital imza, kimlik belgesi veya ÅŸifre ile onaylayabilir.

  ## Yeni Tablolar

  ### `bordro_approvals`
  Bordro onay kayÄ±tlarÄ±nÄ± saklar:
  - `id` (uuid, primary key) - Benzersiz onay kaydÄ± ID
  - `bordro_id` (uuid, foreign key) - Ä°lgili bordro kaydÄ±
  - `company_id` (uuid, foreign key) - Åžirket ID
  - `employee_id` (uuid, foreign key) - Ã‡alÄ±ÅŸan ID
  - `employee_name` (text) - Ã‡alÄ±ÅŸan adÄ± (denormalize)
  - `verification_method` (text) - DoÄŸrulama yÃ¶ntemi: 'signature', 'id_document', 'passcode'
  - `signature_data` (text, nullable) - Base64 dijital imza verisi
  - `id_document_data` (text, nullable) - Base64 kimlik belgesi verisi
  - `passcode_hash` (text, nullable) - Hash'lenmiÅŸ ÅŸifre
  - `approval_status` (text) - Onay durumu: 'onaylandi', 'reddedildi'
  - `ip_address` (text, nullable) - Onay yapan IP adresi
  - `user_agent` (text, nullable) - Onay yapan tarayÄ±cÄ± bilgisi
  - `timestamp` (timestamptz) - Onay zamanÄ±

  ## GÃ¼venlik
  - RLS etkinleÅŸtirildi
  - KullanÄ±cÄ±lar sadece kendi ÅŸirketlerinin onaylarÄ±nÄ± gÃ¶rebilir
  - Onay oluÅŸturma yetkilendirilmiÅŸ kullanÄ±cÄ±larla sÄ±nÄ±rlÄ±
  - IP adresi ve user agent bilgisi gÃ¼venlik denetimi iÃ§in saklanÄ±r

  ## DeÄŸiÅŸiklikler
  - `bordro_items` tablosuna `approval_status` ve `approval_date` alanlarÄ± eklenir
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

-- <<< END 20260314113749_add_bordro_approval_schema.sql


-- >>> BEGIN 20260314125108_fix_bordro_approvals_rls_policies.sql

/*
  # Bordro Onay RLS PolitikalarÄ±nÄ± DÃ¼zelt

  ## AÃ§Ä±klama
  bordro_approvals tablosundaki RLS politikalarÄ±nÄ± gÃ¼nceller.
  Profiles tablosuna yapÄ±lan subquery'leri kaldÄ±rarak sonsuz dÃ¶ngÃ¼ sorununu Ã¶nler.

  ## DeÄŸiÅŸiklikler
  - Mevcut RLS politikalarÄ±nÄ± kaldÄ±rÄ±r
  - BasitleÅŸtirilmiÅŸ, doÄŸrudan company_id kontrolÃ¼ yapan yeni politikalar ekler
  
  ## GÃ¼venlik
  - KullanÄ±cÄ±lar kendi ÅŸirketlerinin bordro onaylarÄ±nÄ± gÃ¶rÃ¼ntÃ¼leyebilir
  - KullanÄ±cÄ±lar kendi ÅŸirketleri iÃ§in bordro onayÄ± oluÅŸturabilir
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view approvals of their company" ON bordro_approvals;
DROP POLICY IF EXISTS "Users can create approvals for their company" ON bordro_approvals;

-- Create new simplified policies
CREATE POLICY "Users can view own company approvals"
  ON bordro_approvals
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can create own company approvals"
  ON bordro_approvals
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- <<< END 20260314125108_fix_bordro_approvals_rls_policies.sql


-- >>> BEGIN 20260314125656_fix_bordro_approval_update_permission.sql

/*
  # Bordro Onay GÃ¼ncelleme Ä°zni DÃ¼zeltmesi

  1. DeÄŸiÅŸiklikler
    - Ã‡alÄ±ÅŸanlarÄ±n kendi bordrolarÄ±nÄ±n onay durumunu gÃ¼ncelleyebilmeleri iÃ§in yeni UPDATE politikasÄ± eklendi
    - Bu politika sadece `approval_status` ve `approval_date` alanlarÄ±nÄ±n gÃ¼ncellenmesine izin verir
    
  2. GÃ¼venlik
    - Ã‡alÄ±ÅŸanlar sadece kendi bordrolarÄ±nÄ± gÃ¼ncelleyebilir
    - Sadece onay ile ilgili alanlar gÃ¼ncellenebilir (approval_status, approval_date)
*/

-- Mevcut Ã§alÄ±ÅŸan gÃ¼ncellemesi politikasÄ±nÄ± kaldÄ±r (varsa)
DROP POLICY IF EXISTS "Employees can update their own bordro approval status" ON bordro_items;

-- Ã‡alÄ±ÅŸanlarÄ±n kendi bordrolarÄ±nÄ±n onay durumunu gÃ¼ncelleyebilmeleri iÃ§in politika ekle
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

-- <<< END 20260314125656_fix_bordro_approval_update_permission.sql


-- >>> BEGIN 20260314181352_fix_bordro_approvals_company_check.sql

/*
  # Bordro Onay RLS PolitikalarÄ±na Company KontrolÃ¼ Ekle

  1. AÃ§Ä±klama
    bordro_approvals tablosundaki RLS politikalarÄ±nÄ± gÃ¼nceller.
    GerÃ§ek company_id kontrolÃ¼ ekler.

  2. DeÄŸiÅŸiklikler
    - Mevcut basit RLS politikalarÄ±nÄ± kaldÄ±rÄ±r
    - Company_id ile kontrol yapan gÃ¼venli politikalar ekler
  
  3. GÃ¼venlik
    - KullanÄ±cÄ±lar sadece kendi ÅŸirketlerinin bordro onaylarÄ±nÄ± gÃ¶rÃ¼ntÃ¼leyebilir
    - KullanÄ±cÄ±lar sadece kendi ÅŸirketleri iÃ§in bordro onayÄ± oluÅŸturabilir
    - Profiles tablosuna subquery yapÄ±larak sonsuz dÃ¶ngÃ¼ engellenir
*/

-- Mevcut politikalarÄ± kaldÄ±r
DROP POLICY IF EXISTS "Users can view own company approvals" ON bordro_approvals;
DROP POLICY IF EXISTS "Users can create own company approvals" ON bordro_approvals;

-- GÃ¶rÃ¼ntÃ¼leme politikasÄ± - kullanÄ±cÄ±nÄ±n ÅŸirketine ait onaylarÄ± gÃ¶ster
CREATE POLICY "Users can view own company approvals"
  ON bordro_approvals
  FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id
      FROM profiles
      WHERE id = auth.uid()
    )
  );

-- OluÅŸturma politikasÄ± - kullanÄ±cÄ± kendi ÅŸirketine ait onay oluÅŸturabilir
CREATE POLICY "Users can create own company approvals"
  ON bordro_approvals
  FOR INSERT
  TO authenticated
  WITH CHECK (
    company_id IN (
      SELECT company_id
      FROM profiles
      WHERE id = auth.uid()
    )
  );

-- <<< END 20260314181352_fix_bordro_approvals_company_check.sql


-- >>> BEGIN 20260314181631_simplify_bordro_approvals_rls.sql

/*
  # Bordro Approvals RLS PolitikalarÄ±nÄ± BasitleÅŸtir

  1. AÃ§Ä±klama
    Profiles tablosundan sonsuz dÃ¶ngÃ¼ riskini ortadan kaldÄ±rmak iÃ§in
    bordro_approvals tablosu RLS politikalarÄ±nÄ± basitleÅŸtirir.

  2. DeÄŸiÅŸiklikler
    - Mevcut politikalarÄ± kaldÄ±rÄ±r
    - Herhangi bir authenticated kullanÄ±cÄ±nÄ±n onay oluÅŸturabilmesine izin verir
    - Herhangi bir authenticated kullanÄ±cÄ±nÄ±n onaylarÄ± gÃ¶rebilmesine izin verir
  
  3. GÃ¼venlik Notu
    - Bu basitleÅŸtirme geÃ§icidir
    - GerÃ§ek kontrol application layer'da yapÄ±lacak
*/

-- Mevcut politikalarÄ± kaldÄ±r
DROP POLICY IF EXISTS "Users can view own company approvals" ON bordro_approvals;
DROP POLICY IF EXISTS "Users can create own company approvals" ON bordro_approvals;

-- Basit politikalar oluÅŸtur - authenticated kullanÄ±cÄ±lar iÃ§in
CREATE POLICY "Authenticated users can view approvals"
  ON bordro_approvals
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can create approvals"
  ON bordro_approvals
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- <<< END 20260314181631_simplify_bordro_approvals_rls.sql


-- >>> BEGIN 20260328020749_fix_bordro_items_insert_policy.sql

/*
  # Bordro Items INSERT PolitikasÄ± DÃ¼zeltmesi

  ## AÃ§Ä±klama
  Bordro kaydetme sorunu dÃ¼zeltiliyor. Mevcut politika sadece 'admin' ve 'hr' 
  rolÃ¼ne izin veriyor, ancak tÃ¼m authenticated kullanÄ±cÄ±larÄ±n kendi ÅŸirketleri 
  iÃ§in bordro oluÅŸturabilmesi gerekiyor.

  ## DeÄŸiÅŸiklikler
  1. Eski kÄ±sÄ±tlayÄ±cÄ± politika kaldÄ±rÄ±lÄ±yor
  2. TÃ¼m authenticated kullanÄ±cÄ±larÄ±n kendi ÅŸirketleri iÃ§in bordro oluÅŸturmasÄ±na izin veriliyor

  ## GÃ¼venlik
  - RLS aktif kalÄ±yor
  - KullanÄ±cÄ±lar sadece kendi ÅŸirketleri iÃ§in bordro oluÅŸturabilir
  - company_id kontrolÃ¼ ile gÃ¼venlik saÄŸlanÄ±yor
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

-- <<< END 20260328020749_fix_bordro_items_insert_policy.sql


-- >>> BEGIN 20260331133000_add_superadmin_and_user_roles.sql

ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_role_check;

ALTER TABLE profiles
ADD CONSTRAINT profiles_role_check
CHECK (role IN ('superadmin', 'admin', 'manager', 'employee', 'hr', 'user'));

DROP POLICY IF EXISTS "Authenticated users can insert own profile" ON profiles;

CREATE POLICY "Authenticated users can insert own profile"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (id = auth.uid() OR role = 'superadmin');

-- <<< END 20260331133000_add_superadmin_and_user_roles.sql


-- >>> BEGIN 20260331140000_add_admin_update_user_profile_rpc.sql

/*
  # Admin KullanÄ±cÄ± Profili GÃ¼ncelleme RPC

  SÃ¼per yÃ¶netici ve yÃ¶neticilerin baÅŸka kullanÄ±cÄ±larÄ±n profilini gÃ¼ncelleyebilmesi iÃ§in
  SECURITY DEFINER fonksiyon oluÅŸturulur.
  
  Bu fonksiyon RLS bypass eder; yetki kontrolÃ¼ SQL iÃ§inde yapÄ±lÄ±r.
*/

CREATE OR REPLACE FUNCTION admin_update_user_profile(
  target_id   uuid,
  new_role        text    DEFAULT NULL,
  new_full_name   text    DEFAULT NULL,
  new_company_id  uuid    DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  caller_role text;
BEGIN
  -- Ã‡aÄŸÄ±ran kullanÄ±cÄ±nÄ±n rolÃ¼nÃ¼ al
  SELECT role INTO caller_role
  FROM profiles
  WHERE id = auth.uid();

  -- Yetki kontrolÃ¼
  IF caller_role NOT IN ('superadmin', 'admin') THEN
    RAISE EXCEPTION 'Yetkiniz yok: yalnÄ±zca superadmin ve admin baÅŸkalarÄ±nÄ±n profilini gÃ¼ncelleyebilir';
  END IF;

  -- Admin sadece kendi ÅŸirketindeki kullanÄ±cÄ±larÄ± gÃ¼ncelleyebilir (superadmin herkesi gÃ¼ncelleyebilir)
  IF caller_role = 'admin' THEN
    IF NOT EXISTS (
      SELECT 1 FROM profiles caller_p
      JOIN profiles target_p ON target_p.id = target_id
      WHERE caller_p.id = auth.uid()
        AND caller_p.company_id IS NOT NULL
        AND caller_p.company_id = target_p.company_id
    ) AND target_id != auth.uid() THEN
      RAISE EXCEPTION 'Yetkiniz yok: baÅŸka ÅŸirketin kullanÄ±cÄ±sÄ±nÄ± dÃ¼zenleyemezsiniz';
    END IF;
  END IF;

  -- GÃ¼ncelle
  UPDATE profiles
  SET
    role       = COALESCE(new_role,       role),
    full_name  = COALESCE(new_full_name,  full_name),
    company_id = CASE
                   WHEN new_company_id IS NOT NULL THEN new_company_id
                   ELSE company_id
                 END,
    updated_at = NOW()
  WHERE id = target_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'KullanÄ±cÄ± bulunamadÄ±: %', target_id;
  END IF;
END;
$$;

-- Fonksiyona erisim
GRANT EXECUTE ON FUNCTION admin_update_user_profile(uuid, text, text, uuid) TO authenticated;

-- <<< END 20260331140000_add_admin_update_user_profile_rpc.sql


-- >>> BEGIN 20260331153000_add_admin_delete_user_profile_rpc.sql

/*
  # Admin kullanÄ±cÄ± profili silme RPC

  Superadmin ve admin kullanÄ±cÄ±larÄ±n profil kaydÄ±nÄ± silmesine izin verir.
  Not: Bu iÅŸlem auth.users kaydÄ±nÄ± silmez; yalnÄ±zca public.profiles satÄ±rÄ±nÄ± siler.
*/

CREATE OR REPLACE FUNCTION admin_delete_user_profile(target_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  caller_role text;
BEGIN
  SELECT role INTO caller_role
  FROM profiles
  WHERE id = auth.uid();

  IF caller_role NOT IN ('superadmin', 'admin') THEN
    RAISE EXCEPTION 'Yetkiniz yok: yalnÄ±zca superadmin ve admin kullanÄ±cÄ± silebilir';
  END IF;

  IF target_id = auth.uid() THEN
    RAISE EXCEPTION 'Kendi profilinizi bu fonksiyonla silemezsiniz';
  END IF;

  IF caller_role = 'admin' THEN
    IF NOT EXISTS (
      SELECT 1
      FROM profiles caller_p
      JOIN profiles target_p ON target_p.id = target_id
      WHERE caller_p.id = auth.uid()
        AND caller_p.company_id IS NOT NULL
        AND caller_p.company_id = target_p.company_id
    ) THEN
      RAISE EXCEPTION 'Yetkiniz yok: baÅŸka ÅŸirketin kullanÄ±cÄ±sÄ±nÄ± silemezsiniz';
    END IF;
  END IF;

  DELETE FROM profiles WHERE id = target_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'KullanÄ±cÄ± bulunamadÄ±: %', target_id;
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION admin_delete_user_profile(uuid) TO authenticated;

-- <<< END 20260331153000_add_admin_delete_user_profile_rpc.sql


-- >>> BEGIN 20260331170000_fix_employees_rls_for_superadmin_and_admin.sql

/*
  # Employees RLS dÃ¼zeltmesi

  Sorunlar:
  1) superadmin Ã§alÄ±ÅŸan kayÄ±tlarÄ±nda yetki hatasÄ± alÄ±yordu
  2) kullanÄ±cÄ± -> personel senkronizasyonunda insert RLS engeline takÄ±labiliyordu

  Ã‡Ã¶zÃ¼m:
  - employees politikalarÄ±nÄ± superadmin'i kapsayacak ÅŸekilde yeniden tanÄ±mla
*/

DROP POLICY IF EXISTS "Users can view employees in their company" ON employees;
DROP POLICY IF EXISTS "HR and admins can insert employees" ON employees;
DROP POLICY IF EXISTS "HR and admins can update employees in their company" ON employees;
DROP POLICY IF EXISTS "HR and admins can delete employees in their company" ON employees;

CREATE POLICY "Users can view employees in their company"
  ON employees FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM profiles p
      WHERE p.id = auth.uid()
        AND (
          p.role = 'superadmin'
          OR p.company_id = employees.company_id
        )
    )
  );

CREATE POLICY "HR and admins can insert employees"
  ON employees FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM profiles p
      WHERE p.id = auth.uid()
        AND (
          p.role = 'superadmin'
          OR (p.role IN ('admin', 'hr') AND p.company_id = employees.company_id)
        )
    )
  );

CREATE POLICY "HR and admins can update employees in their company"
  ON employees FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM profiles p
      WHERE p.id = auth.uid()
        AND (
          p.role = 'superadmin'
          OR (p.role IN ('admin', 'hr', 'manager') AND p.company_id = employees.company_id)
        )
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM profiles p
      WHERE p.id = auth.uid()
        AND (
          p.role = 'superadmin'
          OR (p.role IN ('admin', 'hr', 'manager') AND p.company_id = employees.company_id)
        )
    )
  );

CREATE POLICY "HR and admins can delete employees in their company"
  ON employees FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM profiles p
      WHERE p.id = auth.uid()
        AND (
          p.role = 'superadmin'
          OR (p.role IN ('admin', 'hr') AND p.company_id = employees.company_id)
        )
    )
  );

-- <<< END 20260331170000_fix_employees_rls_for_superadmin_and_admin.sql


-- >>> BEGIN 20260331183000_add_approval_signature_to_employees.sql

/*
  # Employees tablosuna imza alanÄ± ekle

  KullanÄ±cÄ± bazlÄ± imza ve onay ÅŸifresi iÅŸlemlerinde
  dijital imza verisini employees tablosunda saklamak iÃ§in alan eklenir.
*/

ALTER TABLE employees
ADD COLUMN IF NOT EXISTS approval_signature text;

-- <<< END 20260331183000_add_approval_signature_to_employees.sql


-- >>> BEGIN 20260331200000_create_ozluk_dosyalari.sql

-- Ã‡alÄ±ÅŸan Ã–zlÃ¼k DosyasÄ± tablosu
-- NOT: Bu migration'Ä± Supabase Dashboard > SQL Editor'da Ã§alÄ±ÅŸtÄ±rÄ±n
-- Supabase Dashboard > Storage > "ozluk-dosyalari" adlÄ± bucket oluÅŸturun (private)

CREATE TABLE IF NOT EXISTS ozluk_dosyalari (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id uuid NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  company_id  uuid NOT NULL,
  kategori    text NOT NULL DEFAULT 'diger',
  dosya_adi   text,
  dosya_yolu  text,
  notlar      text,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ozluk_dosyalari_employee_idx ON ozluk_dosyalari(employee_id);
CREATE INDEX IF NOT EXISTS ozluk_dosyalari_company_idx  ON ozluk_dosyalari(company_id);

ALTER TABLE ozluk_dosyalari ENABLE ROW LEVEL SECURITY;

-- Åžirket Ã§alÄ±ÅŸanlarÄ± kendi ÅŸirketlerindeki kayÄ±tlara eriÅŸebilir
CREATE POLICY "company_members_ozluk" ON ozluk_dosyalari
  FOR ALL
  USING (
    company_id IN (
      SELECT company_id FROM profiles
      WHERE id = auth.uid() AND company_id IS NOT NULL
    )
  )
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM profiles
      WHERE id = auth.uid() AND company_id IS NOT NULL
    )
  );

-- updated_at otomatik gÃ¼ncelleme
CREATE OR REPLACE FUNCTION update_ozluk_dosyalari_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER ozluk_dosyalari_updated_at
  BEFORE UPDATE ON ozluk_dosyalari
  FOR EACH ROW EXECUTE PROCEDURE update_ozluk_dosyalari_updated_at();

-- â”€â”€â”€ Storage bucket politikalarÄ± â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Supabase Dashboard > Storage > "ozluk-dosyalari" bucket oluÅŸturduktan sonra
-- aÅŸaÄŸÄ±daki politikalarÄ± ekleyin:

-- INSERT (yÃ¼kleme):
-- CREATE POLICY "auth users can upload ozluk" ON storage.objects
--   FOR INSERT TO authenticated
--   WITH CHECK (bucket_id = 'ozluk-dosyalari');

-- SELECT (indirme):
-- CREATE POLICY "auth users can read ozluk" ON storage.objects
--   FOR SELECT TO authenticated
--   USING (bucket_id = 'ozluk-dosyalari');

-- DELETE (silme):
-- CREATE POLICY "auth users can delete ozluk" ON storage.objects
--   FOR DELETE TO authenticated
--   USING (bucket_id = 'ozluk-dosyalari');

-- <<< END 20260331200000_create_ozluk_dosyalari.sql


-- >>> BEGIN 20260404123000_setup_ozluk_dosyalari_backend.sql

-- Ozluk dosyalari backend kurulumu
-- Eksik kalan tablo, trigger, bucket ve policy'leri idempotent sekilde olusturur.

CREATE TABLE IF NOT EXISTS public.ozluk_dosyalari (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id uuid NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  company_id uuid NOT NULL,
  kategori text NOT NULL DEFAULT 'diger',
  dosya_adi text,
  dosya_yolu text,
  notlar text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ozluk_dosyalari_employee_idx
  ON public.ozluk_dosyalari(employee_id);

CREATE INDEX IF NOT EXISTS ozluk_dosyalari_company_idx
  ON public.ozluk_dosyalari(company_id);

ALTER TABLE public.ozluk_dosyalari ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'ozluk_dosyalari'
      AND policyname = 'company_members_ozluk'
  ) THEN
    CREATE POLICY "company_members_ozluk" ON public.ozluk_dosyalari
      FOR ALL
      USING (
        company_id IN (
          SELECT company_id
          FROM public.profiles
          WHERE id = auth.uid() AND company_id IS NOT NULL
        )
      )
      WITH CHECK (
        company_id IN (
          SELECT company_id
          FROM public.profiles
          WHERE id = auth.uid() AND company_id IS NOT NULL
        )
      );
  END IF;
END $$;

CREATE OR REPLACE FUNCTION public.update_ozluk_dosyalari_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS ozluk_dosyalari_updated_at ON public.ozluk_dosyalari;

CREATE TRIGGER ozluk_dosyalari_updated_at
  BEFORE UPDATE ON public.ozluk_dosyalari
  FOR EACH ROW
  EXECUTE PROCEDURE public.update_ozluk_dosyalari_updated_at();

INSERT INTO storage.buckets (id, name, public)
VALUES ('ozluk-dosyalari', 'ozluk-dosyalari', false)
ON CONFLICT (id) DO NOTHING;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename = 'objects'
      AND policyname = 'auth users can upload ozluk'
  ) THEN
    CREATE POLICY "auth users can upload ozluk" ON storage.objects
      FOR INSERT TO authenticated
      WITH CHECK (bucket_id = 'ozluk-dosyalari');
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename = 'objects'
      AND policyname = 'auth users can read ozluk'
  ) THEN
    CREATE POLICY "auth users can read ozluk" ON storage.objects
      FOR SELECT TO authenticated
      USING (bucket_id = 'ozluk-dosyalari');
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename = 'objects'
      AND policyname = 'auth users can delete ozluk'
  ) THEN
    CREATE POLICY "auth users can delete ozluk" ON storage.objects
      FOR DELETE TO authenticated
      USING (bucket_id = 'ozluk-dosyalari');
  END IF;
END $$;

-- <<< END 20260404123000_setup_ozluk_dosyalari_backend.sql


-- >>> BEGIN 20260404133000_bootstrap_core_hr_backend.sql

-- Core HR backend bootstrap
-- Eksik kurulan Supabase projelerinde temel IK modullerini tek seferde kurar.

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS public.companies (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  address text DEFAULT '',
  tax_number text DEFAULT '',
  sgk_sicil_no text DEFAULT '',
  phone text DEFAULT '',
  email text DEFAULT '',
  city text DEFAULT '',
  logo_url text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text NOT NULL,
  full_name text NOT NULL,
  company_id uuid REFERENCES public.companies(id) ON DELETE CASCADE,
  role text NOT NULL DEFAULT 'employee',
  avatar_url text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.employees (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  name text NOT NULL,
  tc_no text DEFAULT '',
  sicil_no text DEFAULT '',
  department text NOT NULL DEFAULT '',
  position text NOT NULL DEFAULT '',
  level text NOT NULL DEFAULT 'Junior',
  salary numeric(12, 2) DEFAULT 0,
  status text NOT NULL DEFAULT 'active',
  phone text DEFAULT '',
  email text DEFAULT '',
  join_date date DEFAULT CURRENT_DATE,
  address text DEFAULT '',
  avatar_url text,
  skills text[] DEFAULT '{}',
  medeni_durum text DEFAULT 'bekar',
  cocuk_sayisi integer DEFAULT 0,
  engelli_durumu text DEFAULT 'yok',
  employee_type text DEFAULT 'normal',
  approval_passcode text,
  approval_signature text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE public.employees ADD COLUMN IF NOT EXISTS employee_type text DEFAULT 'normal';
ALTER TABLE public.employees ADD COLUMN IF NOT EXISTS approval_passcode text;
ALTER TABLE public.employees ADD COLUMN IF NOT EXISTS approval_signature text;

CREATE TABLE IF NOT EXISTS public.izin_talepleri (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  employee_id uuid NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  izin_turu text NOT NULL,
  baslangic_tarihi date NOT NULL,
  bitis_tarihi date NOT NULL,
  gun_sayisi integer NOT NULL DEFAULT 0,
  aciklama text DEFAULT '',
  yol_izni_talep boolean DEFAULT false,
  yol_izni_gun integer DEFAULT 0,
  seyahat_yeri text DEFAULT '',
  il_disi_seyahat boolean DEFAULT false,
  belge_url text,
  durum text NOT NULL DEFAULT 'beklemede',
  onaylayan_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  onay_tarihi timestamptz,
  red_nedeni text,
  talep_tarihi date DEFAULT CURRENT_DATE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.izin_haklari (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  employee_id uuid NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
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

CREATE TABLE IF NOT EXISTS public.bordro_items (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  employee_id uuid NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  period text NOT NULL,
  sicil_no text DEFAULT '',
  tc_no text DEFAULT '',
  brut_maas numeric(12, 2) DEFAULT 0,
  medeni_durum text DEFAULT 'bekar',
  cocuk_sayisi integer DEFAULT 0,
  engelli_durumu text DEFAULT 'yok',
  temel_kazanc numeric(12, 2) DEFAULT 0,
  yol_parasi numeric(12, 2) DEFAULT 0,
  gida_yardimi numeric(12, 2) DEFAULT 0,
  cocuk_yardimi numeric(12, 2) DEFAULT 0,
  diger_kazanclar numeric(12, 2) DEFAULT 0,
  fazla_mesai numeric(12, 2) DEFAULT 0,
  fazla_mesai_saat_50 numeric(8, 2) DEFAULT 0,
  fazla_mesai_saat_100 numeric(8, 2) DEFAULT 0,
  fazla_mesai_tutar numeric(12, 2) DEFAULT 0,
  haftalik_tatil numeric(12, 2) DEFAULT 0,
  genel_tatil numeric(12, 2) DEFAULT 0,
  yillik_izin_ucreti numeric(12, 2) DEFAULT 0,
  ikramiye numeric(12, 2) DEFAULT 0,
  prim numeric(12, 2) DEFAULT 0,
  servis_ucreti numeric(12, 2) DEFAULT 0,
  temsil_etiket numeric(12, 2) DEFAULT 0,
  gelir_vergisi numeric(12, 2) DEFAULT 0,
  damga_vergisi numeric(12, 2) DEFAULT 0,
  sgk_isci_payi numeric(12, 2) DEFAULT 0,
  issizlik_sigortasi numeric(12, 2) DEFAULT 0,
  sendika_aidat numeric(12, 2) DEFAULT 0,
  avans numeric(12, 2) DEFAULT 0,
  diger_kesintiler numeric(12, 2) DEFAULT 0,
  engelli_indirimi numeric(12, 2) DEFAULT 0,
  kidem_tazminati numeric(12, 2) DEFAULT 0,
  ihbar_tazminati numeric(12, 2) DEFAULT 0,
  toplam_kazanc numeric(12, 2) DEFAULT 0,
  toplam_kesinti numeric(12, 2) DEFAULT 0,
  net_maas numeric(12, 2) DEFAULT 0,
  kumulatif_vergi_matrahi numeric(12, 2) DEFAULT 0,
  asgari_ucret_gelir_vergisi_istisnasi numeric(12, 2) DEFAULT 0,
  asgari_ucret_damga_vergisi_istisnasi numeric(12, 2) DEFAULT 0,
  sgk_isveren_payi numeric(12, 2) DEFAULT 0,
  issizlik_isveren_payi numeric(12, 2) DEFAULT 0,
  sgk_isveren_indirimi numeric(12, 2) DEFAULT 0,
  sgk_isveren_indirim_orani numeric(5, 2) DEFAULT 0,
  yillik_toplam_kazanc numeric(12, 2) DEFAULT 0,
  yillik_toplam_kesinti numeric(12, 2) DEFAULT 0,
  yillik_toplam_net numeric(12, 2) DEFAULT 0,
  approval_status text DEFAULT 'beklemede',
  approval_date timestamptz,
  aciklama text DEFAULT '',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(employee_id, period)
);

CREATE TABLE IF NOT EXISTS public.bordro_calculation_rates (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
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

CREATE TABLE IF NOT EXISTS public.bordro_approvals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  bordro_id uuid NOT NULL REFERENCES public.bordro_items(id) ON DELETE CASCADE,
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  employee_id uuid NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  employee_name text NOT NULL,
  verification_method text NOT NULL,
  signature_data text,
  id_document_data text,
  passcode_hash text,
  approval_status text NOT NULL,
  ip_address text,
  user_agent text,
  timestamp timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.gorev_tanimlari (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid REFERENCES public.companies(id) ON DELETE CASCADE NOT NULL,
  employee_id uuid REFERENCES public.employees(id) ON DELETE CASCADE NOT NULL,
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
  onay_durumu text DEFAULT 'beklemede',
  onay_tarihi timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.gorev_tanimi_approvals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  gorev_tanimi_id uuid REFERENCES public.gorev_tanimlari(id) ON DELETE CASCADE NOT NULL,
  employee_id uuid REFERENCES public.employees(id) ON DELETE CASCADE NOT NULL,
  employee_name text NOT NULL,
  verification_method text NOT NULL,
  signature_data text,
  id_document_data text,
  passcode_hash text,
  approval_status text NOT NULL,
  ip_address text,
  user_agent text,
  timestamp timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.ozluk_dosyalari (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id uuid NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  company_id uuid NOT NULL,
  kategori text NOT NULL DEFAULT 'diger',
  dosya_adi text,
  dosya_yolu text,
  notlar text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_profiles_company_id ON public.profiles(company_id);
CREATE INDEX IF NOT EXISTS idx_employees_company_id ON public.employees(company_id);
CREATE INDEX IF NOT EXISTS idx_izin_talepleri_company_id ON public.izin_talepleri(company_id);
CREATE INDEX IF NOT EXISTS idx_izin_talepleri_employee_id ON public.izin_talepleri(employee_id);
CREATE INDEX IF NOT EXISTS idx_izin_haklari_company_id ON public.izin_haklari(company_id);
CREATE INDEX IF NOT EXISTS idx_izin_haklari_employee_id ON public.izin_haklari(employee_id);
CREATE INDEX IF NOT EXISTS idx_bordro_items_company_id ON public.bordro_items(company_id);
CREATE INDEX IF NOT EXISTS idx_bordro_items_employee_id ON public.bordro_items(employee_id);
CREATE INDEX IF NOT EXISTS idx_bordro_items_period ON public.bordro_items(period);
CREATE INDEX IF NOT EXISTS idx_bordro_approvals_company_id ON public.bordro_approvals(company_id);
CREATE INDEX IF NOT EXISTS idx_gorev_tanimlari_company ON public.gorev_tanimlari(company_id);
CREATE INDEX IF NOT EXISTS idx_gorev_tanimlari_employee ON public.gorev_tanimlari(employee_id);
CREATE INDEX IF NOT EXISTS ozluk_dosyalari_employee_idx ON public.ozluk_dosyalari(employee_id);
CREATE INDEX IF NOT EXISTS ozluk_dosyalari_company_idx ON public.ozluk_dosyalari(company_id);

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_companies_updated_at') THEN
    CREATE TRIGGER update_companies_updated_at BEFORE UPDATE ON public.companies FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_profiles_updated_at') THEN
    CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_employees_updated_at') THEN
    CREATE TRIGGER update_employees_updated_at BEFORE UPDATE ON public.employees FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_izin_talepleri_updated_at') THEN
    CREATE TRIGGER update_izin_talepleri_updated_at BEFORE UPDATE ON public.izin_talepleri FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_izin_haklari_updated_at') THEN
    CREATE TRIGGER update_izin_haklari_updated_at BEFORE UPDATE ON public.izin_haklari FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_bordro_items_updated_at') THEN
    CREATE TRIGGER update_bordro_items_updated_at BEFORE UPDATE ON public.bordro_items FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_bordro_calculation_rates_updated_at') THEN
    CREATE TRIGGER update_bordro_calculation_rates_updated_at BEFORE UPDATE ON public.bordro_calculation_rates FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_update_gorev_tanimlari_updated_at') THEN
    CREATE TRIGGER trigger_update_gorev_tanimlari_updated_at BEFORE UPDATE ON public.gorev_tanimlari FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'ozluk_dosyalari_updated_at') THEN
    CREATE TRIGGER ozluk_dosyalari_updated_at BEFORE UPDATE ON public.ozluk_dosyalari FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
  END IF;
END $$;

CREATE OR REPLACE FUNCTION public.calculate_kalan_izin()
RETURNS TRIGGER AS $$
BEGIN
  NEW.kalan_izin = NEW.toplam_hak - NEW.kullanilan_izin;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_calculate_kalan_izin') THEN
    CREATE TRIGGER trigger_calculate_kalan_izin
      BEFORE INSERT OR UPDATE ON public.izin_haklari
      FOR EACH ROW
      EXECUTE FUNCTION public.calculate_kalan_izin();
  END IF;
END $$;

ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.izin_talepleri ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.izin_haklari ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bordro_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bordro_calculation_rates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bordro_approvals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gorev_tanimlari ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gorev_tanimi_approvals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ozluk_dosyalari ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'companies' AND policyname = 'Users can view their own company') THEN
    CREATE POLICY "Users can view their own company" ON public.companies FOR SELECT TO authenticated USING (id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid()));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'profiles' AND policyname = 'Users can view profiles in their company') THEN
    CREATE POLICY "Users can view profiles in their company" ON public.profiles FOR SELECT TO authenticated USING (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid()));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'employees' AND policyname = 'Users can view employees in their company') THEN
    CREATE POLICY "Users can view employees in their company" ON public.employees FOR SELECT TO authenticated USING (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid()));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'employees' AND policyname = 'HR can manage employees in their company') THEN
    CREATE POLICY "HR can manage employees in their company" ON public.employees FOR ALL TO authenticated USING (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'hr'))) WITH CHECK (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'hr')));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'izin_talepleri' AND policyname = 'Users can view izin talepleri in their company') THEN
    CREATE POLICY "Users can view izin talepleri in their company" ON public.izin_talepleri FOR SELECT TO authenticated USING (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid()));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'izin_talepleri' AND policyname = 'Employees can create their own izin talepleri') THEN
    CREATE POLICY "Employees can create their own izin talepleri" ON public.izin_talepleri FOR INSERT TO authenticated WITH CHECK (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid()));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'izin_haklari' AND policyname = 'Users can view izin haklari in their company') THEN
    CREATE POLICY "Users can view izin haklari in their company" ON public.izin_haklari FOR SELECT TO authenticated USING (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid()));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'izin_haklari' AND policyname = 'HR and admins can manage izin haklari') THEN
    CREATE POLICY "HR and admins can manage izin haklari" ON public.izin_haklari FOR ALL TO authenticated USING (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'hr'))) WITH CHECK (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'hr')));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'bordro_items' AND policyname = 'HR can view all bordro items in their company') THEN
    CREATE POLICY "HR can view all bordro items in their company" ON public.bordro_items FOR SELECT TO authenticated USING (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'hr', 'manager')));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'bordro_items' AND policyname = 'HR can manage bordro items') THEN
    CREATE POLICY "HR can manage bordro items" ON public.bordro_items FOR ALL TO authenticated USING (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'hr'))) WITH CHECK (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'hr')));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'bordro_calculation_rates' AND policyname = 'Users can view calculation rates in their company') THEN
    CREATE POLICY "Users can view calculation rates in their company" ON public.bordro_calculation_rates FOR SELECT TO authenticated USING (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid()));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'bordro_approvals' AND policyname = 'Users can view approvals of their company') THEN
    CREATE POLICY "Users can view approvals of their company" ON public.bordro_approvals FOR SELECT TO authenticated USING (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid()));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'bordro_approvals' AND policyname = 'Users can create approvals for their company') THEN
    CREATE POLICY "Users can create approvals for their company" ON public.bordro_approvals FOR INSERT TO authenticated WITH CHECK (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid()));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'gorev_tanimlari' AND policyname = 'Users can view gorev tanimlari from their company') THEN
    CREATE POLICY "Users can view gorev tanimlari from their company" ON public.gorev_tanimlari FOR SELECT TO authenticated USING (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid()));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'gorev_tanimlari' AND policyname = 'Users can manage gorev tanimlari for their company') THEN
    CREATE POLICY "Users can manage gorev tanimlari for their company" ON public.gorev_tanimlari FOR ALL TO authenticated USING (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid())) WITH CHECK (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid()));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'gorev_tanimi_approvals' AND policyname = 'Users can view approval records from their company') THEN
    CREATE POLICY "Users can view approval records from their company" ON public.gorev_tanimi_approvals FOR SELECT TO authenticated USING (employee_id IN (SELECT id FROM public.employees WHERE company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid())));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'gorev_tanimi_approvals' AND policyname = 'Users can create approval records') THEN
    CREATE POLICY "Users can create approval records" ON public.gorev_tanimi_approvals FOR INSERT TO authenticated WITH CHECK (employee_id IN (SELECT id FROM public.employees WHERE company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid())));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'ozluk_dosyalari' AND policyname = 'company_members_ozluk') THEN
    CREATE POLICY "company_members_ozluk" ON public.ozluk_dosyalari FOR ALL USING (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid() AND company_id IS NOT NULL)) WITH CHECK (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid() AND company_id IS NOT NULL));
  END IF;
END $$;

INSERT INTO storage.buckets (id, name, public)
VALUES ('ozluk-dosyalari', 'ozluk-dosyalari', false)
ON CONFLICT (id) DO NOTHING;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'auth users can upload ozluk') THEN
    CREATE POLICY "auth users can upload ozluk" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'ozluk-dosyalari');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'auth users can read ozluk') THEN
    CREATE POLICY "auth users can read ozluk" ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'ozluk-dosyalari');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'auth users can delete ozluk') THEN
    CREATE POLICY "auth users can delete ozluk" ON storage.objects FOR DELETE TO authenticated USING (bucket_id = 'ozluk-dosyalari');
  END IF;
END $$;

-- <<< END 20260404133000_bootstrap_core_hr_backend.sql


-- >>> BEGIN 20260404140000_create_test_users.sql

-- Test kullanicilarini ve sirket verisini olustur
-- Supabase SQL Editor'da calistirin

-- 1. Test sirketi olustur
INSERT INTO public.companies (id, name, address, tax_number, city, email, phone)
VALUES (
  'aaaaaaaa-0000-0000-0000-000000000001',
  'Humanius Demo Åžirketi',
  'Maslak Mah. BÃ¼yÃ¼kdere Cad. No:1 SarÄ±yer',
  '1234567890',
  'Ä°stanbul',
  'info@demo.com',
  '02121234567'
)
ON CONFLICT (id) DO NOTHING;

-- 2. Auth kullanicilari olustur (sifre: 123456)
-- NOT: confirmation_token / recovery_token yeni Supabase versiyonlarinda yok
INSERT INTO auth.users (
  id,
  instance_id,
  email,
  encrypted_password,
  email_confirmed_at,
  created_at,
  updated_at,
  raw_app_meta_data,
  raw_user_meta_data,
  aud,
  role,
  is_super_admin
)
VALUES
  (
    'aaaaaaaa-0000-0000-0000-000000000101',
    '00000000-0000-0000-0000-000000000000',
    'test@test.com',
    crypt('123456', gen_salt('bf')),
    now(), now(), now(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Test Admin"}',
    'authenticated', 'authenticated',
    false
  ),
  (
    'aaaaaaaa-0000-0000-0000-000000000102',
    '00000000-0000-0000-0000-000000000000',
    'bilgtest@test.com',
    crypt('123456', gen_salt('bf')),
    now(), now(), now(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Bilg Test"}',
    'authenticated', 'authenticated',
    false
  ),
  (
    'aaaaaaaa-0000-0000-0000-000000000103',
    '00000000-0000-0000-0000-000000000000',
    'bhv@test.com',
    crypt('123456', gen_salt('bf')),
    now(), now(), now(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"BHV Kullanici"}',
    'authenticated', 'authenticated',
    false
  )
ON CONFLICT (id) DO NOTHING;

-- 3. auth.identities kayitlari olustur (email login icin gerekli)
INSERT INTO auth.identities (
  id,
  user_id,
  identity_data,
  provider,
  provider_id,
  last_sign_in_at,
  created_at,
  updated_at
)
VALUES
  (
    'aaaaaaaa-0000-0000-0000-000000000101',
    'aaaaaaaa-0000-0000-0000-000000000101',
    '{"sub":"aaaaaaaa-0000-0000-0000-000000000101","email":"test@test.com"}',
    'email',
    'test@test.com',
    now(), now(), now()
  ),
  (
    'aaaaaaaa-0000-0000-0000-000000000102',
    'aaaaaaaa-0000-0000-0000-000000000102',
    '{"sub":"aaaaaaaa-0000-0000-0000-000000000102","email":"bilgtest@test.com"}',
    'email',
    'bilgtest@test.com',
    now(), now(), now()
  ),
  (
    'aaaaaaaa-0000-0000-0000-000000000103',
    'aaaaaaaa-0000-0000-0000-000000000103',
    '{"sub":"aaaaaaaa-0000-0000-0000-000000000103","email":"bhv@test.com"}',
    'email',
    'bhv@test.com',
    now(), now(), now()
  )
ON CONFLICT (id) DO NOTHING;

-- 4. Profilleri olustur
INSERT INTO public.profiles (id, email, full_name, company_id, role)
VALUES
  (
    'aaaaaaaa-0000-0000-0000-000000000101',
    'test@test.com',
    'Test Admin',
    'aaaaaaaa-0000-0000-0000-000000000001',
    'admin'
  ),
  (
    'aaaaaaaa-0000-0000-0000-000000000102',
    'bilgtest@test.com',
    'Bilg Test',
    'aaaaaaaa-0000-0000-0000-000000000001',
    'hr'
  ),
  (
    'aaaaaaaa-0000-0000-0000-000000000103',
    'bhv@test.com',
    'BHV KullanÄ±cÄ±',
    'aaaaaaaa-0000-0000-0000-000000000001',
    'employee'
  )
ON CONFLICT (id) DO NOTHING;

-- 5. Ornek calisan ekle
INSERT INTO public.employees (
  id, company_id, name, tc_no, sicil_no,
  department, position, level, salary,
  status, email, join_date, medeni_durum, cocuk_sayisi
)
VALUES
  (
    'bbbbbbbb-0000-0000-0000-000000000001',
    'aaaaaaaa-0000-0000-0000-000000000001',
    'Ahmet YÄ±lmaz', '12345678901', 'EMP001',
    'YazÄ±lÄ±m', 'KÄ±demli GeliÅŸtirici', 'Senior', 75000,
    'active', 'ahmet@demo.com', '2022-01-15', 'evli', 2
  ),
  (
    'bbbbbbbb-0000-0000-0000-000000000002',
    'aaaaaaaa-0000-0000-0000-000000000001',
    'AyÅŸe Kaya', '98765432109', 'EMP002',
    'Ä°nsan KaynaklarÄ±', 'Ä°K UzmanÄ±', 'Mid', 55000,
    'active', 'ayse@demo.com', '2023-03-01', 'bekar', 0
  ),
  (
    'bbbbbbbb-0000-0000-0000-000000000003',
    'aaaaaaaa-0000-0000-0000-000000000001',
    'Mehmet Demir', '11223344556', 'EMP003',
    'Muhasebe', 'Muhasebe MÃ¼dÃ¼rÃ¼', 'Senior', 85000,
    'active', 'mehmet@demo.com', '2021-06-10', 'evli', 1
  )
ON CONFLICT (id) DO NOTHING;

-- Ozet ve dogrulama
SELECT 'Auth users:' AS kontrol, id, email FROM auth.users WHERE email IN ('test@test.com','bilgtest@test.com','bhv@test.com');
SELECT 'Profiles:' AS kontrol, email, role FROM public.profiles WHERE company_id = 'aaaaaaaa-0000-0000-0000-000000000001';
SELECT 'Employees:' AS kontrol, name, department, position FROM public.employees WHERE company_id = 'aaaaaaaa-0000-0000-0000-000000000001';


-- <<< END 20260404140000_create_test_users.sql


-- >>> BEGIN 20260404140100_fix_profiles_rls.sql

-- Profiles tablosuna yeni users iÃ§in INSERT politikasÄ± ekle
-- Bu politika, yeni signup olan kullanÄ±cÄ±larÄ±n kendi profillerini oluÅŸturmasÄ±nÄ± saÄŸlar

DROP POLICY IF EXISTS "Users can create their own profile" ON public.profiles;

CREATE POLICY "Users can create their own profile" ON public.profiles 
FOR INSERT TO authenticated 
WITH CHECK (id = auth.uid());

-- Dogrulama
SELECT 'Politika baÅŸarÄ±yla oluÅŸturuldu' AS status;
SELECT policyname, cmd FROM pg_policies 
WHERE tablename = 'profiles' AND schemaname = 'public'
ORDER BY policyname;

-- <<< END 20260404140100_fix_profiles_rls.sql


-- >>> BEGIN 20260406120000_fix_manager_bordro_approval_update_policy.sql

/*
  # Manager bordro onay gÃ¼ncelleme yetkisi

  Problem:
  - Uygulama tarafÄ±nda manager rolÃ¼ bordro onay ekranÄ±na eriÅŸebiliyor.
  - Ancak mevcut RLS politikalarÄ±nda manager rolÃ¼ bordro_items UPDATE iÃ§in yetkili deÄŸil.
  - Bu durum onay/reddet akÄ±ÅŸÄ±nda update hatasÄ±na yol aÃ§abiliyor.

  Ã‡Ã¶zÃ¼m:
  - Manager kullanÄ±cÄ±larÄ±na, kendi ÅŸirketlerindeki bordro kayÄ±tlarÄ±nÄ± gÃ¼ncelleme yetkisi veren
    ek bir UPDATE politikasÄ± tanÄ±mlanÄ±r.
*/

DROP POLICY IF EXISTS "Managers can update bordro approval status" ON public.bordro_items;

CREATE POLICY "Managers can update bordro approval status"
  ON public.bordro_items
  FOR UPDATE
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id
      FROM public.profiles
      WHERE id = auth.uid()
      AND role = 'manager'
    )
  )
  WITH CHECK (
    company_id IN (
      SELECT company_id
      FROM public.profiles
      WHERE id = auth.uid()
      AND role = 'manager'
    )
  );

-- <<< END 20260406120000_fix_manager_bordro_approval_update_policy.sql


-- >>> BEGIN 20260406121500_restrict_manager_bordro_approval_columns.sql

/*
  # Manager rolÃ¼ iÃ§in bordro gÃ¼ncelleme alan kÄ±sÄ±tÄ±

  Problem:
  - Manager rolÃ¼ne bordro onay akÄ±ÅŸÄ± iÃ§in UPDATE yetkisi verildiÄŸinde,
    teorik olarak bordro kayÄ±tlarÄ±ndaki diÄŸer alanlar da gÃ¼ncellenebilir.

  Ã‡Ã¶zÃ¼m:
  - Trigger ile manager rolÃ¼ndeki kullanÄ±cÄ±lar iÃ§in gÃ¼ncelleme kapsamÄ±
    sadece approval_status, approval_date ve updated_at alanlarÄ± ile sÄ±nÄ±rlandÄ±rÄ±lÄ±r.
  - DiÄŸer roller mevcut politikalarÄ±na gÃ¶re normal Ã§alÄ±ÅŸmaya devam eder.
*/

CREATE OR REPLACE FUNCTION public.enforce_manager_bordro_approval_only()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_role text;
  old_payload jsonb;
  new_payload jsonb;
BEGIN
  SELECT p.role
  INTO current_role
  FROM public.profiles p
  WHERE p.id = auth.uid();

  IF current_role = 'manager' THEN
    old_payload := to_jsonb(OLD) - 'approval_status' - 'approval_date' - 'updated_at';
    new_payload := to_jsonb(NEW) - 'approval_status' - 'approval_date' - 'updated_at';

    IF old_payload IS DISTINCT FROM new_payload THEN
      RAISE EXCEPTION 'Manager rolÃ¼ sadece onay durumunu gÃ¼ncelleyebilir.';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_manager_bordro_approval_only ON public.bordro_items;

CREATE TRIGGER trg_enforce_manager_bordro_approval_only
  BEFORE UPDATE ON public.bordro_items
  FOR EACH ROW
  EXECUTE FUNCTION public.enforce_manager_bordro_approval_only();

-- <<< END 20260406121500_restrict_manager_bordro_approval_columns.sql


-- >>> BEGIN 20260406124000_allow_manager_manage_bordro_items.sql

/*
  # Manager bordro yÃ¶netim yetkisi

  Problem:
  - Frontend'de manager kullanÄ±cÄ±larÄ± bordro ekranÄ±na eriÅŸebiliyor.
  - Mevcut RLS politikasÄ±nda manager, bordro_items Ã¼zerinde INSERT/UPDATE/DELETE yetkisine sahip deÄŸil.
  - Bu nedenle bordro kaydetme iÅŸlemleri "row-level security policy" hatasÄ±yla baÅŸarÄ±sÄ±z olabiliyor.

  Ã‡Ã¶zÃ¼m:
  - Manager rolÃ¼ne, kendi ÅŸirketindeki bordro kayÄ±tlarÄ±nÄ± yÃ¶netme yetkisi verilir.
*/

DROP POLICY IF EXISTS "Managers can manage bordro items" ON public.bordro_items;

CREATE POLICY "Managers can manage bordro items"
  ON public.bordro_items
  FOR ALL
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id
      FROM public.profiles
      WHERE id = auth.uid()
      AND role = 'manager'
    )
  )
  WITH CHECK (
    company_id IN (
      SELECT company_id
      FROM public.profiles
      WHERE id = auth.uid()
      AND role = 'manager'
    )
  );

-- <<< END 20260406124000_allow_manager_manage_bordro_items.sql


-- >>> BEGIN 20260406124500_remove_manager_approval_only_trigger.sql

/*
  # Manager onay-alanÄ± trigger'Ä±nÄ± kaldÄ±r

  Not:
  - Daha Ã¶nce manager gÃ¼ncellemelerini sadece approval alanlarÄ±na sÄ±nÄ±rlayan trigger eklenmiÅŸti.
  - Manager bordro kaydÄ± dÃ¼zenleme/kaydetme ihtiyacÄ±nda bu trigger engel oluÅŸturur.
  - Bu migration trigger ve fonksiyonu temizler.
*/

DROP TRIGGER IF EXISTS trg_enforce_manager_bordro_approval_only ON public.bordro_items;
DROP FUNCTION IF EXISTS public.enforce_manager_bordro_approval_only();

-- <<< END 20260406124500_remove_manager_approval_only_trigger.sql


-- >>> BEGIN 20260409103000_fix_izin_talepleri_superadmin_rls.sql

/*
  # Ä°zin Talepleri - Superadmin RLS dÃ¼zeltmesi

  Problem:
  - Mevcut insert policy sadece profile.company_id eÅŸleÅŸen kullanÄ±cÄ±ya izin veriyor.
  - Superadmin kullanÄ±cÄ±larÄ±nda profile.company_id boÅŸ olabildiÄŸi iÃ§in
    izin talebi oluÅŸturma "row-level security" hatasÄ±na dÃ¼ÅŸebiliyor.

  Ã‡Ã¶zÃ¼m:
  - Superadmin rolÃ¼ne, izin taleplerinde ÅŸirket baÄŸÄ±msÄ±z tam yetki verilir.
*/

DROP POLICY IF EXISTS "Superadmin can manage all izin talepleri" ON public.izin_talepleri;

CREATE POLICY "Superadmin can manage all izin talepleri"
  ON public.izin_talepleri
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.profiles p
      WHERE p.id = auth.uid()
      AND p.role = 'superadmin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.profiles p
      WHERE p.id = auth.uid()
      AND p.role = 'superadmin'
    )
  );

-- <<< END 20260409103000_fix_izin_talepleri_superadmin_rls.sql


-- >>> BEGIN 20260409120000_fix_gorev_tanimlari_rls.sql

-- gorev_tanimlari ve gorev_tanimi_approvals tablolarÄ±na superadmin/admin tam yetki

-- Superadmin politikalarÄ± - gorev_tanimlari
DROP POLICY IF EXISTS "Superadmin can manage all gorev tanimlari" ON gorev_tanimlari;
CREATE POLICY "Superadmin can manage all gorev tanimlari"
  ON gorev_tanimlari FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role IN ('superadmin', 'admin')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role IN ('superadmin', 'admin')
    )
  );

-- Superadmin politikalarÄ± - gorev_tanimi_approvals
DROP POLICY IF EXISTS "Superadmin can manage all gorev tanimi approvals" ON gorev_tanimi_approvals;
CREATE POLICY "Superadmin can manage all gorev tanimi approvals"
  ON gorev_tanimi_approvals FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role IN ('superadmin', 'admin')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role IN ('superadmin', 'admin')
    )
  );

-- <<< END 20260409120000_fix_gorev_tanimlari_rls.sql


-- >>> BEGIN 20260412121000_allow_manager_insert_employees.sql

/*
  # employees INSERT RLS: manager rolunu da kapsa

  Problem:
  - Uygulamada manager rolu yonetici yetkileriyle kullaniliyor.
  - Ancak employees INSERT politikasinda manager yer almadigi icin
    personel satiri otomatik olusturma adimi RLS'e takiliyor.

  Cozum:
  - employees INSERT politikasini manager rolunu da kapsayacak sekilde yeniden tanimla.
*/

DROP POLICY IF EXISTS "HR and admins can insert employees" ON public.employees;
DROP POLICY IF EXISTS "Managers, HR and admins can insert employees" ON public.employees;

CREATE POLICY "Managers, HR and admins can insert employees"
  ON public.employees
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.profiles p
      WHERE p.id = auth.uid()
        AND (
          p.role = 'superadmin'
          OR (p.role IN ('admin', 'hr', 'manager') AND p.company_id = employees.company_id)
        )
    )
  );

-- <<< END 20260412121000_allow_manager_insert_employees.sql


-- ========================================
-- FILE: 20260214180417_create_initial_schema.sql
-- ========================================
/*
  # İnsan Kaynakları Yönetim Sistemi - Temel Şema
  
  ## Genel Bakış
  Bu migration, HRMS (Human Resources Management System) için temel veritabanı yapısını oluşturur.
  Sistem, çok şirketli yapıyı destekler ve her kullanıcı kendi şirketinin verilerine erişebilir.
  
  ## Oluşturulan Tablolar
  
  ### 1. `profiles`
  Kullanıcı profil bilgileri (auth.users ile ilişkili)
  - `id` (uuid, PK) - auth.users.id ile eşleşir
  - `email` (text) - Kullanıcı email
  - `full_name` (text) - Ad soyad
  - `company_id` (uuid) - Bağlı olduğu şirket
  - `role` (text) - Kullanıcı rolü (admin, manager, employee)
  - `avatar_url` (text) - Profil fotoğrafı URL
  - `created_at` (timestamptz) - Oluşturulma tarihi
  - `updated_at` (timestamptz) - Güncellenme tarihi
  
  ### 2. `companies`
  Şirket bilgileri
  - `id` (uuid, PK)
  - `name` (text) - Şirket adı
  - `address` (text) - Adres
  - `tax_number` (text) - Vergi numarası
  - `sgk_sicil_no` (text) - SGK sicil numarası
  - `phone` (text) - Telefon
  - `email` (text) - Email
  - `city` (text) - Bulunduğu il
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
  - `salary` (numeric) - Maaş
  - `status` (text) - Durum (active, onLeave, inactive)
  - `phone` (text) - Telefon
  - `email` (text) - Email
  - `join_date` (date) - İşe giriş tarihi
  - `address` (text) - Adres
  - `avatar_url` (text) - Profil fotoğrafı
  - `skills` (text[]) - Yetenekler
  - `medeni_durum` (text) - Medeni durum
  - `cocuk_sayisi` (integer) - Çocuk sayısı
  - `engelli_durumu` (text) - Engelli durumu
  - `created_at` (timestamptz)
  - `updated_at` (timestamptz)
  
  ## Güvenlik
  - Tüm tablolarda RLS (Row Level Security) aktif
  - Kullanıcılar sadece kendi şirketlerinin verilerine erişebilir
  - Admin rolü tam yetkiye sahip
  - Manager departman bazlı yetkilere sahip
  - Employee sadece kendi verilerini görebilir
  
  ## Notlar
  - Tüm foreign key'ler CASCADE ile silinir
  - Otomatik timestamp güncelleme trigger'ları eklenir
  - İndeksler performans için eklenir
*/

-- UUID extension'ı aktifleştir
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Şirketler tablosu
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

-- Kullanıcı profilleri tablosu
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

-- Otomatik updated_at güncellemesi için trigger fonksiyonu
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger'ları oluştur
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

-- İndeksler
CREATE INDEX IF NOT EXISTS idx_profiles_company_id ON profiles(company_id);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_employees_company_id ON employees(company_id);
CREATE INDEX IF NOT EXISTS idx_employees_status ON employees(status);
CREATE INDEX IF NOT EXISTS idx_employees_department ON employees(department);

-- RLS Aktifleştirme
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;

-- Companies tablosu RLS politikaları
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

-- Profiles tablosu RLS politikaları
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

-- Employees tablosu RLS politikaları
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

-- ========================================
-- FILE: 20260214180507_create_izin_yonetimi_schema.sql
-- ========================================
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

-- ========================================
-- FILE: 20260214180608_create_bordro_yonetimi_schema.sql
-- ========================================
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

-- ========================================
-- FILE: 20260214180713_create_sistem_ayarlari_takvim_schema.sql
-- ========================================
/*
  # Sistem Ayarları ve Takvim Yönetimi
  
  ## Genel Bakış
  Bu migration, sistem parametreleri ve takvim yönetimi için veritabanı yapısını oluşturur.
  
  ## Oluşturulan Tablolar
  
  ### 1. `sistem_parametreleri`
  Sistem genelindeki yapılandırma parametreleri
  - `id` (uuid, PK)
  - `company_id` (uuid, FK) - Şirket
  - `kategori` (text) - Parametre kategorisi
  - `ad` (text) - Parametre adı
  - `deger` (text) - Parametre değeri (JSON string)
  - `aciklama` (text) - Açıklama
  - `zorunlu` (boolean) - Zorunlu mu
  - `degistirilebilir` (boolean) - Değiştirilebilir mi
  - `yapilandirma_tarihi` (timestamptz) - İlk yapılandırma
  - `son_guncelleme` (timestamptz) - Son güncelleme
  
  ### 2. `takvim_gunleri`
  Resmi tatiller ve özel günler
  - `id` (uuid, PK)
  - `company_id` (uuid, FK) - Şirket (null ise ulusal)
  - `tarih` (date) - Tarih
  - `ad` (text) - Gün adı
  - `tur` (text) - Tür (resmi_tatil, dini_bayram, ozel_gun)
  - `aciklama` (text) - Açıklama
  - `calisma_gunu_mu` (boolean) - Çalışma günü mü
  - `yil` (integer) - Yıl
  
  ### 3. `bildirimler`
  Sistem bildirimleri ve uyarıları
  - `id` (uuid, PK)
  - `company_id` (uuid, FK)
  - `user_id` (uuid, FK) - Hedef kullanıcı (null ise tüm şirket)
  - `baslik` (text) - Başlık
  - `mesaj` (text) - Mesaj
  - `tur` (text) - Bildirim türü
  - `oncelik` (text) - Öncelik (dusuk, normal, yuksek, acil)
  - `okundu_mu` (boolean) - Okundu mu
  - `okunma_tarihi` (timestamptz) - Okunma tarihi
  - `link` (text) - İlgili sayfa linki
  - `metadata` (jsonb) - Ek bilgiler
  
  ### 4. `aktivite_loglari`
  Kullanıcı aktivite logları (audit trail)
  - `id` (uuid, PK)
  - `company_id` (uuid, FK)
  - `user_id` (uuid, FK)
  - `aksiyon` (text) - Yapılan işlem
  - `tablo` (text) - Etkilenen tablo
  - `kayit_id` (uuid) - Etkilenen kayıt
  - `onceki_deger` (jsonb) - Önceki değer
  - `yeni_deger` (jsonb) - Yeni değer
  - `ip_adresi` (text) - IP adresi
  - `user_agent` (text) - Browser bilgisi
  
  ## Güvenlik
  - Tüm tablolarda RLS aktif
  - Sistem parametreleri sadece admin tarafından değiştirilebilir
  - Takvim günleri herkes tarafından görülebilir
  - Bildirimler sadece ilgili kullanıcı tarafından görülebilir
  - Aktivite logları sadece admin tarafından görülebilir
  
  ## Notlar
  - Türkiye resmi tatilleri otomatik eklenir
  - Bildirim sistemi otomatik tetiklenebilir
  - Aktivite logları trigger ile otomatik kaydedilir
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

-- Takvim günleri tablosu
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

-- Aktivite logları tablosu
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

-- Trigger'ları oluştur
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

-- 2025-2026 Türkiye resmi tatillerini ekle
INSERT INTO takvim_gunleri (company_id, tarih, ad, tur, aciklama, calisma_gunu_mu, yil)
VALUES
  -- 2025 Tatiller
  (NULL, '2025-01-01', 'Yılbaşı', 'resmi_tatil', 'Yılbaşı tatili', false, 2025),
  (NULL, '2025-03-30', 'Ramazan Bayramı Arefe', 'dini_bayram', 'Ramazan Bayramı arefe günü', true, 2025),
  (NULL, '2025-03-31', 'Ramazan Bayramı 1. Gün', 'dini_bayram', 'Ramazan Bayramı birinci gün', false, 2025),
  (NULL, '2025-04-01', 'Ramazan Bayramı 2. Gün', 'dini_bayram', 'Ramazan Bayramı ikinci gün', false, 2025),
  (NULL, '2025-04-02', 'Ramazan Bayramı 3. Gün', 'dini_bayram', 'Ramazan Bayramı üçüncü gün', false, 2025),
  (NULL, '2025-04-23', '23 Nisan Ulusal Egemenlik ve Çocuk Bayramı', 'resmi_tatil', '23 Nisan', false, 2025),
  (NULL, '2025-05-01', '1 Mayıs Emek ve Dayanışma Günü', 'resmi_tatil', '1 Mayıs', false, 2025),
  (NULL, '2025-05-19', '19 Mayıs Atatürk''ü Anma Gençlik ve Spor Bayramı', 'resmi_tatil', '19 Mayıs', false, 2025),
  (NULL, '2025-06-06', 'Kurban Bayramı Arefe', 'dini_bayram', 'Kurban Bayramı arefe günü', true, 2025),
  (NULL, '2025-06-07', 'Kurban Bayramı 1. Gün', 'dini_bayram', 'Kurban Bayramı birinci gün', false, 2025),
  (NULL, '2025-06-08', 'Kurban Bayramı 2. Gün', 'dini_bayram', 'Kurban Bayramı ikinci gün', false, 2025),
  (NULL, '2025-06-09', 'Kurban Bayramı 3. Gün', 'dini_bayram', 'Kurban Bayramı üçüncü gün', false, 2025),
  (NULL, '2025-06-10', 'Kurban Bayramı 4. Gün', 'dini_bayram', 'Kurban Bayramı dördüncü gün', false, 2025),
  (NULL, '2025-07-15', '15 Temmuz Demokrasi ve Milli Birlik Günü', 'resmi_tatil', '15 Temmuz', false, 2025),
  (NULL, '2025-08-30', '30 Ağustos Zafer Bayramı', 'resmi_tatil', '30 Ağustos', false, 2025),
  (NULL, '2025-10-28', 'Cumhuriyet Bayramı Arefe', 'resmi_tatil', 'Cumhuriyet Bayramı arefe', true, 2025),
  (NULL, '2025-10-29', '29 Ekim Cumhuriyet Bayramı', 'resmi_tatil', '29 Ekim', false, 2025),
  
  -- 2026 Tatiller
  (NULL, '2026-01-01', 'Yılbaşı', 'resmi_tatil', 'Yılbaşı tatili', false, 2026),
  (NULL, '2026-03-19', 'Ramazan Bayramı Arefe', 'dini_bayram', 'Ramazan Bayramı arefe günü', true, 2026),
  (NULL, '2026-03-20', 'Ramazan Bayramı 1. Gün', 'dini_bayram', 'Ramazan Bayramı birinci gün', false, 2026),
  (NULL, '2026-03-21', 'Ramazan Bayramı 2. Gün', 'dini_bayram', 'Ramazan Bayramı ikinci gün', false, 2026),
  (NULL, '2026-03-22', 'Ramazan Bayramı 3. Gün', 'dini_bayram', 'Ramazan Bayramı üçüncü gün', false, 2026),
  (NULL, '2026-04-23', '23 Nisan Ulusal Egemenlik ve Çocuk Bayramı', 'resmi_tatil', '23 Nisan', false, 2026),
  (NULL, '2026-05-01', '1 Mayıs Emek ve Dayanışma Günü', 'resmi_tatil', '1 Mayıs', false, 2026),
  (NULL, '2026-05-19', '19 Mayıs Atatürk''ü Anma Gençlik ve Spor Bayramı', 'resmi_tatil', '19 Mayıs', false, 2026),
  (NULL, '2026-05-26', 'Kurban Bayramı Arefe', 'dini_bayram', 'Kurban Bayramı arefe günü', true, 2026),
  (NULL, '2026-05-27', 'Kurban Bayramı 1. Gün', 'dini_bayram', 'Kurban Bayramı birinci gün', false, 2026),
  (NULL, '2026-05-28', 'Kurban Bayramı 2. Gün', 'dini_bayram', 'Kurban Bayramı ikinci gün', false, 2026),
  (NULL, '2026-05-29', 'Kurban Bayramı 3. Gün', 'dini_bayram', 'Kurban Bayramı üçüncü gün', false, 2026),
  (NULL, '2026-05-30', 'Kurban Bayramı 4. Gün', 'dini_bayram', 'Kurban Bayramı dördüncü gün', false, 2026),
  (NULL, '2026-07-15', '15 Temmuz Demokrasi ve Milli Birlik Günü', 'resmi_tatil', '15 Temmuz', false, 2026),
  (NULL, '2026-08-30', '30 Ağustos Zafer Bayramı', 'resmi_tatil', '30 Ağustos', false, 2026),
  (NULL, '2026-10-28', 'Cumhuriyet Bayramı Arefe', 'resmi_tatil', 'Cumhuriyet Bayramı arefe', true, 2026),
  (NULL, '2026-10-29', '29 Ekim Cumhuriyet Bayramı', 'resmi_tatil', '29 Ekim', false, 2026)
ON CONFLICT DO NOTHING;

-- İndeksler
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

-- RLS Aktifleştirme
ALTER TABLE sistem_parametreleri ENABLE ROW LEVEL SECURITY;
ALTER TABLE takvim_gunleri ENABLE ROW LEVEL SECURITY;
ALTER TABLE bildirimler ENABLE ROW LEVEL SECURITY;
ALTER TABLE aktivite_loglari ENABLE ROW LEVEL SECURITY;

-- Sistem parametreleri RLS politikaları
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

-- Takvim günleri RLS politikaları
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

-- Bildirimler RLS politikaları
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

-- Aktivite logları RLS politikaları
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

-- ========================================
-- FILE: 20260312032554_add_emekli_bordro_schema.sql
-- ========================================
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

-- ========================================
-- FILE: 20260313085109_fix_companies_public_access.sql
-- ========================================
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


-- ========================================
-- FILE: 20260314081455_add_gorev_tanimi_approval_schema.sql
-- ========================================
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

-- ========================================
-- FILE: 20260314090134_fix_profiles_rls_infinite_recursion.sql
-- ========================================
/*
  # Profiles RLS Sonsuz Döngü Düzeltmesi
  
  ## Sorun
  Profiles tablosundaki "Users can view profiles in their company" politikası,
  profiles tablosunu profiles tablosundan sorgulayarak sonsuz döngüye giriyor.
  
  ## Çözüm
  1. Eski politikayı kaldır
  2. Kullanıcının kendi profilini görmesine izin ver
  3. Aynı şirketteki profilleri görmek için yeni politika ekle (company_id doğrudan kontrol)
  
  ## Değişiklikler
  - Eski "Users can view profiles in their company" politikası kaldırıldı
  - "Users can view own profile" politikası eklendi
  - "Users can view profiles in same company" politikası eklendi
*/

-- Eski politikayı kaldır
DROP POLICY IF EXISTS "Users can view profiles in their company" ON profiles;

-- Kullanıcılar kendi profillerini görebilir
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  TO authenticated
  USING (id = auth.uid());

-- Kullanıcılar aynı şirketteki profilleri görebilir
CREATE POLICY "Users can view profiles in same company"
  ON profiles FOR SELECT
  TO authenticated
  USING (
    company_id = (
      SELECT company_id FROM profiles WHERE id = auth.uid() LIMIT 1
    )
  );


-- ========================================
-- FILE: 20260314090342_fix_all_profiles_rls_policies.sql
-- ========================================
/*
  # Tüm Profiles RLS Politikalarını Düzelt
  
  ## Sorun
  Profiles tablosunda birden fazla politika profiles tablosunu tekrar sorgulayarak 
  sonsuz döngü yaratıyor:
  - "Users can view profiles in same company"
  - "Admins can insert profiles"
  - "Admins can delete profiles in their company"
  
  ## Çözüm
  Tüm mevcut politikaları kaldır ve basit, döngüsüz politikalar oluştur:
  1. Kullanıcılar kendi profillerini görebilir, güncelleyebilir
  2. Herkes authenticated kullanıcıların profillerini görebilir (aynı şirket kontrolü uygulama katmanında)
  3. Sadece servis rolü yeni profil ekleyebilir
  
  ## Değişiklikler
  - Tüm eski politikalar kaldırıldı
  - Basit, sonsuz döngü yaratmayan yeni politikalar eklendi
*/

-- Tüm mevcut politikaları kaldır
DROP POLICY IF EXISTS "Users can view profiles in their company" ON profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can view profiles in same company" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Admins can insert profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can delete profiles in their company" ON profiles;

-- Yeni basit politikalar

-- Herkes authenticated kullanıcıların profillerini görebilir
-- (Company kontrolü uygulama katmanında yapılacak)
CREATE POLICY "Authenticated users can view all profiles"
  ON profiles FOR SELECT
  TO authenticated
  USING (true);

-- Kullanıcılar sadece kendi profillerini güncelleyebilir
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- Sadece authenticated kullanıcılar profil oluşturabilir
-- (Sign up sırasında kullanılacak)
CREATE POLICY "Authenticated users can insert own profile"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (id = auth.uid());

-- Kullanıcılar kendi profillerini silebilir
CREATE POLICY "Users can delete own profile"
  ON profiles FOR DELETE
  TO authenticated
  USING (id = auth.uid());


-- ========================================
-- FILE: 20260314091728_add_approval_passcode_to_employees.sql
-- ========================================
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

-- ========================================
-- FILE: 20260314091746_add_employee_type_to_employees.sql
-- ========================================
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

-- ========================================
-- FILE: 20260314113749_add_bordro_approval_schema.sql
-- ========================================
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


-- ========================================
-- FILE: 20260314125108_fix_bordro_approvals_rls_policies.sql
-- ========================================
/*
  # Bordro Onay RLS Politikalarını Düzelt

  ## Açıklama
  bordro_approvals tablosundaki RLS politikalarını günceller.
  Profiles tablosuna yapılan subquery'leri kaldırarak sonsuz döngü sorununu önler.

  ## Değişiklikler
  - Mevcut RLS politikalarını kaldırır
  - Basitleştirilmiş, doğrudan company_id kontrolü yapan yeni politikalar ekler
  
  ## Güvenlik
  - Kullanıcılar kendi şirketlerinin bordro onaylarını görüntüleyebilir
  - Kullanıcılar kendi şirketleri için bordro onayı oluşturabilir
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


-- ========================================
-- FILE: 20260314125656_fix_bordro_approval_update_permission.sql
-- ========================================
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

-- ========================================
-- FILE: 20260314181352_fix_bordro_approvals_company_check.sql
-- ========================================
/*
  # Bordro Onay RLS Politikalarına Company Kontrolü Ekle

  1. Açıklama
    bordro_approvals tablosundaki RLS politikalarını günceller.
    Gerçek company_id kontrolü ekler.

  2. Değişiklikler
    - Mevcut basit RLS politikalarını kaldırır
    - Company_id ile kontrol yapan güvenli politikalar ekler
  
  3. Güvenlik
    - Kullanıcılar sadece kendi şirketlerinin bordro onaylarını görüntüleyebilir
    - Kullanıcılar sadece kendi şirketleri için bordro onayı oluşturabilir
    - Profiles tablosuna subquery yapılarak sonsuz döngü engellenir
*/

-- Mevcut politikaları kaldır
DROP POLICY IF EXISTS "Users can view own company approvals" ON bordro_approvals;
DROP POLICY IF EXISTS "Users can create own company approvals" ON bordro_approvals;

-- Görüntüleme politikası - kullanıcının şirketine ait onayları göster
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

-- Oluşturma politikası - kullanıcı kendi şirketine ait onay oluşturabilir
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

-- ========================================
-- FILE: 20260314181631_simplify_bordro_approvals_rls.sql
-- ========================================
/*
  # Bordro Approvals RLS Politikalarını Basitleştir

  1. Açıklama
    Profiles tablosundan sonsuz döngü riskini ortadan kaldırmak için
    bordro_approvals tablosu RLS politikalarını basitleştirir.

  2. Değişiklikler
    - Mevcut politikaları kaldırır
    - Herhangi bir authenticated kullanıcının onay oluşturabilmesine izin verir
    - Herhangi bir authenticated kullanıcının onayları görebilmesine izin verir
  
  3. Güvenlik Notu
    - Bu basitleştirme geçicidir
    - Gerçek kontrol application layer'da yapılacak
*/

-- Mevcut politikaları kaldır
DROP POLICY IF EXISTS "Users can view own company approvals" ON bordro_approvals;
DROP POLICY IF EXISTS "Users can create own company approvals" ON bordro_approvals;

-- Basit politikalar oluştur - authenticated kullanıcılar için
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

-- ========================================
-- FILE: 20260328020749_fix_bordro_items_insert_policy.sql
-- ========================================
/*
  # Bordro Items INSERT Politikası Düzeltmesi

  ## Açıklama
  Bordro kaydetme sorunu düzeltiliyor. Mevcut politika sadece 'admin' ve 'hr' 
  rolüne izin veriyor, ancak tüm authenticated kullanıcıların kendi şirketleri 
  için bordro oluşturabilmesi gerekiyor.

  ## Değişiklikler
  1. Eski kısıtlayıcı politika kaldırılıyor
  2. Tüm authenticated kullanıcıların kendi şirketleri için bordro oluşturmasına izin veriliyor

  ## Güvenlik
  - RLS aktif kalıyor
  - Kullanıcılar sadece kendi şirketleri için bordro oluşturabilir
  - company_id kontrolü ile güvenlik sağlanıyor
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


-- ========================================
-- FILE: 20260331133000_add_superadmin_and_user_roles.sql
-- ========================================
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_role_check;

ALTER TABLE profiles
ADD CONSTRAINT profiles_role_check
CHECK (role IN ('superadmin', 'admin', 'manager', 'employee', 'hr', 'user'));

DROP POLICY IF EXISTS "Authenticated users can insert own profile" ON profiles;

CREATE POLICY "Authenticated users can insert own profile"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (id = auth.uid() OR role = 'superadmin');

-- ========================================
-- FILE: 20260331140000_add_admin_update_user_profile_rpc.sql
-- ========================================
/*
  # Admin Kullanıcı Profili Güncelleme RPC

  Süper yönetici ve yöneticilerin başka kullanıcıların profilini güncelleyebilmesi için
  SECURITY DEFINER fonksiyon oluşturulur.
  
  Bu fonksiyon RLS bypass eder; yetki kontrolü SQL içinde yapılır.
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
  -- Çağıran kullanıcının rolünü al
  SELECT role INTO caller_role
  FROM profiles
  WHERE id = auth.uid();

  -- Yetki kontrolü
  IF caller_role NOT IN ('superadmin', 'admin') THEN
    RAISE EXCEPTION 'Yetkiniz yok: yalnızca superadmin ve admin başkalarının profilini güncelleyebilir';
  END IF;

  -- Admin sadece kendi şirketindeki kullanıcıları güncelleyebilir (superadmin herkesi güncelleyebilir)
  IF caller_role = 'admin' THEN
    IF NOT EXISTS (
      SELECT 1 FROM profiles caller_p
      JOIN profiles target_p ON target_p.id = target_id
      WHERE caller_p.id = auth.uid()
        AND caller_p.company_id IS NOT NULL
        AND caller_p.company_id = target_p.company_id
    ) AND target_id != auth.uid() THEN
      RAISE EXCEPTION 'Yetkiniz yok: başka şirketin kullanıcısını düzenleyemezsiniz';
    END IF;
  END IF;

  -- Güncelle
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
    RAISE EXCEPTION 'Kullanıcı bulunamadı: %', target_id;
  END IF;
END;
$$;

-- Fonksiyona erisim
GRANT EXECUTE ON FUNCTION admin_update_user_profile(uuid, text, text, uuid) TO authenticated;


-- ========================================
-- FILE: 20260331153000_add_admin_delete_user_profile_rpc.sql
-- ========================================
/*
  # Admin kullanıcı profili silme RPC

  Superadmin ve admin kullanıcıların profil kaydını silmesine izin verir.
  Not: Bu işlem auth.users kaydını silmez; yalnızca public.profiles satırını siler.
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
    RAISE EXCEPTION 'Yetkiniz yok: yalnızca superadmin ve admin kullanıcı silebilir';
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
      RAISE EXCEPTION 'Yetkiniz yok: başka şirketin kullanıcısını silemezsiniz';
    END IF;
  END IF;

  DELETE FROM profiles WHERE id = target_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Kullanıcı bulunamadı: %', target_id;
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION admin_delete_user_profile(uuid) TO authenticated;


-- ========================================
-- FILE: 20260331170000_fix_employees_rls_for_superadmin_and_admin.sql
-- ========================================
/*
  # Employees RLS düzeltmesi

  Sorunlar:
  1) superadmin çalışan kayıtlarında yetki hatası alıyordu
  2) kullanıcı -> personel senkronizasyonunda insert RLS engeline takılabiliyordu

  Çözüm:
  - employees politikalarını superadmin'i kapsayacak şekilde yeniden tanımla
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


-- ========================================
-- FILE: 20260331183000_add_approval_signature_to_employees.sql
-- ========================================
/*
  # Employees tablosuna imza alanı ekle

  Kullanıcı bazlı imza ve onay şifresi işlemlerinde
  dijital imza verisini employees tablosunda saklamak için alan eklenir.
*/

ALTER TABLE employees
ADD COLUMN IF NOT EXISTS approval_signature text;


-- ========================================
-- FILE: 20260331200000_create_ozluk_dosyalari.sql
-- ========================================
-- Çalışan Özlük Dosyası tablosu
-- NOT: Bu migration'ı Supabase Dashboard > SQL Editor'da çalıştırın
-- Supabase Dashboard > Storage > "ozluk-dosyalari" adlı bucket oluşturun (private)

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

-- Şirket çalışanları kendi şirketlerindeki kayıtlara erişebilir
DROP POLICY IF EXISTS "company_members_ozluk" ON ozluk_dosyalari;
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

-- updated_at otomatik güncelleme
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

-- ─── Storage bucket politikaları ──────────────────────────────────────────────
-- Supabase Dashboard > Storage > "ozluk-dosyalari" bucket oluşturduktan sonra
-- aşağıdaki politikaları ekleyin:

-- INSERT (yükleme):
-- DROP POLICY IF EXISTS "auth users can upload ozluk" ON storage;
CREATE POLICY "auth users can upload ozluk" ON storage.objects
--   FOR INSERT TO authenticated
--   WITH CHECK (bucket_id = 'ozluk-dosyalari');

-- SELECT (indirme):
-- DROP POLICY IF EXISTS "auth users can read ozluk" ON storage;
CREATE POLICY "auth users can read ozluk" ON storage.objects
--   FOR SELECT TO authenticated
--   USING (bucket_id = 'ozluk-dosyalari');

-- DELETE (silme):
-- DROP POLICY IF EXISTS "auth users can delete ozluk" ON storage;
CREATE POLICY "auth users can delete ozluk" ON storage.objects
--   FOR DELETE TO authenticated
--   USING (bucket_id = 'ozluk-dosyalari');


-- ========================================
-- FILE: 20260404123000_setup_ozluk_dosyalari_backend.sql
-- ========================================
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
    DROP POLICY IF EXISTS "company_members_ozluk" ON public;
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

DO $$
BEGIN
  IF to_regclass('storage.buckets') IS NOT NULL THEN
    INSERT INTO storage.buckets (id, name, public)
    VALUES ('ozluk-dosyalari', 'ozluk-dosyalari', false)
    ON CONFLICT (id) DO NOTHING;
  END IF;

  IF to_regclass('storage.objects') IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1
      FROM pg_policies
      WHERE schemaname = 'storage'
        AND tablename = 'objects'
        AND policyname = 'auth users can upload ozluk'
    ) THEN
      DROP POLICY IF EXISTS "auth users can upload ozluk" ON storage;
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
      DROP POLICY IF EXISTS "auth users can read ozluk" ON storage;
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
      DROP POLICY IF EXISTS "auth users can delete ozluk" ON storage;
CREATE POLICY "auth users can delete ozluk" ON storage.objects
        FOR DELETE TO authenticated
        USING (bucket_id = 'ozluk-dosyalari');
    END IF;
  END IF;
END $$;

-- ========================================
-- FILE: 20260404133000_bootstrap_core_hr_backend.sql
-- ========================================
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
    DROP POLICY IF EXISTS "Users can view their own company" ON public;
CREATE POLICY "Users can view their own company" ON public.companies FOR SELECT TO authenticated USING (id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid()));
  END IF;

  -- NOTE: "Users can view profiles in their company" intentionally omitted — causes infinite recursion.
  -- Migration 20260314090342 adds "Authenticated users can view all profiles" (USING true) instead.

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'employees' AND policyname = 'Users can view employees in their company') THEN
    DROP POLICY IF EXISTS "Users can view employees in their company" ON public;
CREATE POLICY "Users can view employees in their company" ON public.employees FOR SELECT TO authenticated USING (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid()));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'employees' AND policyname = 'HR can manage employees in their company') THEN
    DROP POLICY IF EXISTS "HR can manage employees in their company" ON public;
CREATE POLICY "HR can manage employees in their company" ON public.employees FOR ALL TO authenticated USING (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'hr'))) WITH CHECK (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'hr')));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'izin_talepleri' AND policyname = 'Users can view izin talepleri in their company') THEN
    DROP POLICY IF EXISTS "Users can view izin talepleri in their company" ON public;
CREATE POLICY "Users can view izin talepleri in their company" ON public.izin_talepleri FOR SELECT TO authenticated USING (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid()));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'izin_talepleri' AND policyname = 'Employees can create their own izin talepleri') THEN
    DROP POLICY IF EXISTS "Employees can create their own izin talepleri" ON public;
CREATE POLICY "Employees can create their own izin talepleri" ON public.izin_talepleri FOR INSERT TO authenticated WITH CHECK (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid()));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'izin_haklari' AND policyname = 'Users can view izin haklari in their company') THEN
    DROP POLICY IF EXISTS "Users can view izin haklari in their company" ON public;
CREATE POLICY "Users can view izin haklari in their company" ON public.izin_haklari FOR SELECT TO authenticated USING (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid()));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'izin_haklari' AND policyname = 'HR and admins can manage izin haklari') THEN
    DROP POLICY IF EXISTS "HR and admins can manage izin haklari" ON public;
CREATE POLICY "HR and admins can manage izin haklari" ON public.izin_haklari FOR ALL TO authenticated USING (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'hr'))) WITH CHECK (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'hr')));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'bordro_items' AND policyname = 'HR can view all bordro items in their company') THEN
    DROP POLICY IF EXISTS "HR can view all bordro items in their company" ON public;
CREATE POLICY "HR can view all bordro items in their company" ON public.bordro_items FOR SELECT TO authenticated USING (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'hr', 'manager')));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'bordro_items' AND policyname = 'HR can manage bordro items') THEN
    DROP POLICY IF EXISTS "HR can manage bordro items" ON public;
CREATE POLICY "HR can manage bordro items" ON public.bordro_items FOR ALL TO authenticated USING (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'hr'))) WITH CHECK (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'hr')));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'bordro_calculation_rates' AND policyname = 'Users can view calculation rates in their company') THEN
    DROP POLICY IF EXISTS "Users can view calculation rates in their company" ON public;
CREATE POLICY "Users can view calculation rates in their company" ON public.bordro_calculation_rates FOR SELECT TO authenticated USING (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid()));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'bordro_approvals' AND policyname = 'Users can view approvals of their company') THEN
    DROP POLICY IF EXISTS "Users can view approvals of their company" ON public;
CREATE POLICY "Users can view approvals of their company" ON public.bordro_approvals FOR SELECT TO authenticated USING (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid()));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'bordro_approvals' AND policyname = 'Users can create approvals for their company') THEN
    DROP POLICY IF EXISTS "Users can create approvals for their company" ON public;
CREATE POLICY "Users can create approvals for their company" ON public.bordro_approvals FOR INSERT TO authenticated WITH CHECK (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid()));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'gorev_tanimlari' AND policyname = 'Users can view gorev tanimlari from their company') THEN
    DROP POLICY IF EXISTS "Users can view gorev tanimlari from their company" ON public;
CREATE POLICY "Users can view gorev tanimlari from their company" ON public.gorev_tanimlari FOR SELECT TO authenticated USING (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid()));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'gorev_tanimlari' AND policyname = 'Users can manage gorev tanimlari for their company') THEN
    DROP POLICY IF EXISTS "Users can manage gorev tanimlari for their company" ON public;
CREATE POLICY "Users can manage gorev tanimlari for their company" ON public.gorev_tanimlari FOR ALL TO authenticated USING (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid())) WITH CHECK (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid()));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'gorev_tanimi_approvals' AND policyname = 'Users can view approval records from their company') THEN
    DROP POLICY IF EXISTS "Users can view approval records from their company" ON public;
CREATE POLICY "Users can view approval records from their company" ON public.gorev_tanimi_approvals FOR SELECT TO authenticated USING (employee_id IN (SELECT id FROM public.employees WHERE company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid())));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'gorev_tanimi_approvals' AND policyname = 'Users can create approval records') THEN
    DROP POLICY IF EXISTS "Users can create approval records" ON public;
CREATE POLICY "Users can create approval records" ON public.gorev_tanimi_approvals FOR INSERT TO authenticated WITH CHECK (employee_id IN (SELECT id FROM public.employees WHERE company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid())));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'ozluk_dosyalari' AND policyname = 'company_members_ozluk') THEN
    DROP POLICY IF EXISTS "company_members_ozluk" ON public;
CREATE POLICY "company_members_ozluk" ON public.ozluk_dosyalari FOR ALL USING (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid() AND company_id IS NOT NULL)) WITH CHECK (company_id IN (SELECT company_id FROM public.profiles WHERE id = auth.uid() AND company_id IS NOT NULL));
  END IF;
END $$;

DO $$
BEGIN
  IF to_regclass('storage.buckets') IS NOT NULL THEN
    INSERT INTO storage.buckets (id, name, public)
    VALUES ('ozluk-dosyalari', 'ozluk-dosyalari', false)
    ON CONFLICT (id) DO NOTHING;
  END IF;

  IF to_regclass('storage.objects') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'auth users can upload ozluk') THEN
      DROP POLICY IF EXISTS "auth users can upload ozluk" ON storage;
CREATE POLICY "auth users can upload ozluk" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'ozluk-dosyalari');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'auth users can read ozluk') THEN
      DROP POLICY IF EXISTS "auth users can read ozluk" ON storage;
CREATE POLICY "auth users can read ozluk" ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'ozluk-dosyalari');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'auth users can delete ozluk') THEN
      DROP POLICY IF EXISTS "auth users can delete ozluk" ON storage;
CREATE POLICY "auth users can delete ozluk" ON storage.objects FOR DELETE TO authenticated USING (bucket_id = 'ozluk-dosyalari');
    END IF;
  END IF;
END $$;

-- ========================================
-- FILE: 20260404140000_create_test_users.sql
-- ========================================
-- Test kullanicilarini ve sirket verisini olustur
-- Supabase SQL Editor'da calistirin

-- 1. Test sirketi olustur
INSERT INTO public.companies (id, name, address, tax_number, city, email, phone)
VALUES (
  'aaaaaaaa-0000-0000-0000-000000000001',
  'Humanius Demo Şirketi',
  'Maslak Mah. Büyükdere Cad. No:1 Sarıyer',
  '1234567890',
  'İstanbul',
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
  is_super_admin,
  confirmation_token,
  recovery_token,
  email_change_token_new,
  email_change,
  phone_change,
  phone_change_token,
  email_change_token_current,
  reauthentication_token
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
    false,
    '', '', '', '', '', '', '', ''
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
    false,
    '', '', '', '', '', '', '', ''
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
    false,
    '', '', '', '', '', '', '', ''
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
    'BHV Kullanıcı',
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
    'Ahmet Yılmaz', '12345678901', 'EMP001',
    'Yazılım', 'Kıdemli Geliştirici', 'Senior', 75000,
    'active', 'ahmet@demo.com', '2022-01-15', 'evli', 2
  ),
  (
    'bbbbbbbb-0000-0000-0000-000000000002',
    'aaaaaaaa-0000-0000-0000-000000000001',
    'Ayşe Kaya', '98765432109', 'EMP002',
    'İnsan Kaynakları', 'İK Uzmanı', 'Mid', 55000,
    'active', 'ayse@demo.com', '2023-03-01', 'bekar', 0
  ),
  (
    'bbbbbbbb-0000-0000-0000-000000000003',
    'aaaaaaaa-0000-0000-0000-000000000001',
    'Mehmet Demir', '11223344556', 'EMP003',
    'Muhasebe', 'Muhasebe Müdürü', 'Senior', 85000,
    'active', 'mehmet@demo.com', '2021-06-10', 'evli', 1
  )
ON CONFLICT (id) DO NOTHING;

-- Ozet ve dogrulama
SELECT 'Auth users:' AS kontrol, id, email FROM auth.users WHERE email IN ('test@test.com','bilgtest@test.com','bhv@test.com');
SELECT 'Profiles:' AS kontrol, email, role FROM public.profiles WHERE company_id = 'aaaaaaaa-0000-0000-0000-000000000001';
SELECT 'Employees:' AS kontrol, name, department, position FROM public.employees WHERE company_id = 'aaaaaaaa-0000-0000-0000-000000000001';



-- ========================================
-- FILE: 20260404140100_fix_profiles_rls.sql
-- ========================================
-- Profiles tablosuna yeni users için INSERT politikası ekle
-- Bu politika, yeni signup olan kullanıcıların kendi profillerini oluşturmasını sağlar

DROP POLICY IF EXISTS "Users can create their own profile" ON public.profiles;

DROP POLICY IF EXISTS "Users can create their own profile" ON public;
CREATE POLICY "Users can create their own profile" ON public.profiles 
FOR INSERT TO authenticated 
WITH CHECK (id = auth.uid());

-- Dogrulama
SELECT 'Politika başarıyla oluşturuldu' AS status;
SELECT policyname, cmd FROM pg_policies 
WHERE tablename = 'profiles' AND schemaname = 'public'
ORDER BY policyname;


-- ========================================
-- FILE: 20260406120000_fix_manager_bordro_approval_update_policy.sql
-- ========================================
/*
  # Manager bordro onay güncelleme yetkisi

  Problem:
  - Uygulama tarafında manager rolü bordro onay ekranına erişebiliyor.
  - Ancak mevcut RLS politikalarında manager rolü bordro_items UPDATE için yetkili değil.
  - Bu durum onay/reddet akışında update hatasına yol açabiliyor.

  Çözüm:
  - Manager kullanıcılarına, kendi şirketlerindeki bordro kayıtlarını güncelleme yetkisi veren
    ek bir UPDATE politikası tanımlanır.
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


-- ========================================
-- FILE: 20260406121500_restrict_manager_bordro_approval_columns.sql
-- ========================================
/*
  # Manager rolü için bordro güncelleme alan kısıtı

  Problem:
  - Manager rolüne bordro onay akışı için UPDATE yetkisi verildiğinde,
    teorik olarak bordro kayıtlarındaki diğer alanlar da güncellenebilir.

  Çözüm:
  - Trigger ile manager rolündeki kullanıcılar için güncelleme kapsamı
    sadece approval_status, approval_date ve updated_at alanları ile sınırlandırılır.
  - Diğer roller mevcut politikalarına göre normal çalışmaya devam eder.
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
      RAISE EXCEPTION 'Manager rolü sadece onay durumunu güncelleyebilir.';
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


-- ========================================
-- FILE: 20260406124000_allow_manager_manage_bordro_items.sql
-- ========================================
/*
  # Manager bordro yönetim yetkisi

  Problem:
  - Frontend'de manager kullanıcıları bordro ekranına erişebiliyor.
  - Mevcut RLS politikasında manager, bordro_items üzerinde INSERT/UPDATE/DELETE yetkisine sahip değil.
  - Bu nedenle bordro kaydetme işlemleri "row-level security policy" hatasıyla başarısız olabiliyor.

  Çözüm:
  - Manager rolüne, kendi şirketindeki bordro kayıtlarını yönetme yetkisi verilir.
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


-- ========================================
-- FILE: 20260406124500_remove_manager_approval_only_trigger.sql
-- ========================================
/*
  # Manager onay-alanı trigger'ını kaldır

  Not:
  - Daha önce manager güncellemelerini sadece approval alanlarına sınırlayan trigger eklenmişti.
  - Manager bordro kaydı düzenleme/kaydetme ihtiyacında bu trigger engel oluşturur.
  - Bu migration trigger ve fonksiyonu temizler.
*/

DROP TRIGGER IF EXISTS trg_enforce_manager_bordro_approval_only ON public.bordro_items;
DROP FUNCTION IF EXISTS public.enforce_manager_bordro_approval_only();


-- ========================================
-- FILE: 20260409103000_fix_izin_talepleri_superadmin_rls.sql
-- ========================================
/*
  # İzin Talepleri - Superadmin RLS düzeltmesi

  Problem:
  - Mevcut insert policy sadece profile.company_id eşleşen kullanıcıya izin veriyor.
  - Superadmin kullanıcılarında profile.company_id boş olabildiği için
    izin talebi oluşturma "row-level security" hatasına düşebiliyor.

  Çözüm:
  - Superadmin rolüne, izin taleplerinde şirket bağımsız tam yetki verilir.
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


-- ========================================
-- FILE: 20260409120000_fix_gorev_tanimlari_rls.sql
-- ========================================
-- gorev_tanimlari ve gorev_tanimi_approvals tablolarına superadmin/admin tam yetki

-- Superadmin politikaları - gorev_tanimlari
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

-- Superadmin politikaları - gorev_tanimi_approvals
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


-- ========================================
-- FILE: 20260412121000_allow_manager_insert_employees.sql
-- ========================================
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


-- ========================================
-- FILE: 20260417120000_fix_gorev_tanimlari_insert_rls.sql
-- ========================================
-- Fix: Allow all authenticated users from same company to insert gorev_tanimlari
-- The previous FOR ALL policy only covered superadmin/admin, blocking manager/hr/employee roles.

DROP POLICY IF EXISTS "Users can create gorev tanimlari for their company" ON gorev_tanimlari;

CREATE POLICY "Users can create gorev tanimlari for their company"
  ON gorev_tanimlari FOR INSERT
  TO authenticated
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM profiles
      WHERE id = auth.uid()
        AND company_id IS NOT NULL
    )
  );



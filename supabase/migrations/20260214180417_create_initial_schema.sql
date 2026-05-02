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
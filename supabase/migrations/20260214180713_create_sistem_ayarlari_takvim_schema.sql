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
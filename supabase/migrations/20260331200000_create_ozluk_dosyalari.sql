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

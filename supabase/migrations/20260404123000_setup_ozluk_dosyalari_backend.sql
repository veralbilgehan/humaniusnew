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
  END IF;
END $$;
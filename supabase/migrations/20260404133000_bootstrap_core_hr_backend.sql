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

  -- NOTE: "Users can view profiles in their company" intentionally omitted — causes infinite recursion.
  -- Migration 20260314090342 adds "Authenticated users can view all profiles" (USING true) instead.

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

DO $$
BEGIN
  IF to_regclass('storage.buckets') IS NOT NULL THEN
    INSERT INTO storage.buckets (id, name, public)
    VALUES ('ozluk-dosyalari', 'ozluk-dosyalari', false)
    ON CONFLICT (id) DO NOTHING;
  END IF;

  IF to_regclass('storage.objects') IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'auth users can upload ozluk') THEN
      CREATE POLICY "auth users can upload ozluk" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'ozluk-dosyalari');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'auth users can read ozluk') THEN
      CREATE POLICY "auth users can read ozluk" ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'ozluk-dosyalari');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'auth users can delete ozluk') THEN
      CREATE POLICY "auth users can delete ozluk" ON storage.objects FOR DELETE TO authenticated USING (bucket_id = 'ozluk-dosyalari');
    END IF;
  END IF;
END $$;
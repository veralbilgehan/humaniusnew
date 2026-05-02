


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE EXTENSION IF NOT EXISTS "pg_net" WITH SCHEMA "extensions";






COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "public"."admin_delete_user_profile"("target_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
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


ALTER FUNCTION "public"."admin_delete_user_profile"("target_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."admin_update_user_profile"("target_id" "uuid", "new_role" "text" DEFAULT NULL::"text", "new_full_name" "text" DEFAULT NULL::"text", "new_company_id" "uuid" DEFAULT NULL::"uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
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


ALTER FUNCTION "public"."admin_update_user_profile"("target_id" "uuid", "new_role" "text", "new_full_name" "text", "new_company_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."calculate_kalan_izin"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  NEW.kalan_izin = NEW.toplam_hak - NEW.kullanilan_izin;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."calculate_kalan_izin"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_gorev_tanimlari_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_gorev_tanimlari_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_ozluk_dosyalari_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_ozluk_dosyalari_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_updated_at_column"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_updated_at_column"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."aktivite_loglari" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "company_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "aksiyon" "text" NOT NULL,
    "tablo" "text",
    "kayit_id" "uuid",
    "onceki_deger" "jsonb",
    "yeni_deger" "jsonb",
    "ip_adresi" "text",
    "user_agent" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."aktivite_loglari" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."bildirimler" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "company_id" "uuid" NOT NULL,
    "user_id" "uuid",
    "baslik" "text" NOT NULL,
    "mesaj" "text" NOT NULL,
    "tur" "text" DEFAULT 'bilgi'::"text" NOT NULL,
    "oncelik" "text" DEFAULT 'normal'::"text" NOT NULL,
    "okundu_mu" boolean DEFAULT false,
    "okunma_tarihi" timestamp with time zone,
    "link" "text",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "bildirimler_oncelik_check" CHECK (("oncelik" = ANY (ARRAY['dusuk'::"text", 'normal'::"text", 'yuksek'::"text", 'acil'::"text"]))),
    CONSTRAINT "bildirimler_tur_check" CHECK (("tur" = ANY (ARRAY['bilgi'::"text", 'uyari'::"text", 'hata'::"text", 'basari'::"text", 'izin'::"text", 'bordro'::"text", 'sistem'::"text"])))
);


ALTER TABLE "public"."bildirimler" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."bordro_approvals" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "bordro_id" "uuid" NOT NULL,
    "company_id" "uuid" NOT NULL,
    "employee_id" "uuid" NOT NULL,
    "employee_name" "text" NOT NULL,
    "verification_method" "text" NOT NULL,
    "signature_data" "text",
    "id_document_data" "text",
    "passcode_hash" "text",
    "approval_status" "text" NOT NULL,
    "ip_address" "text",
    "user_agent" "text",
    "timestamp" timestamp with time zone DEFAULT "now"(),
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "bordro_approvals_approval_status_check" CHECK (("approval_status" = ANY (ARRAY['onaylandi'::"text", 'reddedildi'::"text"]))),
    CONSTRAINT "bordro_approvals_verification_method_check" CHECK (("verification_method" = ANY (ARRAY['signature'::"text", 'id_document'::"text", 'passcode'::"text"])))
);


ALTER TABLE "public"."bordro_approvals" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."bordro_calculation_rates" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "company_id" "uuid" NOT NULL,
    "yil" integer NOT NULL,
    "gelir_vergisi_dilimleri" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "damga_vergisi_orani" numeric(5,4) DEFAULT 0.00759,
    "sgk_isci_payi_orani" numeric(5,4) DEFAULT 0.14,
    "sgk_isveren_payi_orani" numeric(5,4) DEFAULT 0.205,
    "issizlik_isci_payi_orani" numeric(5,4) DEFAULT 0.01,
    "issizlik_isveren_payi_orani" numeric(5,4) DEFAULT 0.02,
    "asgari_ucret" numeric(12,2) DEFAULT 0,
    "sgk_tavani" numeric(12,2) DEFAULT 0,
    "asgari_ucret_istisnasi" "jsonb" DEFAULT '{"damgaVergisi": 0, "gelirVergisi": 0}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."bordro_calculation_rates" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."bordro_items" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "company_id" "uuid" NOT NULL,
    "employee_id" "uuid" NOT NULL,
    "period" "text" NOT NULL,
    "sicil_no" "text" DEFAULT ''::"text",
    "tc_no" "text" DEFAULT ''::"text",
    "brut_maas" numeric(12,2) DEFAULT 0,
    "medeni_durum" "text" DEFAULT 'bekar'::"text",
    "cocuk_sayisi" integer DEFAULT 0,
    "engelli_durumu" "text" DEFAULT 'yok'::"text",
    "temel_kazanc" numeric(12,2) DEFAULT 0,
    "yol_parasi" numeric(12,2) DEFAULT 0,
    "gida_yardimi" numeric(12,2) DEFAULT 0,
    "cocuk_yardimi" numeric(12,2) DEFAULT 0,
    "diger_kazanclar" numeric(12,2) DEFAULT 0,
    "fazla_mesai" numeric(12,2) DEFAULT 0,
    "fazla_mesai_saat_50" numeric(8,2) DEFAULT 0,
    "fazla_mesai_saat_100" numeric(8,2) DEFAULT 0,
    "fazla_mesai_tutar" numeric(12,2) DEFAULT 0,
    "haftalik_tatil" numeric(12,2) DEFAULT 0,
    "genel_tatil" numeric(12,2) DEFAULT 0,
    "yillik_izin_ucreti" numeric(12,2) DEFAULT 0,
    "ikramiye" numeric(12,2) DEFAULT 0,
    "prim" numeric(12,2) DEFAULT 0,
    "servis_ucreti" numeric(12,2) DEFAULT 0,
    "temsil_etiket" numeric(12,2) DEFAULT 0,
    "gelir_vergisi" numeric(12,2) DEFAULT 0,
    "damga_vergisi" numeric(12,2) DEFAULT 0,
    "sgk_isci_payi" numeric(12,2) DEFAULT 0,
    "issizlik_sigortasi" numeric(12,2) DEFAULT 0,
    "sendika_aidat" numeric(12,2) DEFAULT 0,
    "avans" numeric(12,2) DEFAULT 0,
    "diger_kesintiler" numeric(12,2) DEFAULT 0,
    "engelli_indirimi" numeric(12,2) DEFAULT 0,
    "kidem_tazminati" numeric(12,2) DEFAULT 0,
    "ihbar_tazminati" numeric(12,2) DEFAULT 0,
    "toplam_kazanc" numeric(12,2) DEFAULT 0,
    "toplam_kesinti" numeric(12,2) DEFAULT 0,
    "net_maas" numeric(12,2) DEFAULT 0,
    "kumulatif_vergi_matrahi" numeric(12,2) DEFAULT 0,
    "asgari_ucret_gelir_vergisi_istisnasi" numeric(12,2) DEFAULT 0,
    "asgari_ucret_damga_vergisi_istisnasi" numeric(12,2) DEFAULT 0,
    "sgk_isveren_payi" numeric(12,2) DEFAULT 0,
    "issizlik_isveren_payi" numeric(12,2) DEFAULT 0,
    "sgk_isveren_indirimi" numeric(12,2) DEFAULT 0,
    "sgk_isveren_indirim_orani" numeric(5,2) DEFAULT 0,
    "yillik_toplam_kazanc" numeric(12,2) DEFAULT 0,
    "yillik_toplam_kesinti" numeric(12,2) DEFAULT 0,
    "yillik_toplam_net" numeric(12,2) DEFAULT 0,
    "aciklama" "text" DEFAULT ''::"text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "approval_status" "text" DEFAULT 'beklemede'::"text",
    "approval_date" timestamp with time zone,
    CONSTRAINT "bordro_items_engelli_durumu_check" CHECK (("engelli_durumu" = ANY (ARRAY['yok'::"text", 'birinci'::"text", 'ikinci'::"text", 'ucuncu'::"text"]))),
    CONSTRAINT "bordro_items_medeni_durum_check" CHECK (("medeni_durum" = ANY (ARRAY['bekar'::"text", 'evli'::"text"])))
);


ALTER TABLE "public"."bordro_items" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."bordro_templates" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "company_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "description" "text" DEFAULT ''::"text",
    "default_values" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."bordro_templates" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."companies" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "name" "text" NOT NULL,
    "address" "text" DEFAULT ''::"text",
    "tax_number" "text" DEFAULT ''::"text",
    "sgk_sicil_no" "text" DEFAULT ''::"text",
    "phone" "text" DEFAULT ''::"text",
    "email" "text" DEFAULT ''::"text",
    "city" "text" DEFAULT ''::"text",
    "logo_url" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."companies" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."emekli_bordro_items" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "company_id" "uuid" NOT NULL,
    "employee_id" "uuid" NOT NULL,
    "period" "text" NOT NULL,
    "sicil_no" "text" DEFAULT ''::"text",
    "tc_no" "text" DEFAULT ''::"text",
    "brut_maas" numeric(12,2) DEFAULT 0,
    "medeni_durum" "text" DEFAULT 'bekar'::"text",
    "cocuk_sayisi" integer DEFAULT 0,
    "normal_calisma_brut" numeric(12,2) DEFAULT 0,
    "normal_calisma_gun" integer DEFAULT 30,
    "fazla_mesai_50" numeric(12,2) DEFAULT 0,
    "fazla_mesai_50_saat" numeric(8,2) DEFAULT 0,
    "yol_yemek_yardimi" numeric(12,2) DEFAULT 0,
    "diger_kazanclar" numeric(12,2) DEFAULT 0,
    "sgk_isci_payi" numeric(12,2) DEFAULT 0,
    "sgk_isci_payi_oran" numeric(5,4) DEFAULT 0.14,
    "issizlik_sigortasi_isci" numeric(12,2) DEFAULT 0,
    "issizlik_sigortasi_isci_oran" numeric(5,4) DEFAULT 0.01,
    "gelir_vergisi" numeric(12,2) DEFAULT 0,
    "gelir_vergisi_oran" numeric(5,4) DEFAULT 0.15,
    "damga_vergisi" numeric(12,2) DEFAULT 0,
    "damga_vergisi_oran" numeric(5,4) DEFAULT 0.00759,
    "gelir_vergisi_matrahi" numeric(12,2) DEFAULT 0,
    "kumulatif_vergi_matrahi" numeric(12,2) DEFAULT 0,
    "sgk_isveren_payi" numeric(12,2) DEFAULT 0,
    "sgk_isveren_payi_oran" numeric(5,4) DEFAULT 0.205,
    "issizlik_isveren_payi" numeric(12,2) DEFAULT 0,
    "issizlik_isveren_payi_oran" numeric(5,4) DEFAULT 0.02,
    "toplam_kazanc" numeric(12,2) DEFAULT 0,
    "toplam_kesinti" numeric(12,2) DEFAULT 0,
    "net_maas" numeric(12,2) DEFAULT 0,
    "aciklama" "text" DEFAULT ''::"text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "emekli_bordro_items_medeni_durum_check" CHECK (("medeni_durum" = ANY (ARRAY['bekar'::"text", 'evli'::"text"])))
);


ALTER TABLE "public"."emekli_bordro_items" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."emekli_hesaplama_parametreleri" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "company_id" "uuid" NOT NULL,
    "kod" "text" NOT NULL,
    "ad" "text" NOT NULL,
    "oran" "text" DEFAULT ''::"text",
    "tutar" numeric(12,2) DEFAULT 0,
    "tip" "text" DEFAULT 'kazanc'::"text" NOT NULL,
    "aktif" boolean DEFAULT true,
    "sira" integer DEFAULT 0,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "emekli_hesaplama_parametreleri_tip_check" CHECK (("tip" = ANY (ARRAY['kazanc'::"text", 'kesinti'::"text", 'bilgi'::"text"])))
);


ALTER TABLE "public"."emekli_hesaplama_parametreleri" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."employee_passcodes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "employee_id" "uuid" NOT NULL,
    "passcode_hash" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "expires_at" timestamp with time zone
);


ALTER TABLE "public"."employee_passcodes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."employees" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "company_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "tc_no" "text" DEFAULT ''::"text",
    "sicil_no" "text" DEFAULT ''::"text",
    "department" "text" NOT NULL,
    "position" "text" NOT NULL,
    "level" "text" DEFAULT 'Junior'::"text" NOT NULL,
    "salary" numeric(12,2) DEFAULT 0,
    "status" "text" DEFAULT 'active'::"text" NOT NULL,
    "phone" "text" DEFAULT ''::"text",
    "email" "text" DEFAULT ''::"text",
    "join_date" "date" DEFAULT CURRENT_DATE,
    "address" "text" DEFAULT ''::"text",
    "avatar_url" "text",
    "skills" "text"[] DEFAULT '{}'::"text"[],
    "medeni_durum" "text" DEFAULT 'bekar'::"text",
    "cocuk_sayisi" integer DEFAULT 0,
    "engelli_durumu" "text" DEFAULT 'yok'::"text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "approval_passcode" "text",
    "employee_type" "text" DEFAULT 'normal'::"text",
    "approval_signature" "text",
    CONSTRAINT "employees_employee_type_check" CHECK (("employee_type" = ANY (ARRAY['normal'::"text", 'emekli'::"text"]))),
    CONSTRAINT "employees_engelli_durumu_check" CHECK (("engelli_durumu" = ANY (ARRAY['yok'::"text", 'birinci'::"text", 'ikinci'::"text", 'ucuncu'::"text"]))),
    CONSTRAINT "employees_level_check" CHECK (("level" = ANY (ARRAY['Junior'::"text", 'Mid'::"text", 'Senior'::"text", 'Lead'::"text", 'Manager'::"text"]))),
    CONSTRAINT "employees_medeni_durum_check" CHECK (("medeni_durum" = ANY (ARRAY['bekar'::"text", 'evli'::"text"]))),
    CONSTRAINT "employees_status_check" CHECK (("status" = ANY (ARRAY['active'::"text", 'onLeave'::"text", 'inactive'::"text"])))
);


ALTER TABLE "public"."employees" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."gorev_tanimi_approvals" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "gorev_tanimi_id" "uuid" NOT NULL,
    "employee_id" "uuid" NOT NULL,
    "employee_name" "text" NOT NULL,
    "verification_method" "text" NOT NULL,
    "signature_data" "text",
    "id_document_data" "text",
    "passcode_hash" "text",
    "approval_status" "text" NOT NULL,
    "ip_address" "text",
    "user_agent" "text",
    "timestamp" timestamp with time zone DEFAULT "now"(),
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "gorev_tanimi_approvals_approval_status_check" CHECK (("approval_status" = ANY (ARRAY['onaylandi'::"text", 'reddedildi'::"text"]))),
    CONSTRAINT "gorev_tanimi_approvals_verification_method_check" CHECK (("verification_method" = ANY (ARRAY['signature'::"text", 'id_document'::"text", 'passcode'::"text"])))
);


ALTER TABLE "public"."gorev_tanimi_approvals" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."gorev_tanimlari" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "company_id" "uuid" NOT NULL,
    "employee_id" "uuid" NOT NULL,
    "employee_name" "text" NOT NULL,
    "gorev_adi" "text" NOT NULL,
    "gorev_aciklama" "text" DEFAULT ''::"text",
    "sorumluluklar" "text"[] DEFAULT '{}'::"text"[],
    "yetki_ve_sorumluluklar" "text"[] DEFAULT '{}'::"text"[],
    "calismalar" "text"[] DEFAULT '{}'::"text"[],
    "performans_kriterleri" "text"[] DEFAULT '{}'::"text"[],
    "bagli_oldugu_pozisyon" "text" DEFAULT ''::"text",
    "is_birimi" "text" DEFAULT ''::"text",
    "olusturma_tarihi" timestamp with time zone DEFAULT "now"(),
    "onay_durumu" "text" DEFAULT 'beklemede'::"text",
    "onay_tarihi" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "gorev_tanimlari_onay_durumu_check" CHECK (("onay_durumu" = ANY (ARRAY['beklemede'::"text", 'onaylandi'::"text", 'reddedildi'::"text"])))
);


ALTER TABLE "public"."gorev_tanimlari" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."izin_haklari" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "company_id" "uuid" NOT NULL,
    "employee_id" "uuid" NOT NULL,
    "yil" integer NOT NULL,
    "toplam_hak" numeric(5,1) DEFAULT 0,
    "kullanilan_izin" numeric(5,1) DEFAULT 0,
    "kalan_izin" numeric(5,1) DEFAULT 0,
    "calisma_yili" integer DEFAULT 0,
    "ise_giris_tarihi" "date",
    "hesaplama_tarihi" "date" DEFAULT CURRENT_DATE,
    "mazeret_izin" numeric(5,1) DEFAULT 0,
    "hastalik_izin" numeric(5,1) DEFAULT 0,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."izin_haklari" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."izin_onaycilar" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "company_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "department" "text",
    "yetki_seviyesi" "text" DEFAULT 'departman'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "izin_onaycilar_yetki_seviyesi_check" CHECK (("yetki_seviyesi" = ANY (ARRAY['departman'::"text", 'genel'::"text", 'ik'::"text"])))
);


ALTER TABLE "public"."izin_onaycilar" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."izin_talepleri" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "company_id" "uuid" NOT NULL,
    "employee_id" "uuid" NOT NULL,
    "izin_turu" "text" NOT NULL,
    "baslangic_tarihi" "date" NOT NULL,
    "bitis_tarihi" "date" NOT NULL,
    "gun_sayisi" integer DEFAULT 0 NOT NULL,
    "aciklama" "text" DEFAULT ''::"text",
    "yol_izni_talep" boolean DEFAULT false,
    "yol_izni_gun" integer DEFAULT 0,
    "seyahat_yeri" "text" DEFAULT ''::"text",
    "il_disi_seyahat" boolean DEFAULT false,
    "belge_url" "text",
    "durum" "text" DEFAULT 'beklemede'::"text" NOT NULL,
    "onaylayan_id" "uuid",
    "onay_tarihi" timestamp with time zone,
    "red_nedeni" "text",
    "talep_tarihi" "date" DEFAULT CURRENT_DATE,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "izin_talepleri_durum_check" CHECK (("durum" = ANY (ARRAY['beklemede'::"text", 'onaylandi'::"text", 'reddedildi'::"text", 'iptal'::"text"]))),
    CONSTRAINT "izin_talepleri_izin_turu_check" CHECK (("izin_turu" = ANY (ARRAY['yillik'::"text", 'mazeret'::"text", 'hastalik'::"text", 'dogum'::"text", 'babalik'::"text", 'evlilik'::"text", 'olum'::"text", 'askerlik'::"text", 'ucretsiz'::"text"]))),
    CONSTRAINT "valid_date_range" CHECK (("bitis_tarihi" >= "baslangic_tarihi"))
);


ALTER TABLE "public"."izin_talepleri" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ozluk_dosyalari" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "employee_id" "uuid" NOT NULL,
    "company_id" "uuid" NOT NULL,
    "kategori" "text" DEFAULT 'diger'::"text" NOT NULL,
    "dosya_adi" "text",
    "dosya_yolu" "text",
    "notlar" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."ozluk_dosyalari" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" NOT NULL,
    "email" "text" NOT NULL,
    "full_name" "text" NOT NULL,
    "company_id" "uuid",
    "role" "text" DEFAULT 'employee'::"text" NOT NULL,
    "avatar_url" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "profiles_role_check" CHECK (("role" = ANY (ARRAY['superadmin'::"text", 'admin'::"text", 'manager'::"text", 'employee'::"text", 'hr'::"text", 'user'::"text"])))
);


ALTER TABLE "public"."profiles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."sistem_parametreleri" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "company_id" "uuid" NOT NULL,
    "kategori" "text" NOT NULL,
    "ad" "text" NOT NULL,
    "deger" "text" NOT NULL,
    "aciklama" "text" DEFAULT ''::"text",
    "zorunlu" boolean DEFAULT false,
    "degistirilebilir" boolean DEFAULT true,
    "yapilandirma_tarihi" timestamp with time zone DEFAULT "now"(),
    "son_guncelleme" timestamp with time zone DEFAULT "now"(),
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "sistem_parametreleri_kategori_check" CHECK (("kategori" = ANY (ARRAY['is_kanunu'::"text", 'bordro_sgk'::"text", 'vergi_sigorta'::"text", 'egitim'::"text", 'belge_kurallari'::"text", 'sistem_kurallari'::"text", 'sirket_bilgileri'::"text"])))
);


ALTER TABLE "public"."sistem_parametreleri" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."takvim_gunleri" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "company_id" "uuid",
    "tarih" "date" NOT NULL,
    "ad" "text" NOT NULL,
    "tur" "text" DEFAULT 'resmi_tatil'::"text" NOT NULL,
    "aciklama" "text" DEFAULT ''::"text",
    "calisma_gunu_mu" boolean DEFAULT false,
    "yil" integer NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "takvim_gunleri_tur_check" CHECK (("tur" = ANY (ARRAY['resmi_tatil'::"text", 'dini_bayram'::"text", 'ozel_gun'::"text", 'firma_ozel'::"text"])))
);


ALTER TABLE "public"."takvim_gunleri" OWNER TO "postgres";


ALTER TABLE ONLY "public"."aktivite_loglari"
    ADD CONSTRAINT "aktivite_loglari_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."bildirimler"
    ADD CONSTRAINT "bildirimler_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."bordro_approvals"
    ADD CONSTRAINT "bordro_approvals_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."bordro_calculation_rates"
    ADD CONSTRAINT "bordro_calculation_rates_company_id_yil_key" UNIQUE ("company_id", "yil");



ALTER TABLE ONLY "public"."bordro_calculation_rates"
    ADD CONSTRAINT "bordro_calculation_rates_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."bordro_items"
    ADD CONSTRAINT "bordro_items_employee_id_period_key" UNIQUE ("employee_id", "period");



ALTER TABLE ONLY "public"."bordro_items"
    ADD CONSTRAINT "bordro_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."bordro_templates"
    ADD CONSTRAINT "bordro_templates_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."companies"
    ADD CONSTRAINT "companies_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."emekli_bordro_items"
    ADD CONSTRAINT "emekli_bordro_items_employee_id_period_key" UNIQUE ("employee_id", "period");



ALTER TABLE ONLY "public"."emekli_bordro_items"
    ADD CONSTRAINT "emekli_bordro_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."emekli_hesaplama_parametreleri"
    ADD CONSTRAINT "emekli_hesaplama_parametreleri_company_id_kod_key" UNIQUE ("company_id", "kod");



ALTER TABLE ONLY "public"."emekli_hesaplama_parametreleri"
    ADD CONSTRAINT "emekli_hesaplama_parametreleri_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."employee_passcodes"
    ADD CONSTRAINT "employee_passcodes_employee_id_key" UNIQUE ("employee_id");



ALTER TABLE ONLY "public"."employee_passcodes"
    ADD CONSTRAINT "employee_passcodes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."employees"
    ADD CONSTRAINT "employees_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."gorev_tanimi_approvals"
    ADD CONSTRAINT "gorev_tanimi_approvals_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."gorev_tanimlari"
    ADD CONSTRAINT "gorev_tanimlari_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."izin_haklari"
    ADD CONSTRAINT "izin_haklari_employee_id_yil_key" UNIQUE ("employee_id", "yil");



ALTER TABLE ONLY "public"."izin_haklari"
    ADD CONSTRAINT "izin_haklari_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."izin_onaycilar"
    ADD CONSTRAINT "izin_onaycilar_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."izin_onaycilar"
    ADD CONSTRAINT "izin_onaycilar_user_id_department_key" UNIQUE ("user_id", "department");



ALTER TABLE ONLY "public"."izin_talepleri"
    ADD CONSTRAINT "izin_talepleri_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ozluk_dosyalari"
    ADD CONSTRAINT "ozluk_dosyalari_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."sistem_parametreleri"
    ADD CONSTRAINT "sistem_parametreleri_company_id_kategori_ad_key" UNIQUE ("company_id", "kategori", "ad");



ALTER TABLE ONLY "public"."sistem_parametreleri"
    ADD CONSTRAINT "sistem_parametreleri_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."takvim_gunleri"
    ADD CONSTRAINT "takvim_gunleri_pkey" PRIMARY KEY ("id");



CREATE INDEX "idx_aktivite_loglari_company_id" ON "public"."aktivite_loglari" USING "btree" ("company_id");



CREATE INDEX "idx_aktivite_loglari_created_at" ON "public"."aktivite_loglari" USING "btree" ("created_at");



CREATE INDEX "idx_aktivite_loglari_user_id" ON "public"."aktivite_loglari" USING "btree" ("user_id");



CREATE INDEX "idx_bildirimler_company_id" ON "public"."bildirimler" USING "btree" ("company_id");



CREATE INDEX "idx_bildirimler_okundu_mu" ON "public"."bildirimler" USING "btree" ("okundu_mu");



CREATE INDEX "idx_bildirimler_user_id" ON "public"."bildirimler" USING "btree" ("user_id");



CREATE INDEX "idx_bordro_approvals_bordro_id" ON "public"."bordro_approvals" USING "btree" ("bordro_id");



CREATE INDEX "idx_bordro_approvals_company_id" ON "public"."bordro_approvals" USING "btree" ("company_id");



CREATE INDEX "idx_bordro_approvals_employee_id" ON "public"."bordro_approvals" USING "btree" ("employee_id");



CREATE INDEX "idx_bordro_calculation_rates_company_id" ON "public"."bordro_calculation_rates" USING "btree" ("company_id");



CREATE INDEX "idx_bordro_calculation_rates_yil" ON "public"."bordro_calculation_rates" USING "btree" ("yil");



CREATE INDEX "idx_bordro_items_company_id" ON "public"."bordro_items" USING "btree" ("company_id");



CREATE INDEX "idx_bordro_items_employee_id" ON "public"."bordro_items" USING "btree" ("employee_id");



CREATE INDEX "idx_bordro_items_period" ON "public"."bordro_items" USING "btree" ("period");



CREATE INDEX "idx_bordro_templates_company_id" ON "public"."bordro_templates" USING "btree" ("company_id");



CREATE INDEX "idx_emekli_bordro_items_company_id" ON "public"."emekli_bordro_items" USING "btree" ("company_id");



CREATE INDEX "idx_emekli_bordro_items_employee_id" ON "public"."emekli_bordro_items" USING "btree" ("employee_id");



CREATE INDEX "idx_emekli_bordro_items_period" ON "public"."emekli_bordro_items" USING "btree" ("period");



CREATE INDEX "idx_emekli_hesaplama_parametreleri_company_id" ON "public"."emekli_hesaplama_parametreleri" USING "btree" ("company_id");



CREATE INDEX "idx_emekli_hesaplama_parametreleri_tip" ON "public"."emekli_hesaplama_parametreleri" USING "btree" ("tip");



CREATE INDEX "idx_employee_passcodes_employee" ON "public"."employee_passcodes" USING "btree" ("employee_id");



CREATE INDEX "idx_employees_company_id" ON "public"."employees" USING "btree" ("company_id");



CREATE INDEX "idx_employees_department" ON "public"."employees" USING "btree" ("department");



CREATE INDEX "idx_employees_status" ON "public"."employees" USING "btree" ("status");



CREATE INDEX "idx_gorev_tanimi_approvals_employee" ON "public"."gorev_tanimi_approvals" USING "btree" ("employee_id");



CREATE INDEX "idx_gorev_tanimi_approvals_gorev" ON "public"."gorev_tanimi_approvals" USING "btree" ("gorev_tanimi_id");



CREATE INDEX "idx_gorev_tanimlari_company" ON "public"."gorev_tanimlari" USING "btree" ("company_id");



CREATE INDEX "idx_gorev_tanimlari_employee" ON "public"."gorev_tanimlari" USING "btree" ("employee_id");



CREATE INDEX "idx_gorev_tanimlari_onay_durumu" ON "public"."gorev_tanimlari" USING "btree" ("onay_durumu");



CREATE INDEX "idx_izin_haklari_company_id" ON "public"."izin_haklari" USING "btree" ("company_id");



CREATE INDEX "idx_izin_haklari_employee_id" ON "public"."izin_haklari" USING "btree" ("employee_id");



CREATE INDEX "idx_izin_haklari_yil" ON "public"."izin_haklari" USING "btree" ("yil");



CREATE INDEX "idx_izin_onaycilar_company_id" ON "public"."izin_onaycilar" USING "btree" ("company_id");



CREATE INDEX "idx_izin_onaycilar_user_id" ON "public"."izin_onaycilar" USING "btree" ("user_id");



CREATE INDEX "idx_izin_talepleri_company_id" ON "public"."izin_talepleri" USING "btree" ("company_id");



CREATE INDEX "idx_izin_talepleri_durum" ON "public"."izin_talepleri" USING "btree" ("durum");



CREATE INDEX "idx_izin_talepleri_employee_id" ON "public"."izin_talepleri" USING "btree" ("employee_id");



CREATE INDEX "idx_izin_talepleri_tarih" ON "public"."izin_talepleri" USING "btree" ("baslangic_tarihi", "bitis_tarihi");



CREATE INDEX "idx_profiles_company_id" ON "public"."profiles" USING "btree" ("company_id");



CREATE INDEX "idx_profiles_email" ON "public"."profiles" USING "btree" ("email");



CREATE INDEX "idx_sistem_parametreleri_company_id" ON "public"."sistem_parametreleri" USING "btree" ("company_id");



CREATE INDEX "idx_sistem_parametreleri_kategori" ON "public"."sistem_parametreleri" USING "btree" ("kategori");



CREATE INDEX "idx_takvim_gunleri_company_id" ON "public"."takvim_gunleri" USING "btree" ("company_id");



CREATE INDEX "idx_takvim_gunleri_tarih" ON "public"."takvim_gunleri" USING "btree" ("tarih");



CREATE INDEX "idx_takvim_gunleri_yil" ON "public"."takvim_gunleri" USING "btree" ("yil");



CREATE INDEX "ozluk_dosyalari_company_idx" ON "public"."ozluk_dosyalari" USING "btree" ("company_id");



CREATE INDEX "ozluk_dosyalari_employee_idx" ON "public"."ozluk_dosyalari" USING "btree" ("employee_id");



CREATE OR REPLACE TRIGGER "ozluk_dosyalari_updated_at" BEFORE UPDATE ON "public"."ozluk_dosyalari" FOR EACH ROW EXECUTE FUNCTION "public"."update_ozluk_dosyalari_updated_at"();



CREATE OR REPLACE TRIGGER "trigger_calculate_kalan_izin" BEFORE INSERT OR UPDATE ON "public"."izin_haklari" FOR EACH ROW EXECUTE FUNCTION "public"."calculate_kalan_izin"();



CREATE OR REPLACE TRIGGER "trigger_update_gorev_tanimlari_updated_at" BEFORE UPDATE ON "public"."gorev_tanimlari" FOR EACH ROW EXECUTE FUNCTION "public"."update_gorev_tanimlari_updated_at"();



CREATE OR REPLACE TRIGGER "update_bildirimler_updated_at" BEFORE UPDATE ON "public"."bildirimler" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_bordro_calculation_rates_updated_at" BEFORE UPDATE ON "public"."bordro_calculation_rates" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_bordro_items_updated_at" BEFORE UPDATE ON "public"."bordro_items" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_bordro_templates_updated_at" BEFORE UPDATE ON "public"."bordro_templates" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_companies_updated_at" BEFORE UPDATE ON "public"."companies" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_emekli_bordro_items_updated_at" BEFORE UPDATE ON "public"."emekli_bordro_items" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_emekli_hesaplama_parametreleri_updated_at" BEFORE UPDATE ON "public"."emekli_hesaplama_parametreleri" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_employees_updated_at" BEFORE UPDATE ON "public"."employees" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_izin_haklari_updated_at" BEFORE UPDATE ON "public"."izin_haklari" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_izin_onaycilar_updated_at" BEFORE UPDATE ON "public"."izin_onaycilar" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_izin_talepleri_updated_at" BEFORE UPDATE ON "public"."izin_talepleri" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_profiles_updated_at" BEFORE UPDATE ON "public"."profiles" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_sistem_parametreleri_updated_at" BEFORE UPDATE ON "public"."sistem_parametreleri" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_takvim_gunleri_updated_at" BEFORE UPDATE ON "public"."takvim_gunleri" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



ALTER TABLE ONLY "public"."aktivite_loglari"
    ADD CONSTRAINT "aktivite_loglari_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."aktivite_loglari"
    ADD CONSTRAINT "aktivite_loglari_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."bildirimler"
    ADD CONSTRAINT "bildirimler_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."bildirimler"
    ADD CONSTRAINT "bildirimler_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."bordro_approvals"
    ADD CONSTRAINT "bordro_approvals_bordro_id_fkey" FOREIGN KEY ("bordro_id") REFERENCES "public"."bordro_items"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."bordro_approvals"
    ADD CONSTRAINT "bordro_approvals_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."bordro_approvals"
    ADD CONSTRAINT "bordro_approvals_employee_id_fkey" FOREIGN KEY ("employee_id") REFERENCES "public"."employees"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."bordro_calculation_rates"
    ADD CONSTRAINT "bordro_calculation_rates_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."bordro_items"
    ADD CONSTRAINT "bordro_items_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."bordro_items"
    ADD CONSTRAINT "bordro_items_employee_id_fkey" FOREIGN KEY ("employee_id") REFERENCES "public"."employees"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."bordro_templates"
    ADD CONSTRAINT "bordro_templates_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."emekli_bordro_items"
    ADD CONSTRAINT "emekli_bordro_items_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."emekli_bordro_items"
    ADD CONSTRAINT "emekli_bordro_items_employee_id_fkey" FOREIGN KEY ("employee_id") REFERENCES "public"."employees"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."emekli_hesaplama_parametreleri"
    ADD CONSTRAINT "emekli_hesaplama_parametreleri_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."employee_passcodes"
    ADD CONSTRAINT "employee_passcodes_employee_id_fkey" FOREIGN KEY ("employee_id") REFERENCES "public"."employees"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."employees"
    ADD CONSTRAINT "employees_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."gorev_tanimi_approvals"
    ADD CONSTRAINT "gorev_tanimi_approvals_employee_id_fkey" FOREIGN KEY ("employee_id") REFERENCES "public"."employees"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."gorev_tanimi_approvals"
    ADD CONSTRAINT "gorev_tanimi_approvals_gorev_tanimi_id_fkey" FOREIGN KEY ("gorev_tanimi_id") REFERENCES "public"."gorev_tanimlari"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."gorev_tanimlari"
    ADD CONSTRAINT "gorev_tanimlari_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."gorev_tanimlari"
    ADD CONSTRAINT "gorev_tanimlari_employee_id_fkey" FOREIGN KEY ("employee_id") REFERENCES "public"."employees"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."izin_haklari"
    ADD CONSTRAINT "izin_haklari_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."izin_haklari"
    ADD CONSTRAINT "izin_haklari_employee_id_fkey" FOREIGN KEY ("employee_id") REFERENCES "public"."employees"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."izin_onaycilar"
    ADD CONSTRAINT "izin_onaycilar_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."izin_onaycilar"
    ADD CONSTRAINT "izin_onaycilar_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."izin_talepleri"
    ADD CONSTRAINT "izin_talepleri_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."izin_talepleri"
    ADD CONSTRAINT "izin_talepleri_employee_id_fkey" FOREIGN KEY ("employee_id") REFERENCES "public"."employees"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."izin_talepleri"
    ADD CONSTRAINT "izin_talepleri_onaylayan_id_fkey" FOREIGN KEY ("onaylayan_id") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."ozluk_dosyalari"
    ADD CONSTRAINT "ozluk_dosyalari_employee_id_fkey" FOREIGN KEY ("employee_id") REFERENCES "public"."employees"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."sistem_parametreleri"
    ADD CONSTRAINT "sistem_parametreleri_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."takvim_gunleri"
    ADD CONSTRAINT "takvim_gunleri_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE CASCADE;



CREATE POLICY "Admins can delete their company" ON "public"."companies" FOR DELETE TO "authenticated" USING (("id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = 'admin'::"text")))));



CREATE POLICY "Admins can insert companies" ON "public"."companies" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = 'admin'::"text")))));



CREATE POLICY "Admins can manage calculation rates" ON "public"."bordro_calculation_rates" TO "authenticated" USING (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = 'admin'::"text"))))) WITH CHECK (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = 'admin'::"text")))));



CREATE POLICY "Admins can manage izin onaycilar" ON "public"."izin_onaycilar" TO "authenticated" USING (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = 'admin'::"text"))))) WITH CHECK (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = 'admin'::"text")))));



CREATE POLICY "Admins can manage passcodes" ON "public"."employee_passcodes" TO "authenticated" USING (("employee_id" IN ( SELECT "e"."id"
   FROM ("public"."employees" "e"
     JOIN "public"."profiles" "p" ON (("p"."company_id" = "e"."company_id")))
  WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role" = ANY (ARRAY['admin'::"text", 'hr'::"text"])))))) WITH CHECK (("employee_id" IN ( SELECT "e"."id"
   FROM ("public"."employees" "e"
     JOIN "public"."profiles" "p" ON (("p"."company_id" = "e"."company_id")))
  WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role" = ANY (ARRAY['admin'::"text", 'hr'::"text"]))))));



CREATE POLICY "Admins can manage sistem parametreleri" ON "public"."sistem_parametreleri" TO "authenticated" USING (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = 'admin'::"text"))))) WITH CHECK (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = 'admin'::"text")))));



CREATE POLICY "Admins can update their company" ON "public"."companies" FOR UPDATE TO "authenticated" USING (("id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"text", 'hr'::"text"])))))) WITH CHECK (("id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"text", 'hr'::"text"]))))));



CREATE POLICY "Admins can view aktivite loglari in their company" ON "public"."aktivite_loglari" FOR SELECT TO "authenticated" USING (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = 'admin'::"text")))));



CREATE POLICY "Anyone can view companies" ON "public"."companies" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Authenticated users can create approvals" ON "public"."bordro_approvals" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Authenticated users can insert companies" ON "public"."companies" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Authenticated users can insert own profile" ON "public"."profiles" FOR INSERT TO "authenticated" WITH CHECK ((("id" = "auth"."uid"()) OR ("role" = 'superadmin'::"text")));



CREATE POLICY "Authenticated users can view all profiles" ON "public"."profiles" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Authenticated users can view approvals" ON "public"."bordro_approvals" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Employees can create their own izin talepleri" ON "public"."izin_talepleri" FOR INSERT TO "authenticated" WITH CHECK (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"()))));



CREATE POLICY "Employees can update their own bordro approval status" ON "public"."bordro_items" FOR UPDATE TO "authenticated" USING (("employee_id" IN ( SELECT "employees"."id"
   FROM "public"."employees"
  WHERE (("employees"."email" = ( SELECT "profiles"."email"
           FROM "public"."profiles"
          WHERE ("profiles"."id" = "auth"."uid"()))) AND ("employees"."company_id" IN ( SELECT "profiles"."company_id"
           FROM "public"."profiles"
          WHERE ("profiles"."id" = "auth"."uid"()))))))) WITH CHECK (("employee_id" IN ( SELECT "employees"."id"
   FROM "public"."employees"
  WHERE (("employees"."email" = ( SELECT "profiles"."email"
           FROM "public"."profiles"
          WHERE ("profiles"."id" = "auth"."uid"()))) AND ("employees"."company_id" IN ( SELECT "profiles"."company_id"
           FROM "public"."profiles"
          WHERE ("profiles"."id" = "auth"."uid"())))))));



CREATE POLICY "Employees can view their own bordro" ON "public"."bordro_items" FOR SELECT TO "authenticated" USING (("employee_id" IN ( SELECT "employees"."id"
   FROM "public"."employees"
  WHERE (("employees"."email" = ( SELECT "profiles"."email"
           FROM "public"."profiles"
          WHERE ("profiles"."id" = "auth"."uid"()))) AND ("employees"."company_id" IN ( SELECT "profiles"."company_id"
           FROM "public"."profiles"
          WHERE ("profiles"."id" = "auth"."uid"())))))));



CREATE POLICY "Employees can view their own emekli bordro" ON "public"."emekli_bordro_items" FOR SELECT TO "authenticated" USING (("employee_id" IN ( SELECT "employees"."id"
   FROM "public"."employees"
  WHERE (("employees"."email" = ( SELECT "profiles"."email"
           FROM "public"."profiles"
          WHERE ("profiles"."id" = "auth"."uid"()))) AND ("employees"."company_id" IN ( SELECT "profiles"."company_id"
           FROM "public"."profiles"
          WHERE ("profiles"."id" = "auth"."uid"())))))));



CREATE POLICY "Everyone can view takvim gunleri" ON "public"."takvim_gunleri" FOR SELECT TO "authenticated" USING ((("company_id" IS NULL) OR ("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())))));



CREATE POLICY "HR and admins can create bildirimler" ON "public"."bildirimler" FOR INSERT TO "authenticated" WITH CHECK (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"text", 'hr'::"text", 'manager'::"text"]))))));



CREATE POLICY "HR and admins can delete bildirimler" ON "public"."bildirimler" FOR DELETE TO "authenticated" USING (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"text", 'hr'::"text"]))))));



CREATE POLICY "HR and admins can delete employees in their company" ON "public"."employees" FOR DELETE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND (("p"."role" = 'superadmin'::"text") OR (("p"."role" = ANY (ARRAY['admin'::"text", 'hr'::"text"])) AND ("p"."company_id" = "employees"."company_id")))))));



CREATE POLICY "HR and admins can delete izin haklari" ON "public"."izin_haklari" FOR DELETE TO "authenticated" USING (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = 'admin'::"text")))));



CREATE POLICY "HR and admins can delete izin talepleri" ON "public"."izin_talepleri" FOR DELETE TO "authenticated" USING (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"text", 'hr'::"text"]))))));



CREATE POLICY "HR and admins can manage izin haklari" ON "public"."izin_haklari" FOR INSERT TO "authenticated" WITH CHECK (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"text", 'hr'::"text"]))))));



CREATE POLICY "HR and admins can manage takvim gunleri" ON "public"."takvim_gunleri" TO "authenticated" USING (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"text", 'hr'::"text"])))))) WITH CHECK (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"text", 'hr'::"text"]))))));



CREATE POLICY "HR and admins can update employees in their company" ON "public"."employees" FOR UPDATE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND (("p"."role" = 'superadmin'::"text") OR (("p"."role" = ANY (ARRAY['admin'::"text", 'hr'::"text", 'manager'::"text"])) AND ("p"."company_id" = "employees"."company_id"))))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND (("p"."role" = 'superadmin'::"text") OR (("p"."role" = ANY (ARRAY['admin'::"text", 'hr'::"text", 'manager'::"text"])) AND ("p"."company_id" = "employees"."company_id")))))));



CREATE POLICY "HR and admins can update izin haklari" ON "public"."izin_haklari" FOR UPDATE TO "authenticated" USING (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"text", 'hr'::"text"])))))) WITH CHECK (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"text", 'hr'::"text"]))))));



CREATE POLICY "HR and managers can update izin talepleri" ON "public"."izin_talepleri" FOR UPDATE TO "authenticated" USING (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"text", 'hr'::"text", 'manager'::"text"])))))) WITH CHECK (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"text", 'hr'::"text", 'manager'::"text"]))))));



CREATE POLICY "HR can create emekli bordro items" ON "public"."emekli_bordro_items" FOR INSERT TO "authenticated" WITH CHECK (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"text", 'hr'::"text"]))))));



CREATE POLICY "HR can delete bordro items" ON "public"."bordro_items" FOR DELETE TO "authenticated" USING (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"text", 'hr'::"text"]))))));



CREATE POLICY "HR can delete emekli bordro items" ON "public"."emekli_bordro_items" FOR DELETE TO "authenticated" USING (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"text", 'hr'::"text"]))))));



CREATE POLICY "HR can manage bordro items" ON "public"."bordro_items" TO "authenticated" USING (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"text", 'hr'::"text"])))))) WITH CHECK (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"text", 'hr'::"text"]))))));



CREATE POLICY "HR can manage emekli parameters" ON "public"."emekli_hesaplama_parametreleri" TO "authenticated" USING (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"text", 'hr'::"text"])))))) WITH CHECK (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"text", 'hr'::"text"]))))));



CREATE POLICY "HR can manage employees in their company" ON "public"."employees" TO "authenticated" USING (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"text", 'hr'::"text"])))))) WITH CHECK (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"text", 'hr'::"text"]))))));



CREATE POLICY "HR can manage templates" ON "public"."bordro_templates" TO "authenticated" USING (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"text", 'hr'::"text"])))))) WITH CHECK (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"text", 'hr'::"text"]))))));



CREATE POLICY "HR can update bordro items" ON "public"."bordro_items" FOR UPDATE TO "authenticated" USING (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"text", 'hr'::"text"])))))) WITH CHECK (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"text", 'hr'::"text"]))))));



CREATE POLICY "HR can update emekli bordro items" ON "public"."emekli_bordro_items" FOR UPDATE TO "authenticated" USING (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"text", 'hr'::"text"])))))) WITH CHECK (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"text", 'hr'::"text"]))))));



CREATE POLICY "HR can view all bordro items in their company" ON "public"."bordro_items" FOR SELECT TO "authenticated" USING (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"text", 'hr'::"text", 'manager'::"text"]))))));



CREATE POLICY "HR can view all emekli bordro items in their company" ON "public"."emekli_bordro_items" FOR SELECT TO "authenticated" USING (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"text", 'hr'::"text", 'manager'::"text"]))))));



CREATE POLICY "Managers can manage bordro items" ON "public"."bordro_items" TO "authenticated" USING (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = 'manager'::"text"))))) WITH CHECK (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = 'manager'::"text")))));



CREATE POLICY "Managers can update bordro approval status" ON "public"."bordro_items" FOR UPDATE TO "authenticated" USING (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = 'manager'::"text"))))) WITH CHECK (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = 'manager'::"text")))));



CREATE POLICY "Managers, HR and admins can insert employees" ON "public"."employees" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND (("p"."role" = 'superadmin'::"text") OR (("p"."role" = ANY (ARRAY['admin'::"text", 'hr'::"text", 'manager'::"text"])) AND ("p"."company_id" = "employees"."company_id")))))));



CREATE POLICY "Superadmin can manage all gorev tanimi approvals" ON "public"."gorev_tanimi_approvals" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['superadmin'::"text", 'admin'::"text"])))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['superadmin'::"text", 'admin'::"text"]))))));



CREATE POLICY "Superadmin can manage all gorev tanimlari" ON "public"."gorev_tanimlari" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['superadmin'::"text", 'admin'::"text"])))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['superadmin'::"text", 'admin'::"text"]))))));



CREATE POLICY "Superadmin can manage all izin talepleri" ON "public"."izin_talepleri" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role" = 'superadmin'::"text"))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role" = 'superadmin'::"text")))));



CREATE POLICY "System can insert aktivite loglari" ON "public"."aktivite_loglari" FOR INSERT TO "authenticated" WITH CHECK (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"()))));



CREATE POLICY "Users can create approval records" ON "public"."gorev_tanimi_approvals" FOR INSERT TO "authenticated" WITH CHECK (("employee_id" IN ( SELECT "employees"."id"
   FROM "public"."employees"
  WHERE ("employees"."company_id" IN ( SELECT "profiles"."company_id"
           FROM "public"."profiles"
          WHERE ("profiles"."id" = "auth"."uid"()))))));



CREATE POLICY "Users can create approvals for their company" ON "public"."bordro_approvals" FOR INSERT TO "authenticated" WITH CHECK (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"()))));



CREATE POLICY "Users can create bordro items for their company" ON "public"."bordro_items" FOR INSERT TO "authenticated" WITH CHECK (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"()))));



CREATE POLICY "Users can create gorev tanimlari for their company" ON "public"."gorev_tanimlari" FOR INSERT TO "authenticated" WITH CHECK (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"()))));



CREATE POLICY "Users can create their own profile" ON "public"."profiles" FOR INSERT TO "authenticated" WITH CHECK (("id" = "auth"."uid"()));



CREATE POLICY "Users can delete gorev tanimlari from their company" ON "public"."gorev_tanimlari" FOR DELETE TO "authenticated" USING (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"()))));



CREATE POLICY "Users can delete own company" ON "public"."companies" FOR DELETE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."company_id" = "companies"."id") AND ("profiles"."id" = "auth"."uid"())))));



CREATE POLICY "Users can delete own profile" ON "public"."profiles" FOR DELETE TO "authenticated" USING (("id" = "auth"."uid"()));



CREATE POLICY "Users can manage gorev tanimlari for their company" ON "public"."gorev_tanimlari" TO "authenticated" USING (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())))) WITH CHECK (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"()))));



CREATE POLICY "Users can update gorev tanimlari from their company" ON "public"."gorev_tanimlari" FOR UPDATE TO "authenticated" USING (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())))) WITH CHECK (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"()))));



CREATE POLICY "Users can update own company" ON "public"."companies" FOR UPDATE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."company_id" = "companies"."id") AND ("profiles"."id" = "auth"."uid"()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."company_id" = "companies"."id") AND ("profiles"."id" = "auth"."uid"())))));



CREATE POLICY "Users can update own profile" ON "public"."profiles" FOR UPDATE TO "authenticated" USING (("id" = "auth"."uid"())) WITH CHECK (("id" = "auth"."uid"()));



CREATE POLICY "Users can update their own bildirimler" ON "public"."bildirimler" FOR UPDATE TO "authenticated" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can view approval records from their company" ON "public"."gorev_tanimi_approvals" FOR SELECT TO "authenticated" USING (("employee_id" IN ( SELECT "employees"."id"
   FROM "public"."employees"
  WHERE ("employees"."company_id" IN ( SELECT "profiles"."company_id"
           FROM "public"."profiles"
          WHERE ("profiles"."id" = "auth"."uid"()))))));



CREATE POLICY "Users can view approvals of their company" ON "public"."bordro_approvals" FOR SELECT TO "authenticated" USING (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"()))));



CREATE POLICY "Users can view calculation rates in their company" ON "public"."bordro_calculation_rates" FOR SELECT TO "authenticated" USING (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"()))));



CREATE POLICY "Users can view emekli parameters in their company" ON "public"."emekli_hesaplama_parametreleri" FOR SELECT TO "authenticated" USING (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"()))));



CREATE POLICY "Users can view employees in their company" ON "public"."employees" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND (("p"."role" = 'superadmin'::"text") OR ("p"."company_id" = "employees"."company_id"))))));



CREATE POLICY "Users can view gorev tanimlari from their company" ON "public"."gorev_tanimlari" FOR SELECT TO "authenticated" USING (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"()))));



CREATE POLICY "Users can view izin haklari in their company" ON "public"."izin_haklari" FOR SELECT TO "authenticated" USING (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"()))));



CREATE POLICY "Users can view izin onaycilar in their company" ON "public"."izin_onaycilar" FOR SELECT TO "authenticated" USING (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"()))));



CREATE POLICY "Users can view izin talepleri in their company" ON "public"."izin_talepleri" FOR SELECT TO "authenticated" USING (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"()))));



CREATE POLICY "Users can view passcodes from their company" ON "public"."employee_passcodes" FOR SELECT TO "authenticated" USING (("employee_id" IN ( SELECT "employees"."id"
   FROM "public"."employees"
  WHERE ("employees"."company_id" IN ( SELECT "profiles"."company_id"
           FROM "public"."profiles"
          WHERE ("profiles"."id" = "auth"."uid"()))))));



CREATE POLICY "Users can view profiles in their company" ON "public"."profiles" FOR SELECT TO "authenticated" USING (("company_id" IN ( SELECT "profiles_1"."company_id"
   FROM "public"."profiles" "profiles_1"
  WHERE ("profiles_1"."id" = "auth"."uid"()))));



CREATE POLICY "Users can view sistem parametreleri in their company" ON "public"."sistem_parametreleri" FOR SELECT TO "authenticated" USING (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"()))));



CREATE POLICY "Users can view templates in their company" ON "public"."bordro_templates" FOR SELECT TO "authenticated" USING (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"()))));



CREATE POLICY "Users can view their own bildirimler" ON "public"."bildirimler" FOR SELECT TO "authenticated" USING ((("user_id" = "auth"."uid"()) OR (("user_id" IS NULL) AND ("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"()))))));



CREATE POLICY "Users can view their own company" ON "public"."companies" FOR SELECT TO "authenticated" USING (("id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"()))));



ALTER TABLE "public"."aktivite_loglari" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."bildirimler" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."bordro_approvals" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."bordro_calculation_rates" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."bordro_items" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."bordro_templates" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."companies" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "company_members_ozluk" ON "public"."ozluk_dosyalari" USING (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."company_id" IS NOT NULL))))) WITH CHECK (("company_id" IN ( SELECT "profiles"."company_id"
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."company_id" IS NOT NULL)))));



ALTER TABLE "public"."emekli_bordro_items" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."emekli_hesaplama_parametreleri" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."employee_passcodes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."employees" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."gorev_tanimi_approvals" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."gorev_tanimlari" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."izin_haklari" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."izin_onaycilar" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."izin_talepleri" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."ozluk_dosyalari" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."sistem_parametreleri" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."takvim_gunleri" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";





GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";































































































































































GRANT ALL ON FUNCTION "public"."admin_delete_user_profile"("target_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."admin_delete_user_profile"("target_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."admin_delete_user_profile"("target_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."admin_update_user_profile"("target_id" "uuid", "new_role" "text", "new_full_name" "text", "new_company_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."admin_update_user_profile"("target_id" "uuid", "new_role" "text", "new_full_name" "text", "new_company_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."admin_update_user_profile"("target_id" "uuid", "new_role" "text", "new_full_name" "text", "new_company_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."calculate_kalan_izin"() TO "anon";
GRANT ALL ON FUNCTION "public"."calculate_kalan_izin"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."calculate_kalan_izin"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_gorev_tanimlari_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_gorev_tanimlari_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_gorev_tanimlari_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_ozluk_dosyalari_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_ozluk_dosyalari_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_ozluk_dosyalari_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "service_role";


















GRANT ALL ON TABLE "public"."aktivite_loglari" TO "anon";
GRANT ALL ON TABLE "public"."aktivite_loglari" TO "authenticated";
GRANT ALL ON TABLE "public"."aktivite_loglari" TO "service_role";



GRANT ALL ON TABLE "public"."bildirimler" TO "anon";
GRANT ALL ON TABLE "public"."bildirimler" TO "authenticated";
GRANT ALL ON TABLE "public"."bildirimler" TO "service_role";



GRANT ALL ON TABLE "public"."bordro_approvals" TO "anon";
GRANT ALL ON TABLE "public"."bordro_approvals" TO "authenticated";
GRANT ALL ON TABLE "public"."bordro_approvals" TO "service_role";



GRANT ALL ON TABLE "public"."bordro_calculation_rates" TO "anon";
GRANT ALL ON TABLE "public"."bordro_calculation_rates" TO "authenticated";
GRANT ALL ON TABLE "public"."bordro_calculation_rates" TO "service_role";



GRANT ALL ON TABLE "public"."bordro_items" TO "anon";
GRANT ALL ON TABLE "public"."bordro_items" TO "authenticated";
GRANT ALL ON TABLE "public"."bordro_items" TO "service_role";



GRANT ALL ON TABLE "public"."bordro_templates" TO "anon";
GRANT ALL ON TABLE "public"."bordro_templates" TO "authenticated";
GRANT ALL ON TABLE "public"."bordro_templates" TO "service_role";



GRANT ALL ON TABLE "public"."companies" TO "anon";
GRANT ALL ON TABLE "public"."companies" TO "authenticated";
GRANT ALL ON TABLE "public"."companies" TO "service_role";



GRANT ALL ON TABLE "public"."emekli_bordro_items" TO "anon";
GRANT ALL ON TABLE "public"."emekli_bordro_items" TO "authenticated";
GRANT ALL ON TABLE "public"."emekli_bordro_items" TO "service_role";



GRANT ALL ON TABLE "public"."emekli_hesaplama_parametreleri" TO "anon";
GRANT ALL ON TABLE "public"."emekli_hesaplama_parametreleri" TO "authenticated";
GRANT ALL ON TABLE "public"."emekli_hesaplama_parametreleri" TO "service_role";



GRANT ALL ON TABLE "public"."employee_passcodes" TO "anon";
GRANT ALL ON TABLE "public"."employee_passcodes" TO "authenticated";
GRANT ALL ON TABLE "public"."employee_passcodes" TO "service_role";



GRANT ALL ON TABLE "public"."employees" TO "anon";
GRANT ALL ON TABLE "public"."employees" TO "authenticated";
GRANT ALL ON TABLE "public"."employees" TO "service_role";



GRANT ALL ON TABLE "public"."gorev_tanimi_approvals" TO "anon";
GRANT ALL ON TABLE "public"."gorev_tanimi_approvals" TO "authenticated";
GRANT ALL ON TABLE "public"."gorev_tanimi_approvals" TO "service_role";



GRANT ALL ON TABLE "public"."gorev_tanimlari" TO "anon";
GRANT ALL ON TABLE "public"."gorev_tanimlari" TO "authenticated";
GRANT ALL ON TABLE "public"."gorev_tanimlari" TO "service_role";



GRANT ALL ON TABLE "public"."izin_haklari" TO "anon";
GRANT ALL ON TABLE "public"."izin_haklari" TO "authenticated";
GRANT ALL ON TABLE "public"."izin_haklari" TO "service_role";



GRANT ALL ON TABLE "public"."izin_onaycilar" TO "anon";
GRANT ALL ON TABLE "public"."izin_onaycilar" TO "authenticated";
GRANT ALL ON TABLE "public"."izin_onaycilar" TO "service_role";



GRANT ALL ON TABLE "public"."izin_talepleri" TO "anon";
GRANT ALL ON TABLE "public"."izin_talepleri" TO "authenticated";
GRANT ALL ON TABLE "public"."izin_talepleri" TO "service_role";



GRANT ALL ON TABLE "public"."ozluk_dosyalari" TO "anon";
GRANT ALL ON TABLE "public"."ozluk_dosyalari" TO "authenticated";
GRANT ALL ON TABLE "public"."ozluk_dosyalari" TO "service_role";



GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";



GRANT ALL ON TABLE "public"."sistem_parametreleri" TO "anon";
GRANT ALL ON TABLE "public"."sistem_parametreleri" TO "authenticated";
GRANT ALL ON TABLE "public"."sistem_parametreleri" TO "service_role";



GRANT ALL ON TABLE "public"."takvim_gunleri" TO "anon";
GRANT ALL ON TABLE "public"."takvim_gunleri" TO "authenticated";
GRANT ALL ON TABLE "public"."takvim_gunleri" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";
































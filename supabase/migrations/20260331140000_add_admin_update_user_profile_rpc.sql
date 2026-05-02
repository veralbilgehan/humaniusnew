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

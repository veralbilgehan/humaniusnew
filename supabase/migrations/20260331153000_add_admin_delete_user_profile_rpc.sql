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

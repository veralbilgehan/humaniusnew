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

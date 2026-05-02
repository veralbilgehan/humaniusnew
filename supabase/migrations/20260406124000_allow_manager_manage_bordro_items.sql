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

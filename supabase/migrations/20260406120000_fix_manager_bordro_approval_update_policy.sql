/*
  # Manager bordro onay güncelleme yetkisi

  Problem:
  - Uygulama tarafında manager rolü bordro onay ekranına erişebiliyor.
  - Ancak mevcut RLS politikalarında manager rolü bordro_items UPDATE için yetkili değil.
  - Bu durum onay/reddet akışında update hatasına yol açabiliyor.

  Çözüm:
  - Manager kullanıcılarına, kendi şirketlerindeki bordro kayıtlarını güncelleme yetkisi veren
    ek bir UPDATE politikası tanımlanır.
*/

DROP POLICY IF EXISTS "Managers can update bordro approval status" ON public.bordro_items;

CREATE POLICY "Managers can update bordro approval status"
  ON public.bordro_items
  FOR UPDATE
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

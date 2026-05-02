/*
  # İzin Talepleri - Superadmin RLS düzeltmesi

  Problem:
  - Mevcut insert policy sadece profile.company_id eşleşen kullanıcıya izin veriyor.
  - Superadmin kullanıcılarında profile.company_id boş olabildiği için
    izin talebi oluşturma "row-level security" hatasına düşebiliyor.

  Çözüm:
  - Superadmin rolüne, izin taleplerinde şirket bağımsız tam yetki verilir.
*/

DROP POLICY IF EXISTS "Superadmin can manage all izin talepleri" ON public.izin_talepleri;

CREATE POLICY "Superadmin can manage all izin talepleri"
  ON public.izin_talepleri
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.profiles p
      WHERE p.id = auth.uid()
      AND p.role = 'superadmin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.profiles p
      WHERE p.id = auth.uid()
      AND p.role = 'superadmin'
    )
  );

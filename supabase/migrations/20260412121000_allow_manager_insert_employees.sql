/*
  # employees INSERT RLS: manager rolunu da kapsa

  Problem:
  - Uygulamada manager rolu yonetici yetkileriyle kullaniliyor.
  - Ancak employees INSERT politikasinda manager yer almadigi icin
    personel satiri otomatik olusturma adimi RLS'e takiliyor.

  Cozum:
  - employees INSERT politikasini manager rolunu da kapsayacak sekilde yeniden tanimla.
*/

DROP POLICY IF EXISTS "HR and admins can insert employees" ON public.employees;
DROP POLICY IF EXISTS "Managers, HR and admins can insert employees" ON public.employees;

CREATE POLICY "Managers, HR and admins can insert employees"
  ON public.employees
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.profiles p
      WHERE p.id = auth.uid()
        AND (
          p.role = 'superadmin'
          OR (p.role IN ('admin', 'hr', 'manager') AND p.company_id = employees.company_id)
        )
    )
  );

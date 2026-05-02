/*
  # Employees RLS düzeltmesi

  Sorunlar:
  1) superadmin çalışan kayıtlarında yetki hatası alıyordu
  2) kullanıcı -> personel senkronizasyonunda insert RLS engeline takılabiliyordu

  Çözüm:
  - employees politikalarını superadmin'i kapsayacak şekilde yeniden tanımla
*/

DROP POLICY IF EXISTS "Users can view employees in their company" ON employees;
DROP POLICY IF EXISTS "HR and admins can insert employees" ON employees;
DROP POLICY IF EXISTS "HR and admins can update employees in their company" ON employees;
DROP POLICY IF EXISTS "HR and admins can delete employees in their company" ON employees;

CREATE POLICY "Users can view employees in their company"
  ON employees FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM profiles p
      WHERE p.id = auth.uid()
        AND (
          p.role = 'superadmin'
          OR p.company_id = employees.company_id
        )
    )
  );

CREATE POLICY "HR and admins can insert employees"
  ON employees FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM profiles p
      WHERE p.id = auth.uid()
        AND (
          p.role = 'superadmin'
          OR (p.role IN ('admin', 'hr') AND p.company_id = employees.company_id)
        )
    )
  );

CREATE POLICY "HR and admins can update employees in their company"
  ON employees FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM profiles p
      WHERE p.id = auth.uid()
        AND (
          p.role = 'superadmin'
          OR (p.role IN ('admin', 'hr', 'manager') AND p.company_id = employees.company_id)
        )
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM profiles p
      WHERE p.id = auth.uid()
        AND (
          p.role = 'superadmin'
          OR (p.role IN ('admin', 'hr', 'manager') AND p.company_id = employees.company_id)
        )
    )
  );

CREATE POLICY "HR and admins can delete employees in their company"
  ON employees FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM profiles p
      WHERE p.id = auth.uid()
        AND (
          p.role = 'superadmin'
          OR (p.role IN ('admin', 'hr') AND p.company_id = employees.company_id)
        )
    )
  );

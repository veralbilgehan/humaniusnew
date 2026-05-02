-- gorev_tanimlari ve gorev_tanimi_approvals tablolarına superadmin/admin tam yetki

-- Superadmin politikaları - gorev_tanimlari
DROP POLICY IF EXISTS "Superadmin can manage all gorev tanimlari" ON gorev_tanimlari;
CREATE POLICY "Superadmin can manage all gorev tanimlari"
  ON gorev_tanimlari FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role IN ('superadmin', 'admin')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role IN ('superadmin', 'admin')
    )
  );

-- Superadmin politikaları - gorev_tanimi_approvals
DROP POLICY IF EXISTS "Superadmin can manage all gorev tanimi approvals" ON gorev_tanimi_approvals;
CREATE POLICY "Superadmin can manage all gorev tanimi approvals"
  ON gorev_tanimi_approvals FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role IN ('superadmin', 'admin')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role IN ('superadmin', 'admin')
    )
  );

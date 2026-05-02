-- Fix: Allow all authenticated users from same company to insert gorev_tanimlari
-- The previous FOR ALL policy only covered superadmin/admin, blocking manager/hr/employee roles.

DROP POLICY IF EXISTS "Users can create gorev tanimlari for their company" ON gorev_tanimlari;

CREATE POLICY "Users can create gorev tanimlari for their company"
  ON gorev_tanimlari FOR INSERT
  TO authenticated
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM profiles
      WHERE id = auth.uid()
        AND company_id IS NOT NULL
    )
  );

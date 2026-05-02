ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_role_check;

ALTER TABLE profiles
ADD CONSTRAINT profiles_role_check
CHECK (role IN ('superadmin', 'admin', 'manager', 'employee', 'hr', 'user'));

DROP POLICY IF EXISTS "Authenticated users can insert own profile" ON profiles;

CREATE POLICY "Authenticated users can insert own profile"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (id = auth.uid() OR role = 'superadmin');
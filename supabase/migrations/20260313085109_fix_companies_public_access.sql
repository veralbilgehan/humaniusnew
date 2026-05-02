/*
  # Fix Companies Public Access

  1. Changes
    - Allow anonymous (non-authenticated) users to read companies table
    - This is needed for the registration form to display available companies
    
  2. Security
    - Only SELECT permission is granted to anonymous users
    - INSERT/UPDATE/DELETE still require authentication
*/

-- Drop existing restrictive policy
DROP POLICY IF EXISTS "Users can view their own company" ON companies;

-- Allow everyone (including anonymous users) to view companies for registration
CREATE POLICY "Anyone can view companies"
  ON companies
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- Only authenticated users can insert companies
CREATE POLICY "Authenticated users can insert companies"
  ON companies
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Users can only update their own company
CREATE POLICY "Users can update own company"
  ON companies
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.company_id = companies.id
      AND profiles.id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.company_id = companies.id
      AND profiles.id = auth.uid()
    )
  );

-- Users can only delete their own company
CREATE POLICY "Users can delete own company"
  ON companies
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.company_id = companies.id
      AND profiles.id = auth.uid()
    )
  );

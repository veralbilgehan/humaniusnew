-- Profiles tablosuna yeni users için INSERT politikası ekle
-- Bu politika, yeni signup olan kullanıcıların kendi profillerini oluşturmasını sağlar

DROP POLICY IF EXISTS "Users can create their own profile" ON public.profiles;

CREATE POLICY "Users can create their own profile" ON public.profiles 
FOR INSERT TO authenticated 
WITH CHECK (id = auth.uid());

-- Dogrulama
SELECT 'Politika başarıyla oluşturuldu' AS status;
SELECT policyname, cmd FROM pg_policies 
WHERE tablename = 'profiles' AND schemaname = 'public'
ORDER BY policyname;

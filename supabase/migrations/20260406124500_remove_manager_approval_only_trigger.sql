/*
  # Manager onay-alanı trigger'ını kaldır

  Not:
  - Daha önce manager güncellemelerini sadece approval alanlarına sınırlayan trigger eklenmişti.
  - Manager bordro kaydı düzenleme/kaydetme ihtiyacında bu trigger engel oluşturur.
  - Bu migration trigger ve fonksiyonu temizler.
*/

DROP TRIGGER IF EXISTS trg_enforce_manager_bordro_approval_only ON public.bordro_items;
DROP FUNCTION IF EXISTS public.enforce_manager_bordro_approval_only();

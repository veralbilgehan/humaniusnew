import { supabase } from '../lib/supabase';

export interface OzlukDosya {
  id: string;
  employee_id: string;
  company_id: string;
  kategori: string;
  dosya_adi: string | null;
  dosya_yolu: string | null;
  notlar: string | null;
  created_at: string;
}

const BUCKET = 'ozluk-dosyalari';

const isNetworkResolutionError = (error: unknown) => {
  const message = String((error as { message?: string } | null)?.message ?? error ?? '').toLowerCase();
  return (
    message.includes('name resolution failed') ||
    message.includes('failed to fetch') ||
    message.includes('networkerror')
  );
};

const toFriendlyStorageError = (error: unknown) => {
  if (!isNetworkResolutionError(error)) return error;
  return new Error('Supabase baglantisi su anda kullanilamiyor. Local calisiyorsaniz backend servislerinin ayakta oldugunu kontrol edin.');
};

export const ozlukDosyasiService = {
  async getDosyalar(employeeId: string): Promise<OzlukDosya[]> {
    try {
      const { data, error } = await supabase
        .from('ozluk_dosyalari')
        .select('*')
        .eq('employee_id', employeeId)
        .order('created_at', { ascending: false });
      if (error) throw error;
      return (data ?? []) as OzlukDosya[];
    } catch (error) {
      // Belgeler sekmesini tamamen bloklamamak icin gecici ag hatalarinda bos liste don.
      if (isNetworkResolutionError(error)) return [];
      throw error;
    }
  },

  async uploadDosya(
    companyId: string,
    employeeId: string,
    kategori: string,
    file: File,
    notlar?: string
  ): Promise<OzlukDosya> {
    const dosyaYolu = `${companyId}/${employeeId}/${kategori}/${Date.now()}_${file.name}`;

    const { error: uploadError } = await supabase.storage
      .from(BUCKET)
      .upload(dosyaYolu, file, { upsert: false });
    if (uploadError) throw toFriendlyStorageError(uploadError);

    const { data, error } = await supabase
      .from('ozluk_dosyalari')
      .insert({
        employee_id: employeeId,
        company_id: companyId,
        kategori,
        dosya_adi: file.name,
        dosya_yolu: dosyaYolu,
        notlar: notlar ?? null,
      })
      .select()
      .single();
    if (error) {
      // Yüklenen dosyayı geri al
      await supabase.storage.from(BUCKET).remove([dosyaYolu]);
      throw toFriendlyStorageError(error);
    }
    return data as OzlukDosya;
  },

  async saveYaziKaydi(
    companyId: string,
    employeeId: string,
    kategori: string,
    notlar: string
  ): Promise<OzlukDosya> {
    const { data, error } = await supabase
      .from('ozluk_dosyalari')
      .insert({
        employee_id: employeeId,
        company_id: companyId,
        kategori,
        dosya_adi: null,
        dosya_yolu: null,
        notlar,
      })
      .select()
      .single();
    if (error) throw error;
    return data as OzlukDosya;
  },

  async deleteDosya(id: string, dosyaYolu: string | null): Promise<void> {
    if (dosyaYolu) {
      const { error: storageDeleteError } = await supabase.storage.from(BUCKET).remove([dosyaYolu]);
      if (storageDeleteError) throw toFriendlyStorageError(storageDeleteError);
    }
    const { error } = await supabase
      .from('ozluk_dosyalari')
      .delete()
      .eq('id', id);
    if (error) throw error;
  },

  async getSignedUrl(dosyaYolu: string): Promise<string> {
    const { data, error } = await supabase.storage
      .from(BUCKET)
      .createSignedUrl(dosyaYolu, 3600);
    if (error) throw toFriendlyStorageError(error);
    return data.signedUrl;
  },
};

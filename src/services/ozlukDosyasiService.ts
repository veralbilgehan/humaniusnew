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

const MAX_FILE_MB = 4;

function fileToBase64(file: File): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(reader.result as string);
    reader.onerror = () => reject(new Error('Dosya okunamadı'));
    reader.readAsDataURL(file);
  });
}

export const ozlukDosyasiService = {
  async getDosyalar(employeeId: string): Promise<OzlukDosya[]> {
    const { data, error } = await supabase
      .from('ozluk_dosyalari')
      .select('*')
      .eq('employee_id', employeeId)
      .order('created_at', { ascending: false });
    if (error) throw error;
    return (data ?? []) as OzlukDosya[];
  },

  async uploadDosya(
    companyId: string,
    employeeId: string,
    kategori: string,
    file: File,
    notlar?: string
  ): Promise<OzlukDosya> {
    if (file.size > MAX_FILE_MB * 1024 * 1024) {
      throw new Error(`Dosya boyutu ${MAX_FILE_MB} MB'ı geçemez.`);
    }

    const base64 = await fileToBase64(file);

    const { data, error } = await supabase
      .from('ozluk_dosyalari')
      .insert({
        employee_id: employeeId,
        company_id: companyId,
        kategori,
        dosya_adi: file.name,
        dosya_yolu: base64,
        notlar: notlar ?? null,
      })
      .select()
      .single();

    if (error) throw error;
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

  async deleteDosya(id: string, _dosyaYolu: string | null): Promise<void> {
    const { error } = await supabase
      .from('ozluk_dosyalari')
      .delete()
      .eq('id', id);
    if (error) throw error;
  },

  async getSignedUrl(dosyaYolu: string): Promise<string> {
    // base64 data URL — doğrudan döndür
    return dosyaYolu;
  },
};

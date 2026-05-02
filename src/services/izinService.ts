import { supabase } from '../lib/supabase';
import type { Database } from '../lib/database.types';

type IzinTalebi = Database['public']['Tables']['izin_talepleri']['Row'];
type IzinTalebiInsert = Database['public']['Tables']['izin_talepleri']['Insert'];
type IzinTalebiUpdate = Database['public']['Tables']['izin_talepleri']['Update'];
type IzinHakki = Database['public']['Tables']['izin_haklari']['Row'];
type IzinHakkiInsert = Database['public']['Tables']['izin_haklari']['Insert'];
type IzinHakkiUpdate = Database['public']['Tables']['izin_haklari']['Update'];

export const izinService = {
  async getAllTalepler(companyId: string) {
    const { data, error } = await supabase
      .from('izin_talepleri')
      .select('*, employees(name, department, position)')
      .eq('company_id', companyId)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data;
  },

  async getTalepById(id: string) {
    const { data, error } = await supabase
      .from('izin_talepleri')
      .select('*, employees(name, department, position)')
      .eq('id', id)
      .maybeSingle();

    if (error) throw error;
    return data;
  },

  async createTalep(talep: IzinTalebiInsert) {
    const { data, error } = await supabase
      .from('izin_talepleri')
      .insert(talep)
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async updateTalep(id: string, updates: IzinTalebiUpdate) {
    const { data, error } = await supabase
      .from('izin_talepleri')
      .update(updates)
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async deleteTalep(id: string) {
    const { error } = await supabase
      .from('izin_talepleri')
      .delete()
      .eq('id', id);

    if (error) throw error;
  },

  async approveTalep(id: string, onaylayanId: string) {
    const { data, error } = await supabase
      .from('izin_talepleri')
      .update({
        durum: 'onaylandi',
        onaylayan_id: onaylayanId,
        onay_tarihi: new Date().toISOString()
      })
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async rejectTalep(id: string, onaylayanId: string, redNedeni: string) {
    const { data, error } = await supabase
      .from('izin_talepleri')
      .update({
        durum: 'reddedildi',
        onaylayan_id: onaylayanId,
        onay_tarihi: new Date().toISOString(),
        red_nedeni: redNedeni
      })
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async getTaleplerByStatus(companyId: string, durum: IzinTalebi['durum']) {
    const { data, error } = await supabase
      .from('izin_talepleri')
      .select('*, employees(name, department)')
      .eq('company_id', companyId)
      .eq('durum', durum)
      .order('talep_tarihi', { ascending: false });

    if (error) throw error;
    return data;
  },

  async getEmployeeHakki(employeeId: string, yil: number) {
    const { data, error } = await supabase
      .from('izin_haklari')
      .select('*')
      .eq('employee_id', employeeId)
      .eq('yil', yil)
      .maybeSingle();

    if (error) throw error;
    return data;
  },

  async createOrUpdateHakki(hakki: IzinHakkiInsert) {
    const { data, error } = await supabase
      .from('izin_haklari')
      .upsert(hakki)
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async getAllHaklari(companyId: string, yil: number) {
    const { data, error } = await supabase
      .from('izin_haklari')
      .select('*, employees(name, department)')
      .eq('company_id', companyId)
      .eq('yil', yil)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data;
  },

  async calculateIzinHakki(iseGirisTarihi: string): Promise<number> {
    const giris = new Date(iseGirisTarihi);
    const now = new Date();
    const calismaYili = now.getFullYear() - giris.getFullYear();

    if (calismaYili < 1) return 14;
    if (calismaYili >= 1 && calismaYili < 5) return 14;
    if (calismaYili >= 5 && calismaYili < 15) return 20;
    return 26;
  }
};

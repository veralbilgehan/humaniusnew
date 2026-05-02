import { supabase } from '../lib/supabase';
import type { Database } from '../lib/database.types';

type EmeклiBordroItem = Database['public']['Tables']['emekli_bordro_items']['Row'];
type EmeклiBordroItemInsert = Database['public']['Tables']['emekli_bordro_items']['Insert'];
type EmeклiBordroItemUpdate = Database['public']['Tables']['emekli_bordro_items']['Update'];
type EmeклiBordroParametre = Database['public']['Tables']['emekli_hesaplama_parametreleri']['Row'];

export const emeклiBordroService = {
  async getAll(companyId: string) {
    const { data, error } = await supabase
      .from('emekli_bordro_items')
      .select('*, employees(name, department)')
      .eq('company_id', companyId)
      .order('period', { ascending: false });

    if (error) throw error;
    return data;
  },

  async getById(id: string) {
    const { data, error } = await supabase
      .from('emekli_bordro_items')
      .select('*, employees(name, department, tc_no, sicil_no)')
      .eq('id', id)
      .maybeSingle();

    if (error) throw error;
    return data;
  },

  async getByPeriod(companyId: string, period: string) {
    const { data, error } = await supabase
      .from('emekli_bordro_items')
      .select('*, employees(name, department)')
      .eq('company_id', companyId)
      .eq('period', period)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data;
  },

  async create(bordro: EmeклiBordroItemInsert) {
    const { data, error } = await supabase
      .from('emekli_bordro_items')
      .insert(bordro)
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async update(id: string, updates: EmeклiBordroItemUpdate) {
    const { data, error } = await supabase
      .from('emekli_bordro_items')
      .update(updates)
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async delete(id: string) {
    const { error } = await supabase
      .from('emekli_bordro_items')
      .delete()
      .eq('id', id);

    if (error) throw error;
  },

  async getParametreler(companyId: string) {
    const { data, error } = await supabase
      .from('emekli_hesaplama_parametreleri')
      .select('*')
      .eq('company_id', companyId)
      .eq('aktif', true)
      .order('sira', { ascending: true });

    if (error) throw error;
    return data;
  },

  async updateParametre(id: string, updates: Partial<EmeклiBordroParametre>) {
    const { data, error } = await supabase
      .from('emekli_hesaplama_parametreleri')
      .update(updates)
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return data;
  }
};

import { supabase } from '../lib/supabase';
import type { Database } from '../lib/database.types';

type Employee = Database['public']['Tables']['employees']['Row'];
type EmployeeInsert = Database['public']['Tables']['employees']['Insert'];
type EmployeeUpdate = Database['public']['Tables']['employees']['Update'];

export const employeeService = {
  async getAll(companyId: string) {
    const { data, error } = await supabase
      .from('employees')
      .select('*')
      .eq('company_id', companyId)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data;
  },

  async getById(id: string) {
    const { data, error } = await supabase
      .from('employees')
      .select('*')
      .eq('id', id)
      .maybeSingle();

    if (error) throw error;
    return data;
  },

  async create(employee: EmployeeInsert) {
    const { data, error } = await supabase
      .from('employees')
      .insert(employee)
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async update(id: string, updates: EmployeeUpdate) {
    const { data, error } = await supabase
      .from('employees')
      .update(updates)
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async delete(id: string) {
    const { error } = await supabase
      .from('employees')
      .delete()
      .eq('id', id);

    if (error) throw error;
  },

  async getByDepartment(companyId: string, department: string) {
    const { data, error } = await supabase
      .from('employees')
      .select('*')
      .eq('company_id', companyId)
      .eq('department', department)
      .order('name', { ascending: true });

    if (error) throw error;
    return data;
  },

  async getByStatus(companyId: string, status: Employee['status']) {
    const { data, error } = await supabase
      .from('employees')
      .select('*')
      .eq('company_id', companyId)
      .eq('status', status)
      .order('name', { ascending: true });

    if (error) throw error;
    return data;
  },

  async search(companyId: string, searchTerm: string) {
    const { data, error } = await supabase
      .from('employees')
      .select('*')
      .eq('company_id', companyId)
      .or(`name.ilike.%${searchTerm}%,email.ilike.%${searchTerm}%,position.ilike.%${searchTerm}%`)
      .order('name', { ascending: true });

    if (error) throw error;
    return data;
  },

  async getStats(companyId: string) {
    const { data, error } = await supabase
      .from('employees')
      .select('status')
      .eq('company_id', companyId);

    if (error) throw error;

    const stats = {
      active: data.filter(e => e.status === 'active').length,
      onLeave: data.filter(e => e.status === 'onLeave').length,
      inactive: data.filter(e => e.status === 'inactive').length
    };

    return stats;
  },

  generatePasscode(): string {
    return Math.floor(100000 + Math.random() * 900000).toString();
  },

  async setEmployeePasscode(employeeId: string, passcode: string) {
    const { data, error } = await supabase
      .from('employees')
      .update({ approval_passcode: passcode })
      .eq('id', employeeId)
      .select()
      .maybeSingle();

    if (error) throw error;
    return data;
  },

  async getEmployeePasscode(employeeId: string) {
    const { data, error } = await supabase
      .from('employees')
      .select('approval_passcode')
      .eq('id', employeeId)
      .maybeSingle();

    if (error) throw error;
    return data?.approval_passcode;
  }
};

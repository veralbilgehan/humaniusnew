import { supabase } from '../lib/supabase';

export interface BootstrapSuperAdminPayload {
  email?: string;
  password?: string;
  fullName?: string;
}

export interface CreateCompanyWithAdminPayload {
  companyName: string;
  companyEmail?: string;
  companyPhone?: string;
  companyCity?: string;
  adminFullName: string;
  adminEmail: string;
  adminPassword: string;
}

export interface CreateCompanyUserPayload {
  companyId?: string;
  fullName: string;
  email: string;
  password: string;
  role: 'admin' | 'manager' | 'employee' | 'hr' | 'user';
}

export interface UpdateManagedPasswordPayload {
  userId: string;
  newPassword: string;
}

async function invokeFunction<T>(operation: string, payload: Record<string, unknown>) {
  const { data, error } = await supabase.functions.invoke('user-management', {
    body: {
      operation,
      ...payload,
    },
  });

  if (error) {
    let message = error.message;
    try {
      const body = await (error as any).context?.json?.();
      if (body?.error) message = body.error;
    } catch {
      // ignore
    }
    throw new Error(message);
  }

  if (data?.error) {
    throw new Error(data.error);
  }

  return data as T;
}

export const userManagementService = {
  bootstrapSuperAdmin(payload: BootstrapSuperAdminPayload = {}) {
    return invokeFunction<{ message: string; userId: string }>('bootstrap_superadmin', payload as unknown as Record<string, unknown>);
  },

  createCompanyWithAdmin(payload: CreateCompanyWithAdminPayload) {
    return invokeFunction<{ message: string; companyId: string; adminUserId: string }>('create_company_with_admin', payload as unknown as Record<string, unknown>);
  },

  createCompanyUser(payload: CreateCompanyUserPayload) {
    return invokeFunction<{ message: string; userId: string }>('create_company_user', payload as unknown as Record<string, unknown>);
  },

  updateManagedPassword(payload: UpdateManagedPasswordPayload) {
    return invokeFunction<{ message: string }>('update_password', payload as unknown as Record<string, unknown>);
  },
};

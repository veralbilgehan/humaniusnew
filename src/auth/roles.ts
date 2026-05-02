import type { View } from '../types';

export type RawProfileRole = 'superadmin' | 'admin' | 'manager' | 'employee' | 'hr' | 'user' | null | undefined;
export type AppRole = 'superadmin' | 'admin' | 'user';

export function normalizeRole(role: RawProfileRole): AppRole {
  if (role === 'superadmin') return 'superadmin';
  if (role === 'admin' || role === 'hr' || role === 'manager') return 'admin';
  return 'user';
}

export function getRoleLabel(role: AppRole): string {
  if (role === 'superadmin') return 'Süper Yönetici';
  if (role === 'admin') return 'Şirket Yöneticisi';
  return 'Kullanıcı';
}

export function getDefaultViewForRole(role: AppRole): View {
  if (role === 'superadmin') return 'personel';
  if (role === 'admin') return 'personel';
  return 'arama';
}

export function canAccessView(role: AppRole, view: View): boolean {
  const allowedViews: Record<AppRole, View[]> = {
    superadmin: ['arama', 'personel', 'bordro', 'bordro-onay', 'izin', 'raporlar', 'uyari', 'ayar', 'gorev-tanimi', 'gorev-tanimi-kayitlari', 'ozluk-dosyasi', 'kullanicilar', 'kullanim-kilavuzu'],
    admin:      ['arama', 'personel', 'bordro', 'bordro-onay', 'izin', 'raporlar', 'uyari', 'ayar', 'gorev-tanimi', 'gorev-tanimi-kayitlari', 'ozluk-dosyasi', 'kullanicilar', 'kullanim-kilavuzu'],
    user:       ['arama', 'bordro', 'izin', 'gorev-tanimi', 'kullanim-kilavuzu'],
  };

  return allowedViews[role].includes(view);
}

export function canManageUsers(role: AppRole): boolean {
  return role === 'superadmin' || role === 'admin';
}

export function canCreateCompany(role: AppRole): boolean {
  return role === 'superadmin';
}

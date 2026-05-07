import React, { useState, useEffect, useCallback } from 'react';
import { AuthProvider, useAuth } from './contexts/AuthContext';
import { LanguageProvider } from './contexts/LanguageContext';
import Sidebar from './components/Sidebar';
import Toolbar from './components/Toolbar';
import StatsCards from './components/StatsCards';
import EmployeeTable from './components/EmployeeTable';
import EmployeeDrawer from './components/EmployeeDrawer';
import BordroMain from './components/BordroMain';
import BordroViewModal from './components/BordroViewModal';
import BordroOnayYonetimi from './components/BordroOnayYonetimi';
import GorevTanimi from './components/GorevTanimi';
import IzinTalepForm from './components/IzinTalepForm';
import IzinDuzenlemeForm from './components/IzinDuzenlemeForm';
import IzinTakvimi from './components/IzinTakvimi';
import IzinRaporlari from './components/IzinRaporlari';
import TakvimYonetimi from './components/TakvimYonetimi';
import SistemAyarlari from './components/SistemAyarlari';
import OzlukDosyasi from './components/OzlukDosyasi';
import UpcomingEvents from './components/UpcomingEvents';
import QuickActions from './components/QuickActions';
import { SearchPage } from './components/SearchPage';
import KullanicilarPage from './components/KullanicilarPage';
import IzinOzetKartlari from './components/IzinOzetKartlari';
import AIBrowserPage from './browser/AIBrowserPage';
import GuideContextMenu from './components/GuideContextMenu';
import PDKSYonetimi from './components/PDKSYonetimi';
import PerformansYonetimi from './components/PerformansYonetimi';
import IseAlimATS from './components/IseAlimATS';
import EgitimLMS from './components/EgitimLMS';
import AnalitiKDashboard from './components/AnalitiKDashboard';
import KVKKUyumluluk from './components/KVKKUyumluluk';
import IzinTanimlari from './components/IzinTanimlari';
import OrganizasyonSemasi from './components/OrganizasyonSemasi';
import ZimmetYonetimi from './components/ZimmetYonetimi';
import OKRYonetimi from './components/OKRYonetimi';
import YetkinlikMatrisi from './components/YetkinlikMatrisi';
import OnboardingAkisi from './components/OnboardingAkisi';
import EsnekYanHaklar from './components/EsnekYanHaklar';
import IzinCakismaKontrol from './components/IzinCakismaKontrol';
import DinamikFormBuilder from './components/DinamikFormBuilder';
import { employeeService } from './services/employeeService';
import { companyService } from './services/companyService';
import { izinService } from './services/izinService';
import { bordroService } from './services/bordroService';
import { canAccessView, getDefaultViewForRole } from './auth/roles';
import Login from './components/Login';
import type { Employee, View, Stats, Company, Department } from './types';
import type { IzinTalebi, IzinHakki } from './types/izin';
import type { BordroItem } from './types/bordro';

// ─── Inner app (requires auth context) ───────────────────────────────────────

interface AppSectionErrorBoundaryProps {
  children: React.ReactNode;
  fallback: React.ReactNode;
  resetKey?: string;
}

interface AppSectionErrorBoundaryState {
  hasError: boolean;
}

class AppSectionErrorBoundary extends React.Component<
  AppSectionErrorBoundaryProps,
  AppSectionErrorBoundaryState
> {
  state: AppSectionErrorBoundaryState = { hasError: false };

  static getDerivedStateFromError(): AppSectionErrorBoundaryState {
    return { hasError: true };
  }

  componentDidCatch(error: unknown) {
    console.error('UI section crashed:', error);
  }

  componentDidUpdate(prevProps: AppSectionErrorBoundaryProps) {
    if (this.state.hasError && prevProps.resetKey !== this.props.resetKey) {
      this.setState({ hasError: false });
    }
  }

  render() {
    if (this.state.hasError) {
      return this.props.fallback;
    }

    return this.props.children;
  }
}

const AppInner: React.FC = () => {
  const { user, profile, appRole, loading: authLoading } = useAuth();
  const effectiveAppRole = user ? appRole : 'admin';

  // ── Navigation ──────────────────────────────────────────────────────────────
  const [currentView, setCurrentView] = useState<View>('arama');
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedDepartment, setSelectedDepartment] = useState('all');
  const [selectedCompany, setSelectedCompany] = useState('all');

  useEffect(() => {
    if (currentView === 'chat') {
      setCurrentView('arama');
    }
  }, [currentView]);

  useEffect(() => {
    if (!canAccessView(effectiveAppRole, currentView)) {
      setCurrentView(getDefaultViewForRole(effectiveAppRole));
    }
  }, [effectiveAppRole, currentView]);

  // ── Employee data ───────────────────────────────────────────────────────────
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [companies, setCompanies] = useState<Company[]>([]);
  const [departments, setDepartments] = useState<Department[]>([]);
  const [stats, setStats] = useState<Stats>({ active: 0, onLeave: 0, inactive: 0 });

  // ── Drawer ──────────────────────────────────────────────────────────────────
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [selectedEmployee, setSelectedEmployee] = useState<Employee | null>(null);
  const [isNewEmployee, setIsNewEmployee] = useState(false);

  // ── İzin data ───────────────────────────────────────────────────────────────
  const [izinTalepleri, setIzinTalepleri] = useState<IzinTalebi[]>([]);
  const [izinHaklari, setIzinHaklari] = useState<IzinHakki[]>([]);
  const [showIzinForm, setShowIzinForm] = useState(false);
  const [editingIzin, setEditingIzin] = useState<IzinTalebi | null>(null);

  // ── Bordro data ─────────────────────────────────────────────────────────────
  const [bordrolar, setBordrolar] = useState<BordroItem[]>([]);
  const [selectedBordro, setSelectedBordro] = useState<BordroItem | null>(null);


  // ── Data loading ─────────────────────────────────────────────────────────────
  const loadData = useCallback(async () => {
    if (!profile?.company_id) return;
    try {
      const [empData, empStats] = await Promise.all([
        employeeService.getAll(profile.company_id),
        employeeService.getStats(profile.company_id),
      ]);

      // Map DB rows → frontend Employee shape
      const mapped: Employee[] = (empData ?? []).map((e: any) => ({
        id: e.id,
        company_id: e.company_id,
        name: e.name ?? '',
        tc_no: e.tc_no,
        sicil_no: e.sicil_no,
        company: e.company_id ?? '',
        department: e.department ?? '',
        position: e.position ?? '',
        level: e.level ?? 'Junior',
        salary: Number(e.salary ?? 0),
        status: e.status ?? 'active',
        phone: e.phone ?? '',
        email: e.email ?? '',
        joinDate: e.join_date,
        join_date: e.join_date,
        address: e.address ?? '',
        avatar_url: e.avatar_url,
        skills: e.skills ?? [],
        medeni_durum: e.medeni_durum,
        cocuk_sayisi: e.cocuk_sayisi,
        engelli_durumu: e.engelli_durumu,
        employeeType: e.employee_type ?? 'normal',
        employee_type: e.employee_type,
        approval_passcode: e.approval_passcode,
        created_at: e.created_at,
        updated_at: e.updated_at,
      }));

      setEmployees(mapped);
      setStats(empStats ?? { active: 0, onLeave: 0, inactive: 0 });

      const depts = [...new Set(mapped.map((e) => e.department).filter(Boolean))];
      setDepartments(depts);

      // Şirket listesi — sadece giriş yapan kullanıcının şirketi
      try {
        const compData = await companyService.getById(profile.company_id);
        setCompanies(compData ? [compData.name] : []);
      } catch {}

      // İzin talepleri
      let mappedTalepler: IzinTalebi[] = [];
      try {
        const talepData = await izinService.getAllTalepler(profile.company_id);
        mappedTalepler = (talepData ?? []).map((t: any) => ({
          id: t.id,
          companyId: t.company_id,
          employeeId: t.employee_id,
          izinTuru: t.izin_turu,
          baslangicTarihi: t.baslangic_tarihi,
          bitisTarihi: t.bitis_tarihi,
          gunSayisi: t.gun_sayisi,
          aciklama: t.aciklama ?? '',
          yolIzniTalep: t.yol_izni_talep ?? false,
          yolIzniGun: t.yol_izni_gun ?? 0,
          seyahatYeri: t.seyahat_yeri ?? '',
          ilDisiSeyahat: t.il_disi_seyahat ?? false,
          belgeUrl: t.belge_url,
          durum: t.durum,
          onaylayanId: t.onaylayan_id,
          onayTarihi: t.onay_tarihi,
          redNedeni: t.red_nedeni,
          talepTarihi: t.talep_tarihi,
          createdAt: t.created_at,
          updatedAt: t.updated_at,
          employee: t.employees,
          employeeName: t.employees?.name ?? '',
          department: t.employees?.department ?? '',
        }));
        setIzinTalepleri(mappedTalepler);
      } catch {}

      // İzin hakları
      try {
        const yil = new Date().getFullYear();
        const hakData = await izinService.getAllHaklari(profile.company_id, yil);
        const mappedHaklar: IzinHakki[] = (hakData ?? []).map((h: any) => ({
          id: h.id,
          companyId: h.company_id,
          employeeId: h.employee_id,
          yil: h.yil,
          toplamHak: h.toplam_hak,
          kullanilanIzin: h.kullanilan_izin ?? 0,
          kalanIzin: h.kalan_izin ?? 0,
          calismaYili: h.calisma_yili ?? 0,
          iseGirisTarihi: h.ise_giris_tarihi,
          hesaplamaTarihi: h.hesaplama_tarihi,
          mazeretIzin: h.mazeret_izin ?? 0,
          hastalikIzin: h.hastalik_izin ?? 0,
          mazeret: h.mazeret_izin ?? 0,
          createdAt: h.created_at,
          updatedAt: h.updated_at,
        }));

        // Onaylanan yillik izinler yillik haktan dusulur.
        const approvedAnnualByEmployee = mappedTalepler.reduce<Record<string, number>>((acc, talep) => {
          if (talep.durum !== 'onaylandi') return acc;
          if (talep.izinTuru !== 'yillik') return acc;

          const year = new Date(talep.baslangicTarihi).getFullYear();
          if (year !== yil) return acc;

          const used = (talep.gunSayisi || 0) + (talep.yolIzniTalep ? (talep.yolIzniGun || 0) : 0);
          acc[talep.employeeId] = (acc[talep.employeeId] || 0) + used;
          return acc;
        }, {});

        const calculatedHaklar = mappedHaklar.map((hak) => {
          const annualUsed = approvedAnnualByEmployee[hak.employeeId] || 0;
          const kullanilanIzin = annualUsed;
          const kalanIzin = Math.max(0, Number(hak.toplamHak || 0) - annualUsed);
          return {
            ...hak,
            kullanilanIzin,
            kalanIzin,
          };
        });

        setIzinHaklari(calculatedHaklar);
      } catch {}

      // Bordro
      try {
        const bordroData = await bordroService.getAll(profile.company_id);
        setBordrolar(bordroData ?? []);
      } catch {}
    } catch (err) {
      console.error('Veri yüklenemedi:', err);
    }
  }, [profile?.company_id]);

  useEffect(() => {
    if (user && profile) loadData();
  }, [user, profile, loadData]);

  // ── Filtered lists ──────────────────────────────────────────────────────────
  const filteredEmployees = employees.filter((emp) => {
    const safeName = String(emp.name ?? '').toLowerCase();
    const safeDepartment = String(emp.department ?? '').toLowerCase();
    const safePosition = String(emp.position ?? '').toLowerCase();
    const normalizedSearch = searchTerm.toLowerCase();
    const matchSearch =
      !searchTerm ||
      safeName.includes(normalizedSearch) ||
      safeDepartment.includes(normalizedSearch) ||
      safePosition.includes(normalizedSearch);
    const matchDept =
      selectedDepartment === 'all' || emp.department === selectedDepartment;
    return matchSearch && matchDept;
  });

  const currentEmployeeForIzin = employees.find((emp) => {
    const profileEmail = String(profile?.email ?? '').toLowerCase();
    const empEmail = String(emp.email ?? '').toLowerCase();
    if (profileEmail && empEmail && profileEmail === empEmail) return true;

    const profileName = String(profile?.full_name ?? '').trim().toLowerCase();
    const empName = String(emp.name ?? '').trim().toLowerCase();
    return profileName.length > 0 && profileName === empName;
  });

  const currentEmployeeIzinHakki = currentEmployeeForIzin
    ? izinHaklari.find((hak) => hak.employeeId === currentEmployeeForIzin.id)
    : undefined;

  const currentEmployeeIzinTalepleri = currentEmployeeForIzin
    ? izinTalepleri
        .filter((talep) => talep.employeeId === currentEmployeeForIzin.id)
        .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())
        .slice(0, 3)
    : [];

  // ── Employee CRUD ───────────────────────────────────────────────────────────
  const handleEmployeeClick = (emp: Employee) => {
    setSelectedEmployee(emp);
    setIsNewEmployee(false);
    setDrawerOpen(true);
  };

  const handleNewEmployee = () => {
    setSelectedEmployee({
      id: '',
      name: '',
      company: '',
      department: '',
      position: '',
      level: 'Junior',
      salary: 0,
      status: 'active',
      phone: '',
      email: '',
      address: '',
      skills: [],
      employeeType: 'normal',
    });
    setIsNewEmployee(true);
    setDrawerOpen(true);
  };

  const handleSaveEmployee = async (emp: Employee) => {
    if (!profile?.company_id) return;
    try {
      if (isNewEmployee) {
        await employeeService.create({
          company_id: profile.company_id,
          name: emp.name,
          department: emp.department,
          position: emp.position,
          level: emp.level,
          salary: emp.salary,
          status: emp.status,
          phone: emp.phone,
          email: emp.email,
          address: emp.address,
          skills: emp.skills,
          employee_type: emp.employeeType ?? 'normal',
          tc_no: emp.tc_no ?? '',
          sicil_no: emp.sicil_no ?? '',
        });
      } else {
        await employeeService.update(emp.id, {
          name: emp.name,
          department: emp.department,
          position: emp.position,
          level: emp.level,
          salary: emp.salary,
          status: emp.status,
          phone: emp.phone,
          email: emp.email,
          address: emp.address,
          skills: emp.skills,
          employee_type: emp.employeeType ?? 'normal',
        });
      }
      setDrawerOpen(false);
      await loadData();
    } catch (err) {
      console.error('Personel kaydedilemedi:', err);
    }
  };

  const handleDeleteEmployee = async (id: string) => {
    if (!window.confirm('Bu personeli silmek istediğinize emin misiniz?')) return;
    try {
      await employeeService.delete(id);
      setDrawerOpen(false);
      await loadData();
    } catch (err) {
      console.error('Personel silinemedi:', err);
    }
  };

  const handleEmployeeActionSelect = (emp: Employee, action: 'gorev' | 'bordro' | 'izin') => {
    setSelectedEmployee(emp);
    if (action === 'gorev') setCurrentView('gorev-tanimi');
    else if (action === 'bordro') setCurrentView('bordro');
    else if (action === 'izin') setCurrentView('izin');
  };

  const handleExportCSV = () => {
    const header = ['Ad Soyad', 'Şirket', 'Departman', 'Pozisyon', 'Seviye', 'Ücret', 'Durum', 'Telefon', 'Email'];
    const rows = filteredEmployees.map((e) => [
      e.name, e.company, e.department, e.position, e.level,
      e.salary, e.status, e.phone, e.email,
    ]);
    const csv = [header, ...rows].map((r) => r.join(',')).join('\n');
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'personel_listesi.csv';
    a.click();
    URL.revokeObjectURL(url);
  };

  // ── İzin CRUD ───────────────────────────────────────────────────────────────
  const handleIzinSubmit = async (talep: Partial<IzinTalebi>) => {
    const resolvedCompanyId =
      profile?.company_id ||
      user?.user_metadata?.company_id ||
      employees.find((emp) => !!emp.company_id)?.company_id ||
      null;

    if (!resolvedCompanyId) {
      alert('İzin talebi oluşturulamadı: şirket bilgisi bulunamadı.');
      return;
    }

    const nowIso = new Date().toISOString();
    const today = nowIso.split('T')[0];

    const baseTalep: Partial<IzinTalebi> = {
      companyId: resolvedCompanyId,
      employeeId: talep.employeeId ?? '',
      izinTuru: talep.izinTuru ?? 'yillik',
      baslangicTarihi: talep.baslangicTarihi ?? '',
      bitisTarihi: talep.bitisTarihi ?? '',
      gunSayisi: talep.gunSayisi ?? 0,
      aciklama: talep.aciklama ?? '',
      yolIzniTalep: talep.yolIzniTalep ?? false,
      yolIzniGun: talep.yolIzniGun ?? 0,
      seyahatYeri: talep.seyahatYeri ?? '',
      ilDisiSeyahat: talep.ilDisiSeyahat ?? false,
      belgeUrl: talep.belgeUrl ?? null,
      durum: 'beklemede',
      talepTarihi: today,
      createdAt: nowIso,
      updatedAt: nowIso,
      onaylayanId: null,
      onayTarihi: null,
      redNedeni: null,
    };

    try {
      await izinService.createTalep({
        company_id: resolvedCompanyId,
        employee_id: baseTalep.employeeId ?? '',
        izin_turu: baseTalep.izinTuru ?? 'yillik',
        baslangic_tarihi: baseTalep.baslangicTarihi ?? '',
        bitis_tarihi: baseTalep.bitisTarihi ?? '',
        gun_sayisi: baseTalep.gunSayisi ?? 0,
        aciklama: baseTalep.aciklama ?? '',
        yol_izni_talep: baseTalep.yolIzniTalep ?? false,
        yol_izni_gun: baseTalep.yolIzniGun ?? 0,
        seyahat_yeri: baseTalep.seyahatYeri ?? '',
        il_disi_seyahat: baseTalep.ilDisiSeyahat ?? false,
        durum: 'beklemede',
        talep_tarihi: today,
      });
      setShowIzinForm(false);
      await loadData();
    } catch (err: any) {
      console.error('İzin talebi oluşturulamadı:', err);
      const rawMessage = String(err?.message ?? '').toLowerCase();
      const isPermissionLikeError =
        rawMessage.includes('row-level security') ||
        rawMessage.includes('security policy') ||
        rawMessage.includes('permission denied') ||
        rawMessage.includes('not authorized') ||
        rawMessage.includes('rls');

      const localTalep: IzinTalebi = {
        id: typeof crypto !== 'undefined' && 'randomUUID' in crypto
          ? crypto.randomUUID()
          : `local-izin-${Date.now()}`,
        companyId: String(baseTalep.companyId ?? resolvedCompanyId),
        employeeId: String(baseTalep.employeeId ?? ''),
        izinTuru: (baseTalep.izinTuru ?? 'yillik') as IzinTalebi['izinTuru'],
        baslangicTarihi: String(baseTalep.baslangicTarihi ?? ''),
        bitisTarihi: String(baseTalep.bitisTarihi ?? ''),
        gunSayisi: Number(baseTalep.gunSayisi ?? 0),
        aciklama: String(baseTalep.aciklama ?? ''),
        yolIzniTalep: Boolean(baseTalep.yolIzniTalep),
        yolIzniGun: Number(baseTalep.yolIzniGun ?? 0),
        seyahatYeri: String(baseTalep.seyahatYeri ?? ''),
        ilDisiSeyahat: Boolean(baseTalep.ilDisiSeyahat),
        belgeUrl: baseTalep.belgeUrl ?? null,
        durum: 'beklemede',
        onaylayanId: null,
        onayTarihi: null,
        redNedeni: null,
        talepTarihi: String(baseTalep.talepTarihi ?? today),
        createdAt: String(baseTalep.createdAt ?? nowIso),
        updatedAt: String(baseTalep.updatedAt ?? nowIso),
        employeeName: employees.find((emp) => emp.id === baseTalep.employeeId)?.name ?? '',
        department: employees.find((emp) => emp.id === baseTalep.employeeId)?.department ?? '',
      };

      setIzinTalepleri((prev) => [localTalep, ...prev]);
      setShowIzinForm(false);

      if (isPermissionLikeError) {
        alert('İzin talebi yerel olarak eklendi. Veritabanı erişim yetkileri güncellenince otomatik kayıt aktif olacaktır.');
      } else {
        alert(
          `İzin talebi veritabanına kaydedilemedi, yerel olarak eklendi.${err?.message ? `\nDetay: ${err.message}` : ''}`
        );
      }
    }
  };

  const handleIzinUpdate = async (updatedTalep: Partial<IzinTalebi>) => {
    if (!editingIzin) return;
    try {
      await izinService.updateTalep(editingIzin.id, {
        baslangic_tarihi: updatedTalep.baslangicTarihi,
        bitis_tarihi: updatedTalep.bitisTarihi,
        gun_sayisi: updatedTalep.gunSayisi,
        aciklama: updatedTalep.aciklama,
        yol_izni_talep: updatedTalep.yolIzniTalep,
      });
      setEditingIzin(null);
      await loadData();
    } catch (err: any) {
      console.error('İzin güncellenemedi:', err);
      alert(`İzin güncellenemedi!${err?.message ? `\nDetay: ${err.message}` : ''}`);
    }
  };

  // ── Bordro save ─────────────────────────────────────────────────────────────
  const handleSaveBordro = async (bordro: BordroItem) => {
    const normalizedBordro = {
      ...bordro,
      brut_maas: bordro.brut_maas ?? (bordro as any).temelKazanc ?? 0,
      net_maas: bordro.net_maas ?? (bordro as any).netMaas ?? 0,
      toplam_kesinti: bordro.toplam_kesinti ?? (bordro as any).toplamKesinti ?? 0,
      employees: (bordro as any).employees ?? (selectedEmployee
        ? { name: selectedEmployee.name, department: selectedEmployee.department }
        : undefined),
    } as BordroItem;

    setBordrolar((prev) => {
      const idx = prev.findIndex((item) => item.id === normalizedBordro.id);
      if (idx === -1) return [normalizedBordro, ...prev];

      const next = [...prev];
      next[idx] = { ...next[idx], ...normalizedBordro };
      return next;
    });
  };

  const handleViewBordro = (bordro: BordroItem) => {
    setSelectedBordro(bordro);
  };

  const handleEditBordro = (bordro: BordroItem) => {
    // Edit ekranı henüz ayrı değil; mevcutta detay modalı üzerinden işlem akışını açıyoruz.
    setSelectedBordro(bordro);
  };

  const handleSendBordroForApproval = (bordro: BordroItem) => {
    setSelectedBordro(bordro);
  };

  const handleDeleteBordro = async (id: string) => {
    try {
      await bordroService.delete(id);
      if (selectedBordro?.id === id) {
        setSelectedBordro(null);
      }
      await loadData();
    } catch (err: any) {
      console.error('Bordro silinemedi:', err);
      alert(`Bordro silinemedi!${err?.message ? `\nDetay: ${err.message}` : ''}`);
    }
  };

  // ── Auth guard ──────────────────────────────────────────────────────────────
  if (authLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="w-8 h-8 border-4 border-blue-200 border-t-blue-600 rounded-full animate-spin" />
      </div>
    );
  }

  if (!user) {
    return <Login />;
  }

  // ── Render ──────────────────────────────────────────────────────────────────
  const renderContent = () => {
    // ── Arama Sayfası — tam ekran ─────────────────────────────────
    if (currentView === 'arama') {
      return (
        <div className="flex-1 overflow-y-auto">
          <SearchPage
            employees={employees}
            izinTalepleri={izinTalepleri}
            bordrolar={bordrolar}
            onEmployeeClick={(emp) => { handleEmployeeClick(emp); }}
            onNavigate={(view) => setCurrentView(view)}
          />
        </div>
      );
    }

    // ── Tüm diğer görünümler ─────────────────────────────────────────────────
    return (
      <main className="flex-1 overflow-y-auto p-6 bg-gray-50">

        {/* Personel listesi */}
        {currentView === 'personel' && (
          <>
            <Toolbar
              selectedDepartment={selectedDepartment}
              onDepartmentChange={setSelectedDepartment}
              selectedCompany={selectedCompany}
              onCompanyChange={setSelectedCompany}
              onNewEmployee={handleNewEmployee}
              onExportCSV={handleExportCSV}
              companies={companies}
              departments={departments}
            />
            <StatsCards stats={stats} />
            <EmployeeTable
              employees={filteredEmployees}
              onEmployeeClick={handleEmployeeClick}
              onDeleteEmployee={handleDeleteEmployee}
              onEmployeeActionSelect={handleEmployeeActionSelect}
            />
            <div className="grid grid-cols-1 xl:grid-cols-2 gap-4 mt-4">
              <QuickActions
                onBulkLeave={() => setCurrentView('izin')}
                onBulkAlert={() => setCurrentView('uyari')}
                onUploadPayroll={() => setCurrentView('bordro')}
              />
              <UpcomingEvents />
            </div>
          </>
        )}

        {/* Görev Tanımı */}
        {currentView === 'gorev-tanimi' && <GorevTanimi mode="form" employees={employees} />}
        {currentView === 'gorev-tanimi-kayitlari' && <GorevTanimi mode="records" employees={employees} />}

        {/* Özlük Dosyası */}
        {currentView === 'ozluk-dosyasi' && (
          <OzlukDosyasi
            employees={employees}
            izinTalepleri={izinTalepleri}
            izinHaklari={izinHaklari}
            bordrolar={bordrolar}
          />
        )}

        {/* Bordro */}
        {currentView === 'bordro' && (
          <BordroMain
            employees={employees}
            onSaveBordro={handleSaveBordro}
            bordrolar={bordrolar}
            onEdit={handleEditBordro}
            onDelete={handleDeleteBordro}
            onView={handleViewBordro}
            onSendForApproval={handleSendBordroForApproval}
          />
        )}
        {currentView === 'bordro-onay' && <BordroOnayYonetimi />}

        {/* İzin Yönetimi */}
        {currentView === 'izin' && (
          <div className="space-y-6">
            <div className="flex items-center justify-between mb-2">
              <h2 className="text-xl font-bold text-gray-800">İzin Yönetimi</h2>
              <button
                onClick={() => setShowIzinForm(true)}
                className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-xl text-sm font-medium hover:bg-blue-700 transition-colors"
              >
                + Yeni İzin Talebi
              </button>
            </div>

            <div className="rounded-2xl border border-indigo-200 bg-indigo-50 p-5">
              <div className="flex flex-wrap items-start justify-between gap-4">
                <div>
                  <p className="text-xs font-semibold uppercase tracking-wide text-indigo-700">Aktif Kullanıcı İzin Özeti</p>
                  <h3 className="mt-1 text-lg font-bold text-indigo-900">{profile?.full_name || 'Kullanıcı'}</h3>
                  <p className="mt-1 text-sm text-indigo-800">
                    {currentEmployeeForIzin
                      ? `${currentEmployeeForIzin.department || 'Departman belirtilmedi'} • ${currentEmployeeForIzin.position || 'Pozisyon belirtilmedi'}`
                      : 'Personel kaydı eşleşmedi'}
                  </p>
                </div>
                <div className="grid grid-cols-2 gap-3 min-w-[220px]">
                  <div className="rounded-xl bg-white px-3 py-2 border border-indigo-100">
                    <p className="text-[11px] text-indigo-500">Kullanılan</p>
                    <p className="text-lg font-bold text-indigo-900">{currentEmployeeIzinHakki?.kullanilanIzin ?? 0} gün</p>
                  </div>
                  <div className="rounded-xl bg-white px-3 py-2 border border-indigo-100">
                    <p className="text-[11px] text-indigo-500">Kalan</p>
                    <p className="text-lg font-bold text-indigo-900">{currentEmployeeIzinHakki?.kalanIzin ?? 0} gün</p>
                  </div>
                </div>
              </div>

              <div className="mt-4 rounded-xl bg-white border border-indigo-100 p-3">
                <p className="text-xs font-semibold text-gray-600 mb-2">Son İzin Talepleri</p>
                {currentEmployeeIzinTalepleri.length === 0 ? (
                  <p className="text-sm text-gray-500">Bu kullanıcıya ait izin talebi bulunamadı.</p>
                ) : (
                  <div className="space-y-2">
                    {currentEmployeeIzinTalepleri.map((talep) => (
                      <div key={talep.id} className="flex flex-wrap items-center justify-between gap-2 rounded-lg border border-gray-100 px-3 py-2">
                        <p className="text-sm font-medium text-gray-800">{talep.izinTuru} • {talep.gunSayisi} gün</p>
                        <p className="text-xs text-gray-500">{talep.baslangicTarihi} - {talep.bitisTarihi} • {talep.durum}</p>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>

            {/* Özet kartlar + personel izin durumu */}
            <IzinOzetKartlari
              employees={employees}
              izinTalepleri={izinTalepleri}
              izinHaklari={izinHaklari}
            />

            {showIzinForm && (
              <IzinTalepForm
                employees={employees}
                izinHaklari={izinHaklari}
                onSubmit={handleIzinSubmit}
                onClose={() => setShowIzinForm(false)}
              />
            )}

            {editingIzin && (
              <IzinDuzenlemeForm
                talep={editingIzin}
                employee={employees.find((e) => e.id === editingIzin.employeeId) ?? employees[0]}
                onSubmit={handleIzinUpdate}
                onClose={() => setEditingIzin(null)}
              />
            )}

            <IzinTakvimi izinTalepleri={izinTalepleri} />
          </div>
        )}

        {/* Raporlar */}
        {currentView === 'raporlar' && (
          <IzinRaporlari
            employees={employees}
            izinTalepleri={izinTalepleri}
            izinHaklari={izinHaklari}
          />
        )}

        {/* PDKS */}
        {currentView === 'pdks' && (
          <PDKSYonetimi
            employees={employees}
            izinTalepleri={izinTalepleri}
          />
        )}

        {/* Performans */}
        {currentView === 'performans' && <PerformansYonetimi employees={employees} />}

        {/* İşe Alım ATS */}
        {currentView === 'ise-alim' && <IseAlimATS />}

        {/* Eğitim LMS */}
        {currentView === 'egitim' && <EgitimLMS employees={employees} />}

        {/* Analitik Dashboard */}
        {currentView === 'analitik' && (
          <AnalitiKDashboard
            employees={employees}
            izinTalepleri={izinTalepleri}
            izinHaklari={izinHaklari}
            bordrolar={bordrolar}
          />
        )}

        {/* KVKK Uyumluluk */}
        {currentView === 'kvkk' && <KVKKUyumluluk />}

        {/* İzin Türleri Tanımları */}
        {currentView === 'izin-tanimlari' && <IzinTanimlari />}

        {/* Organizasyon Şeması */}
        {currentView === 'org-sema' && <OrganizasyonSemasi employees={employees} />}

        {/* Zimmet Yönetimi */}
        {currentView === 'zimmet' && <ZimmetYonetimi employees={employees} />}

        {/* OKR Yönetimi */}
        {currentView === 'okr' && <OKRYonetimi employees={employees} />}

        {/* Yetkinlik Matrisi */}
        {currentView === 'yetkinlik' && <YetkinlikMatrisi employees={employees} />}

        {/* ATS → Onboarding Akışı */}
        {currentView === 'onboarding' && <OnboardingAkisi />}

        {/* Esnek Yan Haklar */}
        {currentView === 'yan-haklar' && <EsnekYanHaklar employees={employees} />}

        {/* İzin Çakışma Kontrolü */}
        {currentView === 'izin-cakisma' && <IzinCakismaKontrol employees={employees} />}

        {/* Dinamik Form Builder */}
        {currentView === 'form-builder' && <DinamikFormBuilder />}

        {/* Uyarılar & Takvim */}
        {currentView === 'uyari' && (
          <TakvimYonetimi
            employees={employees}
            izinTalepleri={izinTalepleri}
            bordrolar={bordrolar}
          />
        )}

        {/* Kullanıcı Yönetimi */}
        {currentView === 'kullanicilar' && <KullanicilarPage />}

        {/* Sistem Ayarları */}
        {currentView === 'ayar' && <SistemAyarlari />}

        {/* Kullanım Kılavuzu */}
        {currentView === 'kullanim-kilavuzu' && (
          <iframe
            src="/kullanim-kilavuzu.html"
            className="w-full rounded-2xl border border-gray-200 bg-white"
            style={{ height: 'calc(100vh - 96px)' }}
            title="Kullanım Kılavuzu"
          />
        )}

        {/* Fallback: tanımsız görünümde boş sayfa yerine bilgilendirme göster */}
        {![
          'personel',
          'gorev-tanimi',
          'gorev-tanimi-kayitlari',
          'ozluk-dosyasi',
          'bordro',
          'bordro-onay',
          'izin',
          'raporlar',
          'pdks',
          'performans',
          'ise-alim',
          'egitim',
          'analitik',
          'kvkk',
          'izin-tanimlari',
          'org-sema',
          'zimmet',
          'okr',
          'yetkinlik',
          'onboarding',
          'yan-haklar',
          'izin-cakisma',
          'form-builder',
          'uyari',
          'kullanicilar',
          'ayar',
          'kullanim-kilavuzu',
        ].includes(currentView) && (
          <div className="bg-white border border-amber-200 rounded-xl p-6">
            <h2 className="text-lg font-semibold text-amber-700">Sayfa görüntülenemedi</h2>
            <p className="text-sm text-gray-600 mt-2">Bu görünüm için içerik bulunamadı. Lütfen menüden başka bir sayfa seçin.</p>
          </div>
        )}
      </main>
    );
  };

  return (
    <GuideContextMenu onNavigate={(v) => setCurrentView(v as View)}>
    <div className="flex h-screen overflow-hidden bg-gray-50">
      <AppSectionErrorBoundary
        resetKey={currentView}
        fallback={
          <aside className="w-64 bg-white border-r border-gray-200 p-5 sticky top-0 h-screen overflow-y-auto shadow-sm">
            <h2 className="text-sm font-semibold text-gray-800">Menü geçici olarak yüklenemedi</h2>
            <p className="text-xs text-gray-500 mt-2">Bir sayfa seçerek devam edebilirsiniz.</p>
            <div className="mt-4 space-y-2">
              <button onClick={() => setCurrentView('arama')} className="w-full text-left px-3 py-2 rounded-lg border border-gray-200 text-sm hover:bg-gray-50">Arama</button>
              <button onClick={() => setCurrentView('personel')} className="w-full text-left px-3 py-2 rounded-lg border border-gray-200 text-sm hover:bg-gray-50">Personel</button>
              <button onClick={() => setCurrentView('izin')} className="w-full text-left px-3 py-2 rounded-lg border border-gray-200 text-sm hover:bg-gray-50">İzin</button>
              <button onClick={() => setCurrentView('bordro')} className="w-full text-left px-3 py-2 rounded-lg border border-gray-200 text-sm hover:bg-gray-50">Bordro</button>
            </div>
          </aside>
        }
      >
        <Sidebar
          currentView={currentView}
          onViewChange={setCurrentView}
          searchTerm={searchTerm}
          onSearchChange={setSearchTerm}
        />
      </AppSectionErrorBoundary>

      <AppSectionErrorBoundary
        resetKey={currentView}
        fallback={
          <main className="flex-1 overflow-y-auto p-6 bg-gray-50">
            <div className="bg-white border border-red-200 rounded-xl p-6">
              <h2 className="text-lg font-semibold text-red-700">Sayfa yüklenirken bir hata oluştu</h2>
              <p className="text-sm text-gray-600 mt-2">Lütfen başka bir menüye geçin veya tekrar deneyin.</p>
            </div>
          </main>
        }
      >
        {renderContent()}
      </AppSectionErrorBoundary>

      <EmployeeDrawer
        isOpen={drawerOpen}
        employee={selectedEmployee}
        isNew={isNewEmployee}
        onClose={() => setDrawerOpen(false)}
        onSave={handleSaveEmployee}
        onDelete={handleDeleteEmployee}
        companies={companies}
        departments={departments}
      />

      {selectedBordro && (
        <BordroViewModal
          bordro={selectedBordro}
          employeeId={selectedBordro.employee_id}
          employeeName={
            (selectedBordro as any).employees?.name ??
            employees.find((employee) => employee.id === selectedBordro.employee_id)?.name ??
            'Personel'
          }
          onClose={() => setSelectedBordro(null)}
          onApprovalComplete={loadData}
        />
      )}
    </div>
    </GuideContextMenu>
  );
};

// ─── Root (provides contexts) ─────────────────────────────────────────────────

const App: React.FC = () => (
  <AuthProvider>
    <LanguageProvider>
      <AppInner />
    </LanguageProvider>
  </AuthProvider>
);

export default App;

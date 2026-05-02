import React, { useState } from 'react';
import { Search, Users, Calendar, FileText, CreditCard, Bell, Settings, CreditCard as Edit2, SearchIcon, FolderOpen } from 'lucide-react';
import { View } from '../types';
import { useLanguage } from '../contexts/LanguageContext';
import { useAuth } from '../contexts/AuthContext';
import LanguageSelector from './LanguageSelector';
import LogoEditor, { LogoConfig } from './LogoEditor';
import { canAccessView, getRoleLabel } from '../auth/roles';

const DEFAULT_LOGO_SRC = '/humanius-original.png';
const LEGACY_LOGO_SRCS = ['/14.png', '/humanius-logo.svg'];

const safeReadLocalStorage = (key: string) => {
  try {
    return localStorage.getItem(key);
  } catch {
    return null;
  }
};

const safeWriteLocalStorage = (key: string, value: string) => {
  try {
    localStorage.setItem(key, value);
    return true;
  } catch {
    return false;
  }
};

interface SidebarProps {
  currentView: View;
  onViewChange: (view: View) => void;
  searchTerm: string;
  onSearchChange: (term: string) => void;
}

const Sidebar: React.FC<SidebarProps> = ({
  currentView,
  onViewChange,
  searchTerm,
  onSearchChange
}) => {
  const { t } = useLanguage();
  const { user, profile, appRole } = useAuth();
  const effectiveRole = user ? appRole : 'admin';
  const [showLogoEditor, setShowLogoEditor] = useState(false);
  const [logoSrc, setLogoSrc] = useState(DEFAULT_LOGO_SRC);
  const [logoConfig, setLogoConfig] = useState<LogoConfig>({
    width: 225,
    height: 75,
    x: 0,
    y: 0,
    rotation: 0
  });

  const handleLogoSave = (config: LogoConfig) => {
    setLogoConfig(config);
    safeWriteLocalStorage('logoConfig', JSON.stringify(config));
  };

  const handleLogoSelect = (nextLogoSrc: string) => {
    setLogoSrc(nextLogoSrc);
    safeWriteLocalStorage('logoSrc', nextLogoSrc);
  };

  React.useEffect(() => {
    const savedLogoSrc = safeReadLocalStorage('logoSrc');
    if (savedLogoSrc && !LEGACY_LOGO_SRCS.includes(savedLogoSrc)) {
      setLogoSrc(savedLogoSrc);
    } else {
      setLogoSrc(DEFAULT_LOGO_SRC);
      safeWriteLocalStorage('logoSrc', DEFAULT_LOGO_SRC);
    }

    const saved = safeReadLocalStorage('logoConfig');
    if (!saved) return;

    try {
      const parsed = JSON.parse(saved) as Partial<LogoConfig>;
      const migratedWidth = parsed.width === 180 ? 225 : parsed.width;
      const migratedHeight = parsed.height === 60 ? 75 : parsed.height;

      setLogoConfig((prev) => ({
        ...prev,
        ...(typeof migratedWidth === 'number' ? { width: migratedWidth } : {}),
        ...(typeof migratedHeight === 'number' ? { height: migratedHeight } : {}),
        ...(typeof parsed.x === 'number' ? { x: parsed.x } : {}),
        ...(typeof parsed.y === 'number' ? { y: parsed.y } : {}),
        ...(typeof parsed.rotation === 'number' ? { rotation: parsed.rotation } : {}),
      }));
    } catch {
      try {
        localStorage.removeItem('logoConfig');
      } catch {
        // ignore storage cleanup failures
      }
    }
  }, []);

  const navItems = [
    { id: 'arama' as View, label: 'Arama', icon: SearchIcon },
    { id: 'personel' as View, label: t('sidebar.allPersonnel'), icon: Users, children: [
      { id: 'gorev-tanimi' as View, label: 'Görev Tanımı' },
      { id: 'gorev-tanimi-kayitlari' as View, label: 'Görev Tanımı Kayıtları' },
      { id: 'ozluk-dosyasi' as View, label: 'Özlük Dosyası' },
    ]},
    { id: 'bordro' as View, label: t('sidebar.payroll'), icon: CreditCard, children: [
      { id: 'bordro-onay' as View, label: 'Bordro Onay İşlemleri' }
    ]},
    { id: 'izin' as View, label: t('sidebar.leaveManagement'), icon: Calendar },
    { id: 'raporlar' as View, label: t('sidebar.reports'), icon: FileText },
    { id: 'uyari' as View, label: t('sidebar.alertsCalendar'), icon: Bell },
    { id: 'ayar' as View, label: t('sidebar.systemSettings'), icon: Settings },
  ].filter((item) => canAccessView(effectiveRole, item.id));

  return (
    <aside className="w-64 bg-white border-r border-gray-200 p-5 sticky top-0 h-screen overflow-y-auto shadow-sm">
      {/* Brand */}
      <div className="relative group mb-5">
        <div className="flex items-center justify-center p-3 bg-gray-50 rounded-xl border border-gray-200">
          <img
            src={logoSrc}
            alt="Logo"
            style={{
              width: `${logoConfig.width}px`,
              height: `${logoConfig.height}px`,
              transform: `rotate(${logoConfig.rotation}deg)`,
              maxWidth: '100%',
              objectFit: 'contain'
            }}
            className="transition-transform"
          />
        </div>
        <button
          onClick={() => setShowLogoEditor(true)}
          className="absolute top-2 right-2 p-2 bg-white rounded-lg shadow-md opacity-0 group-hover:opacity-100 transition-opacity hover:bg-gray-50"
          title="Logo'yu Düzenle"
        >
          <Edit2 className="w-4 h-4 text-gray-600" />
        </button>
      </div>

      <div className="mb-4 rounded-xl border border-gray-200 bg-gray-50 p-3">
        <p className="text-sm font-semibold text-gray-800">{profile?.full_name || 'Demo Kullanici'}</p>
        <p className="mt-0.5 text-xs text-gray-400">{profile?.company_id ? '' : 'Humanius Demo Sirketi'}</p>
        <p className="mt-1 text-xs text-gray-500">{getRoleLabel(effectiveRole)}</p>
      </div>

      {showLogoEditor && (
        <LogoEditor
          logoSrc={logoSrc}
          onClose={() => setShowLogoEditor(false)}
          onSave={handleLogoSave}
          onLogoSelect={handleLogoSelect}
          initialConfig={logoConfig}
        />
      )}
      {/* Search */}
      <div className="relative mb-4">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
        <input
          type="text"
          placeholder={t('sidebar.searchPlaceholder')}
          value={searchTerm}
          onChange={(e) => onSearchChange(e.target.value)}
          className="w-full bg-gray-50 border border-gray-200 text-gray-800 rounded-xl py-2.5 pl-10 pr-4 outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100 transition-all"
        />
      </div>

      {/* Navigation */}
      <nav className="space-y-2">
        {navItems.map(item => {
          const Icon = item.icon;
          const isActive = currentView === item.id;
          const hasChildren = item.children && item.children.length > 0;

          return (
            <div key={item.id}>
              <button
                onClick={() => onViewChange(item.id)}
                className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-xl transition-all ${
                  isActive
                    ? 'bg-blue-50 border border-blue-200 text-blue-700'
                    : 'text-gray-600 hover:bg-gray-50 hover:text-gray-800 border border-transparent'
                }`}
              >
                {isActive && <div className="w-2 h-2 rounded-full bg-blue-500" />}
                <Icon className="w-4 h-4" />
                <span className="font-medium">{item.label}</span>
              </button>
              {hasChildren && (
                <div className="ml-8 mt-1 space-y-1">
                  {item.children.map(child => {
                    const isChildActive = currentView === child.id;
                    return (
                      <button
                        key={child.id}
                        onClick={() => onViewChange(child.id)}
                        className={`w-full flex items-center gap-2 px-3 py-2 rounded-lg text-sm transition-all ${
                          isChildActive
                            ? 'bg-blue-50 text-blue-700 font-medium'
                            : 'text-gray-500 hover:bg-gray-50 hover:text-gray-700'
                        }`}
                      >
                        <FileText className="w-3 h-3" />
                        <span>{child.label}</span>
                      </button>
                    );
                  })}
                </div>
              )}
            </div>
          );
        })}
      </nav>

      {/* Language Selector */}
      <div className="mt-6 pt-4 border-t border-gray-200">
        <LanguageSelector />
      </div>

      {/* Version */}
      <div className="mt-auto pt-6 text-xs text-gray-400">
        v0.1 • Modern React + TypeScript
      </div>
    </aside>
  );
};

export default Sidebar;
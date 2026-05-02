import React, { useState, useEffect } from 'react';
import { X, User, Briefcase, Mail, Phone, MapPin, Calendar, Award } from 'lucide-react';
import { Employee, Company, Department } from '../types';
import { useScrollLock } from '../hooks/useScrollLock';

interface EmployeeDrawerProps {
  isOpen: boolean;
  employee: Employee | null;
  isNew: boolean;
  onClose: () => void;
  onSave: (employee: Employee) => void;
  onDelete: (id: string) => void;
  companies: Company[];
  departments: Department[];
}

const EmployeeDrawer: React.FC<EmployeeDrawerProps> = ({
  isOpen,
  employee,
  isNew,
  onClose,
  onSave,
  onDelete,
  companies,
  departments
}) => {
  useScrollLock(isOpen);

  const [formData, setFormData] = useState<Employee | null>(null);
  const [activeTab, setActiveTab] = useState('genel');

  useEffect(() => {
    if (employee) {
      setFormData({ ...employee });
    }
  }, [employee]);

  if (!isOpen || !formData) return null;

  const handleSave = () => {
    onSave(formData);
  };

  const handleInputChange = (field: keyof Employee, value: any) => {
    setFormData({ ...formData, [field]: value });
  };

  const tabs = [
    { id: 'genel', label: 'Genel Bilgiler', icon: User },
    { id: 'is', label: 'İş Bilgileri', icon: Briefcase },
    { id: 'iletisim', label: 'İletişim', icon: Mail },
    { id: 'yetkinlik', label: 'Yetkinlikler', icon: Award }
  ];

  return (
    <div className="fixed inset-0 z-50">
      <div className="fixed inset-0 bg-black/50" onClick={onClose} />
      <div className={`fixed inset-y-0 right-0 max-w-4xl w-full bg-white border-l border-gray-200 transform transition-transform duration-300 ${
        isOpen ? 'translate-x-0' : 'translate-x-full'
      } flex flex-col`}>
        
        {/* Header */}
        <div className="flex items-center justify-between p-4 border-b border-gray-200">
          <h2 className="text-xl font-bold text-gray-800">
            {isNew ? 'Yeni Personel Ekle' : 'Personel Düzenle'}
          </h2>
          <button
            onClick={onClose}
            className="p-2 text-gray-500 hover:text-gray-700 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Content */}
        <div className="flex flex-1 min-h-0">
          {/* Tabs */}
          <div className="w-72 border-r border-gray-200 p-4 overflow-y-auto">
            <div className="space-y-2">
              {tabs.map(tab => {
                const Icon = tab.icon;
                return (
                  <button
                    key={tab.id}
                    onClick={() => setActiveTab(tab.id)}
                    className={`w-full flex items-center gap-3 p-3 rounded-xl transition-all ${
                      activeTab === tab.id
                        ? 'bg-blue-50 border border-blue-200 text-blue-700'
                        : 'text-gray-600 hover:bg-gray-50 border border-gray-200 bg-white'
                    }`}
                  >
                    <Icon className="w-4 h-4" />
                    {tab.label}
                  </button>
                );
              })}
            </div>

            {/* Actions */}
            <div className="mt-6 space-y-2">
              <button
                onClick={handleSave}
                className="w-full bg-blue-600 text-white py-2.5 rounded-xl font-bold hover:bg-blue-700 transition-colors"
              >
                {isNew ? 'Personel Ekle' : 'Değişiklikleri Kaydet'}
              </button>
              {!isNew && (
                <button
                  onClick={() => onDelete(formData.id)}
                  className="w-full bg-red-600 text-white py-2.5 rounded-xl font-bold hover:bg-red-700 transition-colors"
                >
                  Personeli Sil
                </button>
              )}
              <button
                onClick={onClose}
                className="w-full bg-white border border-gray-200 text-gray-700 py-2.5 rounded-xl font-medium hover:border-blue-300 hover:bg-blue-50 transition-colors"
              >
                İptal
              </button>
            </div>
          </div>

          {/* Form */}
          <div className="flex-1 p-6 overflow-y-auto">
            {activeTab === 'genel' && (
              <div className="space-y-6">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label htmlFor="employee-name" className="block text-sm font-medium text-gray-700 mb-2">Ad Soyad</label>
                    <input
                      id="employee-name"
                      type="text"
                      value={formData.name}
                      onChange={(e) => handleInputChange('name', e.target.value)}
                      className="w-full bg-white border border-gray-200 text-gray-800 rounded-xl px-3 py-2.5 outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100"
                    />
                  </div>
                  <div>
                    <label htmlFor="employee-joindate" className="block text-sm font-medium text-gray-700 mb-2">İşe Giriş Tarihi</label>
                    <input
                      id="employee-joindate"
                      type="date"
                      value={formData.joinDate}
                      onChange={(e) => handleInputChange('joinDate', e.target.value)}
                      className="w-full bg-white border border-gray-200 text-gray-800 rounded-xl px-3 py-2.5 outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100"
                    />
                  </div>
                </div>
              </div>
            )}

            {activeTab === 'is' && (
              <div className="space-y-6">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label htmlFor="employee-company" className="block text-sm font-medium text-gray-700 mb-2">Şirket</label>
                    <select
                      id="employee-company"
                      value={formData.company}
                      onChange={(e) => handleInputChange('company', e.target.value)}
                      className="w-full bg-white border border-gray-200 text-gray-800 rounded-xl px-3 py-2.5 outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100"
                    >
                      {companies.map(company => (
                        <option key={company} value={company}>
                          {company}
                        </option>
                      ))}
                    </select>
                  </div>
                  <div>
                    <label htmlFor="employee-department" className="block text-sm font-medium text-gray-700 mb-2">Departman</label>
                    <select
                      id="employee-department"
                      value={formData.department}
                      onChange={(e) => handleInputChange('department', e.target.value)}
                      className="w-full bg-white border border-gray-200 text-gray-800 rounded-xl px-3 py-2.5 outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100"
                    >
                      {departments.map(dept => (
                        <option key={dept} value={dept}>
                          {dept}
                        </option>
                      ))}
                    </select>
                  </div>
                  <div>
                    <label htmlFor="employee-position" className="block text-sm font-medium text-gray-700 mb-2">Pozisyon</label>
                    <input
                      id="employee-position"
                      type="text"
                      value={formData.position}
                      onChange={(e) => handleInputChange('position', e.target.value)}
                      className="w-full bg-white border border-gray-200 text-gray-800 rounded-xl px-3 py-2.5 outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100"
                    />
                  </div>
                  <div>
                    <label htmlFor="employee-type" className="block text-sm font-medium text-gray-700 mb-2">Çalışan Tipi</label>
                    <select
                      id="employee-type"
                      value={formData.employeeType}
                      onChange={(e) => handleInputChange('employeeType', e.target.value)}
                      className="w-full bg-white border border-gray-200 text-gray-800 rounded-xl px-3 py-2.5 outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100"
                    >
                      <option value="normal">Normal Çalışan</option>
                      <option value="emekli">Emekli</option>
                    </select>
                  </div>
                  <div>
                    <label htmlFor="employee-level" className="block text-sm font-medium text-gray-700 mb-2">Seviye</label>
                    <select
                      id="employee-level"
                      value={formData.level}
                      onChange={(e) => handleInputChange('level', e.target.value)}
                      className="w-full bg-white border border-gray-200 text-gray-800 rounded-xl px-3 py-2.5 outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100"
                    >
                      <option value="Junior">Junior</option>
                      <option value="Mid">Mid</option>
                      <option value="Senior">Senior</option>
                      <option value="Lead">Lead</option>
                      <option value="Manager">Manager</option>
                    </select>
                  </div>
                  <div>
                    <label htmlFor="employee-salary" className="block text-sm font-medium text-gray-700 mb-2">Maaş (₺)</label>
                    <input
                      id="employee-salary"
                      type="number"
                      value={formData.salary}
                      onChange={(e) => handleInputChange('salary', parseInt(e.target.value) || 0)}
                      className="w-full bg-white border border-gray-200 text-gray-800 rounded-xl px-3 py-2.5 outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100"
                    />
                  </div>
                  <div>
                    <label htmlFor="employee-status" className="block text-sm font-medium text-gray-700 mb-2">Durum</label>
                    <select
                      id="employee-status"
                      value={formData.status}
                      onChange={(e) => handleInputChange('status', e.target.value)}
                      className="w-full bg-white border border-gray-200 text-gray-800 rounded-xl px-3 py-2.5 outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100"
                    >
                      <option value="active">Aktif</option>
                      <option value="onLeave">İzinde</option>
                      <option value="inactive">Pasif</option>
                    </select>
                  </div>
                </div>
              </div>
            )}

            {activeTab === 'iletisim' && (
              <div className="space-y-6">
                <div className="grid grid-cols-1 gap-4">
                  <div>
                    <label htmlFor="employee-phone" className="block text-sm font-medium text-gray-700 mb-2">Telefon</label>
                    <input
                      id="employee-phone"
                      type="tel"
                      value={formData.phone}
                      onChange={(e) => handleInputChange('phone', e.target.value)}
                      className="w-full bg-white border border-gray-200 text-gray-800 rounded-xl px-3 py-2.5 outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100"
                    />
                  </div>
                  <div>
                    <label htmlFor="employee-email" className="block text-sm font-medium text-gray-700 mb-2">Email</label>
                    <input
                      id="employee-email"
                      type="email"
                      value={formData.email}
                      onChange={(e) => handleInputChange('email', e.target.value)}
                      className="w-full bg-white border border-gray-200 text-gray-800 rounded-xl px-3 py-2.5 outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100"
                    />
                  </div>
                  <div>
                    <label htmlFor="employee-address" className="block text-sm font-medium text-gray-700 mb-2">Adres</label>
                    <textarea
                      id="employee-address"
                      value={formData.address}
                      onChange={(e) => handleInputChange('address', e.target.value)}
                      rows={3}
                      className="w-full bg-white border border-gray-200 text-gray-800 rounded-xl px-3 py-2.5 outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100 resize-none"
                    />
                  </div>
                </div>
              </div>
            )}

            {activeTab === 'yetkinlik' && (
              <div className="space-y-6">
                <div>
                  <label htmlFor="employee-skills" className="block text-sm font-medium text-gray-700 mb-2">Yetkinlikler</label>
                  <input
                    id="employee-skills"
                    type="text"
                    value={formData.skills.join(', ')}
                    onChange={(e) => handleInputChange('skills', e.target.value.split(', ').filter(s => s.trim()))}
                    placeholder="React, TypeScript, Node.js (virgülle ayırın)"
                    className="w-full bg-white border border-gray-200 text-gray-800 rounded-xl px-3 py-2.5 outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100"
                  />
                  <p className="text-xs text-gray-500 mt-1">Yetkinlikleri virgülle ayırarak giriniz</p>
                </div>

                {formData.skills.length > 0 && (
                  <div>
                    <p className="text-sm font-medium text-gray-700 mb-2">Mevcut Yetkinlikler:</p>
                    <div className="flex flex-wrap gap-2">
                      {formData.skills.map((skill, index) => (
                        <span
                          key={index}
                          className="bg-blue-50 border border-blue-200 text-blue-700 px-3 py-1 rounded-full text-sm"
                        >
                          {skill}
                        </span>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            )}

          </div>
        </div>
      </div>
    </div>
  );
};

export default EmployeeDrawer;
import React, { useState, useEffect } from 'react';
import { X, MapPin, Upload, CheckCircle, AlertCircle } from 'lucide-react';
import { Employee } from '../types';
import { IzinTalebi } from '../types/izin';
import { formatDate } from '../utils/izinCalculations';
import { useScrollLock } from '../hooks/useScrollLock';

interface IzinDuzenlemeFormProps {
  talep: IzinTalebi;
  employee: Employee;
  onSubmit: (updatedTalep: Partial<IzinTalebi>) => void;
  onClose: () => void;
}

const IzinDuzenlemeForm: React.FC<IzinDuzenlemeFormProps> = ({
  talep,
  employee,
  onSubmit,
  onClose
}) => {
  useScrollLock(true);

  const [formData, setFormData] = useState({
    yolIzniTalep: talep.yolIzniTalep,
    yolIzniGun: talep.yolIzniGun,
    seyahatYeri: talep.seyahatYeri,
    ilDisiSeyahat: talep.ilDisiSeyahat,
    aciklama: talep.aciklama
  });

  const [belgeDosyasi, setBelgeDosyasi] = useState<File | null>(null);
  const [belgeYuklendi, setBelgeYuklendi] = useState(false);

  // Yol izni değiştiğinde kontroller
  useEffect(() => {
    if (formData.yolIzniTalep) {
      setFormData(prev => ({ ...prev, yolIzniGun: prev.yolIzniGun || 4 }));
    } else {
      setFormData(prev => ({ ...prev, yolIzniGun: 0, seyahatYeri: '', ilDisiSeyahat: false }));
      setBelgeDosyasi(null);
      setBelgeYuklendi(false);
    }
  }, [formData.yolIzniTalep]);

  // Belge yükleme
  const handleBelgeYukle = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      // Dosya türü kontrolü
      const allowedTypes = ['application/pdf', 'image/jpeg', 'image/png', 'image/jpg'];
      if (!allowedTypes.includes(file.type)) {
        alert('Sadece PDF, JPG, PNG dosyaları yükleyebilirsiniz.');
        return;
      }

      // Dosya boyutu kontrolü (5MB)
      if (file.size > 5 * 1024 * 1024) {
        alert('Dosya boyutu 5MB\'dan küçük olmalıdır.');
        return;
      }

      setBelgeDosyasi(file);
      setBelgeYuklendi(true);
    }
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    if (formData.yolIzniTalep && formData.ilDisiSeyahat && !belgeYuklendi && !talep.belgeUrl) {
      alert('İl dışı seyahat için belge yüklemeniz gereklidir!');
      return;
    }

    if (formData.yolIzniTalep && !formData.seyahatYeri.trim()) {
      alert('Seyahat yeri belirtmeniz gereklidir!');
      return;
    }

    onSubmit({
      ...formData,
      belgeDosyasi: belgeDosyasi
    });
  };

  const handleInputChange = (field: string, value: any) => {
    setFormData(prev => ({
      ...prev,
      [field]: value
    }));
  };

  return (
    <div className="fixed inset-0 z-50">
      <div className="fixed inset-0 bg-black/50" onClick={onClose} />
      <div className="fixed inset-y-0 right-0 max-w-2xl w-full bg-white border-l border-gray-200 transform transition-transform duration-300 translate-x-0 flex flex-col">
        
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-gray-200">
          <div className="flex items-center gap-3">
            <MapPin className="w-6 h-6 text-blue-600" />
            <h2 className="text-xl font-bold text-gray-800">Yol İzni Ekle/Düzenle</h2>
          </div>
          <button
            onClick={onClose}
            className="p-2 text-gray-500 hover:text-gray-700 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="flex-1 overflow-y-auto p-6 space-y-6">
          {/* Current Leave Information */}
          <div className="bg-gray-50 border border-gray-200 rounded-xl p-4">
            <h3 className="text-lg font-semibold text-gray-800 mb-3">Mevcut Yıllık İzin Bilgileri</h3>
            <div className="grid grid-cols-2 gap-4 text-sm">
              <div>
                <span className="text-gray-600">Personel:</span>
                <span className="text-gray-800 ml-2 font-medium">{talep.employeeName}</span>
              </div>
              <div>
                <span className="text-gray-600">İzin Türü:</span>
                <span className="text-gray-800 ml-2 font-medium">Yıllık İzin</span>
              </div>
              <div>
                <span className="text-gray-600">Tarih Aralığı:</span>
                <span className="text-gray-800 ml-2 font-medium">
                  {formatDate(talep.baslangicTarihi)} - {formatDate(talep.bitisTarihi)}
                </span>
              </div>
              <div>
                <span className="text-gray-600">Gün Sayısı:</span>
                <span className="text-gray-800 ml-2 font-medium">{talep.gunSayisi} gün</span>
              </div>
            </div>
            <div className="mt-3 p-3 bg-blue-50 border border-blue-200 rounded-lg">
              <p className="text-sm text-blue-700">
                <strong>Not:</strong> Onaylanan yıllık izne yol izni eklenebilir. İzin tarihleri ve süresi değiştirilemez.
              </p>
            </div>
          </div>

          {/* Travel Leave Editing */}
          <div className="space-y-4">
            <div className="border-2 border-blue-300 rounded-xl p-5 bg-gradient-to-r from-blue-50 to-blue-100">
              <div className="flex items-center gap-3 mb-3">
                <MapPin className="w-5 h-5 text-blue-600" />
                <h4 className="text-base font-bold text-blue-800">🚗 Yol İzni Düzenle (4 Güne Kadar)</h4>
              </div>

              <div className="bg-white rounded-lg p-3 mb-4 border border-blue-200">
                <div className="flex items-center gap-2 mb-2">
                  <input
                    type="checkbox"
                    id="yolIzni"
                    checked={formData.yolIzniTalep}
                    onChange={(e) => handleInputChange('yolIzniTalep', e.target.checked)}
                    className="w-5 h-5 text-blue-600 bg-white border-gray-300 rounded focus:ring-blue-500"
                  />
                  <label htmlFor="yolIzni" className="text-sm font-medium text-blue-800">
                    ✅ Yıllık iznime ek olarak yol izni kullanmak istiyorum
                  </label>
                </div>
                <div className="text-xs text-blue-600 bg-blue-50 p-2 rounded border border-blue-200">
                  💡 <strong>Bilgi:</strong> Yol izni, yıllık izninizle birlikte kullanabileceğiniz ek bir izindir.
                </div>
              </div>
              
              {formData.yolIzniTalep && (
                <div className="space-y-4 border-t-2 border-blue-200 pt-4">
                  <div className="bg-green-50 border border-green-200 rounded-lg p-3">
                    <div className="flex items-center gap-2 mb-2">
                      <span className="text-green-600 font-bold">🎯 Yol İzni Aktif!</span>
                    </div>
                    <p className="text-sm text-green-700">
                      Toplam izin süresi: <strong>{talep.gunSayisi} gün yıllık izin + {formData.yolIzniGun} gün yol izni = {talep.gunSayisi + formData.yolIzniGun} gün</strong>
                    </p>
                  </div>

                  <div>
                    <label className="block text-sm font-bold text-blue-800 mb-2">
                      📅 Yol İzni Günü (1-4 gün) *
                    </label>
                    <select
                      value={formData.yolIzniGun}
                      onChange={(e) => handleInputChange('yolIzniGun', parseInt(e.target.value))}
                      className="w-full bg-white border-2 border-blue-300 text-gray-800 rounded-lg px-3 py-2.5 outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100"
                      required
                    >
                      <option value={1}>1 gün</option>
                      <option value={2}>2 gün</option>
                      <option value={3}>3 gün</option>
                      <option value={4}>4 gün</option>
                    </select>
                  </div>

                  <div>
                    <label className="block text-sm font-bold text-blue-800 mb-2">
                      🗺️ Seyahat Yeri *
                    </label>
                    <input
                      type="text"
                      value={formData.seyahatYeri}
                      onChange={(e) => handleInputChange('seyahatYeri', e.target.value)}
                      placeholder="Örn: Antalya, İzmir, Trabzon, Bodrum..."
                      className="w-full bg-white border-2 border-blue-300 text-gray-800 rounded-lg px-3 py-2.5 outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100"
                      required
                    />
                  </div>

                  <div className="flex items-center gap-2">
                    <input
                      type="checkbox"
                      id="ilDisi"
                      checked={formData.ilDisiSeyahat}
                      onChange={(e) => handleInputChange('ilDisiSeyahat', e.target.checked)}
                      className="w-4 h-4 text-blue-600 bg-white border-gray-300 rounded focus:ring-blue-500"
                    />
                    <label htmlFor="ilDisi" className="text-sm text-blue-700">
                      İşyerinin bulunduğu şehir dışına seyahat edeceğim
                    </label>
                  </div>
                  
                  {formData.ilDisiSeyahat && (
                    <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-3">
                      <div className="flex items-center gap-2 mb-2">
                        <AlertCircle className="w-4 h-4 text-yellow-600" />
                        <span className="text-sm font-medium text-yellow-800">
                          Belge Yükleme Gereksinimi
                        </span>
                      </div>
                      <p className="text-xs text-yellow-700 mb-3">
                        Şehir dışı seyahat için rezervasyon belgesi, uçak bileti veya benzeri kanıt belgesi yüklemeniz gerekmektedir.
                      </p>

                      <div className="space-y-2">
                        <label className="block text-sm font-medium text-yellow-800">
                          Belge Yükle (PDF, JPG, PNG - Maks 5MB) *
                        </label>
                        <div className="flex items-center gap-2">
                          <input
                            type="file"
                            accept=".pdf,.jpg,.jpeg,.png"
                            onChange={handleBelgeYukle}
                            className="hidden"
                            id="belgeYukle"
                          />
                          <label
                            htmlFor="belgeYukle"
                            className="flex items-center gap-2 bg-white border border-yellow-300 text-yellow-700 px-3 py-2 rounded-lg cursor-pointer hover:bg-yellow-50 transition-colors"
                          >
                            <Upload className="w-4 h-4" />
                            Belge Seç
                          </label>
                          {(belgeYuklendi || talep.belgeUrl) && (
                            <div className="flex items-center gap-2 text-green-600">
                              <CheckCircle className="w-4 h-4" />
                              <span className="text-sm">
                                {belgeDosyasi?.name || 'Mevcut belge mevcut'}
                              </span>
                            </div>
                          )}
                        </div>
                      </div>
                    </div>
                  )}
                </div>
              )}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Açıklama</label>
              <textarea
                value={formData.aciklama}
                onChange={(e) => handleInputChange('aciklama', e.target.value)}
                rows={3}
                placeholder="İzin talebi hakkında açıklama..."
                className="w-full bg-white border border-gray-200 text-gray-800 rounded-xl px-3 py-2.5 outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100 resize-none"
              />
            </div>
          </div>
        </form>

        {/* Footer */}
        <div className="flex items-center justify-end gap-3 p-6 border-t border-gray-200">
          <button
            type="button"
            onClick={onClose}
            className="px-4 py-2 text-gray-700 bg-white border border-gray-200 rounded-lg font-medium hover:bg-gray-50 transition-colors"
          >
            İptal
          </button>
          <button
            onClick={handleSubmit}
            disabled={
              formData.yolIzniTalep && formData.ilDisiSeyahat && !belgeYuklendi && !talep.belgeUrl
            }
            className="px-4 py-2 bg-blue-600 text-white rounded-lg font-bold hover:bg-blue-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Güncelle
          </button>
        </div>
      </div>
    </div>
  );
};

export default IzinDuzenlemeForm;
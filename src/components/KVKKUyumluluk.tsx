import React, { useState } from 'react';
import { Shield, Lock, Eye, FileText, AlertTriangle, CheckCircle, Clock, Download, User, Database, Key, Globe } from 'lucide-react';

interface VeriKategori {
  id: string;
  ad: string;
  aciklama: string;
  hassasiyet: 'kisisel' | 'ozel-nitelikli' | 'genel';
  saklama: string;
  sifreli: boolean;
  erisimLog: boolean;
}

interface AuditLog {
  id: string;
  kullanici: string;
  rol: string;
  eylem: string;
  kaynak: string;
  ip: string;
  tarih: string;
  sonuc: 'basarili' | 'basarisiz' | 'uyari';
}

interface VeriSahibiHakki {
  hak: string;
  aciklama: string;
  destekleniyor: boolean;
  mekanizma: string;
}

const VERI_KATEGORILERI: VeriKategori[] = [
  { id: 'kimlik', ad: 'Kimlik Bilgileri', aciklama: 'Ad, soyad, TC No, doğum tarihi', hassasiyet: 'kisisel', saklama: 'İş ilişkisi + 10 yıl', sifreli: true, erisimLog: true },
  { id: 'iletisim', ad: 'İletişim Bilgileri', aciklama: 'E-posta, telefon, adres', hassasiyet: 'kisisel', saklama: 'İş ilişkisi + 5 yıl', sifreli: true, erisimLog: true },
  { id: 'mali', ad: 'Mali Veriler', aciklama: 'Maaş, banka bilgileri, bordro', hassasiyet: 'kisisel', saklama: '10 yıl (vergi mevzuatı)', sifreli: true, erisimLog: true },
  { id: 'saglik', ad: 'Sağlık Verileri', aciklama: 'Hastalık raporu, engellilik durumu', hassasiyet: 'ozel-nitelikli', saklama: 'İş ilişkisi + 15 yıl', sifreli: true, erisimLog: true },
  { id: 'izin', ad: 'İzin & Devam Verileri', aciklama: 'İzin talepleri, PDKS kayıtları', hassasiyet: 'kisisel', saklama: '5 yıl', sifreli: true, erisimLog: false },
  { id: 'performans', ad: 'Performans Verileri', aciklama: 'Değerlendirme sonuçları, KPI', hassasiyet: 'kisisel', saklama: '3 yıl', sifreli: false, erisimLog: true },
  { id: 'cv', ad: 'İşe Alım Verileri', aciklama: 'CV, mülakat notları, referans', hassasiyet: 'kisisel', saklama: '2 yıl (reddedilen adaylar)', sifreli: false, erisimLog: false },
];

const DEMO_AUDIT_LOGS: AuditLog[] = [
  { id: 'l1', kullanici: 'admin@sirket.com', rol: 'Yönetici', eylem: 'Personel Listesi Görüntülendi', kaynak: 'employees', ip: '192.168.1.105', tarih: '2026-05-04 09:15', sonuc: 'basarili' },
  { id: 'l2', kullanici: 'ik@sirket.com', rol: 'İK Uzmanı', eylem: 'Bordro Verisi İndirildi', kaynak: 'bordro/export', ip: '192.168.1.108', tarih: '2026-05-04 10:32', sonuc: 'basarili' },
  { id: 'l3', kullanici: 'user@sirket.com', rol: 'Kullanıcı', eylem: 'Yetkisiz Alan Erişim Denemesi', kaynak: 'kullanicilar', ip: '10.0.0.55', tarih: '2026-05-04 11:04', sonuc: 'basarisiz' },
  { id: 'l4', kullanici: 'admin@sirket.com', rol: 'Yönetici', eylem: 'Çalışan Sağlık Verisi Güncellendi', kaynak: 'employees/health', ip: '192.168.1.105', tarih: '2026-05-04 13:20', sonuc: 'uyari' },
  { id: 'l5', kullanici: 'ik@sirket.com', rol: 'İK Uzmanı', eylem: 'Yeni Aday Kaydedildi', kaynak: 'recruitment/candidates', ip: '192.168.1.108', tarih: '2026-05-04 14:45', sonuc: 'basarili' },
  { id: 'l6', kullanici: 'admin@sirket.com', rol: 'Yönetici', eylem: 'Kullanıcı Yetkisi Değiştirildi', kaynak: 'users/permissions', ip: '192.168.1.105', tarih: '2026-05-04 15:10', sonuc: 'basarili' },
];

const VERI_SAHIBI_HAKLARI: VeriSahibiHakki[] = [
  { hak: 'Bilgi Hakkı', aciklama: 'Hangi verilerinin işlendiğini öğrenme', destekleniyor: true, mekanizma: 'Özlük Dosyası → Veri Özeti' },
  { hak: 'Erişim Hakkı', aciklama: 'Kendi verilerine erişim talep etme', destekleniyor: true, mekanizma: 'Self-Servis Portal / İK Talebi' },
  { hak: 'Düzeltme Hakkı', aciklama: 'Hatalı verilerin düzeltilmesini isteme', destekleniyor: true, mekanizma: 'İK Başvuru Formu' },
  { hak: 'Silme Hakkı', aciklama: 'Verilerinin silinmesini talep etme (yasal süre sonrası)', destekleniyor: true, mekanizma: 'İK Talebi + Hukuk Onayı' },
  { hak: 'İtiraz Hakkı', aciklama: 'Veri işlemeye itiraz etme', destekleniyor: true, mekanizma: 'Resmi Başvuru Formu' },
  { hak: 'Taşınabilirlik', aciklama: 'Verilerini yapılandırılmış formatta alma', destekleniyor: false, mekanizma: 'Geliştirme Aşamasında' },
];

const hassasiyetRengi = {
  'kisisel': 'bg-blue-100 text-blue-700',
  'ozel-nitelikli': 'bg-red-100 text-red-700',
  'genel': 'bg-gray-100 text-gray-600',
};

const hassasiyetEtiketi = {
  'kisisel': 'Kişisel Veri',
  'ozel-nitelikli': 'Özel Nitelikli',
  'genel': 'Genel Veri',
};

const KVKKUyumluluk: React.FC = () => {
  const [aktifSekme, setAktifSekme] = useState<'genel' | 'veri-envanteri' | 'audit-log' | 'haklar'>('genel');

  const uyumlulukSkoru = 87;
  const kritikEksikler = 2;
  const tamamlananKontroller = 22;
  const toplamKontrol = 26;

  return (
    <div className="space-y-6">
      {/* Başlık */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl font-bold text-gray-800">KVKK / GDPR Uyumluluk</h2>
          <p className="text-sm text-gray-500 mt-0.5">
            Veri gizliliği, şifreleme, yetki bazlı erişim ve audit log yönetimi
          </p>
        </div>
        <button className="flex items-center gap-2 border border-gray-200 text-gray-600 px-4 py-2 rounded-xl text-sm hover:bg-gray-50">
          <Download className="w-4 h-4" />
          Uyumluluk Raporu
        </button>
      </div>

      {/* Uyumluluk Skoru Özeti */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="bg-white rounded-2xl border border-gray-200 p-5 flex items-center gap-4 md:col-span-1">
          <div className="relative w-20 h-20 flex-shrink-0">
            <svg viewBox="0 0 36 36" className="w-20 h-20 -rotate-90">
              <circle cx="18" cy="18" r="15.9" fill="none" stroke="#f3f4f6" strokeWidth="3.5" />
              <circle
                cx="18" cy="18" r="15.9" fill="none"
                stroke={uyumlulukSkoru >= 80 ? '#22c55e' : uyumlulukSkoru >= 60 ? '#f59e0b' : '#ef4444'}
                strokeWidth="3.5"
                strokeDasharray={`${uyumlulukSkoru} ${100 - uyumlulukSkoru}`}
                strokeLinecap="round"
              />
            </svg>
            <div className="absolute inset-0 flex items-center justify-center">
              <span className="text-lg font-bold text-gray-800">%{uyumlulukSkoru}</span>
            </div>
          </div>
          <div>
            <p className="text-sm font-semibold text-gray-700">Uyumluluk Skoru</p>
            <p className="text-xs text-gray-400">{tamamlananKontroller}/{toplamKontrol} kontrol</p>
          </div>
        </div>

        <div className="bg-white rounded-2xl border border-green-200 p-4">
          <div className="flex items-center gap-2 mb-1">
            <CheckCircle className="w-4 h-4 text-green-600" />
            <p className="text-xs font-semibold text-green-700">Tamamlanan</p>
          </div>
          <p className="text-2xl font-bold text-green-600">{tamamlananKontroller}</p>
          <p className="text-xs text-gray-400">güvenlik kontrolü</p>
        </div>

        <div className="bg-white rounded-2xl border border-red-200 p-4">
          <div className="flex items-center gap-2 mb-1">
            <AlertTriangle className="w-4 h-4 text-red-500" />
            <p className="text-xs font-semibold text-red-600">Kritik Eksik</p>
          </div>
          <p className="text-2xl font-bold text-red-500">{kritikEksikler}</p>
          <p className="text-xs text-gray-400">acil aksiyon gerekli</p>
        </div>

        <div className="bg-white rounded-2xl border border-gray-200 p-4">
          <div className="flex items-center gap-2 mb-1">
            <Shield className="w-4 h-4 text-indigo-600" />
            <p className="text-xs font-semibold text-indigo-700">Şifreli Veri</p>
          </div>
          <p className="text-2xl font-bold text-indigo-600">AES-256</p>
          <p className="text-xs text-gray-400">at-rest şifreleme</p>
        </div>
      </div>

      {/* Sekmeler */}
      <div className="flex gap-2 border-b border-gray-200">
        {(['genel', 'veri-envanteri', 'audit-log', 'haklar'] as const).map((s) => (
          <button
            key={s}
            onClick={() => setAktifSekme(s)}
            className={`px-4 py-2.5 text-sm font-medium border-b-2 transition-colors ${
              aktifSekme === s ? 'border-indigo-600 text-indigo-600' : 'border-transparent text-gray-500 hover:text-gray-700'
            }`}
          >
            {s === 'genel' ? 'Genel Durum' : s === 'veri-envanteri' ? 'Veri Envanteri' : s === 'audit-log' ? 'Erişim Logu' : 'Veri Sahibi Hakları'}
          </button>
        ))}
      </div>

      {/* Genel Durum */}
      {aktifSekme === 'genel' && (
        <div className="space-y-4">
          {/* Güvenlik Mimarisi */}
          <div className="bg-white rounded-2xl border border-gray-200 p-5">
            <h3 className="text-sm font-semibold text-gray-700 mb-4">Güvenlik Mimarisi</h3>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              {[
                { icon: <Database className="w-5 h-5 text-green-600" />, label: 'At-Rest Şifreleme', deger: 'AES-256', renk: 'bg-green-100', durum: true },
                { icon: <Globe className="w-5 h-5 text-green-600" />, label: 'Transit Şifreleme', deger: 'TLS 1.3', renk: 'bg-green-100', durum: true },
                { icon: <Key className="w-5 h-5 text-green-600" />, label: 'Erişim Kontrolü', deger: 'RBAC', renk: 'bg-green-100', durum: true },
                { icon: <Eye className="w-5 h-5 text-yellow-600" />, label: 'Veri Maskeleme', deger: 'Kısmi', renk: 'bg-yellow-100', durum: false },
              ].map((item, i) => (
                <div key={i} className="text-center p-3 bg-gray-50 rounded-xl">
                  <div className={`w-10 h-10 rounded-xl ${item.renk} flex items-center justify-center mx-auto mb-2`}>
                    {item.icon}
                  </div>
                  <p className="text-xs font-semibold text-gray-700">{item.label}</p>
                  <p className="text-sm font-bold text-gray-800 mt-0.5">{item.deger}</p>
                  <span className={`text-[10px] ${item.durum ? 'text-green-600' : 'text-yellow-600'}`}>
                    {item.durum ? '✓ Aktif' : '⚠ Geliştiriliyor'}
                  </span>
                </div>
              ))}
            </div>
          </div>

          {/* Kontrol Listesi */}
          <div className="bg-white rounded-2xl border border-gray-200 p-5">
            <h3 className="text-sm font-semibold text-gray-700 mb-4">KVKK Uyumluluk Kontrol Listesi</h3>
            <div className="space-y-2">
              {[
                { kontrol: 'Kişisel Veri Envanteri hazırlandı', durum: true, oncelik: 'yuksek' },
                { kontrol: 'Açık rıza metinleri güncel', durum: true, oncelik: 'yuksek' },
                { kontrol: 'Veri işleme amaçları tanımlandı', durum: true, oncelik: 'yuksek' },
                { kontrol: 'KVKK Kurulu kaydı yapıldı', durum: true, oncelik: 'yuksek' },
                { kontrol: 'Veri güvenliği politikası yayınlandı', durum: true, oncelik: 'orta' },
                { kontrol: 'Personel KVKK eğitimi tamamlandı', durum: true, oncelik: 'orta' },
                { kontrol: 'Veri ihlal bildirim prosedürü hazır', durum: true, oncelik: 'yuksek' },
                { kontrol: 'Üçüncü taraf veri işleyici sözleşmeleri', durum: false, oncelik: 'yuksek' },
                { kontrol: 'Veri silme/imha prosedürü aktif', durum: true, oncelik: 'orta' },
                { kontrol: 'DPO (Veri Sorumlusu Temsilcisi) atandı', durum: false, oncelik: 'yuksek' },
                { kontrol: 'Uluslararası veri aktarım sözleşmeleri', durum: true, oncelik: 'dusuk' },
                { kontrol: 'Çerez politikası güncel', durum: true, oncelik: 'dusuk' },
              ].map((item, i) => (
                <div key={i} className={`flex items-center justify-between p-3 rounded-xl ${item.durum ? 'bg-green-50' : 'bg-red-50'}`}>
                  <div className="flex items-center gap-2">
                    {item.durum
                      ? <CheckCircle className="w-4 h-4 text-green-600 flex-shrink-0" />
                      : <AlertTriangle className="w-4 h-4 text-red-500 flex-shrink-0" />}
                    <p className={`text-sm ${item.durum ? 'text-green-800' : 'text-red-700 font-medium'}`}>{item.kontrol}</p>
                  </div>
                  <span className={`text-[10px] px-2 py-0.5 rounded-full font-medium ${
                    item.oncelik === 'yuksek' ? 'bg-red-100 text-red-600' :
                    item.oncelik === 'orta' ? 'bg-yellow-100 text-yellow-600' :
                    'bg-gray-100 text-gray-500'
                  }`}>
                    {item.oncelik === 'yuksek' ? 'Yüksek' : item.oncelik === 'orta' ? 'Orta' : 'Düşük'}
                  </span>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Veri Envanteri */}
      {aktifSekme === 'veri-envanteri' && (
        <div className="bg-white rounded-2xl border border-gray-200 overflow-hidden">
          <div className="p-4 border-b border-gray-100 bg-gray-50">
            <p className="text-xs text-gray-500">İşlenen kişisel veri kategorileri ve saklama süreleri</p>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-gray-50 border-b border-gray-100">
                <tr>
                  <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase">Veri Kategorisi</th>
                  <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase">Hassasiyet</th>
                  <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase">Saklama Süresi</th>
                  <th className="text-center px-4 py-3 text-xs font-semibold text-gray-500 uppercase">Şifreli</th>
                  <th className="text-center px-4 py-3 text-xs font-semibold text-gray-500 uppercase">Erişim Logu</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                {VERI_KATEGORILERI.map((vk) => (
                  <tr key={vk.id} className="hover:bg-gray-50">
                    <td className="px-4 py-3">
                      <p className="font-medium text-gray-800">{vk.ad}</p>
                      <p className="text-xs text-gray-400">{vk.aciklama}</p>
                    </td>
                    <td className="px-4 py-3">
                      <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium ${hassasiyetRengi[vk.hassasiyet]}`}>
                        {hassasiyetEtiketi[vk.hassasiyet]}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-sm text-gray-600">{vk.saklama}</td>
                    <td className="px-4 py-3 text-center">
                      {vk.sifreli
                        ? <CheckCircle className="w-4 h-4 text-green-500 mx-auto" />
                        : <AlertTriangle className="w-4 h-4 text-yellow-500 mx-auto" />}
                    </td>
                    <td className="px-4 py-3 text-center">
                      {vk.erisimLog
                        ? <CheckCircle className="w-4 h-4 text-green-500 mx-auto" />
                        : <Clock className="w-4 h-4 text-gray-300 mx-auto" />}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Audit Log */}
      {aktifSekme === 'audit-log' && (
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <p className="text-sm text-gray-500">Son 24 saatteki erişim ve işlem kayıtları</p>
            <button className="flex items-center gap-1.5 text-xs text-blue-600 hover:underline">
              <Download className="w-3.5 h-3.5" />
              Log Dışa Aktar
            </button>
          </div>
          <div className="bg-white rounded-2xl border border-gray-200 overflow-hidden">
            <table className="w-full text-sm">
              <thead className="bg-gray-50 border-b border-gray-100">
                <tr>
                  <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase">Kullanıcı</th>
                  <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase">Eylem</th>
                  <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase">Kaynak</th>
                  <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase">IP Adresi</th>
                  <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase">Tarih</th>
                  <th className="text-center px-4 py-3 text-xs font-semibold text-gray-500 uppercase">Sonuç</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                {DEMO_AUDIT_LOGS.map((log) => (
                  <tr key={log.id} className={`hover:bg-gray-50 ${log.sonuc === 'basarisiz' ? 'bg-red-50/30' : log.sonuc === 'uyari' ? 'bg-yellow-50/30' : ''}`}>
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-2">
                        <div className="w-6 h-6 rounded-full bg-indigo-100 flex items-center justify-center">
                          <User className="w-3 h-3 text-indigo-600" />
                        </div>
                        <div>
                          <p className="font-medium text-gray-700 text-xs">{log.kullanici}</p>
                          <p className="text-[10px] text-gray-400">{log.rol}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-4 py-3 text-xs text-gray-700">{log.eylem}</td>
                    <td className="px-4 py-3">
                      <code className="text-[10px] bg-gray-100 px-1.5 py-0.5 rounded text-gray-600">{log.kaynak}</code>
                    </td>
                    <td className="px-4 py-3 font-mono text-xs text-gray-500">{log.ip}</td>
                    <td className="px-4 py-3 text-xs text-gray-500">{log.tarih}</td>
                    <td className="px-4 py-3 text-center">
                      <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-medium ${
                        log.sonuc === 'basarili' ? 'bg-green-100 text-green-700' :
                        log.sonuc === 'basarisiz' ? 'bg-red-100 text-red-700' :
                        'bg-yellow-100 text-yellow-700'
                      }`}>
                        {log.sonuc === 'basarili' ? '✓ Başarılı' : log.sonuc === 'basarisiz' ? '✗ Başarısız' : '⚠ Uyarı'}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Veri Sahibi Hakları */}
      {aktifSekme === 'haklar' && (
        <div className="space-y-3">
          <div className="bg-indigo-50 rounded-2xl border border-indigo-100 p-4 mb-4">
            <p className="text-sm font-semibold text-indigo-800 mb-1">KVKK Madde 11 – Veri Sahibi Hakları</p>
            <p className="text-xs text-indigo-600">
              Çalışanlar aşağıdaki haklarını kullanmak için İnsan Kaynakları birimine başvurabilir. Başvurular 30 gün içinde yanıtlanır.
            </p>
          </div>
          {VERI_SAHIBI_HAKLARI.map((hak, i) => (
            <div key={i} className={`bg-white rounded-2xl border p-4 ${hak.destekleniyor ? 'border-gray-200' : 'border-yellow-200 bg-yellow-50/30'}`}>
              <div className="flex items-start justify-between">
                <div className="flex items-start gap-3">
                  {hak.destekleniyor
                    ? <CheckCircle className="w-5 h-5 text-green-500 mt-0.5 flex-shrink-0" />
                    : <Clock className="w-5 h-5 text-yellow-500 mt-0.5 flex-shrink-0" />}
                  <div>
                    <p className="font-semibold text-gray-800 text-sm">{hak.hak}</p>
                    <p className="text-xs text-gray-500 mt-0.5">{hak.aciklama}</p>
                    <div className="flex items-center gap-1 mt-1.5">
                      <FileText className="w-3 h-3 text-gray-400" />
                      <p className="text-xs text-gray-500 italic">{hak.mekanizma}</p>
                    </div>
                  </div>
                </div>
                <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${hak.destekleniyor ? 'bg-green-100 text-green-700' : 'bg-yellow-100 text-yellow-700'}`}>
                  {hak.destekleniyor ? 'Destekleniyor' : 'Geliştiriliyor'}
                </span>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default KVKKUyumluluk;

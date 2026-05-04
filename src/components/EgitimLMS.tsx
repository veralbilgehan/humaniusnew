import React, { useState } from 'react';
import { BookOpen, Play, Award, CheckCircle, Clock, Users, Plus, Search, Lock, ChevronRight } from 'lucide-react';
import type { Employee } from '../types';

interface Egitim {
  id: string;
  baslik: string;
  kategori: string;
  sure: number; // dakika
  seviye: 'baslangic' | 'orta' | 'ileri';
  aciklama: string;
  egitmen: string;
  tur: 'video' | 'sunum' | 'canli' | 'sinav';
  zorunlu: boolean;
  tamamlayanSayisi: number;
  toplam: number;
}

interface SertifikaKaydi {
  id: string;
  egitimId: string;
  egitimAdi: string;
  employeeId: string;
  employeeName: string;
  tamamlanmaTarihi: string;
  gecerlilikSuresi: number | null; // ay
  puan: number;
}

interface PersonelEgitimDurumu {
  employeeId: string;
  employeeName: string;
  department: string;
  tamamlanan: number;
  toplam: number;
  zorunluTamamlanan: number;
  zorunluToplam: number;
  sertifikaAdedi: number;
  sonAktivite: string;
}

const DEMO_EGITIMLER: Egitim[] = [
  { id: 'e1', baslik: 'İş Güvenliği ve İSG Temel Eğitimi', kategori: 'Zorunlu', sure: 120, seviye: 'baslangic', aciklama: 'Tüm çalışanlar için zorunlu iş sağlığı ve güvenliği eğitimi.', egitmen: 'İSG Uzmanı', tur: 'video', zorunlu: true, tamamlayanSayisi: 38, toplam: 45 },
  { id: 'e2', baslik: 'KVKK ve Kişisel Veri Gizliliği', kategori: 'Zorunlu', sure: 90, seviye: 'baslangic', aciklama: 'KVKK kapsamında veri güvenliği politikaları ve uyumluluk.', egitmen: 'Hukuk Ekibi', tur: 'sunum', zorunlu: true, tamamlayanSayisi: 42, toplam: 45 },
  { id: 'e3', baslik: 'Etkili İletişim Becerileri', kategori: 'Kişisel Gelişim', sure: 180, seviye: 'orta', aciklama: 'İş yerinde etkili iletişim stratejileri ve pratik uygulamalar.', egitmen: 'Dr. Ayşe Kara', tur: 'canli', zorunlu: false, tamamlayanSayisi: 15, toplam: 45 },
  { id: 'e4', baslik: 'Excel İleri Seviye', kategori: 'Teknik', sure: 240, seviye: 'ileri', aciklama: 'Pivot tablolar, VLOOKUP, makrolar ve veri analizi teknikleri.', egitmen: 'Eğitim Merkezi', tur: 'video', zorunlu: false, tamamlayanSayisi: 10, toplam: 45 },
  { id: 'e5', baslik: 'Proje Yönetimi (PMP Hazırlık)', kategori: 'Sertifikasyon', sure: 480, seviye: 'ileri', aciklama: 'PMP sertifikasyon sınavına hazırlık kursu.', egitmen: 'Ahmet Yılmaz, PMP', tur: 'video', zorunlu: false, tamamlayanSayisi: 5, toplam: 45 },
  { id: 'e6', baslik: 'Müşteri Hizmetleri Mükemmeliyeti', kategori: 'Satış', sure: 150, seviye: 'orta', aciklama: 'Müşteri memnuniyeti artırma ve şikayet yönetimi.', egitmen: 'Satış Eğitmeni', tur: 'canli', zorunlu: false, tamamlayanSayisi: 22, toplam: 45 },
];

const DEMO_SERTIFIKALAR: SertifikaKaydi[] = [
  { id: 'sc1', egitimId: 'e1', egitimAdi: 'İş Güvenliği ve İSG Temel Eğitimi', employeeId: 'emp1', employeeName: 'Elif Kaya', tamamlanmaTarihi: '2025-03-15', gecerlilikSuresi: 12, puan: 92 },
  { id: 'sc2', egitimId: 'e2', egitimAdi: 'KVKK ve Kişisel Veri Gizliliği', employeeId: 'emp1', employeeName: 'Elif Kaya', tamamlanmaTarihi: '2025-04-01', gecerlilikSuresi: 24, puan: 88 },
  { id: 'sc3', egitimId: 'e5', egitimAdi: 'Proje Yönetimi (PMP Hazırlık)', employeeId: 'emp2', employeeName: 'Murat Şahin', tamamlanmaTarihi: '2025-02-20', gecerlilikSuresi: null, puan: 78 },
  { id: 'sc4', egitimId: 'e1', egitimAdi: 'İş Güvenliği ve İSG Temel Eğitimi', employeeId: 'emp3', employeeName: 'Zeynep Arslan', tamamlanmaTarihi: '2025-03-20', gecerlilikSuresi: 12, puan: 95 },
];

function generatePersonelDurumu(employees: Employee[]): PersonelEgitimDurumu[] {
  return employees.slice(0, 8).map((emp, i) => ({
    employeeId: emp.id,
    employeeName: emp.name,
    department: emp.department,
    tamamlanan: 2 + (i % 4),
    toplam: DEMO_EGITIMLER.length,
    zorunluTamamlanan: i < 4 ? 2 : 1,
    zorunluToplam: 2,
    sertifikaAdedi: i < 5 ? (i % 3 + 1) : 0,
    sonAktivite: `2025-0${4 + (i % 2)}-${10 + i}`,
  }));
}

const seviyeRenk: Record<Egitim['seviye'], string> = {
  baslangic: 'bg-green-100 text-green-700',
  orta: 'bg-yellow-100 text-yellow-700',
  ileri: 'bg-red-100 text-red-700',
};

const turIkon: Record<Egitim['tur'], string> = {
  video: '🎬',
  sunum: '📊',
  canli: '🎥',
  sinav: '📝',
};

const EgitimLMS: React.FC<{ employees: Employee[] }> = ({ employees }) => {
  const [aktifSekme, setAktifSekme] = useState<'katalog' | 'durumlar' | 'sertifikalar'>('katalog');
  const [aramaMetni, setAramaMetni] = useState('');
  const [secilenKategori, setSecilenKategori] = useState('all');
  const [showNewEgitim, setShowNewEgitim] = useState(false);

  const personelDurumlari = generatePersonelDurumu(employees);
  const kategoriler = ['all', ...Array.from(new Set(DEMO_EGITIMLER.map((e) => e.kategori)))];

  const filtreliEgitimler = DEMO_EGITIMLER.filter((eg) => {
    const aramaEslestir = !aramaMetni || eg.baslik.toLowerCase().includes(aramaMetni.toLowerCase()) || eg.kategori.toLowerCase().includes(aramaMetni.toLowerCase());
    const kategoriEslestir = secilenKategori === 'all' || eg.kategori === secilenKategori;
    return aramaEslestir && kategoriEslestir;
  });

  const toplamTamamlama = personelDurumlari.reduce((s, p) => s + p.tamamlanan, 0);
  const toplamZorunluTamamlama = personelDurumlari.filter((p) => p.zorunluTamamlanan >= p.zorunluToplam).length;

  return (
    <div className="space-y-6">
      {/* Başlık */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl font-bold text-gray-800">Eğitim ve Gelişim (LMS)</h2>
          <p className="text-sm text-gray-500 mt-0.5">Online eğitimler, sertifika yönetimi ve çalışan gelişim takibi</p>
        </div>
        <button
          onClick={() => setShowNewEgitim(true)}
          className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-xl text-sm font-medium hover:bg-blue-700 transition-colors"
        >
          <Plus className="w-4 h-4" />
          Yeni Eğitim Ekle
        </button>
      </div>

      {/* Özet Kartlar */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <div className="bg-white rounded-2xl border border-gray-200 p-4">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-blue-100 flex items-center justify-center">
              <BookOpen className="w-5 h-5 text-blue-600" />
            </div>
            <div>
              <p className="text-xs text-gray-500">Toplam Eğitim</p>
              <p className="text-xl font-bold text-gray-800">{DEMO_EGITIMLER.length}</p>
            </div>
          </div>
        </div>
        <div className="bg-white rounded-2xl border border-gray-200 p-4">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-green-100 flex items-center justify-center">
              <CheckCircle className="w-5 h-5 text-green-600" />
            </div>
            <div>
              <p className="text-xs text-gray-500">Tamamlama</p>
              <p className="text-xl font-bold text-gray-800">{toplamTamamlama}</p>
            </div>
          </div>
        </div>
        <div className="bg-white rounded-2xl border border-gray-200 p-4">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-yellow-100 flex items-center justify-center">
              <Award className="w-5 h-5 text-yellow-600" />
            </div>
            <div>
              <p className="text-xs text-gray-500">Sertifikalar</p>
              <p className="text-xl font-bold text-gray-800">{DEMO_SERTIFIKALAR.length}</p>
            </div>
          </div>
        </div>
        <div className="bg-white rounded-2xl border border-gray-200 p-4">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-purple-100 flex items-center justify-center">
              <Users className="w-5 h-5 text-purple-600" />
            </div>
            <div>
              <p className="text-xs text-gray-500">Zorunlu Tamamlayan</p>
              <p className="text-xl font-bold text-gray-800">{toplamZorunluTamamlama}</p>
            </div>
          </div>
        </div>
      </div>

      {/* Sekmeler */}
      <div className="flex gap-2 border-b border-gray-200">
        {(['katalog', 'durumlar', 'sertifikalar'] as const).map((sekme) => (
          <button
            key={sekme}
            onClick={() => setAktifSekme(sekme)}
            className={`px-4 py-2.5 text-sm font-medium border-b-2 transition-colors ${
              aktifSekme === sekme ? 'border-blue-600 text-blue-600' : 'border-transparent text-gray-500 hover:text-gray-700'
            }`}
          >
            {sekme === 'katalog' ? 'Eğitim Kataloğu' : sekme === 'durumlar' ? 'Personel Durumları' : 'Sertifikalar'}
          </button>
        ))}
      </div>

      {/* Eğitim Kataloğu */}
      {aktifSekme === 'katalog' && (
        <div className="space-y-4">
          <div className="flex flex-wrap gap-3">
            <div className="flex items-center gap-2 border border-gray-200 rounded-xl px-3 py-1.5 flex-1 min-w-[200px]">
              <Search className="w-4 h-4 text-gray-400" />
              <input
                type="text"
                value={aramaMetni}
                onChange={(e) => setAramaMetni(e.target.value)}
                placeholder="Eğitim ara..."
                className="flex-1 text-sm focus:outline-none"
              />
            </div>
            <div className="flex gap-2 flex-wrap">
              {kategoriler.map((k) => (
                <button
                  key={k}
                  onClick={() => setSecilenKategori(k)}
                  className={`px-3 py-1.5 rounded-xl text-xs font-medium transition-colors ${
                    secilenKategori === k ? 'bg-blue-600 text-white' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                  }`}
                >
                  {k === 'all' ? 'Tümü' : k}
                </button>
              ))}
            </div>
          </div>

          <div className="grid gap-4 md:grid-cols-2">
            {filtreliEgitimler.map((eg) => {
              const tamamlanmaOrani = Math.round((eg.tamamlayanSayisi / eg.toplam) * 100);
              return (
                <div key={eg.id} className="bg-white rounded-2xl border border-gray-200 p-5 hover:border-blue-300 transition-colors">
                  <div className="flex items-start justify-between mb-3">
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-1">
                        <span className="text-lg">{turIkon[eg.tur]}</span>
                        <h3 className="font-semibold text-gray-800 text-sm">{eg.baslik}</h3>
                        {eg.zorunlu && (
                          <span className="inline-flex items-center px-1.5 py-0.5 rounded text-xs font-medium bg-red-100 text-red-600">Zorunlu</span>
                        )}
                      </div>
                      <p className="text-xs text-gray-500">{eg.egitmen} • {eg.kategori}</p>
                    </div>
                    <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium ${seviyeRenk[eg.seviye]}`}>
                      {eg.seviye === 'baslangic' ? 'Başlangıç' : eg.seviye === 'orta' ? 'Orta' : 'İleri'}
                    </span>
                  </div>

                  <p className="text-xs text-gray-600 mb-3 line-clamp-2">{eg.aciklama}</p>

                  <div className="flex items-center gap-4 text-xs text-gray-500 mb-3">
                    <span className="flex items-center gap-1">
                      <Clock className="w-3 h-3" />
                      {eg.sure >= 60 ? `${Math.floor(eg.sure / 60)}s ${eg.sure % 60 > 0 ? eg.sure % 60 + 'dk' : ''}` : `${eg.sure}dk`}
                    </span>
                    <span className="flex items-center gap-1">
                      <Users className="w-3 h-3" />
                      {eg.tamamlayanSayisi}/{eg.toplam} tamamladı
                    </span>
                  </div>

                  <div className="mb-3">
                    <div className="flex justify-between text-xs text-gray-500 mb-1">
                      <span>Tamamlanma</span>
                      <span>%{tamamlanmaOrani}</span>
                    </div>
                    <div className="h-1.5 bg-gray-100 rounded-full overflow-hidden">
                      <div
                        className={`h-full rounded-full ${tamamlanmaOrani >= 80 ? 'bg-green-500' : tamamlanmaOrani >= 50 ? 'bg-yellow-400' : 'bg-blue-500'}`}
                        style={{ width: `${tamamlanmaOrani}%` }}
                      />
                    </div>
                  </div>

                  <button className="flex items-center gap-1.5 text-sm font-medium text-blue-600 hover:text-blue-700">
                    <Play className="w-4 h-4" />
                    Eğitime Başla
                  </button>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* Personel Durumları */}
      {aktifSekme === 'durumlar' && (
        <div className="bg-white rounded-2xl border border-gray-200 overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-gray-50">
                <tr>
                  <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase">Personel</th>
                  <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase">Departman</th>
                  <th className="text-center px-4 py-3 text-xs font-semibold text-gray-500 uppercase">Tamamlanan</th>
                  <th className="text-center px-4 py-3 text-xs font-semibold text-gray-500 uppercase">Zorunlu</th>
                  <th className="text-center px-4 py-3 text-xs font-semibold text-gray-500 uppercase">Sertifika</th>
                  <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase">Son Aktivite</th>
                  <th className="text-center px-4 py-3 text-xs font-semibold text-gray-500 uppercase">Durum</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                {personelDurumlari.map((pd) => {
                  const zorunluTam = pd.zorunluTamamlanan >= pd.zorunluToplam;
                  const oran = Math.round((pd.tamamlanan / pd.toplam) * 100);
                  return (
                    <tr key={pd.employeeId} className="hover:bg-gray-50 transition-colors">
                      <td className="px-4 py-3 font-medium text-gray-800">{pd.employeeName}</td>
                      <td className="px-4 py-3 text-gray-500">{pd.department}</td>
                      <td className="px-4 py-3 text-center">
                        <div>
                          <span className="font-semibold">{pd.tamamlanan}</span>
                          <span className="text-gray-400">/{pd.toplam}</span>
                          <div className="h-1 bg-gray-100 rounded-full mt-1 w-16 mx-auto">
                            <div className="h-full bg-blue-500 rounded-full" style={{ width: `${oran}%` }} />
                          </div>
                        </div>
                      </td>
                      <td className="px-4 py-3 text-center">
                        <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium ${
                          zorunluTam ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-600'
                        }`}>
                          {zorunluTam ? <CheckCircle className="w-3 h-3" /> : <Lock className="w-3 h-3" />}
                          {pd.zorunluTamamlanan}/{pd.zorunluToplam}
                        </span>
                      </td>
                      <td className="px-4 py-3 text-center">
                        <span className="flex items-center justify-center gap-1 font-semibold text-yellow-600">
                          <Award className="w-3.5 h-3.5" />
                          {pd.sertifikaAdedi}
                        </span>
                      </td>
                      <td className="px-4 py-3 text-gray-500 text-xs">{pd.sonAktivite}</td>
                      <td className="px-4 py-3 text-center">
                        <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium ${
                          oran >= 60 ? 'bg-green-100 text-green-700' : oran >= 30 ? 'bg-yellow-100 text-yellow-700' : 'bg-red-100 text-red-600'
                        }`}>
                          {oran >= 60 ? 'İyi' : oran >= 30 ? 'Orta' : 'Düşük'}
                        </span>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Sertifikalar */}
      {aktifSekme === 'sertifikalar' && (
        <div className="space-y-3">
          {DEMO_SERTIFIKALAR.map((sc) => {
            const gecerlilikTarihi = sc.gecerlilikSuresi
              ? new Date(new Date(sc.tamamlanmaTarihi).setMonth(new Date(sc.tamamlanmaTarihi).getMonth() + sc.gecerlilikSuresi)).toISOString().split('T')[0]
              : null;
            const yakindaGececek = gecerlilikTarihi && new Date(gecerlilikTarihi) < new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);

            return (
              <div key={sc.id} className="bg-white rounded-2xl border border-gray-200 p-5">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-4">
                    <div className="w-12 h-12 rounded-xl bg-yellow-100 flex items-center justify-center">
                      <Award className="w-6 h-6 text-yellow-600" />
                    </div>
                    <div>
                      <p className="font-semibold text-gray-800">{sc.egitimAdi}</p>
                      <p className="text-sm text-gray-500">{sc.employeeName} • Tamamlandı: {sc.tamamlanmaTarihi}</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-4">
                    <div className="text-right">
                      <p className="text-xs text-gray-400">Sınav Puanı</p>
                      <p className={`text-lg font-bold ${sc.puan >= 85 ? 'text-green-600' : sc.puan >= 70 ? 'text-yellow-600' : 'text-red-500'}`}>
                        {sc.puan}/100
                      </p>
                    </div>
                    {gecerlilikTarihi ? (
                      <div className={`text-right px-3 py-2 rounded-xl ${yakindaGececek ? 'bg-red-50' : 'bg-green-50'}`}>
                        <p className="text-xs text-gray-400">Geçerlilik</p>
                        <p className={`text-sm font-semibold ${yakindaGececek ? 'text-red-600' : 'text-green-600'}`}>
                          {gecerlilikTarihi}
                        </p>
                        {yakindaGececek && <p className="text-xs text-red-500">⚠️ Yenileme gerekli</p>}
                      </div>
                    ) : (
                      <span className="px-3 py-2 rounded-xl bg-blue-50 text-xs text-blue-600 font-medium">Süresiz</span>
                    )}
                    <button className="text-xs text-blue-600 hover:underline flex items-center gap-1">
                      <ChevronRight className="w-3 h-3" />
                      Sertifikayı Görüntüle
                    </button>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Yeni Eğitim Modal */}
      {showNewEgitim && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-2xl p-6 w-full max-w-lg shadow-xl">
            <h3 className="text-lg font-bold text-gray-800 mb-4">Yeni Eğitim Ekle</h3>
            <div className="space-y-3">
              <div>
                <label className="block text-xs font-semibold text-gray-600 mb-1">Eğitim Başlığı</label>
                <input type="text" className="w-full border border-gray-200 rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500" />
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-gray-600 mb-1">Kategori</label>
                  <input type="text" className="w-full border border-gray-200 rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500" />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-gray-600 mb-1">Eğitim Türü</label>
                  <select className="w-full border border-gray-200 rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500">
                    <option value="video">Video</option>
                    <option value="sunum">Sunum</option>
                    <option value="canli">Canlı</option>
                    <option value="sinav">Sınav</option>
                  </select>
                </div>
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-gray-600 mb-1">Süre (dakika)</label>
                  <input type="number" min="1" className="w-full border border-gray-200 rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500" />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-gray-600 mb-1">Seviye</label>
                  <select className="w-full border border-gray-200 rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500">
                    <option value="baslangic">Başlangıç</option>
                    <option value="orta">Orta</option>
                    <option value="ileri">İleri</option>
                  </select>
                </div>
              </div>
              <div>
                <label className="block text-xs font-semibold text-gray-600 mb-1">Eğitmen</label>
                <input type="text" className="w-full border border-gray-200 rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500" />
              </div>
              <div className="flex items-center gap-2">
                <input type="checkbox" id="zorunlu" className="rounded" />
                <label htmlFor="zorunlu" className="text-sm text-gray-700">Zorunlu eğitim</label>
              </div>
              <div>
                <label className="block text-xs font-semibold text-gray-600 mb-1">Açıklama</label>
                <textarea rows={2} className="w-full border border-gray-200 rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 resize-none" />
              </div>
            </div>
            <div className="flex gap-3 mt-6">
              <button onClick={() => setShowNewEgitim(false)} className="flex-1 py-2.5 rounded-xl border border-gray-200 text-sm font-medium text-gray-600 hover:bg-gray-50">İptal</button>
              <button onClick={() => setShowNewEgitim(false)} className="flex-1 py-2.5 rounded-xl bg-blue-600 text-white text-sm font-medium hover:bg-blue-700">Eğitim Ekle</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default EgitimLMS;

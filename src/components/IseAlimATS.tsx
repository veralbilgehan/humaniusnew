import React, { useState } from 'react';
import { Briefcase, Users, Calendar, FileText, Plus, Search, ChevronRight, Phone, Mail, Clock } from 'lucide-react';

interface AcikPozisyon {
  id: string;
  baslik: string;
  departman: string;
  tip: 'tam-zamanli' | 'yarim-zamanli' | 'sozlesmeli' | 'stajer';
  konum: string;
  yayinTarihi: string;
  sonBasvuruTarihi: string;
  basvuruSayisi: number;
  durum: 'aktif' | 'pasif' | 'tamamlandi';
  aciklama: string;
}

interface Aday {
  id: string;
  ad: string;
  email: string;
  telefon: string;
  pozisyon: string;
  pozisyonId: string;
  basvuruTarihi: string;
  deneyim: string;
  egitim: string;
  asamaId: string;
  notlar: string;
  puan: number;
}

interface Mulakat {
  id: string;
  adayId: string;
  adayAd: string;
  pozisyon: string;
  tarih: string;
  saat: string;
  tur: 'telefon' | 'video' | 'yuz-yuze' | 'teknik';
  gorusmeYapan: string;
  durum: 'planlandı' | 'tamamlandı' | 'iptal';
  notlar: string;
}

const DEMO_ASAMALAR = [
  { id: 'basvuru', label: 'Başvuru', renk: 'bg-gray-100 text-gray-700' },
  { id: 'on-eleme', label: 'Ön Eleme', renk: 'bg-blue-100 text-blue-700' },
  { id: 'mulakat', label: 'Mülakat', renk: 'bg-purple-100 text-purple-700' },
  { id: 'teknik', label: 'Teknik Test', renk: 'bg-yellow-100 text-yellow-700' },
  { id: 'teklif', label: 'Teklif', renk: 'bg-green-100 text-green-700' },
  { id: 'reddedildi', label: 'Reddedildi', renk: 'bg-red-100 text-red-700' },
];

const DEMO_POZISYONLAR: AcikPozisyon[] = [
  { id: 'p1', baslik: 'Kıdemli Frontend Geliştirici', departman: 'Yazılım', tip: 'tam-zamanli', konum: 'İstanbul / Hibrit', yayinTarihi: '2025-04-15', sonBasvuruTarihi: '2025-05-30', basvuruSayisi: 23, durum: 'aktif', aciklama: 'React ve TypeScript deneyimi gereklidir.' },
  { id: 'p2', baslik: 'İnsan Kaynakları Uzmanı', departman: 'İnsan Kaynakları', tip: 'tam-zamanli', konum: 'Ankara', yayinTarihi: '2025-04-20', sonBasvuruTarihi: '2025-05-25', basvuruSayisi: 15, durum: 'aktif', aciklama: 'İşe alım ve bordro deneyimi tercih edilir.' },
  { id: 'p3', baslik: 'Satış Temsilcisi', departman: 'Satış', tip: 'tam-zamanli', konum: 'İzmir', yayinTarihi: '2025-03-10', sonBasvuruTarihi: '2025-04-30', basvuruSayisi: 41, durum: 'tamamlandi', aciklama: 'B2B satış deneyimi.' },
  { id: 'p4', baslik: 'Stajyer – Veri Analizi', departman: 'Bilişim', tip: 'stajer', konum: 'İstanbul / Uzaktan', yayinTarihi: '2025-05-01', sonBasvuruTarihi: '2025-06-15', basvuruSayisi: 8, durum: 'aktif', aciklama: 'Python ve SQL bilgisi olması avantajdır.' },
];

const DEMO_ADAYLAR: Aday[] = [
  { id: 'a1', ad: 'Elif Kaya', email: 'elif@example.com', telefon: '0532 111 2233', pozisyon: 'Kıdemli Frontend Geliştirici', pozisyonId: 'p1', basvuruTarihi: '2025-04-18', deneyim: '5 yıl', egitim: 'Bilgisayar Mühendisliği', asamaId: 'teknik', notlar: 'Çok güçlü React bilgisi', puan: 4 },
  { id: 'a2', ad: 'Murat Şahin', email: 'murat@example.com', telefon: '0533 222 3344', pozisyon: 'Kıdemli Frontend Geliştirici', pozisyonId: 'p1', basvuruTarihi: '2025-04-20', deneyim: '3 yıl', egitim: 'Yazılım Mühendisliği', asamaId: 'mulakat', notlar: 'İletişim becerileri iyi', puan: 3 },
  { id: 'a3', ad: 'Zeynep Arslan', email: 'zeynep@example.com', telefon: '0544 333 4455', pozisyon: 'İnsan Kaynakları Uzmanı', pozisyonId: 'p2', basvuruTarihi: '2025-04-22', deneyim: '4 yıl', egitim: 'İşletme', asamaId: 'teklif', notlar: 'Bordro konusunda deneyimli', puan: 5 },
  { id: 'a4', ad: 'Ahmet Demir', email: 'ahmet@example.com', telefon: '0555 444 5566', pozisyon: 'Kıdemli Frontend Geliştirici', pozisyonId: 'p1', basvuruTarihi: '2025-04-25', deneyim: '2 yıl', egitim: 'Endüstri Mühendisliği', asamaId: 'on-eleme', notlar: '', puan: 2 },
  { id: 'a5', ad: 'Büşra Yıldız', email: 'busra@example.com', telefon: '0546 555 6677', pozisyon: 'Stajyer – Veri Analizi', pozisyonId: 'p4', basvuruTarihi: '2025-05-02', deneyim: '0 yıl', egitim: 'İstatistik (öğrenci)', asamaId: 'basvuru', notlar: 'Kaggle profili mevcut', puan: 3 },
];

const DEMO_MULAKATLAR: Mulakat[] = [
  { id: 'm1', adayId: 'a1', adayAd: 'Elif Kaya', pozisyon: 'Kıdemli Frontend Geliştirici', tarih: '2025-05-06', saat: '10:00', tur: 'teknik', gorusmeYapan: 'Teknik Ekip', durum: 'planlandı', notlar: '' },
  { id: 'm2', adayId: 'a2', adayAd: 'Murat Şahin', pozisyon: 'Kıdemli Frontend Geliştirici', tarih: '2025-05-07', saat: '14:00', tur: 'video', gorusmeYapan: 'İK Müdürü', durum: 'planlandı', notlar: '' },
  { id: 'm3', adayId: 'a3', adayAd: 'Zeynep Arslan', pozisyon: 'İnsan Kaynakları Uzmanı', tarih: '2025-04-30', saat: '11:00', tur: 'yuz-yuze', gorusmeYapan: 'Genel Müdür', durum: 'tamamlandı', notlar: 'Çok olumlu izlenim' },
];

const tipEtiketi: Record<AcikPozisyon['tip'], string> = {
  'tam-zamanli': 'Tam Zamanlı',
  'yarim-zamanli': 'Yarı Zamanlı',
  'sozlesmeli': 'Sözleşmeli',
  'stajer': 'Stajyer',
};

const mulakatTipRenk: Record<Mulakat['tur'], string> = {
  telefon: 'bg-blue-100 text-blue-700',
  video: 'bg-purple-100 text-purple-700',
  'yuz-yuze': 'bg-green-100 text-green-700',
  teknik: 'bg-orange-100 text-orange-700',
};

const IseAlimATS: React.FC = () => {
  const [aktifSekme, setAktifSekme] = useState<'pozisyonlar' | 'adaylar' | 'mulakatlar'>('pozisyonlar');
  const [aramaMetni, setAramaMetni] = useState('');
  const [secilenAsama, setSecilenAsama] = useState<string>('all');
  const [showNewPozisyon, setShowNewPozisyon] = useState(false);

  const filtreliAdaylar = DEMO_ADAYLAR.filter((a) => {
    const aramaEslestir = !aramaMetni || a.ad.toLowerCase().includes(aramaMetni.toLowerCase()) || a.pozisyon.toLowerCase().includes(aramaMetni.toLowerCase());
    const asamaEslestir = secilenAsama === 'all' || a.asamaId === secilenAsama;
    return aramaEslestir && asamaEslestir;
  });

  return (
    <div className="space-y-6">
      {/* Başlık */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl font-bold text-gray-800">İşe Alım & ATS</h2>
          <p className="text-sm text-gray-500 mt-0.5">Aday takip sistemi – ilan yayınlama, CV yönetimi ve mülakat planlama</p>
        </div>
        <button
          onClick={() => setShowNewPozisyon(true)}
          className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-xl text-sm font-medium hover:bg-blue-700 transition-colors"
        >
          <Plus className="w-4 h-4" />
          Yeni İlan
        </button>
      </div>

      {/* Özet */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <div className="bg-white rounded-2xl border border-gray-200 p-4">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-blue-100 flex items-center justify-center">
              <Briefcase className="w-5 h-5 text-blue-600" />
            </div>
            <div>
              <p className="text-xs text-gray-500">Açık Pozisyon</p>
              <p className="text-xl font-bold text-gray-800">{DEMO_POZISYONLAR.filter((p) => p.durum === 'aktif').length}</p>
            </div>
          </div>
        </div>
        <div className="bg-white rounded-2xl border border-gray-200 p-4">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-purple-100 flex items-center justify-center">
              <Users className="w-5 h-5 text-purple-600" />
            </div>
            <div>
              <p className="text-xs text-gray-500">Toplam Aday</p>
              <p className="text-xl font-bold text-gray-800">{DEMO_ADAYLAR.length}</p>
            </div>
          </div>
        </div>
        <div className="bg-white rounded-2xl border border-gray-200 p-4">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-green-100 flex items-center justify-center">
              <Calendar className="w-5 h-5 text-green-600" />
            </div>
            <div>
              <p className="text-xs text-gray-500">Planlanan Mülakat</p>
              <p className="text-xl font-bold text-gray-800">{DEMO_MULAKATLAR.filter((m) => m.durum === 'planlandı').length}</p>
            </div>
          </div>
        </div>
        <div className="bg-white rounded-2xl border border-gray-200 p-4">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-yellow-100 flex items-center justify-center">
              <FileText className="w-5 h-5 text-yellow-600" />
            </div>
            <div>
              <p className="text-xs text-gray-500">Teklif Aşamasında</p>
              <p className="text-xl font-bold text-gray-800">{DEMO_ADAYLAR.filter((a) => a.asamaId === 'teklif').length}</p>
            </div>
          </div>
        </div>
      </div>

      {/* Sekmeler */}
      <div className="flex gap-2 border-b border-gray-200">
        {(['pozisyonlar', 'adaylar', 'mulakatlar'] as const).map((sekme) => (
          <button
            key={sekme}
            onClick={() => setAktifSekme(sekme)}
            className={`px-4 py-2.5 text-sm font-medium border-b-2 transition-colors ${
              aktifSekme === sekme ? 'border-blue-600 text-blue-600' : 'border-transparent text-gray-500 hover:text-gray-700'
            }`}
          >
            {sekme === 'pozisyonlar' ? 'Açık Pozisyonlar' : sekme === 'adaylar' ? 'Adaylar' : 'Mülakatlar'}
          </button>
        ))}
      </div>

      {/* Açık Pozisyonlar */}
      {aktifSekme === 'pozisyonlar' && (
        <div className="space-y-3">
          {DEMO_POZISYONLAR.map((poz) => (
            <div key={poz.id} className="bg-white rounded-2xl border border-gray-200 p-5 hover:border-blue-300 transition-colors">
              <div className="flex items-start justify-between">
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-1">
                    <h3 className="font-semibold text-gray-800">{poz.baslik}</h3>
                    <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium ${
                      poz.durum === 'aktif' ? 'bg-green-100 text-green-700' :
                      poz.durum === 'tamamlandi' ? 'bg-gray-100 text-gray-500' :
                      'bg-yellow-100 text-yellow-700'
                    }`}>
                      {poz.durum === 'aktif' ? 'Aktif' : poz.durum === 'tamamlandi' ? 'Tamamlandı' : 'Pasif'}
                    </span>
                  </div>
                  <div className="flex flex-wrap items-center gap-3 text-xs text-gray-500">
                    <span className="flex items-center gap-1">
                      <Briefcase className="w-3 h-3" />
                      {poz.departman}
                    </span>
                    <span>{tipEtiketi[poz.tip]}</span>
                    <span>📍 {poz.konum}</span>
                    <span className="flex items-center gap-1">
                      <Clock className="w-3 h-3" />
                      Son: {poz.sonBasvuruTarihi}
                    </span>
                  </div>
                  <p className="mt-2 text-sm text-gray-600">{poz.aciklama}</p>
                </div>
                <div className="ml-4 text-right">
                  <p className="text-2xl font-bold text-blue-600">{poz.basvuruSayisi}</p>
                  <p className="text-xs text-gray-400">başvuru</p>
                </div>
              </div>
              <div className="flex gap-2 mt-4">
                <button className="text-xs text-blue-600 hover:underline">Adayları Görüntüle</button>
                <span className="text-gray-300">•</span>
                <button className="text-xs text-gray-500 hover:underline">Düzenle</button>
                {poz.durum === 'aktif' && (
                  <>
                    <span className="text-gray-300">•</span>
                    <button className="text-xs text-gray-500 hover:underline">İlanı Kapat</button>
                  </>
                )}
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Adaylar */}
      {aktifSekme === 'adaylar' && (
        <div className="space-y-4">
          <div className="flex flex-wrap gap-3">
            <div className="flex items-center gap-2 border border-gray-200 rounded-xl px-3 py-1.5 flex-1 min-w-[200px]">
              <Search className="w-4 h-4 text-gray-400" />
              <input
                type="text"
                value={aramaMetni}
                onChange={(e) => setAramaMetni(e.target.value)}
                placeholder="Aday veya pozisyon ara..."
                className="flex-1 text-sm focus:outline-none"
              />
            </div>
            <select
              value={secilenAsama}
              onChange={(e) => setSecilenAsama(e.target.value)}
              className="border border-gray-200 rounded-xl px-3 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="all">Tüm Aşamalar</option>
              {DEMO_ASAMALAR.map((a) => (
                <option key={a.id} value={a.id}>{a.label}</option>
              ))}
            </select>
          </div>

          {/* Kanban benzeri aşama dağılımı */}
          <div className="grid grid-cols-3 md:grid-cols-6 gap-2">
            {DEMO_ASAMALAR.map((asama) => {
              const count = DEMO_ADAYLAR.filter((a) => a.asamaId === asama.id).length;
              return (
                <button
                  key={asama.id}
                  onClick={() => setSecilenAsama(secilenAsama === asama.id ? 'all' : asama.id)}
                  className={`p-3 rounded-xl text-center border-2 transition-colors ${
                    secilenAsama === asama.id ? 'border-blue-500 bg-blue-50' : 'border-transparent bg-white border border-gray-200'
                  }`}
                >
                  <p className="text-xl font-bold text-gray-800">{count}</p>
                  <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium ${asama.renk}`}>
                    {asama.label}
                  </span>
                </button>
              );
            })}
          </div>

          <div className="space-y-2">
            {filtreliAdaylar.map((aday) => {
              const asama = DEMO_ASAMALAR.find((a) => a.id === aday.asamaId);
              return (
                <div key={aday.id} className="bg-white rounded-2xl border border-gray-200 p-4 hover:border-blue-300 transition-colors">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-purple-100 to-blue-100 flex items-center justify-center text-sm font-bold text-purple-600">
                        {aday.ad.split(' ').map((n) => n[0]).join('').slice(0, 2)}
                      </div>
                      <div>
                        <p className="font-semibold text-gray-800">{aday.ad}</p>
                        <p className="text-xs text-gray-500">{aday.pozisyon} • {aday.deneyim} deneyim</p>
                      </div>
                    </div>
                    <div className="flex items-center gap-3">
                      <div className="flex gap-1">
                        {[1, 2, 3, 4, 5].map((n) => (
                          <div key={n} className={`w-2 h-2 rounded-full ${n <= aday.puan ? 'bg-yellow-400' : 'bg-gray-200'}`} />
                        ))}
                      </div>
                      {asama && (
                        <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium ${asama.renk}`}>
                          {asama.label}
                        </span>
                      )}
                      <ChevronRight className="w-4 h-4 text-gray-400" />
                    </div>
                  </div>
                  <div className="flex flex-wrap gap-4 mt-3 text-xs text-gray-500">
                    <span className="flex items-center gap-1"><Mail className="w-3 h-3" />{aday.email}</span>
                    <span className="flex items-center gap-1"><Phone className="w-3 h-3" />{aday.telefon}</span>
                    <span className="flex items-center gap-1"><FileText className="w-3 h-3" />{aday.egitim}</span>
                    {aday.notlar && <span className="italic">{aday.notlar}</span>}
                  </div>
                  <div className="flex gap-2 mt-3">
                    <button className="text-xs text-blue-600 hover:underline">Mülakat Planla</button>
                    <span className="text-gray-300">•</span>
                    <button className="text-xs text-gray-500 hover:underline">Aşama Güncelle</button>
                    <span className="text-gray-300">•</span>
                    <button className="text-xs text-red-400 hover:underline">Reddet</button>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* Mülakatlar */}
      {aktifSekme === 'mulakatlar' && (
        <div className="space-y-4">
          <div className="flex justify-end">
            <button className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-xl text-sm font-medium hover:bg-blue-700">
              <Plus className="w-4 h-4" />
              Mülakat Planla
            </button>
          </div>
          {DEMO_MULAKATLAR.map((mulakat) => (
            <div key={mulakat.id} className="bg-white rounded-2xl border border-gray-200 p-5">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-4">
                  <div className="w-12 h-12 rounded-xl bg-indigo-100 flex items-center justify-center">
                    <Calendar className="w-6 h-6 text-indigo-600" />
                  </div>
                  <div>
                    <p className="font-semibold text-gray-800">{mulakat.adayAd}</p>
                    <p className="text-sm text-gray-500">{mulakat.pozisyon}</p>
                  </div>
                </div>
                <div className="flex items-center gap-4">
                  <div className="text-right text-sm">
                    <p className="font-semibold text-gray-700">{mulakat.tarih} – {mulakat.saat}</p>
                    <p className="text-xs text-gray-400">Görüşen: {mulakat.gorusmeYapan}</p>
                  </div>
                  <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium ${mulakatTipRenk[mulakat.tur]}`}>
                    {mulakat.tur === 'telefon' ? '📞 Telefon' : mulakat.tur === 'video' ? '📹 Video' : mulakat.tur === 'yuz-yuze' ? '🤝 Yüz Yüze' : '💻 Teknik'}
                  </span>
                  <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium ${
                    mulakat.durum === 'planlandı' ? 'bg-blue-100 text-blue-700' :
                    mulakat.durum === 'tamamlandı' ? 'bg-green-100 text-green-700' :
                    'bg-red-100 text-red-700'
                  }`}>
                    {mulakat.durum === 'planlandı' ? 'Planlandı' : mulakat.durum === 'tamamlandı' ? 'Tamamlandı' : 'İptal'}
                  </span>
                </div>
              </div>
              {mulakat.notlar && (
                <p className="mt-3 text-sm text-gray-600 bg-gray-50 rounded-xl p-3">{mulakat.notlar}</p>
              )}
            </div>
          ))}
        </div>
      )}

      {/* Yeni Pozisyon Modal */}
      {showNewPozisyon && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-2xl p-6 w-full max-w-lg shadow-xl">
            <h3 className="text-lg font-bold text-gray-800 mb-4">Yeni İş İlanı</h3>
            <div className="space-y-3">
              <div>
                <label className="block text-xs font-semibold text-gray-600 mb-1">Pozisyon Başlığı</label>
                <input type="text" className="w-full border border-gray-200 rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500" placeholder="ör. Kıdemli Frontend Geliştirici" />
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-gray-600 mb-1">Departman</label>
                  <input type="text" className="w-full border border-gray-200 rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500" />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-gray-600 mb-1">Çalışma Tipi</label>
                  <select className="w-full border border-gray-200 rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500">
                    <option value="tam-zamanli">Tam Zamanlı</option>
                    <option value="yarim-zamanli">Yarı Zamanlı</option>
                    <option value="sozlesmeli">Sözleşmeli</option>
                    <option value="stajer">Stajyer</option>
                  </select>
                </div>
              </div>
              <div>
                <label className="block text-xs font-semibold text-gray-600 mb-1">Konum</label>
                <input type="text" className="w-full border border-gray-200 rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500" placeholder="ör. İstanbul / Hibrit" />
              </div>
              <div>
                <label className="block text-xs font-semibold text-gray-600 mb-1">Son Başvuru Tarihi</label>
                <input type="date" className="w-full border border-gray-200 rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500" />
              </div>
              <div>
                <label className="block text-xs font-semibold text-gray-600 mb-1">İlan Açıklaması</label>
                <textarea rows={3} className="w-full border border-gray-200 rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 resize-none" />
              </div>
            </div>
            <div className="flex gap-3 mt-6">
              <button onClick={() => setShowNewPozisyon(false)} className="flex-1 py-2.5 rounded-xl border border-gray-200 text-sm font-medium text-gray-600 hover:bg-gray-50">İptal</button>
              <button onClick={() => setShowNewPozisyon(false)} className="flex-1 py-2.5 rounded-xl bg-blue-600 text-white text-sm font-medium hover:bg-blue-700">İlan Yayınla</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default IseAlimATS;

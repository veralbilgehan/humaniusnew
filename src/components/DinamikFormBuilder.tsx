import React, { useState } from 'react';
import { Plus, Trash2, GripVertical, Save, Eye, X, ChevronUp, ChevronDown, Settings, Copy } from 'lucide-react';

type AlanTipi = 'metin' | 'sayi' | 'tarih' | 'secim' | 'coklu-secim' | 'evet-hayir' | 'dosya' | 'uzun-metin';

interface FormAlani {
  id: string;
  ad: string;
  etiket: string;
  tip: AlanTipi;
  zorunlu: boolean;
  secenekler?: string[];
  aciklamaNotu?: string;
  varsayilan?: string;
  sira: number;
}

interface FormSablonu {
  id: string;
  ad: string;
  aciklama: string;
  kategori: string;
  alanlar: FormAlani[];
  olusturulma: string;
}

const TIP_ETIKETI: Record<AlanTipi, string> = {
  metin: 'Tek Satır Metin',
  sayi: 'Sayı',
  tarih: 'Tarih',
  secim: 'Açılır Liste (Tekli)',
  'coklu-secim': 'Çoklu Seçim',
  'evet-hayir': 'Evet / Hayır',
  dosya: 'Dosya Yükleme',
  'uzun-metin': 'Çok Satırlı Metin',
};

const TIP_ICON: Record<AlanTipi, string> = {
  metin: 'T',
  sayi: '#',
  tarih: '📅',
  secim: '▾',
  'coklu-secim': '☑',
  'evet-hayir': '✓',
  dosya: '📎',
  'uzun-metin': '¶',
};

const DEMO_SABLONLAR: FormSablonu[] = [
  {
    id: 'f1',
    ad: 'Ek Personel Bilgileri',
    aciklama: 'Standart özlük formuna ek özel şirket alanları',
    kategori: 'Özlük',
    olusturulma: '2026-04-01',
    alanlar: [
      { id: 'a1', ad: 'askerlik_durumu', etiket: 'Askerlik Durumu', tip: 'secim', zorunlu: true, secenekler: ['Yapıldı', 'Muaf', 'Tecilli', 'Devam Ediyor'], sira: 1 },
      { id: 'a2', ad: 'surucuBelgesi', etiket: 'Sürücü Belgesi Var mı?', tip: 'evet-hayir', zorunlu: false, sira: 2 },
      { id: 'a3', ad: 'surucuBelgeSinifi', etiket: 'Sürücü Belgesi Sınıfı', tip: 'metin', zorunlu: false, aciklamaNotu: 'A, B, C gibi', sira: 3 },
      { id: 'a4', ad: 'yabancilDil', etiket: 'Yabancı Diller', tip: 'coklu-secim', zorunlu: false, secenekler: ['İngilizce', 'Almanca', 'Fransızca', 'Arapça', 'İspanyolca', 'Japonca'], sira: 4 },
    ],
  },
  {
    id: 'f2',
    ad: 'İşe Giriş Başvuru Formu',
    aciklama: 'Yeni çalışan oryantasyon ek bilgileri',
    kategori: 'Onboarding',
    olusturulma: '2026-03-15',
    alanlar: [
      { id: 'b1', ad: 'onceliKullanim', etiket: 'Bilgisayar Tercihi', tip: 'secim', zorunlu: true, secenekler: ['Windows', 'macOS', 'Fark etmez'], sira: 1 },
      { id: 'b2', ad: 'calismaModeli', etiket: 'Çalışma Modeli Tercihi', tip: 'secim', zorunlu: false, secenekler: ['Tam Ofis', 'Hibrit', 'Tam Uzak'], sira: 2 },
      { id: 'b3', ad: 'acilDurumKisi', etiket: 'Acil Durum İletişim Kişisi', tip: 'metin', zorunlu: true, sira: 3 },
      { id: 'b4', ad: 'acilDurumTel', etiket: 'Acil Durum Telefonu', tip: 'metin', zorunlu: true, sira: 4 },
      { id: 'b5', ad: 'saglikNot', etiket: 'Paylaşmak İstediğiniz Sağlık Notu', tip: 'uzun-metin', zorunlu: false, aciklamaNotu: 'Alerji, kronik hastalık vs.', sira: 5 },
    ],
  },
];

function yeniAlan(): FormAlani {
  return {
    id: `alan_${Date.now()}`,
    ad: '',
    etiket: 'Yeni Alan',
    tip: 'metin',
    zorunlu: false,
    sira: 999,
  };
}

const AlanDuzenleyici: React.FC<{
  alan: FormAlani;
  onGuncelle: (a: FormAlani) => void;
  onSil: () => void;
  onYukari: () => void;
  onAsagi: () => void;
}> = ({ alan, onGuncelle, onSil, onYukari, onAsagi }) => {
  const [acik, setAcik] = useState(false);
  const [yeniSecenek, setYeniSecenek] = useState('');

  return (
    <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
      <div className="flex items-center gap-2 px-3 py-2.5 bg-gray-50 border-b border-gray-100 cursor-pointer" onClick={() => setAcik(!acik)}>
        <GripVertical className="w-4 h-4 text-gray-300 flex-shrink-0" />
        <span className="text-sm font-mono text-gray-400 w-6 text-center">{TIP_ICON[alan.tip]}</span>
        <p className="flex-1 text-sm font-medium text-gray-700">{alan.etiket || 'Yeni Alan'}</p>
        <span className="text-[10px] text-gray-400 hidden sm:inline">{TIP_ETIKETI[alan.tip]}</span>
        {alan.zorunlu && <span className="text-[10px] bg-red-100 text-red-600 px-1.5 rounded-full">Zorunlu</span>}
        <div className="flex items-center gap-0.5 ml-1">
          <button onClick={(e) => { e.stopPropagation(); onYukari(); }} className="p-0.5 hover:bg-gray-200 rounded"><ChevronUp className="w-3.5 h-3.5" /></button>
          <button onClick={(e) => { e.stopPropagation(); onAsagi(); }} className="p-0.5 hover:bg-gray-200 rounded"><ChevronDown className="w-3.5 h-3.5" /></button>
          <button onClick={(e) => { e.stopPropagation(); onSil(); }} className="p-0.5 hover:bg-red-100 rounded text-gray-400 hover:text-red-600 ml-1"><Trash2 className="w-3.5 h-3.5" /></button>
        </div>
      </div>

      {acik && (
        <div className="p-3 space-y-3">
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-[10px] font-medium text-gray-500 block mb-0.5">Alan Etiketi</label>
              <input value={alan.etiket} onChange={(e) => onGuncelle({ ...alan, etiket: e.target.value })}
                className="w-full border border-gray-200 rounded-lg px-2.5 py-1.5 text-sm outline-none focus:ring-1 focus:ring-indigo-300" />
            </div>
            <div>
              <label className="text-[10px] font-medium text-gray-500 block mb-0.5">Alan Tipi</label>
              <select value={alan.tip} onChange={(e) => onGuncelle({ ...alan, tip: e.target.value as AlanTipi })}
                className="w-full border border-gray-200 rounded-lg px-2.5 py-1.5 text-sm outline-none focus:ring-1 focus:ring-indigo-300">
                {(Object.keys(TIP_ETIKETI) as AlanTipi[]).map((t) => (
                  <option key={t} value={t}>{TIP_ETIKETI[t]}</option>
                ))}
              </select>
            </div>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-[10px] font-medium text-gray-500 block mb-0.5">Sistem Adı (camelCase)</label>
              <input value={alan.ad} onChange={(e) => onGuncelle({ ...alan, ad: e.target.value })}
                placeholder="ornek_alan_adi"
                className="w-full border border-gray-200 rounded-lg px-2.5 py-1.5 text-sm font-mono outline-none focus:ring-1 focus:ring-indigo-300" />
            </div>
            <div>
              <label className="text-[10px] font-medium text-gray-500 block mb-0.5">Açıklama Notu</label>
              <input value={alan.aciklamaNotu ?? ''} onChange={(e) => onGuncelle({ ...alan, aciklamaNotu: e.target.value })}
                className="w-full border border-gray-200 rounded-lg px-2.5 py-1.5 text-sm outline-none focus:ring-1 focus:ring-indigo-300" />
            </div>
          </div>
          <div className="flex items-center gap-2">
            <input type="checkbox" id={`zor_${alan.id}`} checked={alan.zorunlu} onChange={(e) => onGuncelle({ ...alan, zorunlu: e.target.checked })} className="accent-indigo-600" />
            <label htmlFor={`zor_${alan.id}`} className="text-xs text-gray-600">Zorunlu alan</label>
          </div>

          {(alan.tip === 'secim' || alan.tip === 'coklu-secim') && (
            <div>
              <label className="text-[10px] font-medium text-gray-500 block mb-1">Seçenekler</label>
              <div className="space-y-1 mb-2">
                {(alan.secenekler ?? []).map((s, i) => (
                  <div key={i} className="flex items-center gap-2">
                    <span className="flex-1 text-xs bg-gray-50 border border-gray-200 rounded px-2 py-1">{s}</span>
                    <button onClick={() => onGuncelle({ ...alan, secenekler: alan.secenekler!.filter((_, j) => j !== i) })}
                      className="text-gray-400 hover:text-red-500"><X className="w-3.5 h-3.5" /></button>
                  </div>
                ))}
              </div>
              <div className="flex gap-1.5">
                <input value={yeniSecenek} onChange={(e) => setYeniSecenek(e.target.value)}
                  onKeyDown={(e) => {
                    if (e.key === 'Enter' && yeniSecenek.trim()) {
                      onGuncelle({ ...alan, secenekler: [...(alan.secenekler ?? []), yeniSecenek.trim()] });
                      setYeniSecenek('');
                    }
                  }}
                  placeholder="Seçenek ekle (Enter)"
                  className="flex-1 border border-gray-200 rounded-lg px-2.5 py-1.5 text-xs outline-none focus:ring-1 focus:ring-indigo-300" />
                <button
                  onClick={() => {
                    if (yeniSecenek.trim()) {
                      onGuncelle({ ...alan, secenekler: [...(alan.secenekler ?? []), yeniSecenek.trim()] });
                      setYeniSecenek('');
                    }
                  }}
                  className="px-2.5 py-1.5 bg-indigo-100 text-indigo-700 rounded-lg text-xs font-medium hover:bg-indigo-200">
                  Ekle
                </button>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
};

const OnizlemeAlani: React.FC<{ alan: FormAlani }> = ({ alan }) => {
  switch (alan.tip) {
    case 'metin':
      return <input placeholder={alan.aciklamaNotu} className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm" disabled />;
    case 'uzun-metin':
      return <textarea placeholder={alan.aciklamaNotu} rows={3} className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm resize-none" disabled />;
    case 'sayi':
      return <input type="number" className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm" disabled />;
    case 'tarih':
      return <input type="date" className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm" disabled />;
    case 'secim':
      return (
        <select className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm" disabled>
          <option>Seçiniz...</option>
          {alan.secenekler?.map((s) => <option key={s}>{s}</option>)}
        </select>
      );
    case 'coklu-secim':
      return (
        <div className="flex flex-wrap gap-1.5 p-2 border border-gray-200 rounded-lg bg-gray-50">
          {(alan.secenekler ?? []).map((s) => (
            <span key={s} className="text-xs bg-white border border-gray-200 px-2 py-0.5 rounded-full text-gray-600">{s}</span>
          ))}
        </div>
      );
    case 'evet-hayir':
      return (
        <div className="flex gap-3">
          <label className="flex items-center gap-1.5 text-sm"><input type="radio" disabled />Evet</label>
          <label className="flex items-center gap-1.5 text-sm"><input type="radio" disabled />Hayır</label>
        </div>
      );
    case 'dosya':
      return (
        <div className="border-2 border-dashed border-gray-200 rounded-lg p-4 text-center text-sm text-gray-400">
          📎 Dosya seçmek için tıklayın
        </div>
      );
    default:
      return null;
  }
};

const DinamikFormBuilder: React.FC = () => {
  const [sablonlar, setSablonlar] = useState<FormSablonu[]>(DEMO_SABLONLAR);
  const [secilenSablon, setSecilenSablon] = useState<string>(DEMO_SABLONLAR[0].id);
  const [onizleme, setOnizleme] = useState(false);
  const [yeniSablonModal, setYeniSablonModal] = useState(false);
  const [yeniSablonForm, setYeniSablonForm] = useState({ ad: '', aciklama: '', kategori: 'Özlük' });

  const aktifSablon = sablonlar.find((s) => s.id === secilenSablon)!;

  function guncelle(sablon: FormSablonu) {
    setSablonlar((prev) => prev.map((s) => (s.id === sablon.id ? sablon : s)));
  }

  function alanGuncelle(alanId: string, yeniAlanData: FormAlani) {
    guncelle({ ...aktifSablon, alanlar: aktifSablon.alanlar.map((a) => (a.id === alanId ? yeniAlanData : a)) });
  }

  function alanSil(alanId: string) {
    guncelle({ ...aktifSablon, alanlar: aktifSablon.alanlar.filter((a) => a.id !== alanId) });
  }

  function alanEkle() {
    const a = yeniAlan();
    a.sira = aktifSablon.alanlar.length + 1;
    guncelle({ ...aktifSablon, alanlar: [...aktifSablon.alanlar, a] });
  }

  function alanTasıYukari(alanId: string) {
    const idx = aktifSablon.alanlar.findIndex((a) => a.id === alanId);
    if (idx <= 0) return;
    const alanlar = [...aktifSablon.alanlar];
    [alanlar[idx - 1], alanlar[idx]] = [alanlar[idx], alanlar[idx - 1]];
    guncelle({ ...aktifSablon, alanlar });
  }

  function alanTasıAsagi(alanId: string) {
    const idx = aktifSablon.alanlar.findIndex((a) => a.id === alanId);
    if (idx >= aktifSablon.alanlar.length - 1) return;
    const alanlar = [...aktifSablon.alanlar];
    [alanlar[idx], alanlar[idx + 1]] = [alanlar[idx + 1], alanlar[idx]];
    guncelle({ ...aktifSablon, alanlar });
  }

  function yeniSablonOlustur() {
    const sablon: FormSablonu = {
      id: `f${Date.now()}`,
      ...yeniSablonForm,
      alanlar: [],
      olusturulma: new Date().toISOString().split('T')[0],
    };
    setSablonlar((prev) => [...prev, sablon]);
    setSecilenSablon(sablon.id);
    setYeniSablonModal(false);
    setYeniSablonForm({ ad: '', aciklama: '', kategori: 'Özlük' });
  }

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div>
          <h2 className="text-xl font-bold text-gray-800">Dinamik Form</h2>
          <p className="text-sm text-gray-500 mt-0.5">Özlük formuna özel alanlar ekleyin, sürükle-bırak ile sıralayın</p>
        </div>
        <div className="flex gap-2">
          <button onClick={() => setOnizleme(true)}
            className="flex items-center gap-2 border border-indigo-200 text-indigo-700 px-4 py-2 rounded-xl text-sm font-medium hover:bg-indigo-50">
            <Eye className="w-4 h-4" /> Önizle
          </button>
          <button onClick={() => setYeniSablonModal(true)}
            className="flex items-center gap-2 bg-indigo-600 text-white px-4 py-2 rounded-xl text-sm font-medium hover:bg-indigo-700">
            <Plus className="w-4 h-4" /> Yeni Form
          </button>
        </div>
      </div>

      <div className="flex gap-5 flex-col md:flex-row">
        {/* Sol: Şablon listesi */}
        <div className="w-full md:w-56 flex-shrink-0 space-y-2">
          <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide">Form Şablonları</p>
          {sablonlar.map((s) => (
            <button key={s.id} onClick={() => setSecilenSablon(s.id)}
              className={`w-full text-left p-3 rounded-xl border text-sm transition-all ${secilenSablon === s.id ? 'border-indigo-500 bg-indigo-50' : 'border-gray-200 hover:border-gray-300 bg-white'}`}>
              <p className="font-semibold text-gray-800 truncate">{s.ad}</p>
              <p className="text-[10px] text-gray-400 mt-0.5">{s.kategori} · {s.alanlar.length} alan</p>
            </button>
          ))}
        </div>

        {/* Sağ: Alan editörü */}
        <div className="flex-1 space-y-3">
          <div className="bg-white rounded-2xl border border-gray-200 p-4 flex items-start justify-between gap-3 flex-wrap">
            <div>
              <p className="font-bold text-gray-800">{aktifSablon?.ad}</p>
              <p className="text-xs text-gray-400 mt-0.5">{aktifSablon?.aciklama}</p>
              <p className="text-[10px] text-gray-300 mt-0.5">Oluşturulma: {aktifSablon?.olusturulma}</p>
            </div>
            <span className="text-xs bg-indigo-100 text-indigo-700 px-2 py-0.5 rounded-full">{aktifSablon?.kategori}</span>
          </div>

          <div className="space-y-2">
            {aktifSablon?.alanlar.map((alan) => (
              <AlanDuzenleyici
                key={alan.id}
                alan={alan}
                onGuncelle={(a) => alanGuncelle(alan.id, a)}
                onSil={() => alanSil(alan.id)}
                onYukari={() => alanTasıYukari(alan.id)}
                onAsagi={() => alanTasıAsagi(alan.id)}
              />
            ))}
          </div>

          <button onClick={alanEkle}
            className="w-full border-2 border-dashed border-gray-300 text-gray-500 rounded-xl py-3 text-sm hover:border-indigo-400 hover:text-indigo-600 flex items-center justify-center gap-2">
            <Plus className="w-4 h-4" /> Yeni Alan Ekle
          </button>
        </div>
      </div>

      {/* Önizleme Modal */}
      {onizleme && aktifSablon && (
        <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-lg p-6 space-y-4 max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between">
              <p className="font-bold text-gray-800">{aktifSablon.ad} — Önizleme</p>
              <button onClick={() => setOnizleme(false)}><X className="w-5 h-5 text-gray-400" /></button>
            </div>
            <p className="text-xs text-gray-400 bg-yellow-50 border border-yellow-200 rounded-xl p-2.5">
              Bu, formun kullanıcıya nasıl görüneceğinin önizlemesidir. Alanlar deaktif (düzenlenemez) gösterilmektedir.
            </p>
            <div className="space-y-4">
              {aktifSablon.alanlar.map((alan) => (
                <div key={alan.id}>
                  <label className="text-sm font-medium text-gray-700 block mb-1">
                    {alan.etiket}
                    {alan.zorunlu && <span className="text-red-500 ml-1">*</span>}
                  </label>
                  {alan.aciklamaNotu && <p className="text-xs text-gray-400 mb-1">{alan.aciklamaNotu}</p>}
                  <OnizlemeAlani alan={alan} />
                </div>
              ))}
              {aktifSablon.alanlar.length === 0 && (
                <p className="text-sm text-gray-400 text-center py-6">Henüz alan eklenmemiş</p>
              )}
            </div>
            <button onClick={() => setOnizleme(false)} className="w-full bg-indigo-600 text-white rounded-xl py-2.5 text-sm font-medium hover:bg-indigo-700">
              Kapat
            </button>
          </div>
        </div>
      )}

      {/* Yeni Şablon Modal */}
      {yeniSablonModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md p-6 space-y-4">
            <div className="flex items-center justify-between">
              <p className="font-bold text-gray-800">Yeni Form Şablonu</p>
              <button onClick={() => setYeniSablonModal(false)}><X className="w-5 h-5 text-gray-400" /></button>
            </div>
            <div>
              <label className="text-xs font-medium text-gray-600 block mb-1">Form Adı *</label>
              <input value={yeniSablonForm.ad} onChange={(e) => setYeniSablonForm({ ...yeniSablonForm, ad: e.target.value })}
                className="w-full border border-gray-200 rounded-xl px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-indigo-300" />
            </div>
            <div>
              <label className="text-xs font-medium text-gray-600 block mb-1">Açıklama</label>
              <input value={yeniSablonForm.aciklama} onChange={(e) => setYeniSablonForm({ ...yeniSablonForm, aciklama: e.target.value })}
                className="w-full border border-gray-200 rounded-xl px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-indigo-300" />
            </div>
            <div>
              <label className="text-xs font-medium text-gray-600 block mb-1">Kategori</label>
              <select value={yeniSablonForm.kategori} onChange={(e) => setYeniSablonForm({ ...yeniSablonForm, kategori: e.target.value })}
                className="w-full border border-gray-200 rounded-xl px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-indigo-300">
                {['Özlük', 'Onboarding', 'Performans', 'İzin', 'Genel'].map((k) => <option key={k}>{k}</option>)}
              </select>
            </div>
            <div className="flex gap-2 pt-1">
              <button onClick={() => setYeniSablonModal(false)} className="flex-1 border border-gray-200 rounded-xl py-2 text-sm text-gray-600">İptal</button>
              <button onClick={yeniSablonOlustur} disabled={!yeniSablonForm.ad}
                className="flex-1 bg-indigo-600 text-white rounded-xl py-2 text-sm font-medium hover:bg-indigo-700 disabled:opacity-50 flex items-center justify-center gap-1.5">
                <Save className="w-4 h-4" /> Oluştur
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default DinamikFormBuilder;

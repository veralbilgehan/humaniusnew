import React, { useState } from 'react';
import { CheckCircle, Clock, AlertCircle, ChevronRight, User, BookOpen, FileText, ArrowRight, Play, X } from 'lucide-react';

type OnboardingAdimDurum = 'bekliyor' | 'devam' | 'tamamlandi' | 'gecikti';

interface OnboardingAdim {
  id: string;
  baslik: string;
  aciklama: string;
  sistem: string;
  sure: string;
  durum: OnboardingAdimDurum;
  tarih?: string;
  otomatik: boolean;
}

interface OnboardingKayit {
  id: string;
  adayAdi: string;
  pozisyon: string;
  baslangicTarihi: string;
  tetikTarihi: string;
  adimlar: OnboardingAdim[];
}

const ONBOARDING_TEMPLATE: Omit<OnboardingAdim, 'durum' | 'tarih'>[] = [
  { id: 'a1', baslik: 'Özlük Dosyası Oluşturuldu', aciklama: 'ATS\'ten gelen aday verisi ile personel kaydı otomatik oluşturulur', sistem: 'Özlük İşleri', sure: 'Otomatik', otomatik: true },
  { id: 'a2', baslik: 'Hoş Geldin E-postası Gönderildi', aciklama: 'Şirket bilgileri, ilk gün programı ve giriş bilgilerini içeren e-posta', sistem: 'E-posta Sistemi', sure: 'Otomatik', otomatik: true },
  { id: 'a3', baslik: 'IT Ekipmanı Talebinde Bulunuldu', aciklama: 'Bilgisayar, telefon ve aksesuarlar için IT\'ye otomatik talep iletilir', sistem: 'Zimmet Yönetimi', sure: '1 gün', otomatik: true },
  { id: 'a4', baslik: 'Oryantasyon Eğitimi Atandı', aciklama: 'LMS\'te "Hoş Geldin Paketi" eğitim serisi otomatik atanır', sistem: 'LMS', sure: 'Otomatik', otomatik: true },
  { id: 'a5', baslik: 'KVKK Aydınlatma Metni İmzalandı', aciklama: 'Çalışan KVKK onayını dijital olarak imzalar', sistem: 'KVKK Modülü', sure: '1-2 gün', otomatik: false },
  { id: 'a6', baslik: 'İlk Performans Hedefleri Belirlendi', aciklama: 'Yönetici, çalışanın ilk 30-60-90 gün OKR hedeflerini tanımlar', sistem: 'OKR Yönetimi', sure: '1 hafta', otomatik: false },
  { id: 'a7', baslik: 'Sisteme Erişim Yetkileri Verildi', aciklama: 'Rol bazlı sistem erişimleri IT onayıyla aktifleştirilir', sistem: 'Kullanıcı Yönetimi', sure: '1 gün', otomatik: false },
  { id: 'a8', baslik: 'İlk Ay Değerlendirmesi', aciklama: 'Yönetici ile ilk 30 gün check-in toplantısı gerçekleştirilir', sistem: 'Performans Yönetimi', sure: '30. gün', otomatik: false },
];

function createOnboarding(id: string, ad: string, pozisyon: string, tarih: string): OnboardingKayit {
  return {
    id,
    adayAdi: ad,
    pozisyon,
    baslangicTarihi: tarih,
    tetikTarihi: new Date().toISOString().split('T')[0],
    adimlar: ONBOARDING_TEMPLATE.map((a, i) => ({
      ...a,
      durum: i < 4 ? 'tamamlandi' : i === 4 ? 'devam' : 'bekliyor',
      tarih: i < 4 ? new Date(Date.now() - (4 - i) * 86400000).toISOString().split('T')[0] : undefined,
    })) as OnboardingAdim[],
  };
}

const DEMO_ONBOARDINGLAR: OnboardingKayit[] = [
  createOnboarding('o1', 'Ayşe Kaya', 'Satış Uzmanı', '2026-05-06'),
  createOnboarding('o2', 'Mehmet Yılmaz', 'Yazılım Geliştirici', '2026-05-10'),
];

const DURUM_RENK: Record<OnboardingAdimDurum, string> = {
  tamamlandi: 'bg-green-100 text-green-700 border-green-200',
  devam: 'bg-blue-100 text-blue-700 border-blue-200',
  bekliyor: 'bg-gray-100 text-gray-500 border-gray-200',
  gecikti: 'bg-red-100 text-red-600 border-red-200',
};

const DURUM_IKON: Record<OnboardingAdimDurum, React.ReactNode> = {
  tamamlandi: <CheckCircle className="w-5 h-5 text-green-600" />,
  devam: <Clock className="w-5 h-5 text-blue-500" />,
  bekliyor: <div className="w-5 h-5 rounded-full border-2 border-gray-300" />,
  gecikti: <AlertCircle className="w-5 h-5 text-red-500" />,
};

const OnboardingTimeline: React.FC<{ kayit: OnboardingKayit; onGuncelle: (k: OnboardingKayit) => void }> = ({ kayit, onGuncelle }) => {
  const tamamlanan = kayit.adimlar.filter((a) => a.durum === 'tamamlandi').length;
  const yuzde = Math.round((tamamlanan / kayit.adimlar.length) * 100);

  function adimTamamla(adimId: string) {
    onGuncelle({
      ...kayit,
      adimlar: kayit.adimlar.map((a, i, arr) => {
        if (a.id !== adimId) return a;
        const yeni: OnboardingAdim = { ...a, durum: 'tamamlandi', tarih: new Date().toISOString().split('T')[0] };
        // Bir sonraki adımı 'devam'a al
        return yeni;
      }).map((a, i, arr) => {
        if (a.durum === 'bekliyor' && arr[i - 1]?.durum === 'tamamlandi') {
          return { ...a, durum: 'devam' };
        }
        return a;
      }),
    });
  }

  return (
    <div className="bg-white rounded-2xl border border-gray-200 p-5 space-y-4">
      <div className="flex items-start justify-between">
        <div>
          <p className="font-bold text-gray-800">{kayit.adayAdi}</p>
          <p className="text-xs text-gray-500">{kayit.pozisyon} · Başlangıç: {kayit.baslangicTarihi}</p>
        </div>
        <div className="text-right">
          <p className="text-lg font-bold text-indigo-700">{yuzde}%</p>
          <p className="text-xs text-gray-400">{tamamlanan}/{kayit.adimlar.length} adım</p>
        </div>
      </div>

      {/* Progress bar */}
      <div className="w-full bg-gray-200 rounded-full h-2">
        <div className="bg-indigo-500 h-2 rounded-full transition-all" style={{ width: `${yuzde}%` }} />
      </div>

      {/* Adımlar */}
      <div className="space-y-2">
        {kayit.adimlar.map((adim) => (
          <div key={adim.id} className={`flex items-start gap-3 p-3 rounded-xl border ${DURUM_RENK[adim.durum]}`}>
            <div className="flex-shrink-0 mt-0.5">{DURUM_IKON[adim.durum]}</div>
            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-2 flex-wrap">
                <p className="text-sm font-semibold">{adim.baslik}</p>
                {adim.otomatik && (
                  <span className="text-[10px] bg-indigo-100 text-indigo-700 px-1.5 py-0.5 rounded-full font-medium">
                    Otomatik
                  </span>
                )}
              </div>
              <p className="text-xs text-gray-500 mt-0.5">{adim.aciklama}</p>
              <div className="flex items-center gap-3 mt-1 text-[10px] text-gray-400">
                <span className="flex items-center gap-1">
                  <BookOpen className="w-3 h-3" />{adim.sistem}
                </span>
                <span className="flex items-center gap-1">
                  <Clock className="w-3 h-3" />{adim.sure}
                </span>
                {adim.tarih && <span>{adim.tarih}</span>}
              </div>
            </div>
            {adim.durum === 'devam' && !adim.otomatik && (
              <button
                onClick={() => adimTamamla(adim.id)}
                className="flex-shrink-0 text-xs bg-blue-600 text-white px-2.5 py-1 rounded-lg hover:bg-blue-700"
              >
                Tamamla
              </button>
            )}
          </div>
        ))}
      </div>
    </div>
  );
};

const OnboardingAkisi: React.FC = () => {
  const [onboardinglar, setOnboardinglar] = useState<OnboardingKayit[]>(DEMO_ONBOARDINGLAR);
  const [yeniModal, setYeniModal] = useState(false);
  const [akisGoster, setAkisGoster] = useState(false);
  const [form, setForm] = useState({ ad: '', pozisyon: '', tarih: '' });

  function yeniEkle() {
    const kayit = createOnboarding(`o${Date.now()}`, form.ad, form.pozisyon, form.tarih);
    setOnboardinglar((prev) => [kayit, ...prev]);
    setYeniModal(false);
    setForm({ ad: '', pozisyon: '', tarih: '' });
  }

  return (
    <div className="space-y-5">
      {/* Başlık */}
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div>
          <h2 className="text-xl font-bold text-gray-800">ATS → Özlük → LMS Onboarding Akışı</h2>
          <p className="text-sm text-gray-500 mt-0.5">
            Kabul edilen aday otomatik olarak işe başlatma sürecine alınır
          </p>
        </div>
        <div className="flex gap-2">
          <button
            onClick={() => setAkisGoster(true)}
            className="flex items-center gap-2 border border-indigo-200 text-indigo-700 px-4 py-2 rounded-xl text-sm font-medium hover:bg-indigo-50"
          >
            <Play className="w-4 h-4" />
            Akış Şeması
          </button>
          <button
            onClick={() => setYeniModal(true)}
            className="flex items-center gap-2 bg-indigo-600 text-white px-4 py-2 rounded-xl text-sm font-medium hover:bg-indigo-700"
          >
            <User className="w-4 h-4" />
            Yeni Aday Başlat
          </button>
        </div>
      </div>

      {/* Akış şeması */}
      {akisGoster && (
        <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-3xl p-6 space-y-5">
            <div className="flex items-center justify-between">
              <p className="font-bold text-gray-800 text-lg">Entegrasyon Mimarisi</p>
              <button onClick={() => setAkisGoster(false)}><X className="w-5 h-5 text-gray-400" /></button>
            </div>

            <div className="overflow-x-auto">
              <div className="flex items-stretch gap-0 min-w-max">
                {[
                  { sistem: 'ATS', renk: 'bg-purple-100 border-purple-300', text: 'text-purple-800', eylem: '"Kabul Edildi"\nstatüsü verilir', ikon: <User className="w-5 h-5" /> },
                  { sistem: 'API Gateway', renk: 'bg-gray-100 border-gray-300', text: 'text-gray-700', eylem: 'Webhook tetiklenir\nVeri aktarılır', ikon: <ArrowRight className="w-5 h-5" /> },
                  { sistem: 'Özlük İşleri', renk: 'bg-blue-100 border-blue-300', text: 'text-blue-800', eylem: 'Personel kaydı\notomatik açılır', ikon: <FileText className="w-5 h-5" /> },
                  { sistem: 'LMS', renk: 'bg-green-100 border-green-300', text: 'text-green-800', eylem: 'Oryantasyon paketi\notomatik atanır', ikon: <BookOpen className="w-5 h-5" /> },
                  { sistem: 'IT / Zimmet', renk: 'bg-yellow-100 border-yellow-300', text: 'text-yellow-800', eylem: 'Ekipman talebi\notomatik açılır', ikon: <CheckCircle className="w-5 h-5" /> },
                ].map((node, i, arr) => (
                  <React.Fragment key={i}>
                    <div className={`flex flex-col items-center p-4 rounded-2xl border-2 ${node.renk} min-w-32 text-center`}>
                      <div className={`${node.text} mb-2`}>{node.ikon}</div>
                      <p className={`text-sm font-bold ${node.text}`}>{node.sistem}</p>
                      <p className={`text-[10px] mt-1 ${node.text} whitespace-pre-line leading-tight`}>{node.eylem}</p>
                    </div>
                    {i < arr.length - 1 && (
                      <div className="flex items-center px-2">
                        <ChevronRight className="w-5 h-5 text-gray-400" />
                      </div>
                    )}
                  </React.Fragment>
                ))}
              </div>
            </div>

            <div className="bg-indigo-50 rounded-xl p-4 text-sm text-indigo-800">
              <p className="font-semibold mb-1">Otomatik Tetikleme Mantığı</p>
              <p className="text-xs text-indigo-600">
                ATS'te bir aday "Kabul Edildi" olarak işaretlendiğinde sistem otomatik olarak:
                (1) Özlük kaydını oluşturur, (2) Hoş geldin e-postası gönderir, (3) LMS'te oryantasyon paketini atar, (4) IT'ye ekipman talebi iletir.
                Yönetici sadece KVKK imzası ve hedef tanımlaması için manuel aksiyon alır.
              </p>
            </div>
            <button onClick={() => setAkisGoster(false)} className="w-full bg-indigo-600 text-white rounded-xl py-2.5 text-sm font-medium hover:bg-indigo-700">
              Kapat
            </button>
          </div>
        </div>
      )}

      {/* Özet */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
        {[
          { etiket: 'Aktif Onboarding', deger: onboardinglar.length, renk: 'text-indigo-700 bg-indigo-50' },
          { etiket: 'Otomatik Tamamlanan', deger: onboardinglar.reduce((sum, o) => sum + o.adimlar.filter((a) => a.otomatik && a.durum === 'tamamlandi').length, 0), renk: 'text-green-700 bg-green-50' },
          { etiket: 'Bekleyen Manuel Adım', deger: onboardinglar.reduce((sum, o) => sum + o.adimlar.filter((a) => !a.otomatik && a.durum === 'devam').length, 0), renk: 'text-yellow-700 bg-yellow-50' },
          { etiket: 'Ort. Tamamlanma', deger: `${Math.round(onboardinglar.reduce((sum, o) => sum + o.adimlar.filter((a) => a.durum === 'tamamlandi').length / o.adimlar.length * 100, 0) / (onboardinglar.length || 1))}%`, renk: 'text-blue-700 bg-blue-50' },
        ].map((item) => (
          <div key={item.etiket} className={`${item.renk} rounded-2xl p-4`}>
            <p className="text-xs text-gray-500">{item.etiket}</p>
            <p className={`text-2xl font-bold ${item.renk.split(' ')[0]}`}>{item.deger}</p>
          </div>
        ))}
      </div>

      {/* Onboarding listesi */}
      <div className="space-y-4">
        {onboardinglar.map((kayit) => (
          <OnboardingTimeline
            key={kayit.id}
            kayit={kayit}
            onGuncelle={(k) => setOnboardinglar((prev) => prev.map((o) => (o.id === k.id ? k : o)))}
          />
        ))}
        {onboardinglar.length === 0 && (
          <div className="bg-white rounded-2xl border border-dashed border-gray-300 p-10 text-center text-gray-400">
            <User className="w-8 h-8 mx-auto mb-2 opacity-30" />
            <p className="text-sm">Aktif onboarding süreci yok. Yeni bir aday başlatın.</p>
          </div>
        )}
      </div>

      {/* Yeni Modal */}
      {yeniModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md p-6 space-y-4">
            <div className="flex items-center justify-between">
              <p className="font-bold text-gray-800">Yeni Aday Onboarding Başlat</p>
              <button onClick={() => setYeniModal(false)}><X className="w-5 h-5 text-gray-400" /></button>
            </div>
            <div className="bg-green-50 border border-green-200 rounded-xl p-3 text-xs text-green-700">
              Bu işlem: Özlük kaydı oluşturur, hoş geldin e-postası gönderir, LMS'te oryantasyon paketini atar ve IT ekipman talebini açar.
            </div>
            <div>
              <label className="text-xs font-medium text-gray-600 block mb-1">Aday Adı Soyadı *</label>
              <input value={form.ad} onChange={(e) => setForm({ ...form, ad: e.target.value })}
                className="w-full border border-gray-200 rounded-xl px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-indigo-300" />
            </div>
            <div>
              <label className="text-xs font-medium text-gray-600 block mb-1">Pozisyon *</label>
              <input value={form.pozisyon} onChange={(e) => setForm({ ...form, pozisyon: e.target.value })}
                className="w-full border border-gray-200 rounded-xl px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-indigo-300" />
            </div>
            <div>
              <label className="text-xs font-medium text-gray-600 block mb-1">İşe Başlama Tarihi *</label>
              <input type="date" value={form.tarih} onChange={(e) => setForm({ ...form, tarih: e.target.value })}
                className="w-full border border-gray-200 rounded-xl px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-indigo-300" />
            </div>
            <div className="flex gap-2 pt-1">
              <button onClick={() => setYeniModal(false)} className="flex-1 border border-gray-200 rounded-xl py-2 text-sm text-gray-600">İptal</button>
              <button onClick={yeniEkle} disabled={!form.ad || !form.pozisyon || !form.tarih}
                className="flex-1 bg-indigo-600 text-white rounded-xl py-2 text-sm font-medium hover:bg-indigo-700 disabled:opacity-50">
                Onboarding Başlat
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default OnboardingAkisi;

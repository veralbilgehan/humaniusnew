# IK Yönetim Sistemi + AI Tarayıcı — Entegrasyon Notları

## Kurulum

```bash
npm install
```

## Ortam Değişkenleri

`.env` dosyasına aşağıdaki anahtarları girin:

```env
VITE_SUPABASE_URL=https://...supabase.co
VITE_SUPABASE_ANON_KEY=eyJ...

# AI Tarayıcı için Gemini API anahtarı:
# https://aistudio.google.com/app/apikey adresinden edinin
VITE_GEMINI_API_KEY=AIza...
```

## Çalıştırma

```bash
npm run dev     # geliştirme
npm run build   # production build
npm run preview # build önizleme
```

## Yeni Dosyalar (Entegrasyon)

| Dosya | Açıklama |
|---|---|
| `src/App.tsx` | Ana uygulama — tüm view'ları birleştirir |
| `src/main.tsx` | Vite giriş noktası |
| `src/types.ts` | Paylaşılan tipler (View, Employee, Stats…) |
| `src/types/bordro.ts` | BordroItem arayüzü |
| `src/types/izin.ts` | IzinTalebi, IzinHakki, IzinTuru |
| `src/types/takvim.ts` | TakvimEtkinlik ve ilgili tipler |
| `src/utils/bordroCalculations.ts` | 2026 parametreli bordro hesaplama motoru |
| `src/utils/izinCalculations.ts` | İzin hesaplama yardımcıları |
| `src/utils/takvimUtils.ts` | Takvim etkinlik yardımcıları ve sabitler |
| `src/components/BordroList.tsx` | Bordro kayıtları tablosu |
| `src/browser/` | Flash-Lite AI Tarayıcı modülü |
| `src/browser/AIBrowserPage.tsx` | Tarayıcıyı bolt view'ına bağlayan wrapper |
| `src/browser/browser.css` | Tarayıcı stilleri (Tailwind'den izole) |

## AI Tarayıcı Kullanımı

1. Giriş yaptıktan sonra sol menüden **AI Tarayıcı** (🌐) seçin
2. Metin kutusuna istediğiniz web sitesi açıklamasını yazın
3. Gemini 3.1 Flash-Lite gerçek zamanlı HTML üretir
4. İstediğiniz kadar sekme açabilirsiniz
5. Google Search grounding'ı açmak için adres çubuğundaki menüyü kullanın

## Mimari

```
src/
├── App.tsx                  ← Ana orkestratör
├── browser/                 ← Flash-Lite AI Tarayıcı modülü
│   ├── AIBrowserPage.tsx    ← bolt view wrapper
│   ├── BrowserShell.tsx     ← Tarayıcı kabuğu
│   ├── Sandbox.tsx          ← İzole iframe renderer
│   ├── AddressBar.tsx       ← Omnibar
│   ├── NewTab.tsx           ← Yeni sekme sayfası
│   ├── geminiService.ts     ← Gemini API streaming
│   ├── browserTypes.ts      ← Tarayıcı tipleri
│   ├── urlHelpers.ts        ← URL/breadcrumb yardımcıları
│   └── browser.css          ← Dark tema stilleri
├── components/              ← IK modülü bileşenleri
├── contexts/                ← Auth + Dil context'leri
├── services/                ← Supabase servisleri
├── types/                   ← Modüle özel tip dosyaları
└── utils/                   ← Hesaplama yardımcıları
```

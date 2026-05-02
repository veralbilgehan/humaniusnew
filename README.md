# 🏢 HR Management System - İnsan Kaynakları Yönetim Sistemi

Modern ve kapsamlı bir insan kaynakları yönetim platformu. Personel, izin, bordro ve takvim yönetimini tek bir çatı altında toplayan kullanıcı dostu bir web uygulaması.

## 📋 İçindekiler

- [Özellikler](#-özellikler)
- [Kurulum](#-kurulum)
- [Kullanım](#-kullanım)
- [Modüller](#-modüller)
- [Teknolojiler](#-teknolojiler)
- [Katkıda Bulunma](#-katkıda-bulunma)

## ✨ Özellikler

### 🎯 Ana Özellikler

- **Personel Yönetimi**: Çalışan bilgilerini ekleyin, düzenleyin ve yönetin
- **İzin Yönetimi**: İzin talepleri oluşturun, onaylayın ve takip edin
- **Bordro Hesaplama**: Detaylı bordro hesaplamaları yapın ve kaydedin
- **Takvim & Uyarılar**: Önemli tarihleri takip edin ve hatırlatmalar alın
- **Raporlama**: Kapsamlı raporlar oluşturun ve analiz yapın
- **Sistem Ayarları**: Uygulamayı ihtiyaçlarınıza göre özelleştirin
- **Çoklu Dil Desteği**: Türkçe ve İngilizce dil seçenekleri
- **CSV İçe/Dışa Aktarma**: Verilerinizi kolayca içe ve dışa aktarın

### 🌟 Kullanıcı Dostu Özellikler

- Modern ve temiz arayüz tasarımı
- Responsive tasarım (mobil uyumlu)
- Hızlı arama ve filtreleme
- Gerçek zamanlı istatistikler
- Detaylı personel profilleri
- Otomatik hesaplamalar
- Excel uyumlu veri aktarımı

## 🚀 Kurulum

### Gereksinimler

- Node.js (v18 veya üzeri)
- npm veya yarn paket yöneticisi

### Adım 1: Projeyi İndirin

```bash
git clone <repository-url>
cd project
```

### Adım 2: Bağımlılıkları Yükleyin

```bash
npm install
```

### Adım 3: Geliştirme Sunucusunu Başlatın

```bash
npm run dev
```

Uygulama varsayılan olarak `http://localhost:5173` adresinde çalışacaktır.

### Adım 4: Production Build

```bash
npm run build
npm run preview
```

## 📖 Kullanım

### İlk Giriş

1. Tarayıcınızda `http://localhost:5173` adresini açın
2. Ana sayfa otomatik olarak **Personel Yönetimi** ekranıyla açılır
3. Sol menüden diğer modüllere geçiş yapabilirsiniz

### Hızlı Başlangıç

#### Yeni Personel Ekleme

1. Sağ üst köşedeki **"+ Yeni Personel"** butonuna tıklayın
2. Açılan formda gerekli bilgileri doldurun:
   - Ad Soyad
   - Şirket
   - Departman
   - Pozisyon
   - Seviye (Junior, Mid, Senior, Lead, Manager)
   - Maaş
   - İletişim bilgileri (telefon, email, adres)
   - Giriş tarihi
3. **"Kaydet"** butonuna tıklayın

#### Personel Düzenleme

1. Personel listesinden düzenlemek istediğiniz personele tıklayın
2. Sağ tarafta açılan detay panelinde bilgileri güncelleyin
3. **"Kaydet"** butonuna tıklayın

#### CSV İçe Aktarma

1. **"İçe Aktar"** butonuna tıklayın
2. CSV dosyanızı seçin
3. Sistem otomatik olarak verileri içe aktaracaktır

#### CSV Dışa Aktarma

1. **"Dışa Aktar"** butonuna tıklayın
2. Personel listesi CSV formatında indirilecektir

### Arama ve Filtreleme

#### Arama Çubuğu
- Sol menüdeki arama çubuğunu kullanarak:
  - Personel adı
  - Departman
  - Pozisyon

  bazında arama yapabilirsiniz

#### Filtreler
Üst menüden:
- **Departman Filtresi**: Belirli bir departmanı seçin
- **Şirket Filtresi**: Belirli bir şirketi seçin

## 📦 Modüller

### 1. 👥 Personel Yönetimi

Ana ekran, tüm personel bilgilerini görüntülemenizi ve yönetmenizi sağlar.

**Özellikler:**
- Personel listesi görüntüleme
- Yeni personel ekleme
- Personel bilgilerini düzenleme
- Personel silme
- Detaylı personel profilleri
- İstatistikler (Aktif, İzinli, Pasif personel sayıları)

**Personel Bilgileri:**
- Temel Bilgiler: Ad, Soyad, Şirket, Departman
- Pozisyon Bilgileri: Pozisyon, Seviye, Yetenekler
- İletişim: Telefon, Email, Adres
- Çalışma: Giriş Tarihi, Maaş, Durum

### 2. 📅 İzin Yönetimi

Personel izin taleplerini ve izin haklarını yönetin.

**Özellikler:**
- İzin talebi oluşturma
- İzin taleplerini onaylama/reddetme
- İzin takvimi görüntüleme
- İzin raporları
- Otomatik izin hakkı hesaplama

**İzin Türleri:**
- Yıllık İzin
- Mazeret İzni (Evlenme, Ölüm, Doğum vb.)
- Hastalık İzni
- Ücretsiz İzin
- Diğer İzin Türleri

**İzin Durumları:**
- Beklemede
- Onaylandı
- Reddedildi
- İptal Edildi

**İzin Hesaplamaları:**
- Çalışma süresine göre otomatik yıllık izin hesaplama
- Kalan izin günü takibi
- İzin çakışma kontrolü
- Çalışma günü hesaplama (hafta sonları hariç)

### 3. 💰 Bordro Hesaplama

Detaylı bordro hesaplamaları yapın ve kaydedin.

**Kazanç Kalemleri:**
- Temel Kazanç (Brüt Maaş)
- Yol Parası
- Gıda Yardımı
- Çocuk Yardımı
- Diğer Kazançlar
- Fazla Mesai
- Haftalık Tatil Ücreti
- Genel Tatil Ücreti
- Yıllık İzin Ücreti
- İkramiye
- Prim
- Servis Ücreti
- Temsil/Etiket Gideri
- Kıdem Tazminatı
- İhbar Tazminatı

**Kesinti Kalemleri:**
- SGK Primi (Çalışan Payı)
- İşsizlik Sigortası
- Gelir Vergisi
- Damga Vergisi
- Avans
- Sendika Aidatı
- Diğer Kesintiler

**İndirimler:**
- Asgari Geçim İndirimi (AGİ)
- Engelli İndirimi

**Otomatik Hesaplamalar:**
- Brüt Maaş Hesaplama
- Vergi ve SGK Primleri
- Net Maaş Hesaplama
- İşveren Maliyeti
- Vergi Matrahı

**Bordro İşlemleri:**
- Bordro Oluşturma
- Bordro Düzenleme
- Bordro Silme
- Bordro Görüntüleme
- Excel Formatında İçe/Dışa Aktarma
- PDF Olarak Yazdırma (geliştirme aşamasında)

### 4. 📊 Raporlar

Detaylı personel raporları ve analizler.

**Rapor Türleri:**
- Personel İstatistikleri
- Departman Bazlı Raporlar
- İzin Kullanım Raporları
- Bordro Raporları
- Maliyet Analizleri

### 5. 🔔 Uyarılar & Takvim

Önemli tarihleri takip edin ve hatırlatmalar alın.

**Özellikler:**
- İş Takvimi
- Resmi Tatil Günleri
- Doğum Günü Hatırlatmaları
- İzin Takvimleri
- Bordro Ödeme Tarihleri
- Özel Etkinlikler

**Takvim Yönetimi:**
- Takvim Görünümleri (Ay, Hafta, Gün)
- Etkinlik Ekleme/Düzenleme
- Hatırlatıcılar
- Renk Kodlaması
- Çakışma Kontrolü

### 6. ⚙️ Sistem Ayarları

Uygulamayı ihtiyaçlarınıza göre özelleştirin.

**Ayar Kategorileri:**

#### Genel Ayarlar
- Şirket Bilgileri
- Logo Yükleme
- Dil Seçimi (Türkçe/İngilizce)
- Saat Dilimi
- Para Birimi

#### Bordro Ayarları
- Vergi Oranları
- SGK Primleri
- Asgari Ücret Tanımlaması
- AGİ Oranları
- Otomatik Hesaplama Ayarları

#### İzin Ayarları
- İzin Türleri
- İzin Politikaları
- Onay Süreçleri
- İzin Hakkı Hesaplama Kuralları

#### Bildirim Ayarları
- E-posta Bildirimleri
- Sistem Bildirimleri
- Hatırlatıcı Ayarları

#### Personel Ayarları
- Departman Yönetimi
- Pozisyon Tanımlamaları
- Seviye Tanımlamaları
- Yetkinlik Alanları

## 🛠 Teknolojiler

### Frontend
- **React 18**: Modern UI geliştirme
- **TypeScript**: Tip güvenli kod yazımı
- **Vite**: Hızlı geliştirme ortamı
- **Tailwind CSS**: Utility-first CSS framework
- **Lucide React**: Modern icon kütüphanesi

### Araçlar ve Kütüphaneler
- **ESLint**: Kod kalitesi kontrolü
- **PostCSS**: CSS işleme
- **Autoprefixer**: Tarayıcı uyumluluğu

## 💡 Kullanım İpuçları

### Verimli Çalışma

1. **Klavye Kısayolları**
   - `Ctrl/Cmd + K`: Hızlı arama
   - `ESC`: Açık pencereleri kapatma

2. **Toplu İşlemler**
   - CSV ile toplu personel ekleme
   - Filtrelerle toplu veri görüntüleme

3. **Veri Yedekleme**
   - Düzenli olarak CSV dışa aktarma
   - Önemli bordro verilerini kaydetme

### En İyi Uygulamalar

1. **Personel Yönetimi**
   - Personel bilgilerini düzenli güncelleyin
   - İletişim bilgilerinin doğruluğunu kontrol edin
   - Yetkinlik alanlarını detaylı tanımlayın

2. **İzin Yönetimi**
   - İzin taleplerini zamanında işleme alın
   - İzin politikalarını net tanımlayın
   - Çakışmaları önceden kontrol edin

3. **Bordro İşlemleri**
   - Ay başında bordro hesaplamalarını yapın
   - Yasal değişiklikleri takip edin
   - Bordro kayıtlarını düzenli arşivleyin

## 🔒 Güvenlik

- Tüm veriler tarayıcınızın local storage'ında saklanır
- Hassas bilgiler için encryption kullanılır
- Düzenli veri yedekleme önerilir
- HTTPS kullanımı önerilir (production ortamında)

## 🐛 Sorun Giderme

### Uygulama Açılmıyor

1. Node.js versiyonunu kontrol edin: `node --version`
2. Bağımlılıkları yeniden yükleyin: `npm install`
3. Port 5173'ün kullanımda olup olmadığını kontrol edin
4. Tarayıcı önbelleğini temizleyin (Ctrl+Shift+R)

### Veriler Kayboluyor

1. Tarayıcınızın local storage'ını temizlemeyin
2. Gizli modda çalışmadığınızdan emin olun
3. Düzenli olarak CSV dışa aktarma yapın

### Performans Sorunları

1. Tarayıcınızı güncelleyin
2. Gereksiz browser extension'ları kapatın
3. Çok fazla kayıt varsa filtreleme kullanın

## 📱 Mobil Kullanım

Uygulama responsive tasarıma sahiptir ve mobil cihazlarda da kullanılabilir:

- Tablet ve telefon uyumlu
- Dokunmatik optimizasyon
- Mobil menü navigasyonu

## 🔄 Güncellemeler

### Gelecek Özellikler

- [ ] PDF rapor oluşturma
- [ ] Gelişmiş analitik dashboard
- [ ] E-posta entegrasyonu
- [ ] Çoklu kullanıcı desteği
- [ ] Rol bazlı yetkilendirme
- [ ] API entegrasyonu
- [ ] Bulut senkronizasyonu
- [ ] Mobil uygulama

## 🤝 Katkıda Bulunma

Projeye katkıda bulunmak isterseniz:

1. Fork edin
2. Yeni bir branch oluşturun (`git checkout -b feature/YeniOzellik`)
3. Değişikliklerinizi commit edin (`git commit -am 'Yeni özellik eklendi'`)
4. Branch'inizi push edin (`git push origin feature/YeniOzellik`)
5. Pull Request oluşturun

## 📄 Lisans

Bu proje MIT lisansı altında lisanslanmıştır.

## 📞 Destek

Sorularınız veya önerileriniz için:

- Issue açarak
- Pull request göndererek
- Dokümantasyonu okuyarak

## 🙏 Teşekkürler

Bu projeyi kullandığınız için teşekkür ederiz!

---

**Geliştirici Notu**: Bu uygulama sürekli geliştirilmekte ve iyileştirilmektedir. Geri bildirimleriniz bizim için çok değerlidir.

## 📸 Ekran Görüntüleri

### Ana Sayfa - Personel Yönetimi
Modern ve temiz arayüz ile personel listenizi görüntüleyin ve yönetin.

### İzin Yönetimi
İzin taleplerini takip edin, onaylayın ve takvim üzerinde görselleştirin.

### Bordro Hesaplama
Detaylı bordro hesaplamaları yapın, vergi ve primleri otomatik hesaplayın.

### Takvim Görünümü
Önemli tarihleri ve etkinlikleri tek bir yerden takip edin.

---

**Version**: 1.0.0
**Son Güncelleme**: 2026-01-03
**Geliştirme Durumu**: Aktif

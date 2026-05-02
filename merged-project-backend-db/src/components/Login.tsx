import React, { useState } from 'react';
import { LogIn, Building2, KeyRound, ShieldCheck } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { useAuth } from '../contexts/AuthContext';
import { normalizeRole } from '../auth/roles';

export default function Login() {
  const { signIn } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      const { error } = await signIn(email, password);

      if (error) {
        if (error.message.includes('Invalid login credentials')) {
          setError('E-posta veya şifre hatalı. Lütfen tekrar deneyin.');
        } else {
          setError(error.message);
        }
        setLoading(false);
        return;
      }

      const {
        data: { user },
      } = await supabase.auth.getUser();

      if (user) {
        const { data: profile } = await supabase
          .from('profiles')
          .select('company_id, role')
          .eq('id', user.id)
          .maybeSingle();

        const normalizedRole = normalizeRole(profile?.role);

        if (!profile) {
          setError('Kullanıcı profili bulunamadı. Lütfen yöneticinizle iletişime geçin.');
          await supabase.auth.signOut();
        } else if (!profile.company_id && normalizedRole !== 'superadmin') {
          setError('Bu kullanıcı için şirket ataması bulunamadı. Lütfen yöneticinizle iletişime geçin.');
          await supabase.auth.signOut();
        }
      }
    } catch (err: any) {
      setError(err.message || 'Bir hata oluştu');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="min-h-screen bg-[radial-gradient(circle_at_top_left,_rgba(14,116,144,0.18),_transparent_32%),radial-gradient(circle_at_bottom_right,_rgba(20,184,166,0.18),_transparent_28%),linear-gradient(135deg,_#0f172a,_#1e293b_45%,_#111827)] p-4 md:p-8">
      <div className="mx-auto grid min-h-[calc(100vh-2rem)] max-w-6xl grid-cols-1 gap-6 lg:grid-cols-[1.2fr_0.9fr]">
        <section className="rounded-[32px] border border-white/10 bg-white/8 p-8 text-white shadow-2xl backdrop-blur-xl md:p-10">
          <div className="max-w-2xl">
            <div className="inline-flex items-center gap-3 rounded-full border border-white/15 bg-white/10 px-4 py-2 text-sm text-slate-100">
              <ShieldCheck className="h-4 w-4" />
              Rol bazlı giriş ve şirket ayrımı
            </div>
            <h1 className="mt-6 text-4xl font-semibold tracking-tight md:text-5xl">Humanius giriş merkezi</h1>
            <p className="mt-4 max-w-xl text-sm leading-6 text-slate-200 md:text-base">
              Süper yönetici tüm sistemi yönetir. Şirket yöneticileri sadece kendi şirketlerini görür. Kullanıcılar ise bordro, izin ve görev tanımı onay akışlarına erişir.
            </p>
          </div>

          <div className="mt-8 rounded-3xl border border-cyan-400/20 bg-cyan-400/10 p-5 text-sm text-cyan-50">
            <div className="flex items-center gap-2 font-medium">
              <KeyRound className="h-4 w-4" />
              Parola yönetimi
            </div>
            <p className="mt-2 leading-6 text-cyan-100/90">
              Oturum açan kullanıcı kendi şifresini Sistem Ayarları içinden değiştirebilir. Başka kullanıcıların şifresini merkezi olarak değiştirmek için ayrıca güvenli bir yönetici servisi gerekir.
            </p>
          </div>
        </section>

        <section className="flex items-center justify-center">
          <div className="w-full max-w-md rounded-[32px] bg-white p-8 shadow-2xl md:p-10">
            <div className="text-center mb-8">
              <div className="inline-flex items-center justify-center w-20 h-20 bg-gradient-to-br from-blue-600 via-cyan-600 to-teal-500 rounded-2xl mb-6 shadow-lg">
                <Building2 className="w-10 h-10 text-white" />
              </div>
              <h2 className="text-3xl font-bold text-gray-800 mb-2">Giriş Yap</h2>
              <p className="text-gray-600 text-sm">E-posta ve şifreniz ile devam edin</p>
            </div>

            {error && (
              <div className="mb-5 rounded-2xl border border-red-200 bg-red-50 p-4">
                <p className="text-sm font-medium text-red-800">{error}</p>
              </div>
            )}

            <form onSubmit={handleSubmit} className="space-y-5">
              <div className="space-y-2">
                <label className="block text-sm font-medium text-gray-700">
                  E-posta
                </label>
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="w-full px-4 py-3.5 border-2 border-gray-200 rounded-xl focus:ring-2 focus:ring-cyan-500 focus:border-transparent transition-all bg-white text-sm"
                  placeholder="ornek@sirket.com"
                  required
                />
              </div>

              <div className="space-y-2">
                <label className="block text-sm font-medium text-gray-700">
                  Şifre
                </label>
                <input
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="w-full px-4 py-3.5 border-2 border-gray-200 rounded-xl focus:ring-2 focus:ring-cyan-500 focus:border-transparent transition-all bg-white text-sm"
                  placeholder="••••••••"
                  required
                  minLength={6}
                />
              </div>

              <button
                type="submit"
                disabled={loading}
                className="w-full bg-gradient-to-r from-slate-900 via-cyan-700 to-teal-600 text-white py-4 rounded-xl font-semibold hover:shadow-xl transition-all disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2 text-base"
              >
                {loading ? (
                  <div className="flex items-center gap-2">
                    <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
                    Giriş yapılıyor...
                  </div>
                ) : (
                  <>
                    <LogIn className="w-5 h-5" />
                    Giriş Yap
                  </>
                )}
              </button>
            </form>

            <div className="mt-6 rounded-2xl border border-slate-200 bg-slate-50 p-4 text-xs text-slate-600">
              <p className="font-semibold text-slate-700">Yetki modeli</p>
              <p className="mt-2">Süper yönetici tüm yapıyı yönetir. Şirket yöneticisi yalnız kendi şirketini görür. Kullanıcı rolü ise kendi şirketine ait bordro, izin ve görev tanımı akışlarında çalışır.</p>
              <p className="mt-2">Profil rolü giriş sonrası otomatik okunur ve menüler yetkiye göre filtrelenir.</p>
            </div>
          </div>
        </section>
      </div>
    </div>
  );
}

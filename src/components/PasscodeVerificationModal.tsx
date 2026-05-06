import React, { useState, useEffect } from 'react';
import { X, Lock, Shield, CheckCircle, XCircle, User, KeyRound, ClipboardCheck, AlertTriangle } from 'lucide-react';

export interface PasscodeVerificationModalProps {
  isOpen: boolean;
  onClose: () => void;
  /** Passcode doğrulama + işlemi gerçekleştiren callback. true dönerse başarılı. */
  onVerify: (passcode: string) => Promise<boolean>;
  employeeName: string;
  /** Modal başlığı. Varsayılan: "Güvenli Belge Onayı" */
  title?: string;
  /** Onay butonu etiketi. actionType'dan türetilir. */
  actionLabel?: string;
  /** İşlem açıklaması (3. adımda gösterilir) */
  actionDescription?: string;
  /** Buton rengi. actionType'dan türetilir. */
  actionColor?: 'green' | 'blue' | 'red' | 'indigo';
  /** TC Kimlik No (son 4 hane doğrulaması için, opsiyonel) */
  tcNo?: string;
  /** Geriye dönük uyumluluk */
  actionType?: 'approve' | 'reject';
}

const COLOR_MAP = {
  green:  { bg: 'bg-green-50',  border: 'border-green-200',  text: 'text-green-800',  btn: 'bg-green-600 hover:bg-green-700',  icon: 'text-green-600'  },
  red:    { bg: 'bg-red-50',    border: 'border-red-200',    text: 'text-red-800',    btn: 'bg-red-600 hover:bg-red-700',      icon: 'text-red-600'    },
  blue:   { bg: 'bg-blue-50',   border: 'border-blue-200',   text: 'text-blue-800',   btn: 'bg-blue-600 hover:bg-blue-700',    icon: 'text-blue-600'   },
  indigo: { bg: 'bg-indigo-50', border: 'border-indigo-200', text: 'text-indigo-800', btn: 'bg-indigo-600 hover:bg-indigo-700',icon: 'text-indigo-600' },
};

const LOCKOUT_SECONDS = 30;
const MAX_ATTEMPTS = 3;

const PasscodeVerificationModal: React.FC<PasscodeVerificationModalProps> = ({
  isOpen,
  onClose,
  onVerify,
  employeeName,
  title,
  actionLabel,
  actionDescription,
  actionColor,
  tcNo,
  actionType,
}) => {
  /* ── Türetilmiş değerler ── */
  const resolvedColor: 'green' | 'blue' | 'red' | 'indigo' =
    actionColor ??
    (actionType === 'approve' ? 'green' : actionType === 'reject' ? 'red' : 'indigo');
  const resolvedLabel =
    actionLabel ??
    (actionType === 'approve' ? 'Bordroyu Onayla' : actionType === 'reject' ? 'Bordroyu Reddet' : 'Onayla');
  const resolvedTitle = title ?? 'Güvenli Belge Onayı';
  const C = COLOR_MAP[resolvedColor];

  /* ── State ── */
  const [step, setStep]         = useState<1 | 2 | 3>(tcNo ? 1 : 2);
  const [tcInput, setTcInput]   = useState('');
  const [tcError, setTcError]   = useState('');
  const [passcode, setPasscode] = useState('');
  const [passError, setPassError] = useState('');
  const [attempts, setAttempts] = useState(0);
  const [lockoutUntil, setLockoutUntil] = useState<number | null>(null);
  const [remaining, setRemaining] = useState(0);
  const [loading, setLoading]   = useState(false);
  const [confirmed, setConfirmed] = useState(false);
  const [confirmError, setConfirmError] = useState('');

  /* ── Kilitleme geri sayımı ── */
  useEffect(() => {
    if (!lockoutUntil) return;
    const id = setInterval(() => {
      const left = Math.ceil((lockoutUntil - Date.now()) / 1000);
      if (left <= 0) { setLockoutUntil(null); setRemaining(0); clearInterval(id); }
      else setRemaining(left);
    }, 500);
    return () => clearInterval(id);
  }, [lockoutUntil]);

  /* ── Sıfırla ── */
  useEffect(() => {
    if (!isOpen) return;
    setStep(tcNo ? 1 : 2);
    setTcInput(''); setTcError('');
    setPasscode(''); setPassError('');
    setAttempts(0); setLockoutUntil(null); setRemaining(0);
    setLoading(false); setConfirmed(false); setConfirmError('');
  }, [isOpen, tcNo]);

  if (!isOpen) return null;

  const isLockedOut = lockoutUntil !== null && Date.now() < lockoutUntil;

  /* ── Adım 1: TC doğrulama ── */
  const handleTcNext = () => {
    if (!tcNo) { setStep(2); return; }
    const last4 = tcNo.replace(/\D/g, '').slice(-4);
    if (tcInput.trim() !== last4) {
      setTcError('TC kimlik numaranızın son 4 hanesi eşleşmiyor. Lütfen tekrar deneyin.');
      return;
    }
    setTcError('');
    setStep(2);
  };

  /* ── Adım 2: Şifre doğrulama (step 3'e geçiş için) ── */
  const handlePassNext = () => {
    if (isLockedOut) return;
    if (!passcode.trim()) { setPassError('Lütfen onay şifrenizi girin.'); return; }
    setPassError('');
    setStep(3);
  };

  /* ── Adım 3: Onay (onVerify çağrısı) ── */
  const handleConfirm = async () => {
    if (!confirmed) { setConfirmError('Devam etmek için işlemi onaylamanız gerekiyor.'); return; }
    setLoading(true);
    setConfirmError('');
    try {
      const ok = await onVerify(passcode);
      if (ok) {
        onClose();
      } else {
        const newAttempts = attempts + 1;
        setAttempts(newAttempts);
        if (newAttempts >= MAX_ATTEMPTS) {
          setLockoutUntil(Date.now() + LOCKOUT_SECONDS * 1000);
          setRemaining(LOCKOUT_SECONDS);
          setStep(2);
          setPasscode('');
          setConfirmed(false);
          setConfirmError('');
          setPassError(`${MAX_ATTEMPTS} başarısız deneme. ${LOCKOUT_SECONDS} saniye beklemeniz gerekiyor.`);
        } else {
          setStep(2);
          setPasscode('');
          setConfirmed(false);
          setPassError(`Geçersiz şifre. (${newAttempts}/${MAX_ATTEMPTS} deneme)`);
        }
      }
    } catch (err) {
      setConfirmError(err instanceof Error ? err.message : 'Beklenmeyen bir hata oluştu.');
    } finally {
      setLoading(false);
    }
  };

  const handleClose = () => {
    onClose();
  };

  /* ── Adım göstergesi ── */
  const STEPS = tcNo
    ? [
        { n: 1, icon: User,          label: 'Kimlik'  },
        { n: 2, icon: KeyRound,       label: 'Şifre'   },
        { n: 3, icon: ClipboardCheck, label: 'Onay'    },
      ]
    : [
        { n: 2, icon: KeyRound,       label: 'Kimlik & Şifre' },
        { n: 3, icon: ClipboardCheck, label: 'Onay'           },
      ];

  const stepIndex = STEPS.findIndex(s => s.n === step);

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md flex flex-col overflow-hidden">

        {/* ── Başlık ── */}
        <div className={`flex items-center justify-between px-6 py-4 border-b border-gray-200 ${C.bg}`}>
          <div className="flex items-center gap-3">
            <Shield className={`w-6 h-6 ${C.icon}`} />
            <div>
              <h2 className={`text-lg font-bold ${C.text}`}>{resolvedTitle}</h2>
              <p className="text-xs text-gray-500">{employeeName}</p>
            </div>
          </div>
          <button onClick={handleClose} className="text-gray-400 hover:text-gray-600 transition-colors">
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* ── Adım göstergesi ── */}
        <div className="flex items-center justify-center gap-3 px-6 pt-5 pb-1">
          {STEPS.map((s, i) => {
            const past    = s.n < step;
            const current = s.n === step;
            return (
              <React.Fragment key={s.n}>
                {i > 0 && (
                  <div className={`flex-1 h-0.5 rounded ${past ? C.btn.split(' ')[0] : 'bg-gray-200'}`} />
                )}
                <div className="flex flex-col items-center gap-1">
                  <div className={`w-9 h-9 rounded-full flex items-center justify-center text-sm font-bold border-2 transition-all ${
                    past    ? `${C.btn.split(' ')[0]} border-transparent text-white` :
                    current ? `bg-white ${C.border} ${C.text}` :
                              'bg-gray-100 border-gray-200 text-gray-400'
                  }`}>
                    {past ? <CheckCircle className="w-5 h-5" /> : <s.icon className="w-4 h-4" />}
                  </div>
                  <span className={`text-xs font-medium ${current ? C.text : 'text-gray-400'}`}>{s.label}</span>
                </div>
              </React.Fragment>
            );
          })}
        </div>

        {/* ── İçerik ── */}
        <div className="px-6 py-5 space-y-4">

          {/* Adım 1: TC Kimlik */}
          {step === 1 && (
            <>
              <div className={`rounded-xl p-4 ${C.bg} border ${C.border}`}>
                <p className={`text-sm ${C.text}`}>
                  <strong>{employeeName}</strong> için <strong>{resolvedLabel}</strong> işlemi başlatılıyor.
                </p>
                {actionDescription && (
                  <p className="text-xs text-gray-600 mt-1">{actionDescription}</p>
                )}
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1.5">
                  TC Kimlik Numaranızın son 4 hanesi
                </label>
                <div className="relative">
                  <User className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                  <input
                    type="text"
                    inputMode="numeric"
                    maxLength={4}
                    value={tcInput}
                    onChange={(e) => { setTcInput(e.target.value.replace(/\D/g, '')); setTcError(''); }}
                    onKeyDown={(e) => e.key === 'Enter' && handleTcNext()}
                    placeholder="Son 4 hane"
                    className="w-full pl-9 pr-4 py-2.5 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none text-sm tracking-widest"
                    autoFocus
                  />
                </div>
                {tcError && (
                  <p className="mt-1.5 text-xs text-red-600 flex items-center gap-1">
                    <AlertTriangle className="w-3.5 h-3.5" /> {tcError}
                  </p>
                )}
              </div>
              <div className="flex gap-3 pt-1">
                <button onClick={handleClose} className="flex-1 px-4 py-2.5 bg-gray-100 hover:bg-gray-200 text-gray-700 rounded-xl text-sm font-medium">İptal</button>
                <button onClick={handleTcNext} className={`flex-1 px-4 py-2.5 text-white rounded-xl text-sm font-medium ${C.btn}`}>
                  Devam Et →
                </button>
              </div>
            </>
          )}

          {/* Adım 2: Onay şifresi */}
          {step === 2 && (
            <>
              <div className={`rounded-xl p-4 ${C.bg} border ${C.border}`}>
                <p className={`text-sm ${C.text}`}>
                  <strong>{employeeName}</strong> için <strong>{resolvedLabel}</strong> işlemi.
                </p>
                {actionDescription && (
                  <p className="text-xs text-gray-600 mt-1">{actionDescription}</p>
                )}
                <p className="text-xs text-gray-500 mt-1.5">Onay şifrenizi girerek bir sonraki adıma geçin.</p>
              </div>

              {isLockedOut ? (
                <div className="flex items-center gap-3 bg-red-50 border border-red-200 rounded-xl p-4">
                  <AlertTriangle className="w-5 h-5 text-red-500 shrink-0" />
                  <p className="text-sm text-red-700">Çok fazla hatalı deneme. <strong>{remaining} saniye</strong> sonra tekrar deneyin.</p>
                </div>
              ) : (
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1.5">Onay Şifresi</label>
                  <div className="relative">
                    <Lock className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                    <input
                      type="password"
                      value={passcode}
                      onChange={(e) => { setPasscode(e.target.value); setPassError(''); }}
                      onKeyDown={(e) => e.key === 'Enter' && handlePassNext()}
                      placeholder="Şifrenizi girin"
                      className="w-full pl-9 pr-4 py-2.5 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none text-sm"
                      autoFocus
                    />
                  </div>
                  {passError && (
                    <p className="mt-1.5 text-xs text-red-600 flex items-center gap-1">
                      <XCircle className="w-3.5 h-3.5" /> {passError}
                    </p>
                  )}
                </div>
              )}

              <div className="flex gap-3 pt-1">
                <button onClick={handleClose} className="flex-1 px-4 py-2.5 bg-gray-100 hover:bg-gray-200 text-gray-700 rounded-xl text-sm font-medium">İptal</button>
                <button
                  onClick={handlePassNext}
                  disabled={isLockedOut || !passcode.trim()}
                  className={`flex-1 px-4 py-2.5 text-white rounded-xl text-sm font-medium disabled:opacity-50 ${C.btn}`}
                >
                  Devam Et →
                </button>
              </div>
            </>
          )}

          {/* Adım 3: İşlem özeti & onay */}
          {step === 3 && (
            <>
              <div className={`rounded-xl p-4 ${C.bg} border ${C.border}`}>
                <p className={`text-sm font-semibold ${C.text} mb-1`}>İşlem Özeti</p>
                <p className={`text-sm ${C.text}`}>
                  <strong>{employeeName}</strong> için <strong>{resolvedLabel}</strong> işlemi gerçekleştirilecek.
                </p>
                {actionDescription && (
                  <p className="text-xs text-gray-600 mt-1">{actionDescription}</p>
                )}
                <p className="text-xs text-gray-500 mt-2">
                  Tarih: {new Date().toLocaleString('tr-TR')}
                </p>
              </div>

              <label className="flex items-start gap-3 cursor-pointer select-none">
                <input
                  type="checkbox"
                  checked={confirmed}
                  onChange={(e) => { setConfirmed(e.target.checked); setConfirmError(''); }}
                  className="mt-0.5 w-4 h-4 rounded accent-indigo-600 cursor-pointer"
                />
                <span className="text-sm text-gray-700">
                  Yukarıdaki işlemi gerçekleştirmek istediğimi onaylıyorum. Bu işlemin kayıt altına alınacağını kabul ediyorum.
                </span>
              </label>

              {confirmError && (
                <p className="text-xs text-red-600 flex items-center gap-1">
                  <AlertTriangle className="w-3.5 h-3.5" /> {confirmError}
                </p>
              )}

              <div className="flex gap-3 pt-1">
                <button onClick={() => setStep(2)} disabled={loading} className="flex-1 px-4 py-2.5 bg-gray-100 hover:bg-gray-200 text-gray-700 rounded-xl text-sm font-medium">← Geri</button>
                <button
                  onClick={handleConfirm}
                  disabled={loading}
                  className={`flex-1 px-4 py-2.5 text-white rounded-xl text-sm font-medium disabled:opacity-50 ${C.btn}`}
                >
                  {loading ? (
                    <span className="flex items-center justify-center gap-2">
                      <span className="animate-spin rounded-full h-4 w-4 border-b-2 border-white" />
                      İşleniyor...
                    </span>
                  ) : resolvedLabel}
                </button>
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  );
};

export default PasscodeVerificationModal;

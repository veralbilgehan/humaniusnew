import React, { useState } from 'react';
import { X, Lock, CheckCircle, XCircle } from 'lucide-react';

interface PasscodeVerificationModalProps {
  isOpen: boolean;
  onClose: () => void;
  onVerify: (passcode: string) => Promise<boolean>;
  employeeName: string;
  actionType: 'approve' | 'reject';
}

const PasscodeVerificationModal: React.FC<PasscodeVerificationModalProps> = ({
  isOpen,
  onClose,
  onVerify,
  employeeName,
  actionType
}) => {
  const [passcode, setPasscode] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!passcode.trim()) {
      setError('Lütfen onay şifrenizi girin');
      return;
    }

    setLoading(true);
    setError('');

    try {
      const isValid = await onVerify(passcode);

      if (isValid) {
        setPasscode('');
        onClose();
      } else {
        setError('Geçersiz şifre. Lütfen tekrar deneyin.');
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Bir hata oluştu. Lütfen tekrar deneyin.');
    } finally {
      setLoading(false);
    }
  };

  const handleClose = () => {
    setPasscode('');
    setError('');
    onClose();
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-2xl shadow-2xl max-w-md w-full">
        <div className={`flex items-center justify-between p-6 border-b border-gray-200 ${
          actionType === 'approve' ? 'bg-green-50' : 'bg-red-50'
        }`}>
          <div className="flex items-center gap-3">
            {actionType === 'approve' ? (
              <CheckCircle className="w-6 h-6 text-green-600" />
            ) : (
              <XCircle className="w-6 h-6 text-red-600" />
            )}
            <h2 className={`text-xl font-bold ${
              actionType === 'approve' ? 'text-green-800' : 'text-red-800'
            }`}>
              {actionType === 'approve' ? 'Bordro Onayı' : 'Bordro Reddi'}
            </h2>
          </div>
          <button
            onClick={handleClose}
            className="text-gray-400 hover:text-gray-600 transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-6">
          <div className="bg-blue-50 border border-blue-200 rounded-xl p-4">
            <p className="text-sm text-blue-800">
              <strong>{employeeName}</strong> için bordro{' '}
              {actionType === 'approve' ? 'onaylamak' : 'reddetmek'} üzeresiniz.
            </p>
            <p className="text-xs text-blue-600 mt-2">
              Devam etmek için lütfen size atanan onay şifresini girin.
            </p>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Onay Şifresi
            </label>
            <div className="relative">
              <Lock className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
              <input
                type="password"
                value={passcode}
                onChange={(e) => {
                  setPasscode(e.target.value);
                  setError('');
                }}
                placeholder="Şifrenizi girin"
                className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none"
                disabled={loading}
                autoFocus
              />
            </div>
            {error && (
              <p className="mt-2 text-sm text-red-600 flex items-center gap-1">
                <XCircle className="w-4 h-4" />
                {error}
              </p>
            )}
          </div>

          <div className="flex gap-3">
            <button
              type="button"
              onClick={handleClose}
              className="flex-1 px-4 py-3 bg-gray-100 hover:bg-gray-200 text-gray-700 rounded-xl font-medium transition-colors"
              disabled={loading}
            >
              İptal
            </button>
            <button
              type="submit"
              disabled={loading || !passcode.trim()}
              className={`flex-1 px-4 py-3 text-white rounded-xl font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed ${
                actionType === 'approve'
                  ? 'bg-green-600 hover:bg-green-700'
                  : 'bg-red-600 hover:bg-red-700'
              }`}
            >
              {loading ? (
                <span className="flex items-center justify-center gap-2">
                  <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
                  İşleniyor...
                </span>
              ) : (
                actionType === 'approve' ? 'Onayla' : 'Reddet'
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default PasscodeVerificationModal;

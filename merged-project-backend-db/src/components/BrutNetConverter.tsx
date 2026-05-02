import React, { useState, useEffect } from 'react';
import { ArrowRightLeft } from 'lucide-react';
import { calculateBordro, nettenBruteHesapla, formatNumber } from '../utils/bordroCalculations';
import { useLanguage } from '../contexts/LanguageContext';

const BrutNetConverter: React.FC = () => {
  const { t } = useLanguage();
  const [mode, setMode] = useState<'brutToNet' | 'netToBrut'>('brutToNet');
  const [inputValue, setInputValue] = useState<number>(0);
  const [result, setResult] = useState<number>(0);
  const [details, setDetails] = useState<any>(null);

  useEffect(() => {
    if (inputValue <= 0) {
      setResult(0);
      setDetails(null);
      return;
    }

    if (mode === 'brutToNet') {
      const bordro = calculateBordro({
        temelKazanc: inputValue,
        medeniDurum: 'bekar',
        cocukSayisi: 0,
        id: 'temp',
        employeeId: 'temp',
        employeeName: 'temp',
        period: '2024-01',
        sicilNo: 'temp',
        tcNo: 'temp',
        yolParasi: 0,
        gidaYardimi: 0,
        cocukYardimi: 0,
        digerKazanclar: 0,
        avans: 0,
        sendikaidat: 0,
        digerKesintiler: 0,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      }, undefined, 1, 0, 0); // Ocak ayı, önceki ay yok
      setResult(bordro.netMaas);
      setDetails(bordro);
    } else {
      const brutMaas = nettenBruteHesapla(inputValue, 'bekar', 0, false);
      setResult(brutMaas);

      const bordro = calculateBordro({
        temelKazanc: brutMaas,
        medeniDurum: 'bekar',
        cocukSayisi: 0,
        id: 'temp',
        employeeId: 'temp',
        employeeName: 'temp',
        period: '2024-01',
        sicilNo: 'temp',
        tcNo: 'temp',
        yolParasi: 0,
        gidaYardimi: 0,
        cocukYardimi: 0,
        digerKazanclar: 0,
        avans: 0,
        sendikaidat: 0,
        digerKesintiler: 0,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      }, undefined, 1, 0, 0); // Ocak ayı, önceki ay yok
      setDetails(bordro);
    }
  }, [inputValue, mode]);

  const toggleMode = () => {
    setMode(prev => prev === 'brutToNet' ? 'netToBrut' : 'brutToNet');
    setInputValue(0);
    setResult(0);
    setDetails(null);
  };

  return (
    <div className="space-y-6">
      <div className="bg-white border border-gray-200 rounded-2xl shadow-sm">
        <div className="flex items-center justify-between p-6 border-b border-gray-200">
          <div className="flex items-center gap-3">
            <ArrowRightLeft className="w-6 h-6 text-blue-600" />
            <h2 className="text-xl font-bold text-gray-800">{t('bordro.converter')}</h2>
          </div>
          <button
            onClick={toggleMode}
            className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-xl font-bold hover:bg-blue-700 transition-colors"
          >
            <ArrowRightLeft className="w-4 h-4" />
            {mode === 'brutToNet' ? t('bordro.switchToNetToBrut') : t('bordro.switchToBrutToNet')}
          </button>
        </div>

      <div className="p-6">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          <div className="space-y-6">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  {mode === 'brutToNet' ? t('bordro.grossSalary') : t('bordro.netSalary')}
                </label>
                <input
                  type="number"
                  value={inputValue || ''}
                  onChange={(e) => setInputValue(parseFloat(e.target.value) || 0)}
                  className="w-full bg-white border border-gray-200 text-gray-800 rounded-xl px-4 py-3 text-lg outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100"
                  placeholder="0.00"
                  step="0.01"
                />
              </div>

              <div className="bg-blue-50 border border-blue-200 rounded-xl p-4 flex flex-col justify-center">
                <div className="text-sm font-medium text-gray-700 mb-2">
                  {mode === 'brutToNet' ? t('bordro.netSalary') : t('bordro.grossSalary')}
                </div>
                <div className="text-3xl font-bold text-blue-700">
                  {formatNumber(result)} ₺
                </div>
              </div>
            </div>
          </div>

          {details && (
            <div className="bg-gray-50 border border-gray-200 rounded-xl p-6">
              <h3 className="text-lg font-semibold text-gray-800 mb-4">{t('bordro.calculationDetails')}</h3>

              <div className="space-y-4">
                <div className="border-b border-gray-200 pb-3">
                  <div className="flex justify-between text-sm mb-2">
                    <span className="text-gray-500">{t('bordro.grossSalary')}</span>
                    <span className="text-gray-800 font-semibold">{formatNumber(details.toplamKazanc)} ₺</span>
                  </div>
                </div>

                <div className="border-b border-gray-200 pb-3">
                  <h4 className="text-sm font-medium text-gray-500 mb-2">{t('bordro.deductions')}</h4>
                  <div className="space-y-1 text-sm">
                    <div className="flex justify-between">
                      <span className="text-gray-500">{t('bordro.sgkEmployee')}</span>
                      <span className="text-gray-800">{formatNumber(details.sgkIsciPayi)} ₺</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-500">{t('bordro.unemploymentInsurance')}</span>
                      <span className="text-gray-800">{formatNumber(details.issizlikSigortasi)} ₺</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-500">{t('bordro.incomeTax')}</span>
                      <span className="text-gray-800">{formatNumber(details.gelirVergisi)} ₺</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-500">{t('bordro.stampTax')}</span>
                      <span className="text-gray-800">{formatNumber(details.damgaVergisi)} ₺</span>
                    </div>
                  </div>
                </div>

                <div className="bg-blue-50 border border-blue-200 rounded-lg p-3">
                  <div className="flex justify-between items-center">
                    <span className="text-sm font-semibold text-blue-700">{t('bordro.totalDeduction')}</span>
                    <span className="text-lg font-bold text-blue-700">{formatNumber(details.toplamKesinti)} ₺</span>
                  </div>
                </div>

                <div className="bg-green-50 border border-green-200 rounded-lg p-3">
                  <div className="flex justify-between items-center">
                    <span className="text-sm font-semibold text-green-700">{t('bordro.netSalary')}</span>
                    <span className="text-lg font-bold text-green-700">{formatNumber(details.netMaas)} ₺</span>
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>
      </div>
    </div>
  );
};

export default BrutNetConverter;

import React, { useState } from 'react';
import { Globe, Loader2, Copy, ExternalLink, AlertTriangle } from 'lucide-react';
import { crawlWebsite, type CrawledPage } from '../services/apifyCrawlService';

const IcerikCek: React.FC = () => {
  const [url, setUrl] = useState('');
  const [maxPages, setMaxPages] = useState(1);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [pages, setPages] = useState<CrawledPage[]>([]);
  const [copiedIndex, setCopiedIndex] = useState<number | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setPages([]);
    setLoading(true);
    try {
      const result = await crawlWebsite({
        url: url.trim(),
        maxPages,
        maxDepth: maxPages > 1 ? 1 : 0,
      });
      setPages(result);
      if (result.length === 0) setError('Sayfadan içerik alınamadı.');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'İçerik çekilemedi.');
    } finally {
      setLoading(false);
    }
  };

  const handleCopy = async (text: string, index: number) => {
    try {
      await navigator.clipboard.writeText(text);
      setCopiedIndex(index);
      setTimeout(() => setCopiedIndex(null), 1500);
    } catch {
      // ignore clipboard failures
    }
  };

  return (
    <div className="space-y-6">
      <div className="bg-white border border-gray-200 rounded-xl p-6">
        <div className="flex items-center gap-2 mb-1">
          <Globe className="w-5 h-5 text-blue-600" />
          <h2 className="text-lg font-semibold text-gray-900">URL'den İçerik Çek</h2>
        </div>
        <p className="text-sm text-gray-500 mb-4">
          Verilen sayfanın metnini Apify Website Content Crawler ile çeker. İçerik sayfada ne yazıyorsa odur; yorum veya ekleme yapılmaz.
        </p>

        <form onSubmit={handleSubmit} className="flex flex-col md:flex-row gap-3">
          <input
            type="url"
            required
            value={url}
            onChange={(e) => setUrl(e.target.value)}
            placeholder="https://ornek.com/sayfa"
            className="flex-1 px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
          <select
            value={maxPages}
            onChange={(e) => setMaxPages(Number(e.target.value))}
            className="px-3 py-2 border border-gray-300 rounded-lg text-sm"
            title="Taranacak en fazla sayfa"
          >
            {[1, 3, 5, 10, 20].map((n) => (
              <option key={n} value={n}>{n === 1 ? 'Sadece bu sayfa' : `En fazla ${n} sayfa`}</option>
            ))}
          </select>
          <button
            type="submit"
            disabled={loading}
            className="inline-flex items-center justify-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg text-sm font-medium hover:bg-blue-700 disabled:opacity-60"
          >
            {loading && <Loader2 className="w-4 h-4 animate-spin" />}
            {loading ? 'Çekiliyor…' : 'İçeriği Çek'}
          </button>
        </form>
        {loading && (
          <p className="text-xs text-gray-500 mt-3">Tarama sayfa sayısına göre birkaç dakika sürebilir.</p>
        )}
      </div>

      {error && (
        <div className="flex items-start gap-2 bg-red-50 border border-red-200 text-red-700 rounded-xl p-4 text-sm">
          <AlertTriangle className="w-4 h-4 mt-0.5 shrink-0" />
          <span>{error}</span>
        </div>
      )}

      {pages.map((page, index) => (
        <div key={`${page.url}-${index}`} className="bg-white border border-gray-200 rounded-xl p-6">
          <div className="flex items-start justify-between gap-3 mb-3">
            <div className="min-w-0">
              <h3 className="font-semibold text-gray-900 truncate">{page.title || 'Başlıksız sayfa'}</h3>
              {page.url && (
                <a
                  href={page.url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-1 text-xs text-blue-600 hover:underline break-all"
                >
                  {page.url}
                  <ExternalLink className="w-3 h-3 shrink-0" />
                </a>
              )}
            </div>
            <button
              onClick={() => handleCopy(page.text, index)}
              className="inline-flex items-center gap-1 px-3 py-1.5 border border-gray-300 rounded-lg text-xs text-gray-700 hover:bg-gray-50 shrink-0"
            >
              <Copy className="w-3.5 h-3.5" />
              {copiedIndex === index ? 'Kopyalandı' : 'Kopyala'}
            </button>
          </div>
          <pre className="whitespace-pre-wrap text-sm text-gray-700 bg-gray-50 rounded-lg p-4 max-h-96 overflow-y-auto font-sans">
            {page.text || '(Metin bulunamadı)'}
          </pre>
        </div>
      ))}
    </div>
  );
};

export default IcerikCek;

import React, { useEffect, useState, useRef, useCallback } from 'react';
import { X, BookOpen, ExternalLink } from 'lucide-react';

// ─── Types ────────────────────────────────────────────────────────────────────

interface GuideEntry {
  sectionId: string;
  sectionTitle: string;
  cardTitle: string;
  subTitle: string;
  headers: string[];
  rows: string[][];
}

interface MatchResult {
  entry: GuideEntry;
  matchingRowIndices: number[];
}

interface ModalState {
  visible: boolean;
  x: number;
  y: number;
  labelText: string;
  match: MatchResult | null;
}

// ─── Parse guide HTML into structured entries ─────────────────────────────────

function parseGuide(doc: Document): GuideEntry[] {
  const entries: GuideEntry[] = [];

  doc.querySelectorAll('section').forEach((section) => {
    const sectionId = section.id;
    const sectionTitle = section.querySelector('h2')?.textContent?.trim() ?? '';

    section.querySelectorAll('.card').forEach((card) => {
      const cardTitle = card.querySelector('.card-title')?.textContent?.trim() ?? '';
      let currentSubTitle = '';

      Array.from(card.children).forEach((child) => {
        const tag = child.tagName;

        if (tag === 'H4') {
          currentSubTitle = child.textContent?.trim() ?? '';
          return;
        }

        if (tag === 'TABLE') {
          const headers = Array.from(child.querySelectorAll('thead th')).map(
            (th) => th.textContent?.trim() ?? ''
          );
          const rows = Array.from(child.querySelectorAll('tbody tr')).map((tr) =>
            Array.from(tr.querySelectorAll('td')).map((td) => td.textContent?.trim() ?? '')
          );
          if (rows.length > 0) {
            entries.push({ sectionId, sectionTitle, cardTitle, subTitle: currentSubTitle, headers, rows });
          }
          return;
        }

        // .field-list divs (display fields without tables)
        if ((child as HTMLElement).classList?.contains('field-list')) {
          const rows = Array.from(child.querySelectorAll('.field-item')).map((item) => [
            item.querySelector('.field-label')?.textContent?.trim() ?? '',
            item.querySelector('.field-type')?.textContent?.trim() ?? '',
          ]);
          if (rows.length > 0) {
            entries.push({
              sectionId,
              sectionTitle,
              cardTitle,
              subTitle: currentSubTitle,
              headers: ['Alan', 'Tür'],
              rows,
            });
          }
        }
      });
    });
  });

  return entries;
}

// ─── Extract label text from a DOM element ────────────────────────────────────

function getLabelText(el: HTMLElement): string {
  if (el.tagName === 'LABEL') {
    const clone = el.cloneNode(true) as HTMLElement;
    clone.querySelectorAll('input, select, textarea').forEach((n) => n.remove());
    return clone.textContent?.trim() ?? '';
  }

  const ariaLabel = el.getAttribute('aria-label');
  if (ariaLabel) return ariaLabel;

  const placeholder = el.getAttribute('placeholder');
  if (placeholder && placeholder.length < 60) return placeholder;

  const id = el.id;
  if (id) {
    const assoc = document.querySelector(`label[for="${id}"]`);
    if (assoc) return assoc.textContent?.trim() ?? '';
  }

  const parentLabel = el.closest('label');
  if (parentLabel) {
    const clone = parentLabel.cloneNode(true) as HTMLElement;
    clone.querySelectorAll('input, select, textarea').forEach((n) => n.remove());
    return clone.textContent?.trim() ?? '';
  }

  // Walk up the DOM looking for a sibling label or short text element
  let parent = el.parentElement;
  for (let i = 0; i < 6 && parent; i++) {
    for (const child of Array.from(parent.children)) {
      if (child === el || child.contains(el)) continue;
      if (['LABEL', 'P', 'SPAN', 'DIV'].includes(child.tagName)) {
        const text = child.textContent?.trim();
        if (text && text.length > 0 && text.length < 70 && !text.includes('\n')) return text;
      }
    }
    parent = parent.parentElement;
  }

  return '';
}

// ─── Search guide entries for matching label ───────────────────────────────────

function searchGuide(entries: GuideEntry[], labelText: string): MatchResult | null {
  const search = labelText.toLowerCase().trim();
  if (!search || search.length < 2) return null;

  let bestEntry: GuideEntry | null = null;
  let bestIndices: number[] = [];
  let bestScore = 0;

  for (const entry of entries) {
    const matchingIndices: number[] = [];
    let entryScore = 0;

    entry.rows.forEach((row, idx) => {
      const cellText = (row[0] ?? '').toLowerCase().trim();
      if (!cellText) return;

      if (cellText === search) {
        matchingIndices.push(idx);
        entryScore = Math.max(entryScore, 4);
      } else if (cellText.startsWith(search) || search.startsWith(cellText)) {
        matchingIndices.push(idx);
        entryScore = Math.max(entryScore, 3);
      } else if (cellText.includes(search)) {
        matchingIndices.push(idx);
        entryScore = Math.max(entryScore, 2);
      } else if (search.includes(cellText) && cellText.length > 3) {
        matchingIndices.push(idx);
        entryScore = Math.max(entryScore, 1);
      }
    });

    if (entryScore > bestScore) {
      bestScore = entryScore;
      bestEntry = entry;
      bestIndices = matchingIndices;
    }
  }

  if (!bestEntry || bestScore === 0) return null;
  return { entry: bestEntry, matchingRowIndices: bestIndices };
}

// ─── Component ────────────────────────────────────────────────────────────────

interface Props {
  children: React.ReactNode;
  onNavigate?: (view: string) => void;
}


const GuideContextMenu: React.FC<Props> = ({ children, onNavigate }) => {
  const [modal, setModal] = useState<ModalState>({
    visible: false, x: 0, y: 0, labelText: '', match: null,
  });
  const [guideOpen, setGuideOpen] = useState(false);
  const [guideSectionId, setGuideSectionId] = useState<string>('');
  const entriesRef = useRef<GuideEntry[]>([]);
  const modalRef = useRef<HTMLDivElement>(null);

  // Fetch and parse the guide once
  useEffect(() => {
    fetch('/kullanim-kilavuzu.html')
      .then((r) => r.text())
      .then((html) => {
        const parser = new DOMParser();
        const doc = parser.parseFromString(html, 'text/html');
        entriesRef.current = parseGuide(doc);
      })
      .catch(() => {});
  }, []);

  const closeModal = useCallback(() => setModal((m) => ({ ...m, visible: false })), []);
  const closeGuide = useCallback(() => { setGuideOpen(false); setGuideSectionId(''); }, []);

  const openGuideAtSection = useCallback((sectionId: string) => {
    setGuideSectionId(sectionId);
    setGuideOpen(true);
    setModal((m) => ({ ...m, visible: false }));
  }, []);

  // Global contextmenu + ESC
  useEffect(() => {
    const onContextMenu = (e: MouseEvent) => {
      const target = e.target as HTMLElement;
      const el = target.closest('input, select, textarea, label') as HTMLElement | null;

      e.preventDefault();
      e.stopPropagation();

      if (el) {
        // Form elemanı — bağlamsal yardım göster
        const labelText = getLabelText(el);
        const match = labelText ? searchGuide(entriesRef.current, labelText) : null;
        const x = Math.min(e.clientX + 10, window.innerWidth - 500);
        const y = Math.min(e.clientY + 10, window.innerHeight - 480);
        setGuideOpen(false);
        setModal({ visible: true, x: Math.max(8, x), y: Math.max(8, y), labelText, match });
      } else {
        // Herhangi bir yere sağ tık — tam kılavuzu aç
        setModal((m) => ({ ...m, visible: false }));
        setGuideSectionId('');
        setGuideOpen(true);
      }
    };

    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') { closeModal(); closeGuide(); }
    };

    // postMessage handler — kılavuz iframe'inden navigasyon isteği
    const onMessage = (e: MessageEvent) => {
      if (e.data?.type === 'navigate' && typeof e.data.view === 'string') {
        closeGuide();
        onNavigate?.(e.data.view);
      }
    };

    document.addEventListener('contextmenu', onContextMenu, { capture: true });
    document.addEventListener('keydown', onKeyDown);
    window.addEventListener('message', onMessage);
    return () => {
      document.removeEventListener('contextmenu', onContextMenu, { capture: true });
      document.removeEventListener('keydown', onKeyDown);
      window.removeEventListener('message', onMessage);
    };
  }, [closeModal, closeGuide, onNavigate]);

  // After render, push modal back into viewport if it overflows
  useEffect(() => {
    if (!modal.visible || !modalRef.current) return;
    const rect = modalRef.current.getBoundingClientRect();
    const vw = window.innerWidth;
    const vh = window.innerHeight;
    let { x, y } = modal;
    if (x + rect.width > vw - 8) x = vw - rect.width - 8;
    if (y + rect.height > vh - 8) y = vh - rect.height - 8;
    if (x < 8) x = 8;
    if (y < 8) y = 8;
    if (x !== modal.x || y !== modal.y) setModal((m) => ({ ...m, x, y }));
  });

  const { match } = modal;

  return (
    <>
      {children}

      {modal.visible && (
        <>
          {/* Click-away overlay */}
          <div className="fixed inset-0 z-[9998]" onClick={closeModal} />

          {/* Modal */}
          <div
            ref={modalRef}
            className="fixed z-[9999] bg-white rounded-2xl shadow-2xl border border-gray-200 overflow-hidden flex flex-col"
            style={{ left: modal.x, top: modal.y, width: 480, maxHeight: 500 }}
          >
            {/* Header */}
            <div className="flex items-center justify-between px-4 py-3 bg-blue-600 text-white shrink-0">
              <div className="flex items-center gap-2 min-w-0">
                <BookOpen className="w-4 h-4 shrink-0" />
                <span className="font-semibold text-sm shrink-0">Kullanım Kılavuzu</span>
                {match && (
                  <span className="text-blue-200 text-xs truncate">— {match.entry.sectionTitle}</span>
                )}
              </div>
              <button
                onClick={closeModal}
                className="p-1 hover:bg-blue-500 rounded-lg transition-colors shrink-0 ml-2"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            {/* Body */}
            <div className="overflow-y-auto flex-1 min-h-0">
              {match ? (
                <div className="p-4 space-y-3">
                  {/* Section path */}
                  <div>
                    <p className="text-[11px] font-bold text-blue-600 uppercase tracking-wide">
                      {match.entry.cardTitle}
                    </p>
                    {match.entry.subTitle && (
                      <p className="text-xs text-gray-500 mt-0.5">{match.entry.subTitle}</p>
                    )}
                  </div>

                  {/* Highlighted matching rows */}
                  {match.matchingRowIndices.length > 0 && (
                    <div className="space-y-1.5">
                      {match.matchingRowIndices.map((rowIdx) => {
                        const row = match.entry.rows[rowIdx];
                        return (
                          <div
                            key={rowIdx}
                            className="rounded-xl border border-blue-200 bg-blue-50 px-3 py-2.5 flex flex-wrap gap-x-5 gap-y-1.5"
                          >
                            {match.entry.headers.map((header, j) =>
                              row[j] ? (
                                <div key={j}>
                                  <span className="block text-[10px] font-bold text-blue-400 uppercase tracking-wide">
                                    {header}
                                  </span>
                                  <span className="text-sm font-medium text-gray-800">{row[j]}</span>
                                </div>
                              ) : null
                            )}
                          </div>
                        );
                      })}
                    </div>
                  )}

                  {/* Full table */}
                  <div>
                    <p className="text-[11px] font-semibold text-gray-500 uppercase tracking-wide mb-1.5">
                      Bu bölümdeki tüm alanlar
                    </p>
                    <div className="overflow-x-auto rounded-xl border border-gray-200">
                      <table className="w-full text-xs">
                        <thead>
                          <tr className="bg-gray-50 border-b border-gray-200">
                            {match.entry.headers.map((h, i) => (
                              <th
                                key={i}
                                className="px-3 py-2 text-left font-semibold text-gray-500 whitespace-nowrap"
                              >
                                {h}
                              </th>
                            ))}
                          </tr>
                        </thead>
                        <tbody>
                          {match.entry.rows.map((row, i) => {
                            const isMatch = match.matchingRowIndices.includes(i);
                            return (
                              <tr
                                key={i}
                                className={`border-b border-gray-100 last:border-0 ${
                                  isMatch ? 'bg-yellow-50' : ''
                                }`}
                              >
                                {row.map((cell, j) => (
                                  <td
                                    key={j}
                                    className={`px-3 py-2 align-top ${
                                      j === 0
                                        ? isMatch
                                          ? 'font-bold text-blue-700'
                                          : 'font-medium text-gray-800'
                                        : 'text-gray-600'
                                    }`}
                                  >
                                    {cell}
                                  </td>
                                ))}
                              </tr>
                            );
                          })}
                        </tbody>
                      </table>
                    </div>
                  </div>
                </div>
              ) : (
                <div className="p-8 text-center">
                  <BookOpen className="w-10 h-10 text-gray-200 mx-auto mb-3" />
                  <p className="text-sm font-semibold text-gray-600">"{modal.labelText || 'Alan'}"</p>
                  <p className="text-xs text-gray-400 mt-1">
                    Bu alan için kılavuzda eşleşme bulunamadı.
                  </p>
                </div>
              )}
            </div>

            {/* Footer */}
            <div className="px-4 py-2.5 border-t border-gray-100 bg-gray-50 flex items-center justify-between shrink-0">
              <p className="text-[11px] text-gray-400">ESC ile kapat</p>
              {match && (
                <button
                  onClick={() => openGuideAtSection(match.entry.sectionId)}
                  className="flex items-center gap-1 text-xs text-blue-600 hover:underline font-semibold"
                >
                  <ExternalLink className="w-3 h-3" />
                  Kılavuzda aç →
                </button>
              )}
            </div>
          </div>
        </>
      )}

      {/* Tam kılavuz modalı — herhangi bir yere sağ tıkta açılır */}
      {guideOpen && (
        <>
          <div className="fixed inset-0 z-[9998] bg-black/40" onClick={closeGuide} />
          <div className="fixed z-[9999] inset-4 md:inset-8 bg-white rounded-2xl shadow-2xl flex flex-col overflow-hidden border border-gray-200">
            <div className="flex items-center justify-between px-5 py-3 bg-blue-600 text-white shrink-0">
              <div className="flex items-center gap-2">
                <BookOpen className="w-5 h-5" />
                <span className="font-semibold">Kullanım Kılavuzu</span>
              </div>
              <button
                onClick={closeGuide}
                className="p-1.5 hover:bg-blue-500 rounded-lg transition-colors"
              >
                <X className="w-4 h-4" />
              </button>
            </div>
            <iframe
              key={guideSectionId}
              src={`/kullanim-kilavuzu.html${guideSectionId ? '#' + guideSectionId : ''}`}
              className="flex-1 w-full border-0"
              title="Kullanım Kılavuzu"
            />
          </div>
        </>
      )}
    </>
  );
};

export default GuideContextMenu;

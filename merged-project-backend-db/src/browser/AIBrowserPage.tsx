import React, { useState, useCallback, useRef } from 'react';
import { BrowserShell } from './BrowserShell';
import { Sandbox } from './Sandbox';
import { NewTab } from './NewTab';
import { streamPageGeneration } from './geminiService';
import {
  Page,
  Breadcrumb,
  TokenCount,
  FormFieldState,
  GroundingSource,
  Tab,
  createTab,
} from './browserTypes';
import {
  siteNameFromPrompt,
  parsePageFromHref,
  extractTitleFromHtml,
} from './urlHelpers';
import './browser.css';

function buildAppFeaturesHtml() {
  const sections = [
    {
      title: 'Personel Yonetimi',
      items: ['Tum Personel', 'Gorev Tanimi', 'Gorev Tanimi Kayitlari', 'Personel Cizelgesi ve filtreleme'],
    },
    {
      title: 'Bordro Islemleri',
      items: ['Bordro olusturma', 'Bordro Onay Islemleri', 'Bordro listesi ve takip'],
    },
    {
      title: 'Izin Yonetimi',
      items: ['Izin Talep Formu', 'Izin Duzenleme', 'Izin Takvimi', 'Izin Raporlari'],
    },
    {
      title: 'Takvim ve Sistem',
      items: ['Uyari ve Takvim Yonetimi', 'Sistem Ayarlari', 'Hizli Islemler ve yaklasan etkinlikler'],
    },
    {
      title: 'AI Tarayici',
      items: ['Prompt ile sayfa uretimi', 'Sekme yonetimi', 'Geri-ileri-gezinme', 'Token ve kaynak bilgisi gosterimi'],
    },
  ];

  const sectionHtml = sections
    .map((section, index) => {
      const rows = section.items
        .map((item) => `<li style="margin: 6px 0;">${item}</li>`)
        .join('');
      return `
        <section style="background:#ffffff;border:1px solid #e5e7eb;border-radius:14px;padding:16px 18px;box-shadow:0 4px 14px rgba(0,0,0,0.04)">
          <h2 style="margin:0 0 10px;font-size:18px;color:#0f172a;">${index + 1}. ${section.title}</h2>
          <ol style="margin:0;padding-left:20px;color:#334155;line-height:1.6;">${rows}</ol>
        </section>
      `;
    })
    .join('');

  return `
<!doctype html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Bordro - Uygulama Ozeti</title>
  </head>
  <body style="margin:0;background:#f8fafc;color:#0f172a;font-family:Segoe UI,system-ui,sans-serif;box-sizing:border-box;">
    <main style="width:100%;box-sizing:border-box;padding:28px 18px 42px;">
      <header style="margin-bottom:18px;">
        <h1 style="margin:0 0 8px;font-size:30px;">Bu Uygulamada Neler Var?</h1>
        <p style="margin:0;color:#475569;line-height:1.6;">Asagida uygulamadaki ana moduller ve temel yetenekler sirali olarak listelenmistir.</p>
      </header>
      <div style="display:grid;grid-template-columns:1fr;gap:12px;">${sectionHtml}</div>
    </main>
  </body>
</html>
`;
}

const AIBrowserPage: React.FC = () => {
  const [tabs, setTabs] = useState<Tab[]>([createTab()]);
  const [activeTabIndex, setActiveTabIndex] = useState(0);
  const [isGrounded, setIsGrounded] = useState(false);
  const abortControllersRef = useRef<Map<string, AbortController>>(new Map());

  const activeTab = tabs[activeTabIndex];
  const currentPage =
    activeTab.currentIndex >= 0 ? activeTab.history[activeTab.currentIndex] : null;

  const updateTab = useCallback(
    (tabIndex: number, updater: (tab: Tab) => Tab) => {
      setTabs((prev) => prev.map((t, i) => (i === tabIndex ? updater(t) : t)));
    },
    []
  );

  // ─── Core generation ────────────────────────────────────────────────────────

  const generate = useCallback(
    async (
      prompt: string,
      currentHtml: string | null,
      fallbackBreadcrumb: Breadcrumb,
      pushHistory: boolean = true,
      formState?: FormFieldState[]
    ) => {
      const tabIndex = activeTabIndex;
      const tabId = tabs[tabIndex].id;

      const existingController = abortControllersRef.current.get(tabId);
      if (existingController) existingController.abort();

      const controller = new AbortController();
      abortControllersRef.current.set(tabId, controller);

      updateTab(tabIndex, (tab) => ({
        ...tab,
        loading: true,
        loadingMessage: 'Gemini 3.1 Flash ile sayfa oluşturuluyor…',
        generatedContent: '',
        tokenCount: null,
        groundingSources: [],
        searchEntryPointHtml: '',
        breadcrumb: { sitename: fallbackBreadcrumb.sitename, page: '' },
        ...(pushHistory ? { navigationId: tab.navigationId + 1 } : {}),
      }));

      let fullHtml = '';
      let pageTokenCount: TokenCount = { input: 0, output: 0 };
      let pageGroundingSources: GroundingSource[] = [];
      let pageSearchEntryPointHtml = '';
      let titleExtracted = false;

      try {
        const stream = streamPageGeneration(
          prompt,
          currentHtml,
          isGrounded,
          controller.signal,
          formState,
          window.innerWidth <= 768
        );

        for await (const chunk of stream) {
          if (controller.signal.aborted) break;

          if (chunk.startsWith('__TOKEN__')) {
            try {
              const td = JSON.parse(chunk.replace('__TOKEN__', ''));
              updateTab(tabIndex, (t) => ({ ...t, tokenCount: td }));
            } catch {}
            continue;
          }

          if (chunk.startsWith('__META__')) {
            try {
              const meta = JSON.parse(chunk.replace('__META__', ''));
              pageTokenCount = meta.tokenCount;
              updateTab(tabIndex, (t) => ({ ...t, tokenCount: pageTokenCount }));
              if (meta.groundingSources?.length) {
                pageGroundingSources = meta.groundingSources;
                updateTab(tabIndex, (t) => ({
                  ...t,
                  groundingSources: meta.groundingSources,
                }));
              }
              if (meta.searchEntryPointHtml) {
                pageSearchEntryPointHtml = meta.searchEntryPointHtml;
                updateTab(tabIndex, (t) => ({
                  ...t,
                  searchEntryPointHtml: meta.searchEntryPointHtml,
                }));
              }
            } catch {}
            continue;
          }

          fullHtml += chunk;

          let extractedBreadcrumb: Breadcrumb | null = null;
          if (!titleExtracted && fullHtml.includes('</title>')) {
            extractedBreadcrumb = extractTitleFromHtml(fullHtml);
            if (extractedBreadcrumb) titleExtracted = true;
          }

          updateTab(tabIndex, (t) => ({
            ...t,
            generatedContent: fullHtml,
            ...(extractedBreadcrumb ? { breadcrumb: extractedBreadcrumb } : {}),
          }));
        }

        if (controller.signal.aborted) return;

        const finalBreadcrumb = titleExtracted
          ? extractTitleFromHtml(fullHtml) || fallbackBreadcrumb
          : fallbackBreadcrumb;

        const newPage: Page = {
          html: fullHtml,
          breadcrumb: finalBreadcrumb,
          scrollPosition: 0,
          timestamp: Date.now(),
          tokenCount: pageTokenCount,
          prompt,
          contextHtml: currentHtml,
          isGrounded,
          groundingSources: pageGroundingSources,
          searchEntryPointHtml: pageSearchEntryPointHtml,
        };

        updateTab(tabIndex, (tab) => {
          if (pushHistory) {
            const newHistory = [
              ...tab.history.slice(0, tab.currentIndex + 1),
              newPage,
            ];
            return {
              ...tab,
              history: newHistory,
              currentIndex: newHistory.length - 1,
              breadcrumb: finalBreadcrumb,
              tokenCount: pageTokenCount,
            };
          }
          const updated = [...tab.history];
          if (tab.currentIndex >= 0) updated[tab.currentIndex] = newPage;
          return {
            ...tab,
            history: updated,
            breadcrumb: finalBreadcrumb,
            tokenCount: pageTokenCount,
          };
        });
      } catch (e: any) {
        if (e?.name === 'AbortError' || controller.signal.aborted) return;
        console.error('Generation failed', e);
        updateTab(tabIndex, (t) => ({
          ...t,
          breadcrumb: fallbackBreadcrumb,
          generatedContent: `<div style="padding:40px;font-family:sans-serif"><h2>Hata</h2><p>Sayfa oluşturulurken bir hata oluştu.</p><pre>${e?.message}</pre></div>`,
        }));
      } finally {
        if (abortControllersRef.current.get(tabId) === controller) {
          updateTab(tabIndex, (t) => ({
            ...t,
            loading: false,
            loadingMessage: '',
          }));
          abortControllersRef.current.delete(tabId);
        }
      }
    },
    [isGrounded, activeTabIndex, tabs, updateTab]
  );

  // ─── Navigation handlers ─────────────────────────────────────────────────────

  const handleStop = useCallback(() => {
    const tabId = activeTab.id;
    const controller = abortControllersRef.current.get(tabId);
    if (controller) {
      controller.abort();
      abortControllersRef.current.delete(tabId);
    }
    updateTab(activeTabIndex, (t) => ({
      ...t,
      loading: false,
      loadingMessage: '',
    }));
  }, [activeTab, activeTabIndex, updateTab]);

  const handleCreate = useCallback(
    (prompt: string) => {
      const normalized = prompt.toLowerCase();
      if (
        normalized.includes('bu uygulamada ne var') ||
        normalized.includes('uygulamada neler var') ||
        normalized.includes('modulleri listele')
      ) {
        const html = buildAppFeaturesHtml();
        const breadcrumb: Breadcrumb = { sitename: 'Bordro', page: 'Uygulama Ozeti' };
        const page: Page = {
          html,
          breadcrumb,
          scrollPosition: 0,
          timestamp: Date.now(),
          tokenCount: { input: 0, output: 0 },
          prompt,
          contextHtml: null,
          isGrounded: false,
          groundingSources: [],
          searchEntryPointHtml: '',
        };

        updateTab(activeTabIndex, (tab) => {
          const newHistory = [...tab.history.slice(0, tab.currentIndex + 1), page];
          return {
            ...tab,
            history: newHistory,
            currentIndex: newHistory.length - 1,
            breadcrumb,
            generatedContent: html,
            tokenCount: page.tokenCount,
            groundingSources: [],
            searchEntryPointHtml: '',
            loading: false,
            loadingMessage: '',
            navigationId: tab.navigationId + 1,
          };
        });
        return;
      }

      const fallback: Breadcrumb = {
        sitename: siteNameFromPrompt(prompt),
        page: 'Ana Sayfa',
      };
      generate(prompt, null, fallback, true);
    },
    [activeTabIndex, generate, updateTab]
  );

  const handleShowAppFeatures = useCallback(() => {
    handleCreate('Bu uygulamada ne var? Modulleri listele.');
  }, [handleCreate]);

  const handleLinkClick = useCallback(
    (href: string, linkText: string, formState?: FormFieldState[]) => {
      const prompt = `Kullanıcı "${linkText}" bağlantısına tıkladı (href: ${href})`;
      const isExternal =
        /^https?:\/\//i.test(href) || /^[a-z0-9-]+\.[a-z]{2,}/i.test(href);

      if (isExternal) {
        const domain = href.replace(/^https?:\/\//, '').split('/')[0];
        const sitename = domain
          .replace(/^www\./, '')
          .split('.')[0];
        const capitalizedSitename =
          sitename.charAt(0).toUpperCase() + sitename.slice(1);
        const fallback: Breadcrumb = {
          sitename: capitalizedSitename,
          page: 'Ana Sayfa',
        };
        generate(prompt, null, fallback, true, formState);
      } else {
        const currentSitename = activeTab.breadcrumb.sitename || 'Site';
        const page = parsePageFromHref(href);
        const fallback: Breadcrumb = { sitename: currentSitename, page };
        if (currentPage) {
          generate(prompt, currentPage.html, fallback, true, formState);
        } else {
          generate(prompt, null, fallback, true, formState);
        }
      }
    },
    [generate, currentPage, activeTab.breadcrumb]
  );

  const handleAction = useCallback(
    (intent: string, payload?: string, formState?: FormFieldState[]) => {
      if (!currentPage) return;
      const actionPrompt = payload ? `${intent}: ${payload}` : intent;
      generate(actionPrompt, currentPage.html, activeTab.breadcrumb, false, formState);
    },
    [generate, currentPage, activeTab.breadcrumb]
  );

  const handleOmnibarNavigate = useCallback(
    (type: 'create' | 'edit', prompt: string) => {
      if (type === 'create') {
        const fallback: Breadcrumb = {
          sitename: siteNameFromPrompt(prompt),
          page: 'Ana Sayfa',
        };
        generate(prompt, null, fallback, true);
      } else {
        if (!currentPage) return;
        const fallback: Breadcrumb = {
          sitename: activeTab.breadcrumb.sitename,
          page: prompt,
        };
        generate(prompt, currentPage.html, fallback, false);
      }
    },
    [generate, currentPage, activeTab.breadcrumb]
  );

  const handleBack = useCallback(() => {
    if (activeTab.currentIndex > 0) {
      updateTab(activeTabIndex, (tab) => {
        const newIndex = tab.currentIndex - 1;
        const page = tab.history[newIndex];
        return {
          ...tab,
          currentIndex: newIndex,
          navigationId: tab.navigationId + 1,
          generatedContent: page.html,
          breadcrumb: page.breadcrumb,
          tokenCount: page.tokenCount,
          groundingSources: page.groundingSources || [],
          searchEntryPointHtml: page.searchEntryPointHtml || '',
        };
      });
      const page = activeTab.history[activeTab.currentIndex - 1];
      if (page) setIsGrounded(page.isGrounded);
    }
  }, [activeTab, activeTabIndex, updateTab]);

  const handleForward = useCallback(() => {
    if (activeTab.currentIndex < activeTab.history.length - 1) {
      updateTab(activeTabIndex, (tab) => {
        const newIndex = tab.currentIndex + 1;
        const page = tab.history[newIndex];
        return {
          ...tab,
          currentIndex: newIndex,
          navigationId: tab.navigationId + 1,
          generatedContent: page.html,
          breadcrumb: page.breadcrumb,
          tokenCount: page.tokenCount,
          groundingSources: page.groundingSources || [],
          searchEntryPointHtml: page.searchEntryPointHtml || '',
        };
      });
      const page = activeTab.history[activeTab.currentIndex + 1];
      if (page) setIsGrounded(page.isGrounded);
    }
  }, [activeTab, activeTabIndex, updateTab]);

  const handleRefresh = useCallback(() => {
    if (currentPage) {
      generate(
        currentPage.prompt,
        currentPage.contextHtml,
        currentPage.breadcrumb,
        false
      );
    }
  }, [currentPage, generate]);

  const handleHome = useCallback(() => {
    const tabId = activeTab.id;
    const controller = abortControllersRef.current.get(tabId);
    if (controller) {
      controller.abort();
      abortControllersRef.current.delete(tabId);
    }
    updateTab(activeTabIndex, (t) => ({
      ...t,
      currentIndex: -1,
      loading: false,
      loadingMessage: '',
      generatedContent: '',
      breadcrumb: { sitename: '', page: '' },
      tokenCount: null,
      groundingSources: [],
      searchEntryPointHtml: '',
    }));
  }, [activeTab, activeTabIndex, updateTab]);

  // ─── Tab management ──────────────────────────────────────────────────────────

  const handleNewTab = useCallback(() => {
    const newTab = createTab();
    setTabs((prev) => [...prev, newTab]);
    setActiveTabIndex(tabs.length);
  }, [tabs.length]);

  const handleCloseTab = useCallback(
    (index: number) => {
      const closingTab = tabs[index];
      const controller = abortControllersRef.current.get(closingTab.id);
      if (controller) {
        controller.abort();
        abortControllersRef.current.delete(closingTab.id);
      }

      if (tabs.length === 1) {
        const newTab = createTab();
        setTabs([newTab]);
        setActiveTabIndex(0);
      } else {
        setTabs((prev) => prev.filter((_, i) => i !== index));
        if (activeTabIndex >= index && activeTabIndex > 0) {
          setActiveTabIndex((prev) => prev - 1);
        }
      }
    },
    [tabs, activeTabIndex]
  );

  const handleSwitchTab = useCallback((index: number) => {
    setActiveTabIndex(index);
  }, []);

  const isNewTab = activeTab.currentIndex === -1 && !activeTab.loading;
  const displayContent = activeTab.loading
    ? activeTab.generatedContent
    : currentPage?.html || '';

  return (
    <div className="ai-browser-page">
      {/* Token counter bar */}
      {activeTab.tokenCount && (
        <div className="ai-browser-token-bar">
          <span className="ai-browser-token-label">
            {activeTab.loading ? '⚡ Oluşturuluyor…' : '✓ Tamamlandı'}&nbsp;
          </span>
          <span className="ai-browser-token-count">
            {(
              (activeTab.tokenCount.input ?? 0) +
              (activeTab.tokenCount.output ?? 0)
            ).toLocaleString('tr-TR')}{' '}
            token
          </span>
        </div>
      )}

      {/* Browser shell */}
      <div className="ai-browser-shell-wrapper">
        <BrowserShell
          breadcrumb={activeTab.breadcrumb}
          isLoading={activeTab.loading}
          loadingMessage={activeTab.loadingMessage}
          onNavigate={handleOmnibarNavigate}
          onBack={handleBack}
          onForward={handleForward}
          onRefresh={handleRefresh}
          onStop={handleStop}
          onHome={handleHome}
          canGoBack={activeTab.currentIndex > 0}
          canGoForward={
            activeTab.currentIndex < activeTab.history.length - 1
          }
          groundingSources={activeTab.groundingSources}
          searchEntryPointHtml={activeTab.searchEntryPointHtml}
          tabs={tabs}
          activeTabIndex={activeTabIndex}
          onNewTab={handleNewTab}
          onCloseTab={handleCloseTab}
          onSwitchTab={handleSwitchTab}
          isGrounded={isGrounded}
          onToggleGrounding={() => setIsGrounded((prev) => !prev)}
        >
          {isNewTab ? (
            <NewTab onCreatePage={handleCreate} onShowAppFeatures={handleShowAppFeatures} />
          ) : (
            <Sandbox
              htmlContent={displayContent}
              onNavigate={handleLinkClick}
              onAction={handleAction}
            />
          )}
        </BrowserShell>
      </div>
    </div>
  );
};

export default AIBrowserPage;

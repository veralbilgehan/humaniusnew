import { supabase } from '../lib/supabase';

export interface CrawlPayload {
  url: string;
  maxPages?: number;
  maxDepth?: number;
}

export interface CrawledPage {
  url: string | null;
  title: string | null;
  text: string;
  markdown: string | null;
}

export async function crawlWebsite(payload: CrawlPayload): Promise<CrawledPage[]> {
  const { data, error } = await supabase.functions.invoke('apify-crawl', { body: payload });

  if (error) {
    let message = error.message;
    try {
      const body = await (error as any).context?.json?.();
      if (body?.error) message = body.error;
    } catch {
      // ignore
    }
    throw new Error(message);
  }

  if (data?.error) {
    throw new Error(data.error);
  }

  return (data?.pages ?? []) as CrawledPage[];
}

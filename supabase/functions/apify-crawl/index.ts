import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Client-Info, Apikey",
};

const ACTOR_ID = 'apify~website-content-crawler';
const MAX_PAGES_LIMIT = 20;

const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? '';
const apifyToken = Deno.env.get('APIFY_API_TOKEN') ?? '';

interface CrawlRequest {
  url: string;
  maxPages?: number;
  maxDepth?: number;
}

interface ApifyItem {
  url?: string;
  text?: string;
  markdown?: string;
  metadata?: { title?: string };
}

function jsonResponse(body: Record<string, unknown>, status: number = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  });
}

async function isAuthenticated(req: Request) {
  const authHeader = req.headers.get('Authorization') ?? '';
  if (!authHeader) return false;

  const authClient = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data, error } = await authClient.auth.getUser();
  return !error && !!data.user;
}

function clamp(value: unknown, fallback: number, max: number) {
  const n = Number(value);
  if (!Number.isFinite(n) || n < 1) return fallback;
  return Math.min(Math.floor(n), max);
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 200, headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return jsonResponse({ error: 'Yalnızca POST desteklenir.' }, 405);
  }

  if (!apifyToken) {
    return jsonResponse({ error: 'APIFY_API_TOKEN tanımlı değil.' }, 500);
  }

  try {
    if (!(await isAuthenticated(req))) {
      return jsonResponse({ error: 'Oturum açmanız gerekiyor.' }, 401);
    }

    const payload = (await req.json()) as CrawlRequest;
    let startUrl: URL;
    try {
      startUrl = new URL(String(payload.url ?? '').trim());
      if (startUrl.protocol !== 'http:' && startUrl.protocol !== 'https:') throw new Error();
    } catch {
      return jsonResponse({ error: 'Geçerli bir http(s) url gönderin.' }, 400);
    }

    const input = {
      startUrls: [{ url: startUrl.toString() }],
      maxCrawlPages: clamp(payload.maxPages, 1, MAX_PAGES_LIMIT),
      maxCrawlDepth: clamp(payload.maxDepth, 0, 5),
      crawlerType: 'playwright:adaptive',
    };

    const apifyResponse = await fetch(
      `https://api.apify.com/v2/acts/${ACTOR_ID}/run-sync-get-dataset-items`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${apifyToken}`,
        },
        body: JSON.stringify(input),
      },
    );

    if (!apifyResponse.ok) {
      const detail = await apifyResponse.text();
      return jsonResponse({ error: `Apify hatası (${apifyResponse.status})`, detail }, 502);
    }

    const items = (await apifyResponse.json()) as ApifyItem[];

    return jsonResponse({
      pages: items.map((item) => ({
        url: item.url ?? null,
        title: item.metadata?.title ?? null,
        text: item.text ?? '',
        markdown: item.markdown ?? null,
      })),
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Beklenmeyen bir hata oluştu';
    return jsonResponse({ error: message }, 500);
  }
});

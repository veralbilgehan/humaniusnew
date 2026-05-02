import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Client-Info, Apikey",
};

interface IzinHesaplamaRequest {
  iseGirisTarihi: string;
  dogumTarihi?: string;
}

interface IzinHesaplamaResponse {
  calismaYili: number;
  toplamHak: number;
  yasiEkHak: number;
  aciklama: string;
}

function hesaplaIzinHakki(iseGirisTarihi: string, dogumTarihi?: string): IzinHesaplamaResponse {
  const giris = new Date(iseGirisTarihi);
  const now = new Date();

  const yilFarki = now.getFullYear() - giris.getFullYear();
  const ayFarki = now.getMonth() - giris.getMonth();
  const gunFarki = now.getDate() - giris.getDate();

  let calismaYili = yilFarki;
  if (ayFarki < 0 || (ayFarki === 0 && gunFarki < 0)) {
    calismaYili--;
  }

  let toplamHak = 14;
  let aciklama = "1-5 yıl arası: 14 gün";

  if (calismaYili >= 1 && calismaYili < 5) {
    toplamHak = 14;
    aciklama = "1-5 yıl arası: 14 gün";
  } else if (calismaYili >= 5 && calismaYili < 15) {
    toplamHak = 20;
    aciklama = "5-15 yıl arası: 20 gün";
  } else if (calismaYili >= 15) {
    toplamHak = 26;
    aciklama = "15 yıl ve üzeri: 26 gün";
  } else {
    toplamHak = 0;
    aciklama = "1 yılı doldurmayan personel izin hakkı kazanmamıştır";
  }

  let yasiEkHak = 0;
  if (dogumTarihi) {
    const dogum = new Date(dogumTarihi);
    const yas = now.getFullYear() - dogum.getFullYear();
    if (yas >= 50 && calismaYili >= 15) {
      yasiEkHak = 4;
      toplamHak += yasiEkHak;
      aciklama += " + 50 yaş üstü ek hak: 4 gün";
    }
  }

  return {
    calismaYili,
    toplamHak,
    yasiEkHak,
    aciklama
  };
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 200,
      headers: corsHeaders,
    });
  }

  try {
    const requestData: IzinHesaplamaRequest = await req.json();

    if (!requestData.iseGirisTarihi) {
      return new Response(
        JSON.stringify({ error: "İşe giriş tarihi gereklidir" }),
        {
          status: 400,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
          },
        }
      );
    }

    const sonuc = hesaplaIzinHakki(requestData.iseGirisTarihi, requestData.dogumTarihi);

    return new Response(JSON.stringify(sonuc), {
      headers: {
        ...corsHeaders,
        "Content-Type": "application/json",
      },
    });
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      }
    );
  }
});

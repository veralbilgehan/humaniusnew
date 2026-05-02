import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Client-Info, Apikey",
};

interface BordroHesaplamaRequest {
  brutMaas: number;
  medeniDurum: 'bekar' | 'evli';
  cocukSayisi: number;
  engelliDurumu: 'yok' | 'birinci' | 'ikinci' | 'ucuncu';
  fazlaMesaiSaat50?: number;
  fazlaMesaiSaat100?: number;
  yillikKumulatifMatrah?: number;
}

interface GelirVergisiDilimi {
  alt: number;
  ust: number;
  oran: number;
  oncekiDilimlerToplami: number;
}

const gelirVergisiDilimleri2025: GelirVergisiDilimi[] = [
  { alt: 0, ust: 110000, oran: 0.15, oncekiDilimlerToplami: 0 },
  { alt: 110000, ust: 230000, oran: 0.20, oncekiDilimlerToplami: 16500 },
  { alt: 230000, ust: 580000, oran: 0.27, oncekiDilimlerToplami: 40500 },
  { alt: 580000, ust: 3000000, oran: 0.35, oncekiDilimlerToplami: 135000 },
  { alt: 3000000, ust: Infinity, oran: 0.40, oncekiDilimlerToplami: 982000 }
];

const ORANLAR_2025 = {
  damgaVergisi: 0.00759,
  sgkIsciPayi: 0.14,
  sgkIsverenPayi: 0.205,
  issizlikIsciPayi: 0.01,
  issizlikIsverenPayi: 0.02,
  asgariUcret: 22104.00,
  sgkTavani: 178957.50,
  asgariUcretGelirVergisiIstisnasi: 1803.51,
  asgariUcretDamgaVergisiIstisnasi: 44.95
};

function hesaplaGelirVergisi(matraह: number, yillikKumulatif: number = 0): number {
  const toplamMatrah = yillikKumulatif + matrah;

  let vergi = 0;
  for (const dilim of gelirVergisiDilimleri2025) {
    if (toplamMatrah > dilim.alt) {
      const vergiyeTasiMatrah = Math.min(toplamMatrah, dilim.ust) - dilim.alt;
      vergi += vergiyeTasiMatrah * dilim.oran;
    }
  }

  const oncekiVergi = hesaplaOncekiKumulatifVergi(yillikKumulatif);
  return Math.max(0, vergi - oncekiVergi);
}

function hesaplaOncekiKumulatifVergi(kumulatif: number): number {
  if (kumulatif === 0) return 0;

  let vergi = 0;
  for (const dilim of gelirVergisiDilimleri2025) {
    if (kumulatif > dilim.alt) {
      const vergiyeTabiMatrah = Math.min(kumulatif, dilim.ust) - dilim.alt;
      vergi += vergiyeTabiMatrah * dilim.oran;
    }
  }
  return vergi;
}

function hesaplaBordro(request: BordroHesaplamaRequest) {
  const { brutMaas, medeniDurum, cocukSayisi, engelliDurumu, fazlaMesaiSaat50 = 0, fazlaMesaiSaat100 = 0, yillikKumulatifMatrah = 0 } = request;

  const saatUcreti = (brutMaas * 12) / (52 * 45);
  const fazlaMesai50Tutar = saatUcreti * 1.5 * fazlaMesaiSaat50;
  const fazlaMesai100Tutar = saatUcreti * 2.0 * fazlaMesaiSaat100;
  const toplamFazlaMesai = fazlaMesai50Tutar + fazlaMesai100Tutar;

  const toplamKazanc = brutMaas + toplamFazlaMesai;

  const sgkMatrah = Math.min(toplamKazanc, ORANLAR_2025.sgkTavani);
  const sgkIsciPayi = sgkMatrah * ORANLAR_2025.sgkIsciPayi;
  const issizlikIsciPayi = sgkMatrah * ORANLAR_2025.issizlikIsciPayi;

  const gelirVergisiMatrahi = toplamKazanc - sgkIsciPayi - issizlikIsciPayi;
  let gelirVergisi = hesaplaGelirVergisi(gelirVergisiMatrahi, yillikKumulatifMatrah);

  let asgariUcretGelirVergisiIstisnasi = 0;
  if (brutMaas <= ORANLAR_2025.asgariUcret) {
    asgariUcretGelirVergisiIstisnasi = Math.min(gelirVergisi, ORANLAR_2025.asgariUcretGelirVergisiIstisnasi);
    gelirVergisi -= asgariUcretGelirVergisiIstisnasi;
  }

  let damgaVergisi = toplamKazanc * ORANLAR_2025.damgaVergisi;
  let asgariUcretDamgaVergisiIstisnasi = 0;
  if (brutMaas <= ORANLAR_2025.asgariUcret) {
    asgariUcretDamgaVergisiIstisnasi = Math.min(damgaVergisi, ORANLAR_2025.asgariUcretDamgaVergisiIstisnasi);
    damgaVergisi -= asgariUcretDamgaVergisiIstisnasi;
  }

  const toplamKesinti = gelirVergisi + damgaVergisi + sgkIsciPayi + issizlikIsciPayi;
  const netMaas = toplamKazanc - toplamKesinti;

  const sgkIsverenPayi = sgkMatrah * ORANLAR_2025.sgkIsverenPayi;
  const issizlikIsverenPayi = sgkMatrah * ORANLAR_2025.issizlikIsverenPayi;

  return {
    toplamKazanc: Number(toplamKazanc.toFixed(2)),
    gelirVergisi: Number(gelirVergisi.toFixed(2)),
    damgaVergisi: Number(damgaVergisi.toFixed(2)),
    sgkIsciPayi: Number(sgkIsciPayi.toFixed(2)),
    issizlikSigortasi: Number(issizlikIsciPayi.toFixed(2)),
    toplamKesinti: Number(toplamKesinti.toFixed(2)),
    netMaas: Number(netMaas.toFixed(2)),
    sgkIsverenPayi: Number(sgkIsverenPayi.toFixed(2)),
    issizlikIsverenPayi: Number(issizlikIsverenPayi.toFixed(2)),
    asgariUcretGelirVergisiIstisnasi: Number(asgariUcretGelirVergisiIstisnasi.toFixed(2)),
    asgariUcretDamgaVergisiIstisnasi: Number(asgariUcretDamgaVergisiIstisnasi.toFixed(2)),
    fazlaMesaiTutar: Number(toplamFazlaMesai.toFixed(2)),
    gelirVergisiMatrahi: Number(gelirVergisiMatrahi.toFixed(2))
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
    const requestData: BordroHesaplamaRequest = await req.json();

    if (!requestData.brutMaas || requestData.brutMaas <= 0) {
      return new Response(
        JSON.stringify({ error: "Geçerli bir brüt maaş giriniz" }),
        {
          status: 400,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
          },
        }
      );
    }

    const sonuc = hesaplaBordro(requestData);

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

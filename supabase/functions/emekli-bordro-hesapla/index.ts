import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Client-Info, Apikey",
};

interface EmeклiBordroHesaplamaRequest {
  brutMaas: number;
  medeniDurum?: 'bekar' | 'evli';
  cocukSayisi?: number;
  fazlaMesaiSaat?: number;
  yolYemekYardimi?: number;
  kumulatifMatrah?: number;
  hesaplamaTipi?: 'brut-net' | 'net-brut';
}

interface EmeклiBordroSonuc {
  normalCalismaBrut: number;
  fazlaMesai50: number;
  fazlaMesai50Tutar: number;
  yolYemekYardimi: number;
  toplamKazanc: number;
  sgkIsciPayi: number;
  issizlikSigortasiIsci: number;
  gelirVergisiMatrahi: number;
  gelirVergisi: number;
  damgaVergisi: number;
  toplamKesinti: number;
  netMaas: number;
  sgkIsverenPayi: number;
  issizlikIsverenPayi: number;
  toplamMaliyet: number;
}

const EMEKLI_ORANLARI = {
  sgkIsciPayi: 0.14,
  sgkIsverenPayi: 0.205,
  issizlikIsciPayi: 0.01,
  issizlikIsverenPayi: 0.02,
  gelirVergisi: 0.15,
  damgaVergisi: 0.00759
};

function hesaplaBruttenNete(request: EmeклiBordroHesaplamaRequest): EmeклiBordroSonuc {
  const {
    brutMaas,
    fazlaMesaiSaat = 0,
    yolYemekYardimi = 0,
    kumulatifMatrah = 0
  } = request;

  const normalCalismaBrut = brutMaas;
  const normalCalismaSaatUcreti = (brutMaas * 12) / (52 * 45);

  const fazlaMesai50Tutar = normalCalismaSaatUcreti * 1.5 * fazlaMesaiSaat;

  const toplamKazanc = normalCalismaBrut + fazlaMesai50Tutar + yolYemekYardimi;

  const sgkMatrah = toplamKazanc;
  const sgkIsciPayi = sgkMatrah * EMEKLI_ORANLARI.sgkIsciPayi;
  const issizlikSigortasiIsci = sgkMatrah * EMEKLI_ORANLARI.issizlikIsciPayi;

  const gelirVergisiMatrahi = toplamKazanc - sgkIsciPayi - issizlikSigortasiIsci;
  const gelirVergisi = gelirVergisiMatrahi * EMEKLI_ORANLARI.gelirVergisi;

  const damgaVergisi = toplamKazanc * EMEKLI_ORANLARI.damgaVergisi;

  const toplamKesinti = sgkIsciPayi + issizlikSigortasiIsci + gelirVergisi + damgaVergisi;
  const netMaas = toplamKazanc - toplamKesinti;

  const sgkIsverenPayi = sgkMatrah * EMEKLI_ORANLARI.sgkIsverenPayi;
  const issizlikIsverenPayi = sgkMatrah * EMEKLI_ORANLARI.issizlikIsverenPayi;
  const toplamMaliyet = toplamKazanc + sgkIsverenPayi + issizlikIsverenPayi;

  return {
    normalCalismaBrut: Number(normalCalismaBrut.toFixed(2)),
    fazlaMesai50: fazlaMesaiSaat,
    fazlaMesai50Tutar: Number(fazlaMesai50Tutar.toFixed(2)),
    yolYemekYardimi: Number(yolYemekYardimi.toFixed(2)),
    toplamKazanc: Number(toplamKazanc.toFixed(2)),
    sgkIsciPayi: Number(sgkIsciPayi.toFixed(2)),
    issizlikSigortasiIsci: Number(issizlikSigortasiIsci.toFixed(2)),
    gelirVergisiMatrahi: Number(gelirVergisiMatrahi.toFixed(2)),
    gelirVergisi: Number(gelirVergisi.toFixed(2)),
    damgaVergisi: Number(damgaVergisi.toFixed(2)),
    toplamKesinti: Number(toplamKesinti.toFixed(2)),
    netMaas: Number(netMaas.toFixed(2)),
    sgkIsverenPayi: Number(sgkIsverenPayi.toFixed(2)),
    issizlikIsverenPayi: Number(issizlikIsverenPayi.toFixed(2)),
    toplamMaliyet: Number(toplamMaliyet.toFixed(2))
  };
}

function hesaplaNettenBrute(netHedef: number): EmeклiBordroSonuc {
  let brutTahmin = netHedef * 1.5;
  let iterasyon = 0;
  const maxIterasyon = 100;
  const tolerans = 0.01;

  while (iterasyon < maxIterasyon) {
    const sonuc = hesaplaBruttenNete({
      brutMaas: brutTahmin,
      hesaplamaTipi: 'brut-net'
    });

    const fark = netHedef - sonuc.netMaas;

    if (Math.abs(fark) < tolerans) {
      return sonuc;
    }

    brutTahmin += fark * 0.5;
    iterasyon++;
  }

  return hesaplaBruttenNete({
    brutMaas: brutTahmin,
    hesaplamaTipi: 'brut-net'
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 200,
      headers: corsHeaders,
    });
  }

  try {
    const requestData: EmeклiBordroHesaplamaRequest = await req.json();

    if (requestData.hesaplamaTipi === 'net-brut') {
      if (!requestData.brutMaas || requestData.brutMaas <= 0) {
        return new Response(
          JSON.stringify({ error: "Net maaş giriniz (brutMaas alanında)" }),
          {
            status: 400,
            headers: {
              ...corsHeaders,
              "Content-Type": "application/json",
            },
          }
        );
      }

      const sonuc = hesaplaNettenBrute(requestData.brutMaas);

      return new Response(JSON.stringify(sonuc), {
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      });
    }

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

    const sonuc = hesaplaBruttenNete(requestData);

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

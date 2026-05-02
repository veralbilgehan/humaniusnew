import React, { useMemo, useState } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "./ui/card";
import { Input } from "./ui/input";
import { Label } from "./ui/label";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "./ui/table";
import { Badge } from "./ui/badge";
import { Separator } from "./ui/separator";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "./ui/tabs";
import { Landmark, TrendingUp, Calculator, ShieldCheck } from "lucide-react";
import { VARSAYILAN_SISTEM_AYARLARI } from "../data/sistemAyarlari";

const currency = (value: number) =>
  new Intl.NumberFormat("tr-TR", {
    style: "currency",
    currency: "TRY",
    maximumFractionDigits: 2,
  }).format(Number.isFinite(value) ? value : 0);

const percent = (value: number) => `%${(value * 100).toFixed(2)}`;
const round2 = (value: number) => Math.round((value + Number.EPSILON) * 100) / 100;
const approxEqual = (actual: number, expected: number, tolerance = 0.02) => Math.abs(actual - expected) <= tolerance;

type TaxBracket = {
  limit: number;
  rate: number;
  base: number;
};

type PayrollParams = {
  firstSixSalary: number;
  secondSixSalary: number;
  sgkEmployee: number;
  unemploymentEmployee: number;
  stampTax: number;
  sgkEmployer: number;
  unemploymentEmployer: number;
  sgkCaps: number[];
  incomeTaxBrackets: TaxBracket[];
  minimumWageTaxBase: number[];
  minimumWageStampExemption: number[];
  sgdpEmployee: number;
  sgdpEmployer: number;
};

type PayrollMode = "grossToNet" | "sgdp";

type PayrollRow = {
  month: number;
  gross: number;
  employeeSgk: number;
  employeeUnemployment: number;
  incomeTaxBase: number;
  cumulativeBase: number;
  incomeTax: number;
  minimumWageIncomeTaxBase: number;
  minimumWageCumulativeBase: number;
  minimumWageIncomeTax: number;
  deductedIncomeTax: number;
  grossStampTax: number;
  minimumWageStampExemption: number;
  stampTax: number;
  net: number;
  employerSgk: number;
  employerUnemployment: number;
  totalCost: number;
};

const getDefaultParams = (): PayrollParams => {
  const settings = VARSAYILAN_SISTEM_AYARLARI.emeклiBordroParametreleri;
  return {
    firstSixSalary: settings.varsayilanIlkAltiAyMaas,
    secondSixSalary: settings.varsayilanIkinciAltiAyMaas,
    sgkEmployee: settings.normalBordro.sgkIsciPayiOrani,
    unemploymentEmployee: settings.normalBordro.issizlikIsciPayiOrani,
    stampTax: settings.normalBordro.damgaVergisiOrani,
    sgkEmployer: settings.normalBordro.sgkIsverenPayiOrani,
    unemploymentEmployer: settings.normalBordro.issizlikIsverenPayiOrani,
    sgkCaps: settings.sgkTavanlari,
    incomeTaxBrackets: settings.gelirVergisiDilimleri,
    minimumWageTaxBase: settings.asgariUcretGVMatrahi,
    minimumWageStampExemption: settings.asgariUcretDamgaIstisnasi,
    sgdpEmployee: settings.sgdpBordro.sgkIsciPayiOrani,
    sgdpEmployer: settings.sgdpBordro.sgkIsverenPayiOrani,
  };
};

function totalIncomeTax(base: number, brackets: TaxBracket[]) {
  const safeBase = Math.max(0, base);

  for (let i = 0; i < brackets.length; i += 1) {
    const bracket = brackets[i];
    const previousLimit = i === 0 ? 0 : brackets[i - 1].limit;

    if (safeBase <= bracket.limit) {
      return round2(bracket.base + (safeBase - previousLimit) * bracket.rate);
    }
  }

  return 0;
}

function getMonthlyGrosses(params: PayrollParams) {
  return Array.from({ length: 12 }, (_, index) => round2(index < 6 ? params.firstSixSalary : params.secondSixSalary));
}

function calculateFromMonthlyGrosses(monthlyGrosses: number[], params: PayrollParams, mode: PayrollMode = "grossToNet"): PayrollRow[] {
  let cumulativeBase = 0;
  let minimumWageCumulativeBase = 0;

  return monthlyGrosses.map((inputGross, index) => {
    const gross = round2(inputGross);
    const sgkCap = params.sgkCaps[index] ?? params.sgkCaps[params.sgkCaps.length - 1] ?? 0;
    const sgkBase = Math.min(gross, sgkCap);

    const employeeSgkRate = mode === "sgdp" ? params.sgdpEmployee : params.sgkEmployee;
    const employeeSgk = round2(sgkBase * employeeSgkRate);
    const employeeUnemployment = mode === "sgdp" ? 0 : round2(sgkBase * params.unemploymentEmployee);
    const incomeTaxBase = round2(gross - employeeSgk - employeeUnemployment);

    const previousCumulativeBase = cumulativeBase;
    cumulativeBase = round2(cumulativeBase + incomeTaxBase);

    const cumulativeIncomeTaxNow = totalIncomeTax(cumulativeBase, params.incomeTaxBrackets);
    const cumulativeIncomeTaxPrev = totalIncomeTax(previousCumulativeBase, params.incomeTaxBrackets);
    const incomeTax = round2(cumulativeIncomeTaxNow - cumulativeIncomeTaxPrev);

    const minimumWageIncomeTaxBase = round2(params.minimumWageTaxBase[index] ?? 0);
    const previousMinimumWageCumulativeBase = minimumWageCumulativeBase;
    minimumWageCumulativeBase = round2(minimumWageCumulativeBase + minimumWageIncomeTaxBase);

    const minimumWageIncomeTaxNow = totalIncomeTax(minimumWageCumulativeBase, params.incomeTaxBrackets);
    const minimumWageIncomeTaxPrev = totalIncomeTax(previousMinimumWageCumulativeBase, params.incomeTaxBrackets);
    const minimumWageIncomeTax = round2(minimumWageIncomeTaxNow - minimumWageIncomeTaxPrev);

    const deductedIncomeTax = round2(Math.max(0, incomeTax - minimumWageIncomeTax));
    const grossStampTax = round2(gross * params.stampTax);
    const minimumWageStampExemption = round2(params.minimumWageStampExemption[index] ?? 0);
    const stampTax = round2(Math.max(0, grossStampTax - minimumWageStampExemption));
    const net = round2(gross - employeeSgk - employeeUnemployment - deductedIncomeTax - stampTax);

    const employerSgkRate = mode === "sgdp" ? params.sgdpEmployer : params.sgkEmployer;
    const employerSgk = round2(sgkBase * employerSgkRate);
    const employerUnemployment = mode === "sgdp" ? 0 : round2(sgkBase * params.unemploymentEmployer);
    const totalCost = round2(gross + employerSgk + employerUnemployment);

    return {
      month: index + 1,
      gross,
      employeeSgk,
      employeeUnemployment,
      incomeTaxBase,
      cumulativeBase,
      incomeTax,
      minimumWageIncomeTaxBase,
      minimumWageCumulativeBase,
      minimumWageIncomeTax,
      deductedIncomeTax,
      grossStampTax,
      minimumWageStampExemption,
      stampTax,
      net,
      employerSgk,
      employerUnemployment,
      totalCost,
    };
  });
}

function calculateGrossToNet(params: PayrollParams, mode: PayrollMode = "grossToNet") {
  return calculateFromMonthlyGrosses(getMonthlyGrosses(params), params, mode);
}

function solveBlockGrossForTargetNet(
  targetNet: number,
  params: PayrollParams,
  block: "firstSix" | "secondSix",
  mode: PayrollMode = "grossToNet"
) {
  let low = 0;
  let high = Math.max(targetNet * 4, 100000);

  for (let i = 0; i < 100; i += 1) {
    const candidateGross = round2((low + high) / 2);
    const scenarioParams: PayrollParams = {
      ...params,
      firstSixSalary: block === "firstSix" ? candidateGross : params.firstSixSalary,
      secondSixSalary: block === "secondSix" ? candidateGross : params.secondSixSalary,
    };

    const rows = calculateGrossToNet(scenarioParams, mode);
    const probeNet = block === "firstSix" ? rows[0].net : rows[6].net;

    if (probeNet < targetNet) {
      low = candidateGross;
    } else {
      high = candidateGross;
    }
  }

  return round2(high);
}

function calculateNetToGross(targetFirstSixNet: number, targetSecondSixNet: number, params: PayrollParams) {
  const firstSixGross = solveBlockGrossForTargetNet(targetFirstSixNet, params, "firstSix", "grossToNet");

  const secondPassParams: PayrollParams = {
    ...params,
    firstSixSalary: firstSixGross,
  };

  const secondSixGross = solveBlockGrossForTargetNet(targetSecondSixNet, secondPassParams, "secondSix", "grossToNet");

  const netParams: PayrollParams = {
    ...params,
    firstSixSalary: firstSixGross,
    secondSixSalary: secondSixGross,
  };

  return {
    solvedFirstSixGross: firstSixGross,
    solvedSecondSixGross: secondSixGross,
    rows: calculateGrossToNet(netParams, "grossToNet"),
  };
}

function sumRows(rows: PayrollRow[], selector: (row: PayrollRow) => number) {
  return round2(rows.reduce((total, row) => total + selector(row), 0));
}

function assertApprox(actual: number, expected: number, message: string, tolerance = 0.02) {
  if (!approxEqual(actual, expected, tolerance)) {
    throw new Error(`${message} Beklenen: ${expected}, Gelen: ${actual}`);
  }
}

function runSanityChecks() {
  const defaultParams = getDefaultParams();
  const rows = calculateGrossToNet(defaultParams, "grossToNet");

  if (rows.length !== 12) throw new Error("Beklenen 12 aylık tablo oluşmadı.");
  if (rows[0].gross !== 500000 || rows[11].gross !== 500000) throw new Error("6 aylık ücret dağılımı hatalı.");

  assertApprox(rows[0].employeeSgk, 41617.8, "1. ay SSK işçi primi beklenen değerle uyuşmuyor.");
  assertApprox(rows[0].employeeUnemployment, 2972.7, "1. ay işsizlik işçi primi beklenen değerle uyuşmuyor.");
  assertApprox(rows[0].incomeTaxBase, 455409.5, "1. ay GV matrahı beklenen değerle uyuşmuyor.");
  assertApprox(rows[0].incomeTax, 85460.57, "1. ay gelir vergisi beklenen değerle uyuşmuyor.");
  assertApprox(rows[0].minimumWageIncomeTax, 4211.33, "1. ay asgari ücret GV beklenen değerle uyuşmuyor.");
  assertApprox(rows[0].deductedIncomeTax, 81249.24, "1. ay kesilecek GV beklenen değerle uyuşmuyor.");
  assertApprox(rows[0].stampTax, 3544.3, "1. ay net damga vergisi beklenen değerle uyuşmuyor.");
  assertApprox(rows[0].net, 370615.96, "1. ay net ücret hesaplaması beklenen değerden sapıyor.");
  assertApprox(rows[6].net, 297009.62, "7. ay net ücret beklenen değerle uyuşmuyor.");
  assertApprox(rows[11].net, 289841.27, "12. ay net ücret beklenen değerle uyuşmuyor.");

  const totals = {
    gross: sumRows(rows, (row) => row.gross),
    deductedIncomeTax: sumRows(rows, (row) => row.deductedIncomeTax),
    stampTax: sumRows(rows, (row) => row.stampTax),
    net: sumRows(rows, (row) => row.net),
    totalCost: sumRows(rows, (row) => row.totalCost),
  };

  assertApprox(totals.gross, 6000000, "Toplam brüt tutarı beklenen değerle uyuşmuyor.");
  assertApprox(totals.deductedIncomeTax, 1705584.43, "Toplam kesilecek gelir vergisi beklenen değerle uyuşmuyor.", 0.1);
  assertApprox(totals.stampTax, 42531.6, "Toplam damga vergisi beklenen değerle uyuşmuyor.");
  assertApprox(totals.net, 3716797.97, "Toplam net ücret beklenen değerle uyuşmuyor.", 0.1);
  assertApprox(totals.totalCost, 6847219.56, "Toplam maliyet beklenen değerle uyuşmuyor.");

  const netToGross = calculateNetToGross(370615.96, 297009.62, defaultParams);
  assertApprox(netToGross.rows[0].net, 370615.96, "Netten Brüte 1. ay net sonucu uyuşmuyor.", 0.5);
  assertApprox(netToGross.rows[6].net, 297009.62, "Netten Brüte 7. ay net sonucu uyuşmuyor.", 0.5);
  assertApprox(netToGross.rows[0].gross, 500000, "Netten Brüte 1. ay brüt sonucu uyuşmuyor.", 1);
  assertApprox(netToGross.rows[6].gross, 500000, "Netten Brüte 7. ay brüt sonucu uyuşmuyor.", 1);

  const sgdpRows = calculateGrossToNet(defaultParams, "sgdp");
  if (sgdpRows[0].employeeUnemployment !== 0) {
    throw new Error("SGDP senaryosunda işsizlik işçi primi sıfır olmalı.");
  }
  if (sgdpRows[0].employerUnemployment !== 0) {
    throw new Error("SGDP senaryosunda işsizlik işveren primi sıfır olmalı.");
  }
  if (sgdpRows[0].employeeSgk <= 0 || sgdpRows[0].employerSgk <= 0) {
    throw new Error("SGDP senaryosunda SGDP primleri hesaplanmalı.");
  }
  if (sgdpRows[0].net <= rows[0].net) {
    throw new Error("SGDP senaryosunda ilk ay net ücret normal senaryodan yüksek olmalı.");
  }
}

function SummaryCards({ rows }: { rows: PayrollRow[] }) {
  const totals = useMemo(
    () => ({
      gross: sumRows(rows, (row) => row.gross),
      net: sumRows(rows, (row) => row.net),
      tax: sumRows(rows, (row) => row.deductedIncomeTax + row.stampTax),
      deductions: sumRows(rows, (row) => row.employeeSgk + row.employeeUnemployment),
    }),
    [rows]
  );

  return (
    <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
      <Card className="rounded-2xl border-slate-200 shadow-sm">
        <CardContent className="p-5">
          <div className="flex items-center justify-between">
            <span className="text-sm text-slate-500">Toplam Brüt</span>
            <Landmark className="h-4 w-4 text-slate-400" />
          </div>
          <div className="mt-3 text-2xl font-semibold text-slate-900">{currency(totals.gross)}</div>
        </CardContent>
      </Card>
      <Card className="rounded-2xl border-slate-200 shadow-sm">
        <CardContent className="p-5">
          <div className="flex items-center justify-between">
            <span className="text-sm text-slate-500">Toplam Net</span>
            <TrendingUp className="h-4 w-4 text-slate-400" />
          </div>
          <div className="mt-3 text-2xl font-semibold text-slate-900">{currency(totals.net)}</div>
        </CardContent>
      </Card>
      <Card className="rounded-2xl border-slate-200 shadow-sm">
        <CardContent className="p-5">
          <div className="flex items-center justify-between">
            <span className="text-sm text-slate-500">Vergi Toplamı</span>
            <Calculator className="h-4 w-4 text-slate-400" />
          </div>
          <div className="mt-3 text-2xl font-semibold text-slate-900">{currency(totals.tax)}</div>
        </CardContent>
      </Card>
      <Card className="rounded-2xl border-slate-200 shadow-sm">
        <CardContent className="p-5">
          <div className="flex items-center justify-between">
            <span className="text-sm text-slate-500">Prim Kesintileri</span>
            <ShieldCheck className="h-4 w-4 text-slate-400" />
          </div>
          <div className="mt-3 text-2xl font-semibold text-slate-900">{currency(totals.deductions)}</div>
        </CardContent>
      </Card>
    </div>
  );
}

function PayrollTable({ rows, modeLabel }: { rows: PayrollRow[]; modeLabel: string }) {
  const totals = {
    gross: sumRows(rows, (row) => row.gross),
    employeeSgk: sumRows(rows, (row) => row.employeeSgk),
    employeeUnemployment: sumRows(rows, (row) => row.employeeUnemployment),
    incomeTaxBase: rows[rows.length - 1]?.cumulativeBase ?? 0,
    incomeTax: sumRows(rows, (row) => row.incomeTax),
    minimumWageCumulativeBase: rows[rows.length - 1]?.minimumWageCumulativeBase ?? 0,
    minimumWageIncomeTax: sumRows(rows, (row) => row.minimumWageIncomeTax),
    deductedIncomeTax: sumRows(rows, (row) => row.deductedIncomeTax),
    grossStampTax: sumRows(rows, (row) => row.grossStampTax),
    minimumWageStampExemption: sumRows(rows, (row) => row.minimumWageStampExemption),
    stampTax: sumRows(rows, (row) => row.stampTax),
    net: sumRows(rows, (row) => row.net),
    employerSgk: sumRows(rows, (row) => row.employerSgk),
    employerUnemployment: sumRows(rows, (row) => row.employerUnemployment),
    totalCost: sumRows(rows, (row) => row.totalCost),
  };

  return (
    <div className="overflow-x-auto rounded-2xl border border-slate-200 bg-white">
      <div className="border-b border-slate-200 px-4 py-3 text-sm font-medium text-slate-600">{modeLabel}</div>
      <Table>
        <TableHeader>
          <TableRow className="bg-slate-50 hover:bg-slate-50">
            <TableHead>Ay</TableHead>
            <TableHead className="text-right">Brüt Maaş</TableHead>
            <TableHead className="text-right">Çalışan Primi</TableHead>
            <TableHead className="text-right">İşsizlik İşçi</TableHead>
            <TableHead className="text-right">GV Matrahı</TableHead>
            <TableHead className="text-right">Kümüle GV</TableHead>
            <TableHead className="text-right">Gelir Vergisi</TableHead>
            <TableHead className="text-right">Asg. Üc. GV Matrahı</TableHead>
            <TableHead className="text-right">Asg. Üc. Küm. Matrah</TableHead>
            <TableHead className="text-right">Asgari Ücret GV</TableHead>
            <TableHead className="text-right">Kesilecek GV</TableHead>
            <TableHead className="text-right">Brüt Damga V.</TableHead>
            <TableHead className="text-right">Asg. Üc. Damga İst.</TableHead>
            <TableHead className="text-right">Damga Vergisi</TableHead>
            <TableHead className="text-right">Net Ücret</TableHead>
            <TableHead className="text-right">İşveren Primi</TableHead>
            <TableHead className="text-right">İşsizlik İşveren</TableHead>
            <TableHead className="text-right">Toplam Maliyet</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {rows.map((row) => (
            <TableRow key={row.month}>
              <TableCell className="font-medium">{row.month}</TableCell>
              <TableCell className="text-right">{currency(row.gross)}</TableCell>
              <TableCell className="text-right">{currency(row.employeeSgk)}</TableCell>
              <TableCell className="text-right">{currency(row.employeeUnemployment)}</TableCell>
              <TableCell className="text-right">{currency(row.incomeTaxBase)}</TableCell>
              <TableCell className="text-right">{currency(row.cumulativeBase)}</TableCell>
              <TableCell className="text-right">{currency(row.incomeTax)}</TableCell>
              <TableCell className="text-right">{currency(row.minimumWageIncomeTaxBase)}</TableCell>
              <TableCell className="text-right">{currency(row.minimumWageCumulativeBase)}</TableCell>
              <TableCell className="text-right">{currency(row.minimumWageIncomeTax)}</TableCell>
              <TableCell className="text-right">{currency(row.deductedIncomeTax)}</TableCell>
              <TableCell className="text-right">{currency(row.grossStampTax)}</TableCell>
              <TableCell className="text-right">{currency(row.minimumWageStampExemption)}</TableCell>
              <TableCell className="text-right">{currency(row.stampTax)}</TableCell>
              <TableCell className="text-right font-semibold text-slate-900">{currency(row.net)}</TableCell>
              <TableCell className="text-right">{currency(row.employerSgk)}</TableCell>
              <TableCell className="text-right">{currency(row.employerUnemployment)}</TableCell>
              <TableCell className="text-right">{currency(row.totalCost)}</TableCell>
            </TableRow>
          ))}
          <TableRow className="bg-slate-50 font-semibold hover:bg-slate-50">
            <TableCell>TOPLAM</TableCell>
            <TableCell className="text-right">{currency(totals.gross)}</TableCell>
            <TableCell className="text-right">{currency(totals.employeeSgk)}</TableCell>
            <TableCell className="text-right">{currency(totals.employeeUnemployment)}</TableCell>
            <TableCell className="text-right">{currency(totals.incomeTaxBase)}</TableCell>
            <TableCell className="text-right">-</TableCell>
            <TableCell className="text-right">{currency(totals.incomeTax)}</TableCell>
            <TableCell className="text-right">-</TableCell>
            <TableCell className="text-right">{currency(totals.minimumWageCumulativeBase)}</TableCell>
            <TableCell className="text-right">{currency(totals.minimumWageIncomeTax)}</TableCell>
            <TableCell className="text-right">{currency(totals.deductedIncomeTax)}</TableCell>
            <TableCell className="text-right">{currency(totals.grossStampTax)}</TableCell>
            <TableCell className="text-right">{currency(totals.minimumWageStampExemption)}</TableCell>
            <TableCell className="text-right">{currency(totals.stampTax)}</TableCell>
            <TableCell className="text-right">{currency(totals.net)}</TableCell>
            <TableCell className="text-right">{currency(totals.employerSgk)}</TableCell>
            <TableCell className="text-right">{currency(totals.employerUnemployment)}</TableCell>
            <TableCell className="text-right">{currency(totals.totalCost)}</TableCell>
          </TableRow>
        </TableBody>
      </Table>
    </div>
  );
}

function ParamPanel({
  params,
  setParams,
}: {
  params: PayrollParams;
  setParams: React.Dispatch<React.SetStateAction<PayrollParams>>;
}) {
  const updateScalar = (key: keyof PayrollParams, value: number) => {
    setParams((prev) => ({ ...prev, [key]: value }));
  };

  const updateCap = (index: number, value: number) => {
    setParams((prev) => ({
      ...prev,
      sgkCaps: prev.sgkCaps.map((cap, i) => (i === index ? value : cap)),
    }));
  };

  const updateMinimumWageTaxBase = (index: number, value: number) => {
    setParams((prev) => ({
      ...prev,
      minimumWageTaxBase: prev.minimumWageTaxBase.map((item, i) => (i === index ? value : item)),
    }));
  };

  const updateMinimumWageStampExemption = (index: number, value: number) => {
    setParams((prev) => ({
      ...prev,
      minimumWageStampExemption: prev.minimumWageStampExemption.map((item, i) => (i === index ? value : item)),
    }));
  };

  return (
    <Card className="rounded-3xl border-slate-200 bg-white shadow-sm">
      <CardHeader>
        <CardTitle className="text-lg">Parametreler</CardTitle>
        <CardDescription>Excel parametreleri, Netten Brüte ve SGDP için ortak kullanılır.</CardDescription>
      </CardHeader>
      <CardContent className="grid gap-4">
        <div className="grid gap-2">
          <Label>İlk 6 Aylık Ücret / Hedef</Label>
          <Input type="number" value={params.firstSixSalary} onChange={(e) => updateScalar("firstSixSalary", Number(e.target.value))} />
        </div>
        <div className="grid gap-2">
          <Label>İkinci 6 Aylık Ücret / Hedef</Label>
          <Input type="number" value={params.secondSixSalary} onChange={(e) => updateScalar("secondSixSalary", Number(e.target.value))} />
        </div>
        <div className="grid gap-2">
          <Label>SSK İşçi Primi</Label>
          <Input type="number" step="0.0001" value={params.sgkEmployee} onChange={(e) => updateScalar("sgkEmployee", Number(e.target.value))} />
          <p className="text-xs text-slate-500">{percent(params.sgkEmployee)}</p>
        </div>
        <div className="grid gap-2">
          <Label>İşsizlik İşçi Primi</Label>
          <Input type="number" step="0.0001" value={params.unemploymentEmployee} onChange={(e) => updateScalar("unemploymentEmployee", Number(e.target.value))} />
          <p className="text-xs text-slate-500">{percent(params.unemploymentEmployee)}</p>
        </div>
        <div className="grid gap-2">
          <Label>SGDP İşçi Primi</Label>
          <Input type="number" step="0.0001" value={params.sgdpEmployee} onChange={(e) => updateScalar("sgdpEmployee", Number(e.target.value))} />
          <p className="text-xs text-slate-500">{percent(params.sgdpEmployee)}</p>
        </div>
        <div className="grid gap-2">
          <Label>Damga Vergisi</Label>
          <Input type="number" step="0.00001" value={params.stampTax} onChange={(e) => updateScalar("stampTax", Number(e.target.value))} />
          <p className="text-xs text-slate-500">{percent(params.stampTax)}</p>
        </div>
        <div className="grid gap-2">
          <Label>SSK İşveren Primi</Label>
          <Input type="number" step="0.0001" value={params.sgkEmployer} onChange={(e) => updateScalar("sgkEmployer", Number(e.target.value))} />
          <p className="text-xs text-slate-500">{percent(params.sgkEmployer)}</p>
        </div>
        <div className="grid gap-2">
          <Label>İşsizlik İşveren Primi</Label>
          <Input type="number" step="0.0001" value={params.unemploymentEmployer} onChange={(e) => updateScalar("unemploymentEmployer", Number(e.target.value))} />
          <p className="text-xs text-slate-500">{percent(params.unemploymentEmployer)}</p>
        </div>
        <div className="grid gap-2">
          <Label>SGDP İşveren Primi</Label>
          <Input type="number" step="0.0001" value={params.sgdpEmployer} onChange={(e) => updateScalar("sgdpEmployer", Number(e.target.value))} />
          <p className="text-xs text-slate-500">{percent(params.sgdpEmployer)}</p>
        </div>
        <Separator />
        <div className="grid gap-3">
          <Label>SSK Tavanları</Label>
          <div className="grid grid-cols-2 gap-2">
            {params.sgkCaps.map((cap, index) => (
              <div key={`cap-${index}`} className="grid gap-1">
                <Label className="text-xs text-slate-500">{index + 1}. Ay</Label>
                <Input type="number" value={cap} onChange={(e) => updateCap(index, Number(e.target.value))} />
              </div>
            ))}
          </div>
        </div>
        <Separator />
        <div className="grid gap-3">
          <Label>Asgari Ücret GV Matrahı</Label>
          <div className="grid grid-cols-2 gap-2">
            {params.minimumWageTaxBase.map((value, index) => (
              <div key={`gv-${index}`} className="grid gap-1">
                <Label className="text-xs text-slate-500">{index + 1}. Ay</Label>
                <Input type="number" value={value} onChange={(e) => updateMinimumWageTaxBase(index, Number(e.target.value))} />
              </div>
            ))}
          </div>
        </div>
        <Separator />
        <div className="grid gap-3">
          <Label>Asgari Ücret Damga İstisnası</Label>
          <div className="grid grid-cols-2 gap-2">
            {params.minimumWageStampExemption.map((value, index) => (
              <div key={`stamp-${index}`} className="grid gap-1">
                <Label className="text-xs text-slate-500">{index + 1}. Ay</Label>
                <Input type="number" value={value} onChange={(e) => updateMinimumWageStampExemption(index, Number(e.target.value))} />
              </div>
            ))}
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

export default function CorporatePayrollCalculator() {
  const [params, setParams] = useState<PayrollParams>(getDefaultParams());
  const [showParams, setShowParams] = useState(false);

  const grossToNetRows = useMemo(() => calculateGrossToNet(params, "grossToNet"), [params]);
  const sgdpRows = useMemo(() => calculateGrossToNet(params, "sgdp"), [params]);
  const netToGrossResult = useMemo(() => calculateNetToGross(params.firstSixSalary, params.secondSixSalary, params), [params]);

  return (
    <div className="min-h-screen bg-slate-100">
      <div className="mx-auto max-w-7xl px-4 py-8 md:px-6 lg:px-8">
        <div className="mb-8 grid gap-6 lg:grid-cols-[1.4fr_0.8fr]">
          <Card className="rounded-3xl border-slate-200 bg-white shadow-sm">
            <CardHeader className="pb-4">
              <div className="flex flex-wrap items-center gap-3">
                <Badge className="rounded-full bg-slate-900 px-3 py-1 text-white hover:bg-slate-900">Kurumsal Ücret Hesaplama</Badge>
                <Badge variant="outline" className="rounded-full">React Arayüz</Badge>
              </div>
              <CardTitle className="mt-3 text-3xl font-semibold tracking-tight text-slate-950">
                Brütten Nete, Netten Brüte ve SGDP Hesaplama
              </CardTitle>
              <CardDescription className="max-w-3xl text-base leading-6 text-slate-600">
                Excel dosyasındaki parametre alanlarını giriş olarak kullanır. Aynı hesap çekirdeği ile üç ayrı senaryo üretilir.
              </CardDescription>
            </CardHeader>
          </Card>

          {showParams && <ParamPanel params={params} setParams={setParams} />}
        </div>

        <Tabs defaultValue="grossToNet" className="space-y-6">
          <TabsList className="grid w-full grid-cols-3 rounded-2xl bg-white p-1 shadow-sm">
            <TabsTrigger value="grossToNet">Brütten Nete</TabsTrigger>
            <TabsTrigger value="netToGross">Netten Brüte</TabsTrigger>
            <TabsTrigger value="sgdp">SGDP</TabsTrigger>
          </TabsList>

          <TabsContent value="grossToNet" className="space-y-6">
            <SummaryCards rows={grossToNetRows} />
            <PayrollTable rows={grossToNetRows} modeLabel="Brütten Nete" />
          </TabsContent>

          <TabsContent value="netToGross" className="space-y-6">
            <Card className="rounded-2xl border-slate-200 bg-white shadow-sm">
              <CardContent className="grid gap-4 p-5 md:grid-cols-2">
                <div>
                  <div className="text-sm text-slate-500">Hedef Net (İlk 6 Ay)</div>
                  <div className="mt-1 text-2xl font-semibold text-slate-900">{currency(params.firstSixSalary)}</div>
                  <div className="mt-3 text-sm text-slate-500">Çözülen Brüt</div>
                  <div className="mt-1 text-xl font-semibold text-slate-900">{currency(netToGrossResult.solvedFirstSixGross)}</div>
                </div>
                <div>
                  <div className="text-sm text-slate-500">Hedef Net (İkinci 6 Ay)</div>
                  <div className="mt-1 text-2xl font-semibold text-slate-900">{currency(params.secondSixSalary)}</div>
                  <div className="mt-3 text-sm text-slate-500">Çözülen Brüt</div>
                  <div className="mt-1 text-xl font-semibold text-slate-900">{currency(netToGrossResult.solvedSecondSixGross)}</div>
                </div>
              </CardContent>
            </Card>
            <SummaryCards rows={netToGrossResult.rows} />
            <PayrollTable rows={netToGrossResult.rows} modeLabel="Netten Brüte" />
          </TabsContent>

          <TabsContent value="sgdp" className="space-y-6">
            <SummaryCards rows={sgdpRows} />
            <PayrollTable rows={sgdpRows} modeLabel="Brütten Nete (SGDP)" />
          </TabsContent>
        </Tabs>

        <Separator className="my-8" />

        <Card className="rounded-3xl border-slate-200 bg-white shadow-sm">
          <CardHeader>
            <CardTitle>Formül Mantığı</CardTitle>
            <CardDescription>Excel formüllerinin React / TypeScript karşılığı</CardDescription>
          </CardHeader>
          <CardContent className="grid gap-4 text-sm leading-6 text-slate-700 md:grid-cols-3">
            <div className="rounded-2xl bg-slate-50 p-4">
              <div className="font-semibold text-slate-900">Brütten Nete</div>
              <div>SGK Matrahı = min(Brüt, Aylık SSK Tavanı)</div>
              <div>Çalışan Kesintileri = SSK + İşsizlik</div>
              <div>Aylık Gelir Vergisi = Kümülatif Vergi farkı</div>
              <div>Net = Brüt − Kesintiler − Vergiler</div>
            </div>
            <div className="rounded-2xl bg-slate-50 p-4">
              <div className="font-semibold text-slate-900">Netten Brüte</div>
              <div>İlk 6 ay brütü, 1. ay hedef nete göre çözülür.</div>
              <div>İkinci 6 ay brütü, ilk 6 ay kümülatif etkisi korunarak 7. ay hedef nete göre çözülür.</div>
              <div>Böylece 7. ay neti gerçek vergi akışıyla eşleşir.</div>
            </div>
            <div className="rounded-2xl bg-slate-50 p-4">
              <div className="font-semibold text-slate-900">SGDP</div>
              <div>İşsizlik işçi ve işveren primi uygulanmaz.</div>
              <div>Çalışan ve işveren primi SGDP oranlarıyla hesaplanır.</div>
              <div>Gelir vergisi ve damga vergisi akışı korunur.</div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}

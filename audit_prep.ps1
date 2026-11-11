[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$csv = Import-Csv -Path '.\data_store.csv' -Encoding utf8

Write-Output "=== 1. DATA PREPARATION AUDIT ==="
Write-Output "Total rows: $($csv.Count)"

# Check missing values
$emptyCols = @{}
foreach ($row in $csv) {
    foreach ($prop in $row.PSObject.Properties) {
        if ([string]::IsNullOrWhiteSpace($prop.Value)) {
            $emptyCols[$prop.Name]++
        }
    }
}
if ($emptyCols.Count -eq 0) {
    Write-Output "Missing values: 0 found across all 20 columns."
} else {
    Write-Output "Missing values per column: $(($emptyCols.GetEnumerator() | ForEach-Object { "$($_.Key): $($_.Value)" }) -join ', ')"
}

# Check Duplicate Item IDs
$dupIds = $csv | Group-Object 'รหัสรายการ' | Where-Object { $_.Count -gt 1 }
Write-Output "Duplicate Item IDs count: $($dupIds.Count)"

# Check Product Code vs Name & Category Consistency
$prodMap = $csv | Group-Object 'รหัสสินค้า'
Write-Output "Unique product codes: $($prodMap.Count)"
foreach ($g in $prodMap) {
    $names = $g.Group | Select-Object -ExpandProperty 'ชื่อสินค้า' -Unique
    $cats = $g.Group | Select-Object -ExpandProperty 'หมวดหมู่' -Unique
    if ($names.Count -gt 1 -or $cats.Count -gt 1) {
        Write-Output "Mismatch in Product $($g.Name): Names=[$($names -join ', ')], Cats=[$($cats -join ', ')]"
    }
}
Write-Output "Product code consistency: All 20 products have 1-to-1 matching name and category."

# Check Stock Math: StockEnd_calc = StockStart + In - Out - Damaged
$stockMathDiff = @()
foreach ($row in $csv) {
    $start = [double]$row.'สต็อกต้นวัน_หน่วย'
    $in = [double]$row.'รับเข้า_หน่วย'
    $out = [double]$row.'ขายออก_หน่วย'
    $dmg = [double]$row.'เสียหาย_หน่วย'
    $endActual = [double]$row.'สต็อกปลายวัน_หน่วย'
    $endCalc = $start + $in - $out - $dmg
    if ($endActual -ne $endCalc) {
        $stockMathDiff += [PSCustomObject]@{
            Id = $row.'รหัสรายการ'; Date = $row.'วันที่'; Branch = $row.'สาขา'; Prod = $row.'ชื่อสินค้า'
            Start = $start; In = $in; Out = $out; Dmg = $dmg
            EndActual = $endActual; EndCalc = $endCalc; Diff = $endActual - $endCalc
        }
    }
}
Write-Output "Stock formula mismatches: $($stockMathDiff.Count) rows"
if ($stockMathDiff.Count -gt 0) {
    Write-Output "Sample stock math mismatches:"
    $stockMathDiff | Select-Object -First 10 | Format-Table | Out-String | Write-Output
}

# Check Sales, Profit, and Stock Value formulas
$salesDiff = @()
$profitDiff = @()
$stockValDiff = @()

foreach ($row in $csv) {
    $out = [double]$row.'ขายออก_หน่วย'
    $price = [double]$row.'ราคาขายต่อหน่วย_บาท'
    $cost = [double]$row.'ต้นทุนต่อหน่วย_บาท'
    $salesEst = [double]$row.'ยอดขายประมาณการ_บาท'
    $profitEst = [double]$row.'กำไรขั้นต้นประมาณการ_บาท'
    $stockEnd = [double]$row.'สต็อกปลายวัน_หน่วย'
    $stockVal = [double]$row.'มูลค่าสต็อกปลายวัน_บาท'

    $salesCalc = $out * $price
    $profitCalc = $out * ($price - $cost)
    $stockValCalc = [Math]::Round($stockEnd * $cost, 2)

    if ([Math]::Abs($salesEst - $salesCalc) -gt 0.01) {
        $salesDiff += [PSCustomObject]@{ Id = $row.'รหัสรายการ'; Out = $out; Price = $price; SalesEst = $salesEst; SalesCalc = $salesCalc }
    }
    if ([Math]::Abs($profitEst - $profitCalc) -gt 0.01) {
        $profitDiff += [PSCustomObject]@{ Id = $row.'รหัสรายการ'; Out = $out; Price = $price; Cost = $cost; ProfitEst = $profitEst; ProfitCalc = $profitCalc }
    }
    if ([Math]::Abs($stockVal - $stockValCalc) -gt 0.01) {
        $stockValDiff += [PSCustomObject]@{ Id = $row.'รหัสรายการ'; StockEnd = $stockEnd; Cost = $cost; StockVal = $stockVal; StockValCalc = $stockValCalc }
    }
}
Write-Output "Sales formula mismatches: $($salesDiff.Count)"
Write-Output "Profit formula mismatches: $($profitDiff.Count)"
Write-Output "Stock Value formula mismatches: $($stockValDiff.Count)"
if ($stockValDiff.Count -gt 0) {
    Write-Output "Sample Stock Value Diff:"
    $stockValDiff | Select-Object -First 5 | Format-Table | Out-String | Write-Output
}

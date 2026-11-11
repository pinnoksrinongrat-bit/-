[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$csv = Import-Csv -Path '.\data_store.csv' -Encoding utf8

Write-Output "=== 2. KPI SUMMARY (ภาพรวมร้านค้า) ==="

# Overall Cumulative Metrics
$totalSales = 0
$totalProfit = 0
$totalQtySold = 0
$totalDamaged = 0

foreach ($r in $csv) {
    $totalSales += [double]$r.'ยอดขายประมาณการ_บาท'
    $totalProfit += [double]$r.'กำไรขั้นต้นประมาณการ_บาท'
    $totalQtySold += [double]$r.'ขายออก_หน่วย'
    $totalDamaged += [double]$r.'เสียหาย_หน่วย'
}

$gpMargin = ($totalProfit / $totalSales) * 100

Write-Output "1. ยอดขายรวม (บาท): $($totalSales.ToString('N2'))"
Write-Output "2. กำไรขั้นต้นรวม (บาท): $($totalProfit.ToString('N2'))"
Write-Output "3. อัตรากำไรขั้นต้น (%): $($gpMargin.ToString('N2'))%"
Write-Output "4. จำนวนขายรวม (หน่วย): $($totalQtySold.ToString('N0'))"
Write-Output "5. จำนวนสินค้าเสียหาย (หน่วย): $($totalDamaged.ToString('N0'))"

# Snapshot of Inventory (Latest record per Branch + Product)
# Note: "ชุดข้อมูลมีบันทึกหลายวันของสินค้าและสาขาเดียวกัน ห้ามนำสต็อกปลายวันหรือมูลค่าสต็อกของทุกวันมาบวกกันเพื่อแทน สต็อกปัจจุบัน ให้เลือกข้อมูลวันที่ล่าสุดของแต่ละคู่ สาขา + รหัสสินค้า ก่อนวิเคราะห์ภาพรวมสต็อก"
$sorted = $csv | Sort-Object { [datetime]$_.'วันที่' }
$latestStockMap = @{}

foreach ($r in $sorted) {
    $key = "$($r.'สาขา')_$($r.'รหัสสินค้า')"
    $latestStockMap[$key] = $r
}

Write-Output "`nTotal Branch-Product pairs: $($latestStockMap.Count)"
$currentStockVal = 0
$currentStockUnits = 0

foreach ($pair in $latestStockMap.Values) {
    $currentStockVal += [double]$pair.'มูลค่าสต็อกปลายวัน_บาท'
    $currentStockUnits += [double]$pair.'สต็อกปลายวัน_หน่วย'
}
Write-Output "6. มูลค่าสต็อกคงเหลือปัจจุบัน (Snapshot ล่าสุด) (บาท): $($currentStockVal.ToString('N2'))"
Write-Output "   จำนวนสต็อกคงเหลือรวม (Snapshot ล่าสุด) (หน่วย): $($currentStockUnits.ToString('N0'))"

# If mistakenly summed all rows:
$naiveSumStockVal = ($csv | Measure-Object -Property 'มูลค่าสต็อกปลายวัน_บาท' -Sum).Sum
Write-Output "   (เปรียบเทียบกับดัก: ถ้าเผลอบวกทุกแถว = $($naiveSumStockVal.ToString('N2')) บาท ซึ่งผิดมหันต์เพราะนับซ้ำ!)"

Write-Output "`n=== 3. BRANCH COMPARISON ==="
$branchGroup = $csv | Group-Object 'สาขา'
foreach ($bg in $branchGroup) {
    $bSales = ($bg.Group | Measure-Object -Property 'ยอดขายประมาณการ_บาท' -Sum).Sum
    $bProfit = ($bg.Group | Measure-Object -Property 'กำไรขั้นต้นประมาณการ_บาท' -Sum).Sum
    $bQty = ($bg.Group | Measure-Object -Property 'ขายออก_หน่วย' -Sum).Sum
    $bDmg = ($bg.Group | Measure-Object -Property 'เสียหาย_หน่วย' -Sum).Sum
    $bMargin = ($bProfit / $bSales) * 100
    
    # Branch latest stock
    $bStockVal = 0
    foreach ($pair in $latestStockMap.Values) {
        if ($pair.'สาขา' -eq $bg.Name) {
            $bStockVal += [double]$pair.'มูลค่าสต็อกปลายวัน_บาท'
        }
    }
    
    Write-Output "สาขา: $($bg.Name)"
    Write-Output "  ยอดขาย: $($bSales.ToString('N2')) บาท | สัดส่วน: $(($bSales/$totalSales*100).ToString('N2'))%"
    Write-Output "  กำไรขั้นต้น: $($bProfit.ToString('N2')) บาท | อัตรากำไร (GP%): $($bMargin.ToString('N2'))%"
    Write-Output "  จำนวนชิ้นที่ขาย: $($bQty.ToString('N0')) หน่วย | สินค้าเสียหาย: $($bDmg.ToString('N0')) หน่วย"
    Write-Output "  มูลค่าสต็อกคงเหลือปัจจุบัน: $($bStockVal.ToString('N2')) บาท"
}

Write-Output "`n=== 3. CATEGORY RANKING ==="
$catGroup = $csv | Group-Object 'หมวดหมู่'
$catSummary = @()
foreach ($cg in $catGroup) {
    $cSales = ($cg.Group | Measure-Object -Property 'ยอดขายประมาณการ_บาท' -Sum).Sum
    $cProfit = ($cg.Group | Measure-Object -Property 'กำไรขั้นต้นประมาณการ_บาท' -Sum).Sum
    $cQty = ($cg.Group | Measure-Object -Property 'ขายออก_หน่วย' -Sum).Sum
    $cDmg = ($cg.Group | Measure-Object -Property 'เสียหาย_หน่วย' -Sum).Sum
    $cMargin = ($cProfit / $cSales) * 100
    $catSummary += [PSCustomObject]@{
        Category = $cg.Name
        Sales = $cSales
        Profit = $cProfit
        Qty = $cQty
        Damaged = $cDmg
        GPMargin = $cMargin
    }
}
Write-Output "Ranked by Sales:"
$catSummary | Sort-Object -Property Sales -Descending | Format-Table -AutoSize | Out-String | Write-Output
Write-Output "Ranked by Profit:"
$catSummary | Sort-Object -Property Profit -Descending | Format-Table -AutoSize | Out-String | Write-Output

Write-Output "`n=== 4. INVENTORY RISK (SNAPSHOT LATEST) ==="
# Status count in Latest Snapshot vs All rows
Write-Output "--- Status in All 1000 records ---"
$csv | Group-Object 'สถานะสต็อก' | Select-Object Name, Count | Format-Table | Out-String | Write-Output

Write-Output "--- Status in 60 Current Snapshot pairs ---"
$latestStockMap.Values | Group-Object 'สถานะสต็อก' | Select-Object Name, Count | Format-Table | Out-String | Write-Output

# Compare StockEnd vs MinOrderPoint in Latest Snapshot
$urgentList = @()
foreach ($pair in $latestStockMap.Values) {
    $end = [double]$pair.'สต็อกปลายวัน_หน่วย'
    $min = [double]$pair.'จุดสั่งซื้อขั้นต่ำ_หน่วย'
    $cost = [double]$pair.'ต้นทุนต่อหน่วย_บาท'
    $val = [double]$pair.'มูลค่าสต็อกปลายวัน_บาท'
    $status = $pair.'สถานะสต็อก'
    $ratio = if ($min -gt 0) { $end / $min } else { 1 }
    
    # Flag check: Does recorded status match actual comparison?
    # Usually: if end <= min -> ต้องสั่งซื้อ / ใกล้หมด
    $urgentList += [PSCustomObject]@{
        Branch = $pair.'สาขา'
        Code = $pair.'รหัสสินค้า'
        Name = $pair.'ชื่อสินค้า'
        Category = $pair.'หมวดหมู่'
        EndStock = $end
        MinPoint = $min
        StockVal = $val
        RecordedStatus = $status
        Ratio = $ratio
        Date = $pair.'วันที่'
    }
}

Write-Output "Top Critical / Stockout Items (Lowest Stock to Min Point Ratio):"
$urgentList | Sort-Object -Property EndStock, Ratio | Select-Object -First 10 | Format-Table -AutoSize | Out-String | Write-Output

Write-Output "`n=== 5. MONTHLY TIME TREND ==="
$monthly = $csv | Group-Object { $_.'วันที่'.Substring(0, 7) } | Sort-Object Name
$monthSummary = @()
foreach ($m in $monthly) {
    $mSales = ($m.Group | Measure-Object -Property 'ยอดขายประมาณการ_บาท' -Sum).Sum
    $mProfit = ($m.Group | Measure-Object -Property 'กำไรขั้นต้นประมาณการ_บาท' -Sum).Sum
    $mQty = ($m.Group | Measure-Object -Property 'ขายออก_หน่วย' -Sum).Sum
    $mMargin = ($mProfit / $mSales) * 100
    $monthSummary += [PSCustomObject]@{
        Month = $m.Name
        Rows = $m.Count
        Sales = $mSales
        Profit = $mProfit
        Margin = $mMargin
        Qty = $mQty
    }
}
$monthSummary | Format-Table -AutoSize | Out-String | Write-Output


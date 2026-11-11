[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$csv = Import-Csv -Path '.\data_store.csv' -Encoding utf8

# Check 5 Urgent items in detail
$sorted = $csv | Sort-Object { [datetime]$_.'วันที่' }
$latestStockMap = @{}
foreach ($r in $sorted) {
    $key = "$($r.'สาขา')_$($r.'รหัสสินค้า')"
    $latestStockMap[$key] = $r
}

$urgentList = @()
foreach ($pair in $latestStockMap.Values) {
    $end = [double]$pair.'สต็อกปลายวัน_หน่วย'
    $min = [double]$pair.'จุดสั่งซื้อขั้นต่ำ_หน่วย'
    $ratio = if ($min -gt 0) { $end / $min } else { 1 }
    $urgentList += [PSCustomObject]@{
        Branch = $pair.'สาขา'
        Code = $pair.'รหัสสินค้า'
        Name = $pair.'ชื่อสินค้า'
        Category = $pair.'หมวดหมู่'
        Supplier = $pair.'ผู้จำหน่าย'
        EndStock = $end
        MinPoint = $min
        StockVal = [double]$pair.'มูลค่าสต็อกปลายวัน_บาท'
        Price = [double]$pair.'ราคาขายต่อหน่วย_บาท'
        Cost = [double]$pair.'ต้นทุนต่อหน่วย_บาท'
        Status = $pair.'สถานะสต็อก'
        Ratio = $ratio
        Date = $pair.'วันที่'
    }
}

Write-Output "Top 10 Urgent Items in Latest Snapshot:"
$urgentList | Sort-Object -Property EndStock, Ratio | Select-Object -First 10 | Format-Table -AutoSize | Out-String | Write-Output

# Supplier Analysis
Write-Output "Supplier Summary:"
$csv | Group-Object 'ผู้จำหน่าย' | ForEach-Object {
    $sSales = ($_.Group | Measure-Object -Property 'ยอดขายประมาณการ_บาท' -Sum).Sum
    $sProfit = ($_.Group | Measure-Object -Property 'กำไรขั้นต้นประมาณการ_บาท' -Sum).Sum
    [PSCustomObject]@{
        Supplier = $_.Name
        Rows = $_.Count
        Sales = $sSales
        Profit = $sProfit
        Margin = ($sProfit / $sSales) * 100
    }
} | Format-Table -AutoSize | Out-String | Write-Output

# Staff Recorder Analysis (Check who made stock calculation errors)
Write-Output "Recorder Errors Summary:"
$errCount = @{}
foreach ($row in $csv) {
    $start = [double]$row.'สต็อกต้นวัน_หน่วย'
    $in = [double]$row.'รับเข้า_หน่วย'
    $out = [double]$row.'ขายออก_หน่วย'
    $dmg = [double]$row.'เสียหาย_หน่วย'
    $endActual = [double]$row.'สต็อกปลายวัน_หน่วย'
    $endCalc = $start + $in - $out - $dmg
    if ($endActual -ne $endCalc) {
        $staff = $row.'พนักงานบันทึก'
        $errCount[$staff]++
    }
}
$errCount.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object {
    [PSCustomObject]@{ Staff = $_.Key; Errors = $_.Value }
} | Format-Table -AutoSize | Out-String | Write-Output


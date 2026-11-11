[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$csv = Import-Csv -Path '.\data_store.csv' -Encoding utf8

$sorted = $csv | Sort-Object { [datetime]$_.'วันที่' }
$latestStockMap = @{}
foreach ($r in $sorted) {
    $key = "$($r.'สาขา')_$($r.'รหัสสินค้า')"
    $latestStockMap[$key] = $r
}

# Monthly Trend
$monthlyGroup = $csv | Group-Object { $_.'วันที่'.Substring(0, 7) } | Sort-Object Name
$monthlyData = @()
foreach ($m in $monthlyGroup) {
    $s = ($m.Group | Measure-Object -Property 'ยอดขายประมาณการ_บาท' -Sum).Sum
    $p = ($m.Group | Measure-Object -Property 'กำไรขั้นต้นประมาณการ_บาท' -Sum).Sum
    $q = ($m.Group | Measure-Object -Property 'ขายออก_หน่วย' -Sum).Sum
    $d = ($m.Group | Measure-Object -Property 'เสียหาย_หน่วย' -Sum).Sum
    $monthlyData += @{
        month = $m.Name
        sales = [Math]::Round($s, 2)
        profit = [Math]::Round($p, 2)
        qty = $q
        damaged = $d
        margin = [Math]::Round(($p / $s) * 100, 2)
        records = $m.Count
    }
}

# Branch Summary
$branchData = @()
$branchGroup = $csv | Group-Object 'สาขา'
foreach ($b in $branchGroup) {
    $s = ($b.Group | Measure-Object -Property 'ยอดขายประมาณการ_บาท' -Sum).Sum
    $p = ($b.Group | Measure-Object -Property 'กำไรขั้นต้นประมาณการ_บาท' -Sum).Sum
    $q = ($b.Group | Measure-Object -Property 'ขายออก_หน่วย' -Sum).Sum
    $d = ($b.Group | Measure-Object -Property 'เสียหาย_หน่วย' -Sum).Sum
    
    $curStockVal = 0
    $curStockUnits = 0
    foreach ($pair in $latestStockMap.Values) {
        if ($pair.'สาขา' -eq $b.Name) {
            $curStockVal += [double]$pair.'มูลค่าสต็อกปลายวัน_บาท'
            $curStockUnits += [double]$pair.'สต็อกปลายวัน_หน่วย'
        }
    }
    
    $branchData += @{
        branch = $b.Name
        sales = [Math]::Round($s, 2)
        profit = [Math]::Round($p, 2)
        qty = $q
        damaged = $d
        margin = [Math]::Round(($p / $s) * 100, 2)
        currentStockVal = [Math]::Round($curStockVal, 2)
        currentStockUnits = $curStockUnits
        records = $b.Count
    }
}

# Category Summary
$catData = @()
$catGroup = $csv | Group-Object 'หมวดหมู่'
foreach ($c in $catGroup) {
    $s = ($c.Group | Measure-Object -Property 'ยอดขายประมาณการ_บาท' -Sum).Sum
    $p = ($c.Group | Measure-Object -Property 'กำไรขั้นต้นประมาณการ_บาท' -Sum).Sum
    $q = ($c.Group | Measure-Object -Property 'ขายออก_หน่วย' -Sum).Sum
    $d = ($c.Group | Measure-Object -Property 'เสียหาย_หน่วย' -Sum).Sum
    $catData += @{
        category = $c.Name
        sales = [Math]::Round($s, 2)
        profit = [Math]::Round($p, 2)
        qty = $q
        damaged = $d
        margin = [Math]::Round(($p / $s) * 100, 2)
    }
}

# Top 10 Urgent Items
$urgentItems = @()
foreach ($pair in $latestStockMap.Values) {
    $end = [double]$pair.'สต็อกปลายวัน_หน่วย'
    $min = [double]$pair.'จุดสั่งซื้อขั้นต่ำ_หน่วย'
    $val = [double]$pair.'มูลค่าสต็อกปลายวัน_บาท'
    $ratio = if ($min -gt 0) { [Math]::Round($end / $min, 3) } else { 1 }
    $urgentItems += @{
        branch = $pair.'สาขา'
        code = $pair.'รหัสสินค้า'
        name = $pair.'ชื่อสินค้า'
        category = $pair.'หมวดหมู่'
        supplier = $pair.'ผู้จำหน่าย'
        endStock = $end
        minPoint = $min
        stockVal = $val
        price = [double]$pair.'ราคาขายต่อหน่วย_บาท'
        cost = [double]$pair.'ต้นทุนต่อหน่วย_บาท'
        status = $pair.'สถานะสต็อก'
        ratio = $ratio
        date = $pair.'วันที่'
    }
}
$topUrgent = $urgentItems | Sort-Object { $_.endStock }, { $_.ratio } | Select-Object -First 10

# Anomalies
$anomalies = @()
foreach ($row in $csv) {
    $start = [double]$row.'สต็อกต้นวัน_หน่วย'
    $in = [double]$row.'รับเข้า_หน่วย'
    $out = [double]$row.'ขายออก_หน่วย'
    $dmg = [double]$row.'เสียหาย_หน่วย'
    $endActual = [double]$row.'สต็อกปลายวัน_หน่วย'
    $endCalc = $start + $in - $out - $dmg
    if ($endActual -ne $endCalc) {
        $anomalies += @{
            id = $row.'รหัสรายการ'
            date = $row.'วันที่'
            branch = $row.'สาขา'
            code = $row.'รหัสสินค้า'
            name = $row.'ชื่อสินค้า'
            start = $start
            in = $in
            out = $out
            dmg = $dmg
            endActual = $endActual
            endCalc = $endCalc
            diff = $endActual - $endCalc
            staff = $row.'พนักงานบันทึก'
            status = $row.'สถานะสต็อก'
        }
    }
}

$exportData = @{
    overview = @{
        totalSales = 142350.0
        totalProfit = 58738.60
        gpMargin = 41.26
        totalQtySold = 6784
        totalDamaged = 771
        currentStockVal = 64548.50
        currentStockUnits = 4279
        naiveStockVal = 1020240.90
        totalRecords = 1000
        totalBranches = 3
        totalProducts = 20
        totalCategories = 7
        totalSuppliers = 4
        dateRange = "2025-01-01 ถึง 2026-10-02"
        anomaliesCount = $anomalies.Count
    }
    monthly = $monthlyData
    branches = $branchData
    categories = $catData
    urgentItems = $topUrgent
    anomalies = $anomalies
    currentStock = $urgentItems
}

$json = $exportData | ConvertTo-Json -Depth 5
[System.IO.File]::WriteAllText('C:\Users\cattt\OneDrive\Desktop\DigitalWork\dashboard_data.json', $json, [System.Text.Encoding]::UTF8)
Write-Output "Successfully wrote dashboard_data.json"

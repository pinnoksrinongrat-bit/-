[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$csv = Import-Csv -Path '.\data_store.csv' -Encoding utf8

$tableRows = @()
foreach ($r in $csv) {
    $start = [double]$r.'สต็อกต้นวัน_หน่วย'
    $in = [double]$r.'รับเข้า_หน่วย'
    $out = [double]$r.'ขายออก_หน่วย'
    $dmg = [double]$r.'เสียหาย_หน่วย'
    $end = [double]$r.'สต็อกปลายวัน_หน่วย'
    $calc = $start + $in - $out - $dmg
    $diff = $end - $calc
    
    $isAnomaly = ($diff -ne 0)
    $anomalyType = ""
    if ($isAnomaly) {
        if ($calc -lt 0 -and $end -eq 0) {
            $anomalyType = "stockout_clip"
        } else {
            $anomalyType = "typo"
        }
    }

    $dateStr = $r.'วันที่'
    $yearStr = $dateStr.Substring(0, 4)
    $monthStr = $dateStr.Substring(0, 7)

    $tableRows += @{
        id = $r.'รหัสรายการ'
        date = $dateStr
        year = $yearStr
        month = $monthStr
        branch = $r.'สาขา'
        code = $r.'รหัสสินค้า'
        name = $r.'ชื่อสินค้า'
        cat = $r.'หมวดหมู่'
        supplier = $r.'ผู้จำหน่าย'
        start = $start
        in = $in
        out = $out
        dmg = $dmg
        end = $end
        calc = $calc
        diff = $diff
        isAnomaly = $isAnomaly
        anomalyType = $anomalyType
        min = [double]$r.'จุดสั่งซื้อขั้นต่ำ_หน่วย'
        price = [double]$r.'ราคาขายต่อหน่วย_บาท'
        cost = [double]$r.'ต้นทุนต่อหน่วย_บาท'
        sales = [double]$r.'ยอดขายประมาณการ_บาท'
        profit = [double]$r.'กำไรขั้นต้นประมาณการ_บาท'
        stockVal = [double]$r.'มูลค่าสต็อกปลายวัน_บาท'
        status = $r.'สถานะสต็อก'
        staff = $r.'พนักงานบันทึก'
    }
}

$tableJson = $tableRows | ConvertTo-Json -Depth 4
[System.IO.File]::WriteAllText('C:\Users\cattt\OneDrive\Desktop\DigitalWork\table_data.json', $tableJson, [System.Text.Encoding]::UTF8)

# Update data.js
$dashJson = [System.IO.File]::ReadAllText('C:\Users\cattt\OneDrive\Desktop\DigitalWork\dashboard_data.json', [System.Text.Encoding]::UTF8)
$jsContent = "window.dashboardData = $dashJson;`nwindow.tableData = $tableJson;"
[System.IO.File]::WriteAllText('C:\Users\cattt\OneDrive\Desktop\DigitalWork\data.js', $jsContent, [System.Text.Encoding]::UTF8)

Write-Output "Updated table_data.json and data.js with rich filter flags!"

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$jsonRaw = [System.IO.File]::ReadAllText('C:\Users\cattt\OneDrive\Desktop\DigitalWork\dashboard_data.json', [System.Text.Encoding]::UTF8)

# Read CSV to get full rows for search table
$csv = Import-Csv -Path '.\data_store.csv' -Encoding utf8
$tableRows = @()
foreach ($r in $csv) {
    $tableRows += @{
        id = $r.'รหัสรายการ'
        date = $r.'วันที่'
        branch = $r.'สาขา'
        code = $r.'รหัสสินค้า'
        name = $r.'ชื่อสินค้า'
        cat = $r.'หมวดหมู่'
        supplier = $r.'ผู้จำหน่าย'
        start = [double]$r.'สต็อกต้นวัน_หน่วย'
        in = [double]$r.'รับเข้า_หน่วย'
        out = [double]$r.'ขายออก_หน่วย'
        dmg = [double]$r.'เสียหาย_หน่วย'
        end = [double]$r.'สต็อกปลายวัน_หน่วย'
        min = [double]$r.'จุดสั่งซื้อขั้นต่ำ_หน่วย'
        price = [double]$r.'ราคาขายต่อหน่วย_บาท'
        cost = [double]$r.'ต้นทุนต่อหน่วย_บาท'
        sales = [double]$r.'ยอดขายประมาณการ_บาท'
        profit = [double]$r.'กำไรขั้นต้นประมาณการ_บาท'
        status = $r.'สถานะสต็อก'
        staff = $r.'พนักงานบันทึก'
    }
}
$tableJson = $tableRows | ConvertTo-Json -Depth 3

# Save compact table json
[System.IO.File]::WriteAllText('C:\Users\cattt\OneDrive\Desktop\DigitalWork\table_data.json', $tableJson, [System.Text.Encoding]::UTF8)
Write-Output "Table data saved, count: $($tableRows.Count)"

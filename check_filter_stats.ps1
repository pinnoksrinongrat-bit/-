[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$csv = Import-Csv -Path '.\data_store.csv' -Encoding utf8

# Check unique values and counts for dropdown labels
Write-Output "--- Branch Counts ---"
$csv | Group-Object 'สาขา' | Select-Object Name, Count

Write-Output "--- Category Counts ---"
$csv | Group-Object 'หมวดหมู่' | Select-Object Name, Count

Write-Output "--- Supplier Counts ---"
$csv | Group-Object 'ผู้จำหน่าย' | Select-Object Name, Count

Write-Output "--- Status Counts ---"
$csv | Group-Object 'สถานะสต็อก' | Select-Object Name, Count

Write-Output "--- Staff Counts ---"
$csv | Group-Object 'พนักงานบันทึก' | Select-Object Name, Count

Write-Output "--- Year Counts ---"
$csv | Group-Object { $_.'วันที่'.Substring(0, 4) } | Select-Object Name, Count

# Check zero stock count
$zeroStock = $csv | Where-Object { [double]$_.'สต็อกปลายวัน_หน่วย' -eq 0 }
Write-Output "--- Zero Stock Rows: $($zeroStock.Count) ---"

# Check damaged > 0
$damagedRows = $csv | Where-Object { [double]$_.'เสียหาย_หน่วย' -gt 0 }
Write-Output "--- Damaged > 0 Rows: $($damagedRows.Count) ---"


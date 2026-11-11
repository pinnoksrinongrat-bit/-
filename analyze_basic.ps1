$csv = Import-Csv -Path '.\data_store.csv' -Encoding utf8
Write-Host "Total rows: $($csv.Count)"

# Check columns
$headers = $csv[0].PSObject.Properties.Name
Write-Host "Columns ($($headers.Count)): $($headers -join ', ')"

# Branches
$branches = $csv | Group-Object สาขา
Write-Host "`n--- Branches ---"
$branches | ForEach-Object { "$($_.Name): $($_.Count) rows" }

# Categories
$cats = $csv | Group-Object หมวดหมู่
Write-Host "`n--- Categories ---"
$cats | ForEach-Object { "$($_.Name): $($_.Count) rows" }

# Date range
$dates = $csv | Select-Object -ExpandProperty วันที่ | Sort-Object
Write-Host "`nDate Range: $($dates[0]) to $($dates[-1])"

# Recorders
$recorders = $csv | Group-Object พนักงานบันทึก
Write-Host "`nRecorders ($($recorders.Count)): $($recorders.Name -join ', ')"

# Products
$prods = $csv | Group-Object รหัสสินค้า
Write-Host "`nProducts count: $($prods.Count)"


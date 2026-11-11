[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$csv = Import-Csv -Path '.\data_store.csv' -Encoding utf8
Write-Output "Total rows: $($csv.Count)"
$branches = $csv | Group-Object สาขา
$branches | ForEach-Object { "$($_.Name): $($_.Count) แถว" }

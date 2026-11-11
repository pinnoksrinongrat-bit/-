[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$dashJson = [System.IO.File]::ReadAllText('C:\Users\cattt\OneDrive\Desktop\DigitalWork\dashboard_data.json', [System.Text.Encoding]::UTF8)
$tableJson = [System.IO.File]::ReadAllText('C:\Users\cattt\OneDrive\Desktop\DigitalWork\table_data.json', [System.Text.Encoding]::UTF8)

$jsContent = "window.dashboardData = $dashJson;`nwindow.tableData = $tableJson;"
[System.IO.File]::WriteAllText('C:\Users\cattt\OneDrive\Desktop\DigitalWork\data.js', $jsContent, [System.Text.Encoding]::UTF8)
Write-Output "Successfully wrote data.js ($($jsContent.Length) bytes)"

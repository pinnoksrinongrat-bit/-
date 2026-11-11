[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Let's inspect index.html total lines
$lines = Get-Content 'C:\Users\cattt\OneDrive\Desktop\DigitalWork\index.html' -Encoding utf8
Write-Output "Total lines in index.html: $($lines.Count)"

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$html = [System.IO.File]::ReadAllText('C:\Users\cattt\OneDrive\Desktop\DigitalWork\index.html', [System.Text.Encoding]::UTF8)

# Check if file reads fine
Write-Output "Current HTML length: $($html.Length)"

Clear-Host

$serversPath = "C:\temp\Patching\Scripts"
$kbBasePath  = "C:\temp\Patching\KBs"

# Pobieramy wszystkie pliki servers_GroupX.txt
$serverFiles = Get-ChildItem -Path $serversPath -Filter "servers_*.txt"

foreach ($file in $serverFiles) {
    # Wyciagamy nazwe grupy z pliku, np. "Group1"
    $groupName = ($file.BaseName -split "_")[1]

    # Budujemy sciezke do folderu z KB
    $kbPath = Join-Path $kbBasePath $groupName

    if (-not (Test-Path $kbPath)) {
        Write-Host "Brak folderu z paczkami dla $groupName -> $kbPath" -ForegroundColor Yellow
        continue
    }

    # Lista serwerów z pliku
    $serverList = Get-Content $file.FullName

    foreach ($computer in $serverList) {
        try {
            Write-Host "[$computer] -> Copying KBs from $kbPath" -ForegroundColor Cyan
            Copy-Item $kbPath -Destination "\\$computer\C$\Temp\" -Recurse -Force -ErrorAction Stop
            Write-Host "[$computer] Copy SUCCESS" -ForegroundColor Green
        }
        catch {
            Write-Host "[$computer] Copy FAILED: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}
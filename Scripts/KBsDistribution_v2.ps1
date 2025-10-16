
# === KONFIGURACJA ===
$serverList = @("Server01", "Server02", "Server03")  # <-- Wprowadź ręcznie nazwy sieciowe maszyn
$kbSourcePath = "C:\Temp\Patching\KBs\Group1"        # <-- Folder z paczkami KB
$destinationSubPath = "C$\Temp\TempKB"               # <-- Folder docelowy na VM


# Funkcja 1: Sprawdza połączenie z maszyną
function Test-ServerConnection {
    param($computer)
    return Test-Connection -ComputerName $computer -Count 1 -Quiet
}

# Funkcja 2: Sprawdza, czy folder z paczkami istnieje lokalnie
function Validate-SourceFolder {
    param($path)
    if (-not (Test-Path $path)) {
        Write-Host "Brak folderu z paczkami: $path" -ForegroundColor Red
        return $false
    }
    return $true
}

# Funkcja 3: Kopiuje paczki KB na zdalną maszynę
function Copy-KBsToServer {
    param($computer, $sourcePath, $destinationSubPath)

    $destination = "\\$computer\$destinationSubPath"

    try {
        Write-Host "[$computer] Kopiowanie paczek z $sourcePath do $destination"
        Copy-Item -Path $sourcePath -Destination $destination -Recurse -Force -ErrorAction Stop
        Write-Host "[$computer] Kopiowanie zakończone sukcesem" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "[$computer] Błąd kopiowania: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Funkcja 4: Weryfikuje poprawność kopiowania (rozmiar folderu)
function Verify-CopyIntegrity {
    param($computer, $sourcePath, $destinationSubPath)

    $sourceSize = (Get-ChildItem -Path $sourcePath -Recurse | Measure-Object -Property Length -Sum).Sum
    $remotePath = "\\$computer\$destinationSubPath"
    if (-not (Test-Path $remotePath)) {
        Write-Host "[$computer] Folder docelowy NIE istnieje: $remotePath" -ForegroundColor Red
        return $false
    }

    $destinationSize = (Get-ChildItem -Path $remotePath -Recurse | Measure-Object -Property Length -Sum).Sum

    if ($destinationSize -eq $sourceSize) {
        Write-Host "[$computer] Weryfikacja OK: rozmiar zgodny ($([math]::Round($destinationSize / 1MB, 2)) MB)" -ForegroundColor Green
        return $true
    } else {
        Write-Host "[$computer] Weryfikacja NIEUDANA: rozmiar różny" -ForegroundColor Red
        Write-Host "Źródło: $([math]::Round($sourceSize / 1MB, 2)) MB | Cel: $([math]::Round($destinationSize / 1MB, 2)) MB"
        return $false
    }
}

# Funkcja 4: Weryfikuje poprawność kopiowania (rozmiar folderu)
function Verify-CopyIntegrity {
    param($computer, $sourcePath, $destinationSubPath)

    $sourceSize = (Get-ChildItem -Path $sourcePath -Recurse | Measure-Object -Property Length -Sum).Sum
    $remotePath = "\\$computer\$destinationSubPath"
    if (-not (Test-Path $remotePath)) {
        Write-Host "[$computer] Folder docelowy NIE istnieje: $remotePath" -ForegroundColor Red
        return $false
    }

    $destinationSize = (Get-ChildItem -Path $remotePath -Recurse | Measure-Object -Property Length -Sum).Sum

    if ($destinationSize -eq $sourceSize) {
        Write-Host "[$computer] Weryfikacja OK: rozmiar zgodny ($([math]::Round($destinationSize / 1MB, 2)) MB)" -ForegroundColor Green
        return $true
    } else {
        Write-Host "[$computer] Weryfikacja NIEUDANA: rozmiar różny" -ForegroundColor Red
        Write-Host "Źródło: $([math]::Round($sourceSize / 1MB, 2)) MB | Cel: $([math]::Round($destinationSize / 1MB, 2)) MB"
        return $false
    }
}

# Sprawdzenie folderu źródłowego
if (-not (Validate-SourceFolder -path $kbSourcePath)) {
    return
}

foreach ($computer in $serverList) {
    Write-Host "`n=== [$computer] Rozpoczęcie procesu ==="

    if (-not (Test-ServerConnection -computer $computer)) {
        Write-Host "[$computer] Brak połączenia z maszyną" -ForegroundColor Yellow
        continue
    }

    $copySuccess = Copy-KBsToServer -computer $computer -sourcePath $kbSourcePath -destinationSubPath $destinationSubPath

    if ($copySuccess) {
        Verify-CopyIntegrity -computer $computer -sourcePath $kbSourcePath -destinationSubPath $destinationSubPath
    }
}
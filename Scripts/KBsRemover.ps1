# ======================
# Konfiguracja
# ======================
$serverList = @("Server01", "Server02", "Server03")  # <-- Wprowadź ręcznie nazwy sieciowe maszyn
$folderToDelete = "C$\Temp\TempKB"                   # <-- Ścieżka folderu do usunięcia na VM

# ======================
# Funkcja: Test-ServerConnection
# Opis: Sprawdza, czy maszyna jest osiągalna przez ping
# Parametry: $computer – nazwa maszyny
# ======================
function Test-ServerConnection {
    param($computer)
    return Test-Connection -ComputerName $computer -Count 1 -Quiet
}

# ======================
# Funkcja: Check-FolderExists
# Opis: Sprawdza, czy folder istnieje na zdalnej maszynie
# Parametry: $computer, $folderPath – nazwa maszyny i ścieżka folderu
# ======================
function Check-FolderExists {
    param($computer, $folderPath)
    $remotePath = "\\$computer\$folderPath"
    return Test-Path $remotePath
}

# ======================
# Funkcja: Remove-RemoteFolder
# Opis: Próbuje usunąć folder z maszyny zdalnej
# Parametry: $computer, $folderPath – nazwa maszyny i ścieżka folderu
# ======================
function Remove-RemoteFolder {
    param($computer, $folderPath)
    $remotePath = "\\$computer\$folderPath"

    try {
        Remove-Item -Path $remotePath -Recurse -Force -ErrorAction Stop
        Write-Host "[$computer] Folder został usunięty: $remotePath" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "[$computer] Błąd podczas usuwania folderu: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

foreach ($computer in $serverList) {
    Write-Host "`n=== [$computer] Usuwanie folderu ==="

    if (-not (Test-ServerConnection -computer $computer)) {
        Write-Host "[$computer] Brak połączenia z maszyną" -ForegroundColor Yellow
        continue
    }

    if (-not (Check-FolderExists -computer $computer -folderPath $folderToDelete)) {
        Write-Host "[$computer] Folder NIE istnieje: \\$computer\$folderToDelete" -ForegroundColor Cyan
        continue
    }

    Remove-RemoteFolder -computer $computer -folderPath $folderToDelete
}
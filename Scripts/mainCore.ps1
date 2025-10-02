<#
.SYNOPSIS
Główny skrypt uruchamiający system. 
Wersja lean+ – wszystkie moduły uruchamiane są przez funkcje.
Logi startu i zakończenia.
#>

# Ścieżka logu mainCore
$logFile = "$PSScriptRoot\mainCore.log"

# Funkcja logowania
function Write-Log {
    param([string]$Message)
    "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')) : $Message" | Out-File -FilePath $logFile -Append
}

# Funkcja uruchamiająca statusDashboard
function Start-StatusDashboard {
    Write-Log "Uruchomienie statusDashboard."
    Start-Process powershell.exe -ArgumentList "-NoExit -File `"$PSScriptRoot\statusDashboard_v2.4-lean+.ps1`""
}

# Funkcja uruchamiająca commandPanel
function Start-CommandPanel {
    Write-Log "Uruchomienie commandPanel."
    Start-Process powershell.exe -ArgumentList "-NoExit -File `"$PSScriptRoot\commandPanel_v2.4-lean+.ps1`""
}

# Start mainCore
Write-Host "mainCore v2.4-lean+ uruchomiony."
Write-Log "mainCore uruchomiony."

# Wywołanie funkcji startujących moduły
Start-StatusDashboard
Start-CommandPanel

Write-Host "mainCore uruchomił wszystkie moduły."
Write-Host "Naciśnij Enter aby zakończyć mainCore."
Read-Host

Write-Log "mainCore zakończony."


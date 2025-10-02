<#
.SYNOPSIS
Panel komend:
- statusPrint -> zapisuje snapshot do CSV
- restart -> restart serwisu lokalnego lub zdalnego
- exit -> zamknięcie panelu
Wersja lean+ – cała logika w funkcjach
#>

$StatusFile = "$PSScriptRoot\status.json"
$CSVFile = "$PSScriptRoot\statusLog.csv"
$LogFile = "$PSScriptRoot\commandPanel.log"

# Funkcja logowania działań panelu
function Write-Log {
    param([string]$Message)
    "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')) : $Message" | Out-File -FilePath $LogFile -Append
}

# Funkcja restartująca serwis
function Restart-ServiceRemote {
    param (
        [string]$ComputerName,
        [string]$ServiceName,
        [switch]$Force
    )
    try {
        $svc = Get-Service -ComputerName $ComputerName -Name $ServiceName -ErrorAction Stop
        if ($Force) { Restart-Service -InputObject $svc -Force } else { Restart-Service -InputObject $svc }
        Write-Host "Usługa $ServiceName na $ComputerName została zrestartowana." -ForegroundColor Green
        Write-Log "Restart: $ComputerName $ServiceName (Force=$Force)"
    } catch {
        Write-Host "Nie udało się zrestartować $ServiceName na $ComputerName: $_" -ForegroundColor Red
        Write-Log "Błąd restartu: $ComputerName $ServiceName $_"
    }
}

# Funkcja zapisująca status do CSV
function Save-StatusToCSV {
    if (-Not (Test-Path $StatusFile)) {
        Write-Host "Brak pliku status.json, brak danych do zapisania." -ForegroundColor Yellow
        return
    }
    try {
        $status = Get-Content $StatusFile | ConvertFrom-Json
        $csvObject = [PSCustomObject]@{
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            ComputerName = $status.ComputerName
            OS = $status.OS
            IPAddress = $status.IPAddress
            Services = ($status.Services | ForEach-Object { "$($_.Name):$($_.Status)" } ) -join ";"
            RAMPercent = $status.RAMPercent
            DiskPercent = $status.DiskPercent
            GPUStatus = $status.GPUStatus
            TimeZone = $status.TimeZone
            LastBoot = $status.LastBoot
        }
        $csvObject | Export-Csv -Path $CSVFile -NoTypeInformation -Append
        Write-Host "Stan zapisany do CSV." -ForegroundColor Green
        Write-Log "statusPrint wykonany"
    } catch {
        Write-Host "Błąd zapisu CSV: $_" -ForegroundColor Red
        Write-Log "Błąd zapisu CSV: $_"
    }
}

# Funkcja główna panelu
function Run-CommandPanel {
    Write-Host "CommandPanel v2.4-lean+ uruchomiony."
    Write-Host "Dostępne komendy: statusPrint | restart NazwaKomputera NazwaSerwisu [force] | exit"

    while ($true) {
        $inputCommand = Read-Host "Command>"

        if ($inputCommand -eq "statusPrint") {
            Save-StatusToCSV
        } elseif ($inputCommand -match "^restart\s+(\S+)\s+(\S+)(\s+force)?") {
            $computer = $matches[1]
            $service = $matches[2]
            $force = $matches[3] -eq " force"
            Restart-ServiceRemote -ComputerName $computer -ServiceName $service -Force:$force
        } elseif ($inputCommand -eq "exit") {
            break
        } else {
            Write-Host "Nieznana komenda." -ForegroundColor Yellow
        }
    }
}

# Start panelu
Run-CommandPanel
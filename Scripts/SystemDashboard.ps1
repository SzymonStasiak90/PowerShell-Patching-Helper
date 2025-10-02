<#
.SYNOPSIS
  SystemDash_v1.4.ps1 – Dashboard z rozdzielonym szybkim i wolnym odświeżaniem.
.DESCRIPTION
  - Szybkie odświeżanie (10 s): status urządzenia, uptime, serwisy
  - Wolne odświeżanie (5 min): RAM, dysk, ostatnie patche, IP
  - Serwisy wyświetlają status i tryb startu (Automatic/Manual/Disabled)
  - Kolorowanie RAM i dysku
  - 3 ostatnie patche
#>

# --- KONFIGURACJA ---
$fastRefreshInterval = 10 # sekundy, status i uptime, serwisy
$slowRefreshInterval = 300 # sekundy, RAM, dysk, patche, IP

# --- FUNKCJA POBIERANIA STATUSU URZĄDZENIA ---
function Get-DeviceStatus {
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        $uptime = (Get-Date) - $os.LastBootUpTime
        $status = "Running"
        return @{Status=$status; Uptime=$uptime; LastBoot=$os.LastBootUpTime}
    } catch {
        return @{Status="Disconnected"; Uptime=$null; LastBoot=$null}
    }
}

# --- FUNKCJA POBIERANIA DANYCH CIĘŻKICH ---
function Get-HeavySystemInfo {
    try {
        $comp = Get-CimInstance Win32_ComputerSystem
        $timezone = (Get-TimeZone).Id

        # RAM
        $totalRAM = [math]::Round($comp.TotalPhysicalMemory / 1GB, 2)
        $os = Get-CimInstance Win32_OperatingSystem
        $freeRAM = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
        $usedRAMperc = [math]::Round((($totalRAM - $freeRAM) / $totalRAM) * 100, 1)

        # Dysk C
        $diskC = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
        $freeSpace = [math]::Round(($diskC.FreeSpace / $diskC.Size) * 100, 1)

        # Ostatnie patche
        $patches = Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 3

        # Adres IP
        $ips = Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias 'Ethernet','Wi-Fi' -ErrorAction SilentlyContinue
        $ipAddr = if ($ips) { $ips.IPAddress -join ', ' } else { "Brak IP" }

        return @{
            Computer=$comp.Name;
            TimeZone=$timezone;
            TotalRAM=$totalRAM;
            UsedRAMPerc=$usedRAMperc;
            FreeDiskC=$freeSpace;
            Patches=$patches;
            IP=$ipAddr
        }
    } catch {
        Write-Host "Błąd pobierania danych ciężkich: $_" -ForegroundColor Red
        return $null
    }
}

# --- FUNKCJA POBIERANIA SERWISÓW ---
function Get-ServicesInfo {
    $services = Get-Service | Where-Object { $_.Name -in @("wuauserv","bits","Dnscache") }
    $serviceData = @()
    foreach ($svc in $services) {
        $startType = (Get-CimInstance Win32_Service -Filter "Name='$($svc.Name)'" | Select-Object -ExpandProperty StartMode)
        $serviceData += [PSCustomObject]@{
            Name=$svc.Name
            Status=$svc.Status
            StartType=$startType
        }
    }
    return $serviceData
}

# --- FUNKCJA WYŚWIETLANIA DASHBOARDU ---
function Show-Dashboard {
    param(
        $statusData,
        $heavyData,
        $servicesData
    )

    Clear-Host
    Write-Host "=== System Dashboard v1.4 ===`n" -ForegroundColor Cyan

    # --- SZYBKI PODGLĄD ---
    Write-Host "Status urządzenia: $($statusData.Status)" -ForegroundColor ($(if($statusData.Status -eq "Running"){"Green"} else {"Red"}))
    if ($statusData.Uptime) {
        Write-Host "Uptime: $([math]::Floor($statusData.Uptime.TotalDays)) dni, $($statusData.Uptime.Hours)h $($statusData.Uptime.Minutes)m" -ForegroundColor Yellow
        Write-Host "Ostatni start: $($statusData.LastBoot)" -ForegroundColor Yellow
    }

    # --- SERWISY ---
    Write-Host "`n=== Serwisy ==="
    foreach ($svc in $servicesData) {
        $color = if ($svc.Status -eq "Running") { "Green" } else { "Red" }
        Write-Host "$($svc.Name): $($svc.Status) (Startup: $($svc.StartType))" -ForegroundColor $color
    }

# --- CIĘŻKIE DANE (tylko po odświeżeniu wolnym) ---
if ($heavyData) {
    Write-Host "`n=== System ==="
    Write-Host "Nazwa maszyny: $($heavyData.Computer)" -ForegroundColor Green
    Write-Host "Adres IP: $($heavyData.IP)" -ForegroundColor Green
    Write-Host "Strefa czasowa: $($heavyData.TimeZone)" -ForegroundColor Yellow

    # --- AKTUALNY CZAS SYSTEMOWY ---
    $currentTime = Get-Date -Format "HH:mm:ss dd.MM.yyyy"
    Write-Host "Aktualny czas: $currentTime" -ForegroundColor Cyan

        Write-Host "`n=== Zasoby ==="
        # RAM
        if ($heavyData.UsedRAMPerc -lt 60) { $ramColor="Green" }
        elseif ($heavyData.UsedRAMPerc -lt 85) { $ramColor="Yellow" }
        else { $ramColor="Red" }
        Write-Host "RAM: Użycie $($heavyData.UsedRAMPerc)% z $($heavyData.TotalRAM) GB" -ForegroundColor $ramColor

        # Dysk C
        if ($heavyData.FreeDiskC -gt 30) { $diskColor="Green" }
        elseif ($heavyData.FreeDiskC -gt 15) { $diskColor="Yellow" }
        else { $diskColor="Red" }
        Write-Host "Dysk C: Wolne miejsce $($heavyData.FreeDiskC)%" -ForegroundColor $diskColor

        # Patch
        Write-Host "`n=== Ostatnie patche ==="
        foreach ($p in $heavyData.Patches) {
            Write-Host "$($p.HotFixID) z $($p.InstalledOn)" -ForegroundColor Yellow
        }
    }
}

# --- PĘTLA GŁÓWNA ---
$lastHeavyRefresh = (Get-Date).AddSeconds(-$slowRefreshInterval)
$heavyData = Get-HeavySystemInfo
$servicesData = Get-ServicesInfo

while ($true) {
    $statusData = Get-DeviceStatus
    $servicesData = Get-ServicesInfo

    # Odśwież ciężkie dane co $slowRefreshInterval
    if (((Get-Date) - $lastHeavyRefresh).TotalSeconds -ge $slowRefreshInterval) {
        $heavyData = Get-HeavySystemInfo
        $lastHeavyRefresh = Get-Date
    }

    Show-Dashboard -statusData $statusData -heavyData $heavyData -servicesData $servicesData
    Start-Sleep -Seconds $fastRefreshInterval
}
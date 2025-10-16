# ======================
# KONFIGURACJA
# ======================
$vmList = @("PFMEXI009WAD02", "PFMEXI009WBAK02", "PFMEXI009WAPP01")  # Lista maszyn
$basePath = "C:\Temp\SystemCheck"                                     # Lokalizacja folderów
$services = @("wuauserv", "TrustedInstaller", "msiserver", "RpcSs", "DcomLaunch", "BITS")
$osFolders = @("2016", "2019", "2022")                                 # Obsługiwane wersje systemu

# ======================
# Funkcja: Get-SystemInfo
# Opis: Pobiera informacje o systemie operacyjnym maszyny.
# Parametry: $vm
# ======================
function Get-SystemInfo {
    param($vm)
    Invoke-Command -ComputerName $vm -ScriptBlock {
        $os = Get-CimInstance Win32_OperatingSystem
        Write-Host "System operacyjny: $($os.Caption) $($os.Version)"
        Write-Host "Strefa czasowa: $([System.TimeZoneInfo]::Local.DisplayName)"
        Write-Host "Uptime: $([math]::Round((New-TimeSpan -Start $os.LastBootUpTime).TotalHours, 2)) godzin"
    }
}

# ======================
# Funkcja: Get-RecentUpdates
# Opis: Pokazuje 3 ostatnie aktualizacje KB.
# Parametry: $vm
# ======================
function Get-RecentUpdates {
    param($vm)
    Invoke-Command -ComputerName $vm -ScriptBlock {
        $updates = Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 3
        foreach ($update in $updates) {
            Write-Host "$($update.HotFixID) | Zainstalowano: $($update.InstalledOn)"
        }
    }
}

# ======================
# Funkcja: Check-AndStartServices
# Opis: Sprawdza i uruchamia wskazane usługi.
# Parametry: $vm, $services
# ======================
function Check-AndStartServices {
    param($vm, $services)
    Invoke-Command -ComputerName $vm -ScriptBlock {
        param($services)
        foreach ($service in $services) {
            try {
                Set-Service -Name $service -StartupType Automatic
                Start-Service -Name $service -ErrorAction Stop
                Write-Host "$service -> Uruchomiono"
            }
            catch {
                Write-Host "$service -> NIE udało się uruchomić: $($_.Exception.Message)"
            }
        }
    } -ArgumentList $services
}

# ======================
# Funkcja: Check-DiskSpace
# Opis: Sprawdza ilość wolnego miejsca na dysku C.
# Parametry: $vm
# ======================
function Check-DiskSpace {
    param($vm)
    Invoke-Command -ComputerName $vm -ScriptBlock {
        $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
        $freeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
        $totalGB = [math]::Round($disk.Size / 1GB, 2)
        Write-Host "Wolne miejsce: $freeGB GB / $totalGB GB"
    }
}

# ======================
# Funkcja: Create-FolderStructure
# Opis: Tworzy foldery i pliki z nazwami maszyn wg wersji systemu.
# Parametry: $vm, $basePath, $osFolders
# ======================
function Create-FolderStructure {
    param($vm, $basePath, $osFolders)

    $osInfo = Invoke-Command -ComputerName $vm -ScriptBlock {
        (Get-CimInstance Win32_OperatingSystem).Caption
    }

    $version = if ($osInfo -match "2016") { "2016" }
               elseif ($osInfo -match "2019") { "2019" }
               elseif ($osInfo -match "2022") { "2022" }
               else { "Unknown" }

    if ($version -ne "Unknown") {
        $mainFolder = Join-Path $basePath $version
        $kbFolder = Join-Path $mainFolder "${version}_KBs"

        New-Item -Path $mainFolder -ItemType Directory -Force | Out-Null
        New-Item -Path $kbFolder -ItemType Directory -Force | Out-Null

        $machineFile = Join-Path $mainFolder "$vm.txt"
        Set-Content -Path $machineFile -Value $vm

        Write-Host "[$vm] Zapisano do folderu: $version"
    } else {
        Write-Host "[$vm] Nie rozpoznano wersji systemu." -ForegroundColor Yellow
    }
}

# ======================
# Funkcja: Run-FullAudit
# Opis: Wykonuje pełny audyt dla listy maszyn.
# Parametry: $vmList, $basePath, $services, $osFolders
# ======================
function Run-FullAudit {
    param($vmList, $basePath, $services, $osFolders)

    foreach ($vm in $vmList) {
        Write-Host "`n=== [$vm] Audyt systemu ==="

        if (-not (Test-Connection -ComputerName $vm -Count 1 -Quiet)) {
            Write-Host "[$vm] Brak połączenia." -ForegroundColor Red
            continue
        }

        Get-SystemInfo -vm $vm
        Get-RecentUpdates -vm $vm
        Check-AndStartServices -vm $vm -services $services
        Check-DiskSpace -vm $vm
    }
}

# ======================
# Funkcja: Prompt-CreateFolders
# Opis: Pyta użytkownika czy utworzyć foldery z paczkami instalacyjnymi.
# Parametry: $vmList, $basePath, $osFolders
# ======================
function Prompt-CreateFolders {
    param($vmList, $basePath, $osFolders)

    Write-Host "`nCzy chcesz utworzyć foldery z paczkami instalacyjnymi? (tak/nie)"
    $response = Read-Host "Odpowiedź"

    if ($response -eq "tak") {
        foreach ($vm in $vmList) {
            try {
                Create-FolderStructure -vm $vm -basePath $basePath -osFolders $osFolders
                Write-Host "[$vm] Folder utworzony pomyślnie." -ForegroundColor Green
            } catch {
                Write-Host "[$vm] Nie udało się utworzyć folderu: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "Tworzenie folderów zostało pominięte." -ForegroundColor Yellow
    }
}

# ======================
# WYWOŁANIE SKRYPTU
# ======================
Run-FullAudit -vmList $vmList -basePath $basePath -services $services -osFolders $osFolders

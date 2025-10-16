# ======================
# Konfiguracja
# ======================
$vmList = @("Server01", "Server02", "Server03")  # <-- Wprowadź ręcznie nazwy sieciowe maszyn
$remoteFolder = "C:\Temp\TempKB"                 # <-- Ścieżka do paczek na VM
$logFolder = "C:\Temp\Patching"                  # <-- Lokalizacja logów lokalnych
$logFileCsv = Join-Path $logFolder "install_log.csv"
$logFileTxt = Join-Path $logFolder "install_log.txt"

# ======================
# Funkcja: Initialize-LogFiles
# Opis: Tworzy folder logów i pliki CSV/TXT z nagłówkami.
# Parametry: $logFolder, $logFileCsv, $logFileTxt
# ======================
function Initialize-LogFiles {
    param($logFolder, $logFileCsv, $logFileTxt)

    if (-not (Test-Path $logFolder)) {
        New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
    }

    "Computer,FileName,Location,SizeMB,Status,ExitCode" | Out-File -FilePath $logFileCsv -Encoding UTF8
    "=== Instalacja paczek na maszynach ===" | Out-File -FilePath $logFileTxt -Encoding UTF8
}

# ======================
# Funkcja: Test-ServerConnection
# Opis: Sprawdza, czy maszyna jest osiągalna przez ping.
# Parametry: $computer
# ======================
function Test-ServerConnection {
    param($computer)
    return Test-Connection -ComputerName $computer -Count 1 -Quiet
}

# ======================
# Funkcja: Install-PackagesOnRemote
# Opis: Instaluje paczki .msu i .msi na zdalnej maszynie.
# Parametry: $computer, $remoteFolder
# ======================
function Install-PackagesOnRemote {
    param($computer, $remoteFolder)

    $scriptBlock = {
        param($remoteFolder)

        $results = @()

        if (-not (Test-Path $remoteFolder)) {
            $results += [PSCustomObject]@{
                FileName = "N/A"
                Location = $remoteFolder
                SizeMB = "N/A"
                Status = "FolderNotFound"
                ExitCode = "N/A"
            }
            return $results
        }

        $packages = Get-ChildItem -Path $remoteFolder -Include *.msu, *.msi -File -Recurse | Sort-Object Length

        if ($packages.Count -eq 0) {
            $results += [PSCustomObject]@{
                FileName = "N/A"
                Location = $remoteFolder
                SizeMB = "N/A"
                Status = "NoPackages"
                ExitCode = "N/A"
            }
            return $results
        }

        foreach ($pkg in $packages) {
            $fileName = $pkg.Name
            $filePath = $pkg.FullName
            $fileSizeMB = [math]::Round($pkg.Length / 1MB, 2)
            $exitCode = "N/A"
            $status = "Unknown"

            try {
                if ($pkg.Extension -eq ".msu") {
                    $cmd = "cmd /c wusa `"$filePath`" /quiet /norestart"
                } elseif ($pkg.Extension -eq ".msi") {
                    $cmd = "cmd /c msiexec /i `"$filePath`" /quiet /norestart"
                } else {
                    $status = "UnsupportedType"
                    $results += [PSCustomObject]@{
                        FileName = $fileName
                        Location = $filePath
                        SizeMB = $fileSizeMB
                        Status = $status
                        ExitCode = $exitCode
                    }
                    continue
                }

                Invoke-Expression $cmd
                $exitCode = $LASTEXITCODE
                $status = if ($exitCode -eq 0) { "Success" } else { "Failed" }
            }
            catch {
                $status = "Error"
                $exitCode = $_.Exception.Message
            }

            $results += [PSCustomObject]@{
                FileName = $fileName
                Location = $filePath
                SizeMB = $fileSizeMB
                Status = $status
                ExitCode = $exitCode
            }
        }

        return $results
    }

    return Invoke-Command -ComputerName $computer -ScriptBlock $scriptBlock -ArgumentList $remoteFolder
}

# ======================
# Funkcja: Log-InstallResults
# Opis: Zapisuje wyniki instalacji do plików CSV i TXT.
# Parametry: $computer, $results, $logFileCsv, $logFileTxt
# ======================
function Log-InstallResults {
    param($computer, $results, $logFileCsv, $logFileTxt)

    foreach ($result in $results) {
        $logLineCsv = "$computer,$($result.FileName),$($result.Location),$($result.SizeMB),$($result.Status),$($result.ExitCode)"
        $logLineTxt = "[$computer] $($result.FileName) | $($result.Location) | $($result.SizeMB) MB | $($result.Status) | ExitCode: $($result.ExitCode)"

        Add-Content -Path $logFileCsv -Value $logLineCsv
        Add-Content -Path $logFileTxt -Value $logLineTxt

        Write-Host "[$computer] $($result.FileName) -> $($result.Status)"
    }
}


Initialize-LogFiles -logFolder $logFolder -logFileCsv $logFileCsv -logFileTxt $logFileTxt

foreach ($computer in $vmList) {
    Write-Host "`n=== [$computer] Instalacja paczek ==="

    if (-not (Test-ServerConnection -computer $computer)) {
        Write-Host "[$computer] Brak połączenia." -ForegroundColor Yellow
        Add-Content -Path $logFileCsv -Value "$computer,N/A,N/A,N/A,ConnectionFailed,N/A"
        Add-Content -Path $logFileTxt -Value "[$computer] Brak połączenia."
        continue
    }

    $results = Install-PackagesOnRemote -computer $computer -remoteFolder $remoteFolder
    Log-InstallResults -computer $computer -results $results -logFileCsv $logFileCsv -logFileTxt $logFileTxt
}

Write-Host "`nInstalacja zakończona na wszystkich maszynach."
Write-Host "Log CSV: $logFileCsv"
Write-Host "Log TXT: $logFileTxt"
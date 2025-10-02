Clear-Host

$serversPath = "C:\temp\Patching\Scripts\servers_*.txt"
$kbBasePath = "C:\temp\Patching\KBs"
$serverFiles = Get-ChildItem -Path $serversPath -Filter "servers_*.txt"

foreach ($file in $serverFiles) {
    $groupName = ($file.BaseName -split "_")[1]
    $kbPath = Join-Path $kbBasePath $groupName

    if (-not (Test-Path $kbPath)) {
        Write-Host "Brak folderu z paczkami dla $groupName -> $kbPath" -ForegroundColor Yellow
        continue
    }

    $serverList = Get-Content $file.FullName

    foreach ($computer in $serverList) {
        $destPath = "\\$computer\C$\Temp\$(Split-Path $kbPath -Leaf)"

        if (-not (Test-Path $destPath)) {
            Write-Host "[$computer] Verification FAILED – folder docelowy nie istnieje" -ForegroundColor Red
            continue
        }

        $srcFiles = Get-ChildItem -Path $kbPath -Recurse -File
        $dstFiles = Get-ChildItem -Path $destPath -Recurse -File

        # --- szybka weryfikacja liczby plików ---
        if ($srcFiles.Count -ne $dstFiles.Count) {
            Write-Host "[$computer] WARNING – inna liczba plików (SRC: $($srcFiles.Count), DST: $($dstFiles.Count))" -ForegroundColor Yellow
        }

        # --- dokładna weryfikacja hashy ---
        $differences = @()
        foreach ($src in $srcFiles) {
            $relativePath = $src.FullName.Substring($kbPath.Length)
            $dstFile = $dstFiles | Where-Object { $_.FullName.Substring($destPath.Length) -eq $relativePath }

            if ($null -ne $dstFile) {
                $srcHash = (Get-FileHash $src.FullName).Hash
                $dstHash = (Get-FileHash $dstFile.FullName).Hash

                if ($srcHash -ne $dstHash) {
                    $differences += $relativePath
                }
            }
            else {
                $differences += $relativePath
            }
        }

        if ($differences.Count -eq 0) {
            Write-Host "[$computer] Verification SUCCESS – wszystkie pliki się zgadzają" -ForegroundColor Green
        }
        else {
            Write-Host "[$computer] Verification FAILED – różnice w plikach: $($differences -join ', ')" -ForegroundColor Red
        }
    }
}
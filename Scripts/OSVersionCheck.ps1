$VMList = Get-Content "C:\Temp\Patching\Scripts\servers.txt"



# Plik wyjsciowy

$OutputFile = ".\VM_OS_Report.txt"



# Wyczysc plik wyjsciowy

Clear-Content -Path $OutputFile -ErrorAction SilentlyContinue

Add-Content -Path $OutputFile -Value "VM Name`tOperating System"



foreach ($VM in $VMList) {

    Write-Host "Sprawdzam $VM..."



    try {

        # Pobierz informacje o systemie operacyjnym

        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $VM -ErrorAction Stop



        $line = "$VM`t$($os.Caption) $($os.Version)"

        Add-Content -Path $OutputFile -Value $line

        Write-Host " -> $line"

    }

    catch {

        $line = "$VM`tNie mozna pobrac informacji (blad polaczenia)"

        Add-Content -Path $OutputFile -Value $line

        Write-Host " -> $line" -ForegroundColor Red

    }

}



Write-Host "`nRaport zapisany do: $OutputFile" -ForegroundColor Green



# Pauza, zeby okno sie nie zamknelo

Write-Host "`nNacisnij Enter aby zakonczyc..."

[void][System.Console]::ReadLine()
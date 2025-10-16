# RDP - jednorazowe logowanie i otwarcie wielu sesji
# ======================

# Lista hostów (FQDN lub IP)
$servers = @(
    "FRCHTFSBAK02",
    "FRCHTFSFILE01",
    "FRCHTFSRDS01",
    "FRCHTFSVPX01",
    "FRCHTFSWAD01",
    "FRCHTFSWSUS01"
)

# Poproś o jedno okno logowania
$cred = Get-Credential

# Rozpakowanie SecureString do plaintext (krótkotrwałe, w pamięci)
$ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($cred.Password)
try {
    $plainPass = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($ptr)
} finally {
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
}

# Dodaj poświadczenia do Credential Manager dla każdego hosta i otwórz RDP
foreach ($s in $servers) {
    # Używamy nazwy hosta jako targetu; upewnij się, że to dokładnie to, czego używasz w mstsc
    cmd.exe /c "cmdkey /add:$s /user:$($cred.UserName) /pass:$plainPass" | Out-Null

    # Otwórz mstsc (każde otworzy osobne okno)
    Start-Process "mstsc.exe" -ArgumentList "/v:$s"
}

# Zadbaj o sprzątanie (opcjonalne):
# 1) Możesz od razu usunąć poświadczenia po krótkim delay (ryzyko: mstsc może potrzebować chwili na użycie creds),
# 2) albo poczekać na nacisnięcie klawisza.
Write-Host ""
Write-Host "Wszystkie okna RDP uruchomione."
Write-Host "Naciśnij Enter, żeby usunąć zapisane poświadczenia z Credential Manager (zalecane), lub Ctrl+C żeby zostawić."
Read-Host -Prompt "Usuń poświadczenia i zakończ?"

foreach ($s in $servers) {
    cmd.exe /c "cmdkey /delete:$s" | Out-Null
}
Write-Host "Poświadczenia usunięte."
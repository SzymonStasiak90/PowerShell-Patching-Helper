Function Clear-PME {
    # Cleanup PME Cache folders
    Write-Host "PME Cache Cleanup..." -ForegroundColor Cyan
    $CacheFolderPaths = "$env:ProgramData\SolarWinds MSP\SolarWinds.MSP.CacheService", "$env:ProgramData\SolarWinds MSP\SolarWinds.MSP.CacheService\cache", "$env:ProgramData\MspPlatform\FileCacheServiceAgent", "$env:ProgramData\MspPlatform\FileCacheServiceAgent\cache"
    ForEach ($CacheFolderPath in $CacheFolderPaths) {
        If (Test-Path -Path "$CacheFolderPath") {
            Try {
                Write-Output "Performing cleanup of '$CacheFolderPath' folder"
                [Void](Remove-Item -Path "$CacheFolderPath\*.*" -Force -Confirm:$false)
            }
            Catch {
                Write-EventLog @WriteEventLogErrorParams -Message "Unable to cleanup '$CacheFolderPath\*.*' aborting. Error: $($_.Exception.Message).`nScript: Repair-PME.ps1"
                Throw "Unable to cleanup '$CacheFolderPath\*.*' aborting. Error: $($_.Exception.Message)"
            }
        }
    }
}



Write-host "Press enter to clear PME cache folder"

Read-host 

Clear-PME


Write-host "Job done"



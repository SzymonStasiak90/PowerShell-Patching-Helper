# Windows Update Installer WUInstaller
#Author : Jakub Zarebski
$Version = 4
$Dev = $false
$Full = $true 
#Script will try to install every windows update in root-folder of script
#After finishing the script will transfer back the log file
#Can be launch remotely via Parallel Transfer Script and Windows Task Scheduler tool
#Can be launch standalone, both $ServerName and $SourcePath can be manually added. It will work without them as local instalator

#Parameters for remote actions
param(
    [Parameter(Mandatory=$false)]
    [string]$SourcePath,
    [Parameter(Mandatory=$false)]
    [string]$ServerName
)

#Pathing etc.
$updatePath = "C:\Temp"
$logFile = "C:\Temp\WUInstaller_$ServerName.txt"


#Logging function
function Write-Log {
    param ([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $logFile -Append
}

#Debugging
Write-log $SourcePath

#Variable for log status
$EndStatus

#Magic starts here
Write-Log "Starting Windows Update installation process on $ServerName"

$isScheduledTask = [bool]($env:COMPUTERNAME)
Write-Log "Script is running as a scheduled task: $isScheduledTask"

$updates = Get-ChildItem -Path $updatePath -Filter "*.msu"
Write-Log "Found $($updates.Count) updates to install"

#Main Loop
foreach ($update in $updates) {
    Write-Log "Starting installation of update: $($update.Name)"
    try {
        $process = Start-Process -FilePath "wusa.exe" -ArgumentList "$($update.FullName) /quiet /norestart" -Wait -PassThru -ErrorAction Stop
        
        switch ($process.ExitCode) {
            0 {
                Write-Log "Successfully installed update: $updateName"
                $logFileName = "WUInstaller_${serverName}_Success_${dateStamp}.txt"
                $EndStatus = "Success"
            }
            3010 {
                Write-Log "Update installed successfully, but reboot is required: $updateName"
                $logFileName = "WUInstaller_${serverName}_Reboot_${dateStamp}.txt"
                $EndStatus = "Reboot_required"
            }
            default {
                throw "Installation failed with exit code: $($process.ExitCode)"
                $EndStatus ="Failed"
            }
        }
    }
    catch {
        Write-Log "Error occurred while installing update $updateName with $($process.ExitCode) Exit Code"
        $EndStatus ="Failed"
    }
   
}

#Final Log file is new file that will be transfer back to source server with status in name
$finalLogName = "C:\Temp\WuInstaller_$($ServerName)_$($EndStatus).txt"

Write-Log "Windows Update installation process finished"

Rename-Item -Path $logFile -NewName $finalLogName

# Transfer log file back to source
try {
    Copy-Item -Path $finalLogName -Destination $SourcePath -Force
    Write-Log "Log file transferred back to source: $SourcePath"
}
catch {
    Write-log $_.Exception.Message
    Write-log $_.InvocationInfo.ScriptLineNumber
    Write-Log "Failed to transfer log file back to source: $SourcePath"
}
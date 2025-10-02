#Disk usage checker
#Version 1
#Author: Jakub Zarebski
#Script to check C:\ disk usage 


#usual boring stuff pathing etc
$sPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$file = "$sPath\servers.txt"
$servers = Get-Content -Path "$sPath\servers.txt"
$output = "$sPath\CheckDiskOutput.txt"


#Fluff
Clear-host
Write-host : "Checking disk usage"


#Checking if servers.txt exist
if(Test-Path -Path $file)
{
    Write-host "File exist, script will continue work"
}

else 
{
    Write-host "File does not exist, termination" 
    exit
}


#check if output file exist if yes then it will clear it
if(Test-Path -Path $output)

{
	Clear-Content $output
}


#Main loop
foreach ($server in $servers) 
{
   #Trying to check C drive info
    try {
        # Get disk information for C: drive
        # It can be change if someone really want by checking DeviceID to other letter
        $disk = Get-WmiObject Win32_LogicalDisk -ComputerName $server -Filter "DeviceID='C:'" -ErrorAction Stop

        # Calculate used and free space in GB
        $totalGB = [math]::Round($disk.Size / 1GB, 2)
        $freeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
        $usedGB = $totalGB - $freeGB
        $usedPercent = [math]::Round(($usedGB / $totalGB) * 100, 2)

         Add-Content -Path $output -Value $server
         Add-Content -Path $output -Value "Total Space : $totalGB   GB"                        
         Add-Content -Path $output -Value "Free Space : $freeGB GB"
         Add-Content -Path $output -Value "Used space : $usedGB GB"
         Add-Content -Path $output -Value "Percent used : $usedPercent %"

         Add-Content -Path $output -Value "-------------------------------------"
         Add-Content -Path $output -Value ""


        }
        #Catching error
    catch {
        # If there's an error, add an error entry to the results
          

          Add-Content -Path $output -Value $server
          Add-Content -Path $output -Value  "ErrorMessage = $_.Exception.Message"
          Add-Content -Path $output -Value "-------------------------------------"
          Add-Content -Path $output -Value ""
                                     
        }

    

}



#End, invoking output file
invoke-item $output
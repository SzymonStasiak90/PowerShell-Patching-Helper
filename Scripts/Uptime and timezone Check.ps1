#Uptime Checker
#Author : Jakub Zarebski
#Version : 1

#Script will load list of VMs from file (root dir. of script) to check windows uptime
#Script will terminate if there no file
#Script check for errors eg. No RDP connection and present them in file
#Output file will be genereted in same folder 


#getting root path for script folder
$sPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$file = "$sPath\servers.txt"
$servers = Get-Content -Path "C:\Temp\Patching\Scripts\servers.txt"
$output = "$sPath\CheckUptimeOutput.txt"
$outputZone = "$sPath\CheckTimezoneOutput.txt"


#Test if server file exist
if(Test-Path -Path $file)
{
    Write-host "servers.txt file exist, script will continue work"
}

else 
{
    Write-host "servers.txt file do not exist, script will terminate" 
    exit
}


#Test if output file exist if yes then script will clear it's content
if(Test-Path -Path $output)
    {
        Clear-Content $output
    }



#main loop
foreach ($server in $servers) {
    Write-Host "Checking Windows Uptime on $server"

    #Getting Uptime from servers
    try {
         $os = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $server
         $zone = (Get-TimeZone)
         $uptime = (Get-Date) - $os.ConvertToDateTime($os.LastBootUpTime)
         $line2 = ("$server" + " Uptime: " + $uptime.Days + " days " + $uptime.Hours + " hours " + $uptime.Minutes + " minutes")
         $line3 = ("$server" + " Timezone: " + $zone)
        Add-Content -Path $output -Value $line2
        Add-Content -Path $outputZone -Value $line3
        }
    #Errors catch
     catch {
        Write-Host "Failed to check uptime  on $server  $($_.Exception.Message)"
        $line = "$server  $($_.Exception.Message)"
        add-content -Path $output -Value $line
           }


  Write-host "---------------------------"
  add-content -Path $output -Value "---------------"

}

#opening output file
invoke-item $output




#Clearning Script
#version 1
#Author : Jakub Zarebski
#Clears all .msu in C:Temp



#Define the root and files paths
$sPath = Split-Path -Parent $MyInvocation.MyCommand.Definition


#Server txt plik
$file = "$sPath\servers.txt"

#Always same target path - > Temp folder on C:\
$targetPath = "C:\temp\*"

#Log File for post checks
$logFile = "$sPath\logFileClearning.txt"

#Test if server.txt file is present

if(Test-path -Path $file)
{
#Servers lists
$servers = Get-content $file
}
else{
    Write-host "No server.txt file.Termination of script"
    Exit
}


Write-host "Post-patching Clearning Script v1"
Write-host "-----------"



#Multi-thread magic starts heree
$jobs = @()

#Clearning Logs
if(Test-Path -Path $logFile){
Clear-Content -path $logFile
}

#Main loop

foreach ($server in $servers)
{


#Adding function into job
$jobs += Start-Job -ScriptBlock{

param ($server,$logFile)

$targetPath = "\\$server\C$\TEMP\"



function Clearning-UpdateFiles {

param ([string]$server)



#Trying to clear
try{
$targetPath = "\\$server\C$\TEMP\"
#loop for all .msu

$files = Get-ChildItem $targetPath -Recurse
$msus = $files | Where-Object {$_.extension -eq ".msu"}

# Debugging: Output the contents of $msus
Write-Host "Found the following .msu files:"
$msus | ForEach-Object { Write-Host $_.FullName }


foreach ($msu in $msus)
{

Remove-Item $msu.FullName -Force
Write-Output "Removed $msu on $server"
Add-Content -Path $logFile -Value "Removed $msu at $server"
Add-Content -Path $logFile -Value "--------"
}

}
#Error catcher
catch {
Write-Output "Failed clearning to $server"
Add-Content -Path $logFile -Value "Failed to clear $server $server" 
Add-Content -Path $logFile -Value "--------------"

}

}




#Testing for connection 
Test-Connection -ComputerName $server -Count 1
Write-Output "-------"
#Calling out the function defined above
Clearning-UpdateFiles -server $server

#Write-Output "Clearning files on $server"
}-ArgumentList $server,$logFile



#Limiter of Jobs to 20
if($jobs.Count -ge 20) {
$jobs | ForEach-Object {$_ | Wait-Job ; Receive-Job -Job $_; Remove-Job -Job $_}
$jobs =@()
}

}

#Removing jobs if completed
$jobs | ForEach-Object {$_ | Wait-Job ; Receive-Job -Job $_; Remove-Job -Job $_}


#Summary and invoking log file
 Write-Output "Clearning done, launching log file"

 Invoke-Item $logFile
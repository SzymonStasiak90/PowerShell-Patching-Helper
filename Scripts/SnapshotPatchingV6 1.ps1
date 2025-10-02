Set-PowerCLIConfiguration -ParticipateInCeip $false -InvalidCertificateAction Ignore -Confirm:$false

Clear-host

Write-Host "This Script is to be used to take snapshots of either all VMs running on an IDC or if file is provide for Patching Activities ONLY" -ForegroundColor Yellow
Write-Host "Script also we check overall health status of Storage devices on hosts. If you may suspect low storage space, please double check it in Vcenter" -ForegroundColor Yellow

$Date = Get-Date -Format "dddd_MM_dd_yyyy"
$SnapshotName = "Patching_Activity"

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Load VM names from a text file in the script directory
$file = "$scriptPath\servers.txt"
$VMs = Get-Content -Path "$scriptPath\servers.txt"


Write-host "Snapshot patching script v6" -ForegroundColor Yellow

$vCenter = Read-Host "Enter in the IP of vCenter"


Connect-viserver $vCenter
if(Test-Path -Path $file)
{Write-host "File exist - Script will only do snapshot of VMs listed in file" -ForegroundColor Yellow
}
else
{
Write-host "File do not exist - Script will snapshot all VMs running on IDC" -ForegroundColor Yellow
$VMs = Get-VM | Where-Object {($_.Name -notlike "*vCenter*") -and ($_.Name -notlike "*BAK*") -and ($_.Name -notlike "*network*") -and ($_.Name -notlike "*template*") -and ($_.Name -notlike "*vdp*"-and ($_.Name -notlike "*NetSvcs*") -and ($_.Name -notlike "*Witness*")  -and ($_.VMHost -notlike "*management.ra.internal*") ) }
}

$esxhosts = Get-VMHost

Write-host "Checking for Datastore space usage and overall health status" -ForegroundColor Yellow 

foreach ($esxhost in $esxhosts)

{
	
# Get all the datastores for the current host
   $datastores = Get-Datastore -VMHost $esxhost
   
   # Loop through each datastore
   foreach ($datastore in $datastores)
    {
       # Calculate the free space
       $freeSpaceGB = [math]::Round($datastore.FreeSpaceMB / 1024, 2)
       
       # Calculate the capacity
       $capacityGB = [math]::Round($datastore.CapacityMB / 1024, 2)
       
       # Get the health status
       $healthStatus = $datastore.ExtensionData.OverallStatus
       
       Write-Host "Datastore: $($datastore.Name), Capacity: $capacityGB GB, Free Space: $freeSpaceGB GB, Health Status: $healthStatus" -ForegroundColor Green
   }

}


$SnapshotDescription = "Snapshot Being Taken for Patching Activities on $Date.  This snapshot was taken by $SnapshotEngineer leveraging SnapshotPatchingV6"


$Take = Read-Host "If you want to take a snapshot enter Y, if you want to Delete a Snapshot Enter N"


If ($Take -eq "Y"){

    $SnapshotEngineer = Read-host "Enter your first initial & lastname for snapshot details"

    ForEach ( $vm in $VMs ) 
        {

        New-Snapshot -VM $vm -Name $SnapshotName -Description $SnapshotDescription
        
        }

        Write-Host  "Generating report of snapshots taken.  Will be located in C:\Temp\ labeled $SnapshotName $Date.txt" -ForegroundColor Yellow

        $SnapshotReport = "C:\Temp\$SnapshotName $Date.txt"
        
        Get-Snapshot $VMs -Name $SnapshotName | Select VM,Name | Sort-Object -Property VM | Out-File $SnapshotReport

        Invoke-Item $SnapshotReport

        Disconnect-viserver $vCenter -force -Confirm:$False
        } 
else 
{
    Write-Host "This next step will delete snpashots" -ForegroundColor Red
    $Delete = Read-Host "Do you want to delete snapshots taken from the recent Patching Activity? (Y/N)"
    $SnapshotDeletionReport = "C:\Temp\$SnapshotName $Date Deletion.txt"

    If ($Delete -eq "Y") 
    {
        $SnapshotDeletionReport = "C:\Temp\$SnapshotName $Date Deletion.txt"
        ForEach ($vm in $VMs) {

        $snapshot = Get-Snapshot $vm -Name $SnapshotName 
        if($snapshot)
        {
        $snapshot | Remove-Snapshot -Confirm:$False
        Write-host "Snapshot delete from $vm" -ForegroundColor Yellow
        Add-Content -Path $SnapshotDeletionReport -Value "Snapshot deleted from $vm"
        Add-Content -Path $SnapshotDeletionReport -Value "$Date"
        Add-Content -Path $SnapshotDeletionReport -Value "--------------------------"
        }
        else
        {
            Write-host "$vm has no patching related snapshots"
        }
        }
        

        $Snapshotlist = Get-VM | Get-Snapshot -Name $SnapshotName | select vm, name, description, created, sizegb  
        

        if ($Snapshotlist -eq $null)
         {
        Write-Host "There are no patching activity snapshots" -ForegroundColor Green 
        $current_time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Add-Content -Path $SnapshotDeletionReport -Value "No Patching activity snapshots remains as for $Date"
        Add-Content -Path $SnapshotDeletionReport -Value "$current_time"
        invoke-item $SnapshotDeletionReport
        }
    else
        {
        Write-Host "You can see Snapshot list below" -ForegroundColor RED
        Write-Host "                                                  "
        $Snapshotlist |FT -AutoSize
        }
    

Write-host "---------------------------"
     Disconnect-viserver $vCenter -force -Confirm:$False

    } 
    else {
        
        Write-Host "Option N Was selected.  Terminating Script" -ForegroundColor Yellow
        Clear-host
        Disconnect-viserver $vCenter -force -Confirm:$False
        } 

}




#Script to check every Snapshots on Vcenter
#Jakub Zarebski
#version 1


Set-PowerCLIConfiguration -ParticipateInCeip $false -InvalidCertificateAction Ignore -Confirm:$false

Clear-host



Write-host "SnapshotChecker v1" -ForegroundColor Yellow
Write-host "Output will be stored at C:\Temp\SnapshotCheckerOutput [date].txt"
$vCenter = Read-Host "Enter in the IP of vCenter"
Connect-viserver $vCenter
$VMs = Get-VM 

$SnapshotReport = "C:\Temp\SnapshotCheckerOutput $Date.txt"


ForEach ($vm in $VMs)
{
$snapshot = Get-Snapshot $vm

if($snapshot)
{
     $snapshotInfo = $snapshot | Select-Object VM, Name, @{Name='SizeGB';Expression={[math]::Round($_.SizeGB, 4)}}, Created
        Write-Host "Snapshot on $vm :"
    $snapshotInfo | ForEach-Object {
        Write-Host "VM: $($_.VM), Name: $($_.Name), Size: $($_.SizeGB) GB, Created: $($_.Created)"
    Add-Content -Path $SnapshotReport -Value "VM: $($_.VM), Name: $($_.Name), Size: $($_.SizeGB) GB, Created: $($_.Created)"
    Add-Content -Path $SnapshotReport -Value "------------"
                                   }
    
     
}

else
{
    write-host "No snapshot on $vm"
}

}

Add-Content -Path $SnapshotReport -Value "------------------"
Add-Content -Path $SnapshotReport -Value "$Date"
Add-Content -Path $SnapshotReport -Value "Empty list means that there is no present snapshot on any VMs"
Invoke-Item $SnapshotReport


Disconnect-viserver $vCenter -force -Confirm:$False

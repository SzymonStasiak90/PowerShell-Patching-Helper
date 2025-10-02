Set-PowerCLIConfiguration -ParticipateInCeip $false -InvalidCertificateAction Ignore -Confirm:$false

Write-Host "This Script is to be used to take snapshots of all VMs running on an IDC for Patching Activities ONLY" -ForegroundColor Yellow

$Date = Get-Date -Format "dddd_MM_dd_yyyy"
$SnapshotName = "Patching_Activity"

$vCenter = Read-Host "Enter in the IP of vCenter"

Connect-viserver $vCenter
$VMs = Get-VM | Where-Object {($_.Name -notlike "*vCenter*") -and ($_.Name -notlike "*BAK*") -and ($_.Name -notlike "*network*") -and ($_.Name -notlike "*template*") -and ($_.Name -notlike "*vdp*") }

$SnapshotDescription = "Snapshot Being Taken for Patching Activities on $Date.  This snapshot was taken by $SnapshotEngineer leveraging SnapshotPatchingV3"

$Take = Read-Host "If you want to take a snapshot enter Y, if you want to Delete a Snapshot Enter N"

If ($Take -eq "Y"){

    $SnapshotEngineer = Read-host "Enter your first initial & lastname for snapshot details"

    ForEach ( $vm in $VMs ) {

        New-Snapshot -VM $vm -Name $SnapshotName -Description $SnapshotDescription
        
        }

        Write-Host  "Generating report of snapshots taken.  Will be located in C:\Temp\ labeled $SnapshotName $Date.txt" -ForegroundColor Yellow

        $SnapshotReport = "C:\Temp\$SnapshotName $Date.txt"
        
        Get-Snapshot $VMs -Name $SnapshotName | Select VM,Name | Sort-Object -Property VM | Out-File $SnapshotReport

        Invoke-Item $SnapshotReport

        Disconnect-viserver $vCenter -force -Confirm:$False
} else {
    Write-Host "This next step will delete snpashots" -ForegroundColor Red
    $Delete = Read-Host "Do you want to delete snapshots taken from the recent Patching Activity? (Y/N)"


    If ($Delete -eq "Y") {

        Get-Snapshot $VMs -Name $SnapshotName | Remove-Snapshot -Confirm:$False

        Disconnect-viserver $vCenter -force -Confirm:$False


    } else {
        
        Write-Host "Option N Was selected.  Terminating Script" -ForegroundColor Yellow
        
        Disconnect-viserver $vCenter -force -Confirm:$False
    }

    

}
clear-host
$computers = Get-Content "C:\temp\Patching\Scripts\servers.txt"
$upath='C:\temp\Patching\KBs'

foreach ($computer in $computers){
write-host "Starting file copy $computer"  -ForegroundColor green  
copy-item  $upath -destination "\\$computer\C$\Temp\" -recurse -Force
}

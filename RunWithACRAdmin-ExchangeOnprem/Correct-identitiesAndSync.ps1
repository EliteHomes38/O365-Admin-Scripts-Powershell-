$users = Import-Csv C:\Mig\WinantUsers.csv
ForEach ($user in $users){
$EmpID = $user.EmployeeID
$AgencyCode = $user.AgencyCode
$UPN = $user.UPN
Get-Aduser -Filter {UserPrincipalName -eq $UPN } | Set-ADUser -Replace @{AdSyncEnabled="TRUE"; EmployeeID=$EmpID; AgencyCode=$AgencyCode }

}

$users |ForEach-Object {
$EmpID = $_.EmployeeID
$AgencyCode = $_.AgencyCode
$UPN = $_.UPN
Get-Aduser -Filter {UserPrincipalName -eq $UPN }  -Properties AdSyncEnabled,EmployeeID,AgencyCode


} | Out-GridView
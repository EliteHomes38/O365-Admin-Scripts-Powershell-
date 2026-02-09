#Get-ADUser eskog | Set-ADUser -Replace @{AdSyncEnabled="TRUE"}

cat C:\mig\cowshared.txt| % {Get-Aduser -Filter {UserPrincipalName -eq $_ } -Properties DisplayName, AdSyncEnabled, AgencyCode, employeeid,mail | select DisplayName, UserPrincipalname, SamAccountName, Mail, DistinguishedName, AgencyCode, AdSyncEnabled, EmployeeID } 

cat C:\Mig\taggartleftovers.txt| % {Get-Aduser -Filter {(UserPrincipalName -eq $_ ) -or (Mail -eq $_ ) } | Set-ADUser -Replace @{AdSyncEnabled="TRUE"}}


cat C:\mig\users.txt| % {Get-Aduser -Filter {(UserPrincipalName -eq $_ ) -or (Mail -eq $_ ) } | Set-ADUser -Replace @{AdSyncEnabled="TRUE";EmployeeID="SharedMailbox";AgencyCode="Campbell"}}
cat C:\mig\BENFix.txt | % {Get-Aduser -Filter {(UserPrincipalName -eq $_ ) -or (Mail -eq $_ ) } | Set-ADUser -Enabled:$true -Replace @{AdSyncEnabled="TRUE";}}

#Move-ADObject -

get-aduser -Filter {Userprincipalname -eq "rgeorge@AcrisureLLC.com" }  -Properties AdSyncEnabled, AgencyCode, employeeid  | select UserPrincipalname, SamAccountName, DistinguishedName, AgencyCode, AdSyncEnabled, EmployeeID 
$term = "TSynder@AcrisureLLC.com","PGriffin@AcrisureLLC.com","JCrawford@AcrisureLLC.com" | % {Get-Aduser -Filter {UserPrincipalName -eq $_ } -Properties AdSyncEnabled, AgencyCode, employeeid  | select UserPrincipalname, SamAccountName, DistinguishedName, AgencyCode, AdSyncEnabled, EmployeeID} 

Get-Aduser -Filter {UserPrincipalName -eq "Tvoss@AcrisureLLC.com" } | Set-ADUser  -Replace @{AdSyncEnabled="TRUE";AgencyCode="AP-VAS-VAS";EmployeeID="CLEANMEUPLATER"}

Get-Aduser -Filter {UserPrincipalName -eq "rfarrell@AcrisureLLC.com" } | Set-ADUser  -Replace @{AdSyncEnabled="TRUE";AgencyCode="AP-PGG-EBS";EmployeeID="N05006"}

Get-Aduser -Filter {UserPrincipalName -eq "chrickert@AcrisureLLC.com" } | Set-ADUser  -Replace @{AdSyncEnabled="TRUE";EmployeeID="SharedMailbox";AgencyCode="AP-CAI-CAI"}

$users = Import-csv C:\Mig\Users.csv

ForEach ($user in $users){
    $UPN = $user.UPN
    $ApCode = $user.ApCode

    Get-ADUser -Filter {UserPrincipalName -eq $UPN } | Set-ADUser -Replace @{AgencyCode=$ApCode}
    Get-ADUser -Filter {UserPrincipalName -eq $UPN } -Properties AgencyCode | Select UserPrincipalName, AgencyCode

}


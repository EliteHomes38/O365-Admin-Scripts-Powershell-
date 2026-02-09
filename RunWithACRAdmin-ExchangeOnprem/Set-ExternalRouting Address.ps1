
$aci = cat C:\Mig\users.txt| Get-RemoteMailbox

ForEach ($user in $aci){
    
    $ExternalEmail = $user.SamAccountName + "@acrisure.mail.onmicrosoft.com"
    Set-RemoteMailbox $user.PrimarySmtpAddress -RemoteRoutingAddress $ExternalEmail -EmailAddressPolicyEnabled:$false
    Get-RemoteMailbox $user.PrimarySmtpAddress | Select DisplayName, PrimarySmtpAddress, RemoteRoutingAddress
    #Get-aduser $user.SamAccountName -Properties * | select DisplayName, mail, targetAddress


}


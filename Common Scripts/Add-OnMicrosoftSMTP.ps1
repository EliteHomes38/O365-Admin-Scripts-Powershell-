
#Disconnect-ExchangeOnline -Confirm:$false 
$MSODomain = Read-Host "Enter ONmicrosoft domain suffix"
#$AdminUPN = Read-Host "Enter global admin or Exchange Admin UPN"
#Connect-MsolService 
#Connect-ExchangeOnline -UserPrincipalName $AdminUPN

$mailboxes = Get-Mailbox -ResultSize Unlimited 
ForEach ($Mailbox in $mailboxes){
    #$msoluser = Get-MsolUser -UserPrincipalName $mailbox.UserPrincipalName


    [string]$CurrentEmail = $mailbox.primarySmtpAddress
    [string]$Login = $mailbox.primarySmtpAddress.split("@")[0]
    $newprimary = $Login + "@" + $MSODomain
    Write-Host "adding onmicrosoft smtp to $($mailbox.primarySmtpAddress)"
    Set-Mailbox $mailbox.primarySmtpAddress -EmailAddresses @{add=$newprimary}


}
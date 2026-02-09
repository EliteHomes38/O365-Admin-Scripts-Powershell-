$MSODomain = "donnerfarbercom.onmicrosoft.com"
Connect-MsolService 
Connect-ExchangeOnline -UserPrincipalName oalonzo@donnerfarbercom.onmicrosoft.com


$mailboxes = Get-Mailbox -ResultSize Unlimited 
ForEach ($Mailbox in $mailboxes){
    #$msoluser = Get-MsolUser -UserPrincipalName $mailbox.UserPrincipalName


    [string]$CurrentEmail = $mailbox.primarySmtpAddress
    [string]$Login = $mailbox.primarySmtpAddress.split("@")[0]
    $newprimary = $Login + "@" + $MSODomain
    #$mailboxAddress = $Mailbox.EmailAddresses

    Set-MsolUserPrincipalName -UserPrincipalName $mailbox.UserPrincipalName -NewUserPrincipalName  $newprimary
    Set-Mailbox $mailbox.primarySmtpAddress -EmailAddresses $newprimary 


}

$users = Get-user -RecipientTypeDetails User
ForEach ($user in $users){
    [string]$CurrentEmail = $user.WindowsLiveID
    [string]$Login = $user.WindowsLiveID.split("@")[0]
    $newprimary = $Login + "@" + $MSODomain
    #Set-User $user.WindowsEmailAddress -WindowsEmailAddress  $newprimary
    Set-MsolUserPrincipalName -UserPrincipalName $CurrentEmail -NewUserPrincipalName  $newprimary
}

$Groups = Get-DistributionGroup
ForEach ($group in $groups){
    [string]$CurrentEmail = $group.PrimarySmtpAddress
    [string]$Login = $group.PrimarySmtpAddress.split("@")[0]
    $newprimary = $Login + "@" + $MSODomain
    Set-DistributionGroup $CurrentEmail -EmailAddresses $newprimary #-PrimarySmtpAddress $newprimary
  
}


$UniGroups = Get-UnifiedGroup
ForEach ($group in $UniGroups){
    [string]$CurrentEmail = $group.PrimarySmtpAddress
    [string]$Login = $group.PrimarySmtpAddress.split("@")[0]
    $newprimary = $Login + "@" + $MSODomain
    Set-UnifiedGroup $CurrentEmail -EmailAddresses $newprimary 
  
}

$mailusers = Get-MailUser
ForEach ($Mailbox in $MailUSers){
    #$msoluser = Get-MsolUser -UserPrincipalName $mailbox.UserPrincipalName


    [string]$CurrentEmail = $mailbox.primarySmtpAddress
    [string]$Login = $mailbox.primarySmtpAddress.split("@")[0]
    $newprimary = $Login + "@" + $MSODomain
    #$mailboxAddress = $Mailbox.EmailAddresses

    Set-Mailbox $mailbox.primarySmtpAddress -EmailAddresses $newprimary 


}
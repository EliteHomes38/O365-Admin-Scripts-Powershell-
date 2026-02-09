#Connect-MsolService
Import-Module ActiveDirectory
#connect
$members = Get-MsolGroupMember -GroupObjectId  "c6c7d7f4-2dfd-4c68-83b2-8fd334441be9" -All

foreach ($user in $members){
    $user = $user.EmailAddress
    $mailbox = Get-mailbox $user -errorAction SilentlyContinue
    $AdUSer = Get-AduSer -Filter {(mail -eq $user) -or (UserPrincipalName -eq $user)} -Properties EmployeeID

    if ((($AdUSer.EmployeeID -eq "SharedMailbox") -or ($mailbox.RecipientTypeDetails -eq "SharedMailbox")) -and ($mailbox.PrimarySmtpAddress -notlike "*acrisure.com")){
        Write-Host "$($mailbox.DisplayName) is a shared mailbox - removing"
        Remove-MsolGroupMember -GroupObjectId "c6c7d7f4-2dfd-4c68-83b2-8fd334441be9" -GroupMemberObjectId $mailbox.ExternalDirectoryObjectId 
    }


}


  

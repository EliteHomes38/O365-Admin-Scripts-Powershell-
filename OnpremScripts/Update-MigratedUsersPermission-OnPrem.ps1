$Data = Import-csv "C:\Users\ttiamiyu\OneDrive - acrisurellc.com\TEKSystems Workstream\AP Working Files\Wave 2\WSI\WSI\MailboxAccess.csv"

ForEach ($entry in $Data){
$AccessType = $entry.DelegateAccess
$user = $entry.DelegateEmail
$mailbox = $entry.MailboxEmail

    switch ($AccessType)
    {
        "FullAccess" {
           
                    try {
                        Add-MailboxPermission $mailbox -AccessRights FullAccess -User $user -AutoMapping:$true -Confirm:$false -ErrorAction Stop
                  
                    }
                    catch{
                        Write-Warning -Message "$($error[0].Exception)"
                    }
                    }

        "SendAs" {
                    try {
                        Add-RecipientPermission $mailbox -AccessRights SendAs -Trustee $user -SkipDomainValidationForSharedMailbox -SkipDomainValidationForMailUser -SkipDomainValidationForMailContact -Confirm:$false -ErrorAction Stop
                    }
                    catch{
                        Write-Warning -Message "$($error[0].Exception)"
                    }
                   
        }
        "SendOnBehalf" {
            Set-Mailbox $mailbox -GrantSendOnBehalfTo @{add=$user} -ErrorAction SilentlyContinue
        }
    }
}
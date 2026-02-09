$Data = Import-csv "C:\Users\aburns\acrisurellc.com\M365Rollout - TEKSystems Workstream - TEKSystems Workstream\1 - Phase 2 Working Folder\AP Working Files\Presidio\AP-TNM-TNM-Permissions.csv"

ForEach ($entry in $Data){
$AccessType = $entry.AccessType
$AccessUsers = $entry.UserWithAccess.Split(",") | where {$_ -ne $null}
    switch ($AccessType)
    {
        "FullAccess" {
            forEach ($user in $AccessUsers){
                if($user){
                    $validate = Get-mailbox $user -ErrorAction SilentlyContinue
                    If ($validate){
                        Add-MailboxPermission $entry.UserPrincipalName -AccessRights FullAccess -User $user -AutoMapping:$true -Confirm:$false -ErrorAction SilentlyContinue
                    }
                }
            }
        }
        "SendAs" {
             forEach ($user in $AccessUsers){
                if($user){
                    $validate = Get-mailbox $user -ErrorAction SilentlyContinue
                    If ($validate){
                        Add-RecipientPermission $entry.UserPrincipalName -AccessRights SendAs -Trustee $user -SkipDomainValidationForSharedMailbox -SkipDomainValidationForMailUser -SkipDomainValidationForMailContact -Confirm:$false -ErrorAction SilentlyContinue
                    }
                }
            }       
        }
        "SendOnBehalf" {
            $SoBList = New-Object System.Collections.Generic.List[string]
            $AccessUsers | %{
                if ($_ -ne $null){
                    if (get-user $_ -EA  SilentlyContinue){
                        $SoBList.Add($_) 
                    }
                }
            }
            Set-Mailbox $entry.UserPrincipalName -GrantSendOnBehalfTo $SoBList -ErrorAction SilentlyContinue
        }
    }
}
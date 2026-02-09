Disconnect-ExchangeOnline -Confirm:$false
Connect-ExchangeOnline -UserPrincipalName ttiamiyu.adm@acrisurellc.com

function Connect-Onprem {
$path = "C:\Users\ttiamiyu\LLCpass.txt"
$USERNAME = "ttiamiyu.adm"
$pass = cat $path | ConvertTo-SecureString
$Cred =  New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $USERNAME,$pass
$session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://ACRBARHMX01.acrisurellc.com/PowerShell/ -Credential $Cred
Import-PSSession $Session -DisableNameChecking -AllowClobber -Prefix OnPrem
}

try {
Connect-MsolService 
Import-Module ActiveDirectory -ErrorAction Stop

$ok = $true
}
catch {
    $ok = $false
}
if ($ok){

$sharedlog = "$env:USERPROFILE\desktop\SharedProcessed.txt"
$Mailboxlog = "$env:USERPROFILE\desktop\MailboxProcessed.txt"

$BatchName = Read-Host "Enter batch name or part of the name"


Get-MigrationBatch  | where {$_.Identity -like "*$batchName*" } | Select Identity, Status -OutVariable Batches

$Q = Read-Host "Complete above batches now ? [Y] or [N]"
if ($q -eq "Y"){
#Write-Host "Sleeping for 45min"
    #Sleep -Seconds 2500
    $Batches | % {[string]$id = $_.Identity; 
        Write-Host "Processing $id " -ForegroundColor Green
        if ($_.Status -notlike "Complet*"){
            Complete-MigrationBatch -Identity $id -Confirm:$false 
        }
    }

    $count = 1..100
    Write-Host "Sleeping for 15min"
   # sleep -Seconds 900
    Connect-Onprem
    $i = 0
    forEach ($item in $count){
        $Batches| % {
        
        [string]$id = $_.Identity; 
        $Stats = Get-MigrationUser -BatchId $ID | Get-MigrationUserStatistics
        $Stats | FT BatchId, Identifier, SyncedItemCount, EstimatedTotalTransferCount, TotalItemsInSourceMailboxCount, PercentageComplete, *status* -AutoSize

        
        ForEach ($user in $stats){
         
         $status = $user.StatusDetail
         [string]$Identity = $user.Identity.Id
         if ($Status -eq "Completed"){
            $AdUSer = Get-AdUSer -Filter {UserPrincipalNAme -eq $Identity} -Properties EmployeeID
            if ($AdUSer.EmployeeID -like "*Shared*"){
                $existingShared = cat $sharedlog
                $existingMailbox = cat $Mailboxlog
                if ($existingShared -notcontains $Identity){
                    Write-Host "$identity is a shared mailbox, setting as shared"
                    Set-Mailbox $Identity -Type Shared
                    
                    $RemoteMailbox = Get-OnPremRemoteMailbox $Identity
                    $ExternalEmail = $RemoteMailbox.SamAccountName + "@acrisure.mail.onmicrosoft.com"
                    try {
                        $ok = $true
                        Set-OnPremRemoteMailbox $RemoteMailbox.PrimarySmtpAddress -RemoteRoutingAddress $ExternalEmail -EmailAddressPolicyEnabled:$false -erroraction stop
                    }
                    catch {
                        Write-Warning -Message $Error[0].Exception 
                        $ok = $false
                    }
                    if ($Ok){
                        $Identity >> $sharedlog
                    }
                }

            }
            else {
                if ($existingMailbox -notcontains $Identity){
                    Write-Host "$identity is a user mailbox, adding to phone group and MFA exclusion"
                    $AZUser = Get-Recipient $Identity

                    try {
                     Add-MsolGroupMember -GroupObjectId "c6c7d7f4-2dfd-4c68-83b2-8fd334441be9" -GroupMemberObjectId $AZUser.ExternalDirectoryObjectId -ErrorAction Stop
                     Add-MsolGroupMember -GroupObjectId "724e0275-cc20-41a6-97f1-1f935a4e21e4" -GroupMemberObjectId $AZUser.ExternalDirectoryObjectId -ErrorAction Stop

                    $RemoteMailbox = Get-OnPremRemoteMailbox $Identity -errorAction Stop
                    $ExternalEmail = $RemoteMailbox.SamAccountName + "@acrisure.mail.onmicrosoft.com"
                    Set-OnPremRemoteMailbox $RemoteMailbox.PrimarySmtpAddress -RemoteRoutingAddress $ExternalEmail -EmailAddressPolicyEnabled:$false -errorAction Stop
                    }
                    catch {
                        Write-Warning -Message $Error[0].Exception 
                        $ok = $false
                    }
                    if ($ok){
                        $Identity >> $Mailboxlog
                    }
             }
             }
         }
        }
        }
    $i++
    Write-Host "Sleeping for 5 mins...Will resume momentarily...Grab a popcorn 🍿🍾"
    sleep -Seconds 300
        if ($i -eq 5 ){
        $q = Read-Host "Is all migration completed ?"
             if ($q -eq "y"){
               $ApName = Read-Host "Enter AP friendly name"
                $ABP = Get-AddressBookPolicy | Where {$_.Identity -like "*$APName*"} | Select Identity, AddressLists, @{l="RecipientFilter";e={(Get-AddressList $_.AddressLists[0]).RecipientFilter}} 
                if ($ABP -eq $null){
                    $domainname = Read-Host "Enter domain name"
                    $ApCode = Read-Host "Enter AP Code"
                    Create-AddressBookPolicy -domainSuffix $domainname -APFriendlyName $ApName -APCode $ApCode
                    $ABP = Get-AddressBookPolicy | Where {$_.Identity -like "*$APName*"} | Select Identity, AddressLists, @{l="RecipientFilter";e={(Get-AddressList $_.AddressLists[0]).RecipientFilter}} 
                }
                
                if ($abp.Identity -notlike "acr_*"){
                $domain = $ABP.RecipientFilter.Split("'")[1]
                if ($domain.Length -gt 1 ){
                    $Mailboxes = Get-Recipient -Filter "((RecipientType -eq 'UserMailbox') -AND (EmailAddresses -like '$($domain)'))"

                    ForEach ($mailbox in $Mailboxes){
                        Write-Host "Found $($mailbox.PrimarySmtpAddress)"
                        If ($mailbox.AddressBookPolicy -eq $null){
                            Write-Host "Assigning $($abp.Identity) to $($mailbox.PrimarySmtpAddress) " -ForegroundColor Green
                            Set-mailbox $mailbox.PrimarySmtpAddress -AddressBookPolicy $abp.Identity 
                        }
                    }
        
                }
    
                }

        }
        $i = 0
    }   
    }
}
}
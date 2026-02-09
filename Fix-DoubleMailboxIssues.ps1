

$path = "C:\Users\ttiamiyu\LLCpass.txt"
$USERNAME = "ttiamiyu.adm@acrisurellc.com"
$pass = cat $path | ConvertTo-SecureString
$Cred =  New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $USERNAME,$pass

$session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://ACRBARHMX01.acrisurellc.com/PowerShell/ -Credential $Cred
Import-PSSession $Session -DisableNameChecking -AllowClobber -Prefix OP


$mailboxUPN = Read-Host "Enter mailbox UPN"
$target = $mailboxUPN.Split("@")[0] + "@acrisure.mail.onmicrosoft.com"
$txtfile = $mailboxUPN + ".txt"

$formatenumerationlimit = -1
$OnpremMailbox = Get-OPMailbox $mailboxUPN

$OnpremMailbox | fl > $txtfile
$OnpremMailboxGUID = $OnpremMailbox.ExchangeGuid

$O365Mailbox = Get-Mailbox $mailboxUPN
Disable-OPMailbox $mailboxUPN
Enable-OPRemoteMailbox $mailboxUPN -RemoteRoutingAddress $target
Set-OPRemoteMailbox $mailboxUPN -ExchangeGuid $O365Mailbox.ExchangeGuid
Write-host "Sleeping for 30min..."
Sleep -Seconds 1800


[guid]$O365MailboxGUID = $O365Mailbox.ExchangeGuid

New-MailboxRestoreRequest -RemoteHostName "mail.acrisurellc.com" -RemoteCredential $cred -SourceStoreMailbox $OnpremMailboxGUID `
 -TargetMailbox $O365Mailbox.DistinguishedName -RemoteDatabaseGuid ((Get-OPMailboxDatabase $OnpremMailbox.Database).guid)  -RemoteRestoreType DisconnectedMailbox -OutVariable Batch

Get-MailboxRestoreRequest $Batch.Identity | `
Get-MailboxRestoreRequestStatistics -IncludeReport | `
select -ExpandProperty Report | `
select -ExpandProperty Entries | `
select -Last 2 | `
select -First 1

Get-MailboxRestoreRequest $Batch.Identity | Get-MailboxRestoreRequestStatistics
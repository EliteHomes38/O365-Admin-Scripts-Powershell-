$domain = Read-Host "Enter primary domain"

$mailboxes = Get-Mailbox -ResultSize Unlimited -Filter "EmailAddresses -like '*$($domain)'"



#Disconnect-ExchangeOnline -Confirm:$false
#Connect-ExchangeOnline

$ApName = $domain.Split(".")[0]
$ReportPath = "c:\mig\"
$MailboxStatsPath = $ReportPath + $ApName + "-MailboxReport.csv"
$DomainsFoundPath = $ReportPath + $ApName + "-DomainsFound.csv"

$MailboxData = $domainreport = @()
#Import-Module ActiveDirectory

$count = $Mailboxes.count
$i = 0

foreach ($Mailbox in $Mailboxes) {
	$i++
	Write-Host "checking $i of $count - $mailbox"

	$ArcMbx = ""
	$ArcMbx = ""
	$Arcstats = ""
	$smtp = [string]$Mailbox.PrimarySmtpAddress
    
    $AdUser = Get-aduser -Filter {mail -eq $smtp} -Properties DisplayName,AdSyncEnabled,EmployeeID,AgencyCode

	$obj = $props = @()
    $emailAddresses = $Mailbox.EmailAddresses | where {($_ -like "*@*") -and ($_ -notlike "*onmicrosoft.com") -and ($_ -notlike "SPO:SPO*") -and ($_ -notlike "SIP*")}
       # $emailAddresses = $Mailbox.EmailAddresses | select -expand ProxyAddressString | where {($_ -like "*@*") -and ($_ -notlike "*onmicrosoft.com") -and ($_ -notlike "SPO:SPO*") -and ($_ -notlike "SIP*")}
    $Domains = $emailAddresses | % {
        
        $objD = "" | Select Domains
        $objD.Domains = $_.SPlit("@")[1]
        $domainreport += $objD
    }
    $emailAddresses = $emailAddresses -join ";"
		
	$props = [ordered]@{
		'Name'                            = $Mailbox.DisplayName;
        'UPN'                             = $Mailbox.UserPrincipalName;
		'Email'                           = $smtp;
        'SyncEnabled'            = $AdUser.AdSyncEnabled;
        'EmployeeID'            = $AdUser.EmployeeID;
        'AgencyCode'            = $AdUser.AgencyCode;
        'Company' = $AdUser.Company ;
		'RecipientType'                   = $Mailbox.RecipientTypeDetails;
        'Proxy Collections'               = $emailAddresses

	}		
	$obj = New-Object -TypeName PSObject -Property $props
	$MailboxData += $obj
	$props = $null
	$user = $null
	$mailbox = $null
	$obj = $null
		
}

if ($MailboxData)
{
    $MailboxData| Export-Csv $MailboxStatsPath -Encoding UTF8 -NoTypeInformation
    Invoke-Item $MailboxStatsPath
}
if ($domainreport){
    $domainreport | Select domains -Unique | Export-Csv $DomainsFoundPath -Encoding UTF8 -NoTypeInformation
    Invoke-Item $DomainsFoundPath
}
#Disconnect-ExchangeOnline -Confirm:$false
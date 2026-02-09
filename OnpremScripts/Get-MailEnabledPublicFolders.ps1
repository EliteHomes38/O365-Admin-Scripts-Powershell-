#Disconnect-ExchangeOnline -Confirm:$false
#Connect-ExchangeOnline

$ApName = Read-Host "Enter AP Code or Name"
$ReportPath = "$($env:USERPROFILE)\Desktop\"
$MailboxStatsPath = $ReportPath + $ApName + "-MailboxReport.csv"
$DomainsFoundPath = $ReportPath + $ApName + "-DomainsFound.csv"

$MailboxData = $domainreport = @()
#Import-Module ActiveDirectory

	
$Mailboxes = Get-MailPublicFolder
$count = $Mailboxes.count
$i = 0

foreach ($Mailbox in $Mailboxes) {
	$i++
	Write-Host "checking $i of $count - $mailbox"

	$ArcMbx = ""
	$ArcMbx = ""
	$Arcstats = ""
	$smtp = [string]$Mailbox.PrimarySmtpAddress

	$obj = $props = @()
    $emailAddresses = $Mailbox.EmailAddresses | select -expand ProxyAddressString | where {($_ -like "*@*") -and ($_ -notlike "*onmicrosoft.com") -and ($_ -notlike "SPO:SPO*")}
    $Domains = $emailAddresses | % {
        
        $objD = "" | Select Domains
        $objD.Domains = $_.SPlit("@")[1]
        $domainreport += $objD
    }
    $emailAddresses = $emailAddresses -join ";"
		
	$props = @{

		'Active?'                         = "";
        'Login'                           = $mailbox.alias;
		'Name'                            = $Mailbox.DisplayName;
        'UPN'                             = $Mailbox.UserPrincipalName;
		'Email'                           = $smtp
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
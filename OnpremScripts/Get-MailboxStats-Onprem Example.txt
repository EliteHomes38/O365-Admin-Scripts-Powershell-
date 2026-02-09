#Disconnect-ExchangeOnline -Confirm:$false
#Connect-ExchangeOnline

$ApName = Read-Host "Enter AP Code or Name"
$ReportPath = "$($env:USERPROFILE)\Desktop\"
$MailboxStatsPath = $ReportPath + $ApName + "-MailboxReport.csv"
$DomainsFoundPath = $ReportPath + $ApName + "-DomainsFound.csv"

$MailboxData = $domainreport = @()
#Import-Module ActiveDirectory

	
$Mailboxes = Get-Mailbox -resultsize Unlimited
$count = $Mailboxes.count
$i = 0

foreach ($Mailbox in $Mailboxes) {
	$i++
	Write-Host "checking $i of $count - $mailbox"

	$ArcMbx = ""
	$ArcMbx = ""
	$Arcstats = ""
	$smtp = [string]$Mailbox.PrimarySmtpAddress

	#primary
		
	try {
		$stats = Get-MailboxStatistics $smtp -erroraction SilentlyContinue
	}
	catch {

	}
	$error.Clear()
	#Archive
	try {
		$ArcMbx = Get-Mailbox $smtp -Archive -erroraction SilentlyContinue
	}
	catch {

	}
	$error.Clear()
	try {
		$Arcstats = Get-MailboxStatistics $smtp -archive -erroraction SilentlyContinue
	}
	catch {

	}
	$error.Clear()
			
	#Primary
	
	if ($stats) {
		[string]$Total = $stats.TotalItemSize.value
		$TotalItemSize = [double]$Total.SubString($Total.indexof("(") + 1, $Total.indexof(" b") - $Total.indexof("("))
		$TotalItemSizeGB = $TotalItemSize / 1GB
		$TotalItemSizeGB = "{0:N3}" -f $TotalItemSizeGB
		$TotalItemCount = $stats.ItemCount
		$DeletedItemCount = $stats.DeletedItemCount

		[string]$totalD = $stats.TotalDeletedItemSize.value
		$DeletedItemSize = [double]$TotalD.SubString($TotalD.indexof("(") + 1, $TotalD.indexof(" b") - $TotalD.indexof("("))
		$DeletedItemSizeGB = $DeletedItemSize / 1GB
		$DeletedItemSizeGB = "{0:N3}" -f $DeletedItemSizeGB

	}
	else {
		$TotalItemSizeGB = ""
	}
	#Primarymbx quota
	[string]$mbxquota = $mailbox.ProhibitSendReceiveQuota
	$mbxquotaSize = [double]$mbxquota.SubString($mbxquota.indexof("(") + 1, $mbxquota.indexof(" b") - $mbxquota.indexof("("))
	$mbxquotaSizeGB = $mbxquotaSize / 1GB
	$mbxquotaSizeGB = "{0:N3}" -f $mbxquotaSizeGB
		
	#Archive
		
	if ($Arcstats) {
		[string]$ArcTotal = $Arcstats.TotalItemSize.value
		$ArcTotalItemSize = [double]$ArcTotal.SubString($ArcTotal.indexof("(") + 1, $ArcTotal.indexof(" b") - $ArcTotal.indexof("("))
		$ArcTotalItemSizeGB = $ArcTotalItemSize / 1073741824
		$ArcTotalItemSizeGB = "{0:N3}" -f $ArcTotalItemSizeGB
	}
	else {
		$ArcTotalItemSizeGB = ""
	}
	#ArchiveMbx limit
		
	if ($ArcMbx) {
		[string]$Arcmbxquota = $ArcMbx.ArchiveQuota
		$ArcmbxquotaSize = [double]$Arcmbxquota.SubString($Arcmbxquota.indexof("(") + 1, $Arcmbxquota.indexof(" b") - $Arcmbxquota.indexof("("))
		$ArcmbxquotaSizeGB = $ArcmbxquotaSize / 1GB
		$ArcmbxquotaSizeGB = "{0:N3}" -f $ArcmbxquotaSizeGB
	}
	else {
		$ArcmbxquotaSizeGB = $null
	}
		
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
		'Email'                           = $smtp;
        'Mobile Number'                   = [string](Get-User $Mailbox.UserPrincipalName).MobilePhone
        'Remote ?'                        = "";
        'Found In Acrisure AD'            = "";
        'EmployeeIDInAcrisure'            = "";
        'AgencyCodeInAcrisure'            = "";
		'Primary-TotalItemSize(GB)'       = $TotalItemSizeGB;
		'Primary-TotalItemCount'          = $TotalItemCount;
		'Primary-DeletedItemSize(GB)'     = $DeletedItemSizeGB;
		'Primary-DeletedItemCount'        = $DeletedItemCount;
		'Primary-Mailbox Quota(GB)'       = $mbxquotaSizeGB;
		'Retention Policy'                = $mailbox.RetentionPolicy;
		'Archive-TotalItemSize(GB)'       = $ArcTotalItemSizeGB;
		'AutoExpandingArchiveEnabled'     = $ArcMbx.AutoExpandingArchiveEnabled;
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
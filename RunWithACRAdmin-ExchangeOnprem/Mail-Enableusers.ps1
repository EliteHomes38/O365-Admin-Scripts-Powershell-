[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [string]$ApMailboxReportPath,
    [Parameter(Mandatory = $true)]
    [string]$MigWizReportPath
)
#$data = Import-csv (Read-Host "Enter CSV Path")
$projectdata = Import-csv $MigWizReportPath
$data = Import-Csv $ApMailboxReportPath

$excludefromproxy = "SPO:","SIP:",".local"

ForEach ($user in $projectdata) {
    $email = $user.'Source Email Address'
    $upn = $user.'Destination Email Address'
    $UserInfo = $data | where { $_.Email -eq $email }
    if (!($UserInfo)){
        $UserInfo = $data | where { $_.ProxyCollections -match $email } | Select -First 1
    }

    if ($email -and $UserInfo) {
 
        $usercheck = Get-User $upn -ErrorAction SilentlyContinue 
        if ($usercheck) 
        {

        $proxy = $userInfo.ProxyCollections.trim()
        $target = $usercheck.SamAccountName + "@acrisure.onmicrosoft.com"
        $proxy = $proxy.split(";")
        if ($proxy.Length -gt 1){
            $nproxy = {$proxy}.Invoke()
            $excludefromproxy | % {
            foreach ($entry in $proxy) {
                if ($entry -match $_) {
                    $nproxy.Remove($entry)
                    Write-Host "Testing $_ match with $entry"
                }
            }
        }
            $proxy = $nproxy -join ";"
        }
    
        $proxy = $proxy.Replace("SMTP:", "").Replace("smtp:", "")  

        
        try {
            $ok = $true
            if ($usercheck.RecipientTypeDetails -ne "MailUser"){
                Enable-MailUser $upn -ExternalEmailAddress $target -Confirm:$false -PrimarySmtpAddress $email -ErrorAction Stop
            }
            if ($proxy.Length -gt 1){
            Set-mailuser $upn -EmailAddresses @{Add = $proxy -split ";" } -EmailAddressPolicyEnabled:$false 
            }
            else{
                Set-mailuser $upn -PrimarySmtpAddress $email -EmailAddressPolicyEnabled:$false 
            
            }
            Get-MailUser $upn | Select DisplayName, EMailaddresses, PrimarySMTPAddress, UserprincipalName , ExternalEmailAddress
        }
        catch {
            $ok = $false
            $Errors = $email + ":" + $($Error[0].Exception)
             $adtarget = "SMTP:" + $target
            Get-AdUser -Filter {UserPrincipalName -eq $upn} | Set-ADUser -EmailAddress $email -Replace @{targetAddress=$adtarget} 
            Write-Warning "Failed: $($Error[0].Exception)"
            $Errors >> c:\mig\errorcreatingmailusers.txt 
        }
        if ($ok) {
            Write-Host "Completed for $email" -ForegroundColor Green
        }
        }
    }
}
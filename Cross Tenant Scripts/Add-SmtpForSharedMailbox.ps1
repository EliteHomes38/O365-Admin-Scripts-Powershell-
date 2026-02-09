[CmdletBinding()]
 Param(
        [Parameter(Mandatory=$true)]
        [string] $domainSuffix
)
    get-mailbox -Filter "Customattribute10 -like '*$($domainSuffix)'" | % {
    #cat C:\Mig\users.txt | get-mailbox | % {
    $Email = $_.PrimarySmtpAddress
    $newprimary = @()
    $old = "smtp:" + $_.PrimarySmtpAddress
    [string]$new = $_.Customattribute10; 
    Write-Host "$($_.DisplayNAme) - $($_.CustomAttribute10)"
    if ($new -ne $old){
        $New = "SMTP:" + $new
        $newprimary = $new
            try{
        Set-Mailbox $_.PrimarySmtpAddress -EmailAddresses $newprimary -Force -ErrorAction stop
    #Set-Mailbox $_.PrimarySmtpAddress -EmailAddresses @{Add=$new} -Force 
    }
    catch {

            $obj = "" | Select User, Error, ErrorType
            $obj.User = $Email
            $obj.Error = $Error[0].Exception
            $Obj.errortype = $Error[0].CategoryInfo.Reason
            $obj | Export-Csv  ErrorSettingSmtp.csv -NoTypeInformation -Append 
        }
    }

}

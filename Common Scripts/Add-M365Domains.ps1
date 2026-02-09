Write-Host "************************************************" -ForegroundColor Green
Write-Host "This script requires three things:" -ForegroundColor Green
Write-Host "1 - Global Admin or Domain Name Admin:" -ForegroundColor Green
Write-Host "2 - MSOnline Module, if not installed, run Install-Module MSOnline" -ForegroundColor Green
Write-Host "3 - CSV file with domain list in the following format:" -ForegroundColor Green
Write-Host "Domain" -ForegroundColor Cyan
Write-Host "------" -ForegroundColor Cyan
Write-Host "xyz.com" -ForegroundColor Cyan
Write-Host "abc.com" -ForegroundColor Cyan
Write-Host "************************************************" -ForegroundColor Green

$Report = @()
$OutputPath = "$env:USERPROFILE\"
$csv = Read-Host "Enter csv file path where domains are listed...."

if (Test-Path $csv){
    $ImportedCSV = Import-Csv $csv
    ForEach ($domain in $ImportedCSV){
        $domain = $domain.domain 
        New-MsolDomain –Name $domain -VerificationMethod DnsRecord 
        $TxtRecord = (Get-MsolDomainVerificationDns –DomainName $domain –Mode DnsTxTRecord).Text
        $obj = "" | Select Domain, TXTRecord
        $obj.Domain = $domain
        $obj.TXTRecord = $TxtRecord
        $Report += $obj
    }
}
$reportpath = $OutputPath + "O365domains.csv"
$Report | Export-Csv $reportpath -NoTypeInformation
Invoke-Item $OutputPath

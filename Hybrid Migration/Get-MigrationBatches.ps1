#Connect-ExchangeOnline -UserPrincipalName ttiamiyu.adm@acrisurellc.com
$BatchName = Read-Host "Enter batch name or part of the name"

$reportout = "$env:USERPROFILE\desktop\"+ $BatchName+ "-BatchReport.csv"
$Batches = Get-MigrationUser -ResultSize Unlimited | where {$_.BatchID -like "*$batchName*" } | Select Identity, BatchID, Status, @{l="Mail";e={$ID = $_.Identity;(Get-AduSer -filter {UserPrincipalName -eq $ID} -properties mail).Mail}}
$Batches | Export-csv $reportout -NoTypeInformation
Invoke-Item $reportout


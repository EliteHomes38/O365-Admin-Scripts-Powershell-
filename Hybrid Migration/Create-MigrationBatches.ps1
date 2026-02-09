$MainPath = get-childitem  "C:\Mig\Batches\fix"

$MigEnpoint = Get-MigrationEndpoint

ForEach ($item in $MainPath){
$MigPath = $item.FullName
$FileName = $item.Name -replace ".csv",""
    $Name = $filename
    Write-Host "Creating migration batch for $name" -ForegroundColor Green
    New-MigrationBatch -Name $Name -SourceEndpoint $MigEnpoint.Identity -CSVData ([System.IO.File]::ReadAllBytes($MigPath)) `
    -NotificationEmails "o365_engineers@acrisurellc.com" `
    -TargetDeliveryDomain acrisure.mail.onmicrosoft.com -AutoStart
}


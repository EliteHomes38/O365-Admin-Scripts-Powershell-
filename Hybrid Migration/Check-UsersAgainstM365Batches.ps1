$users = Read-Host "Enter txt path for users"
$apName = Read-Host "AP Name"
$Report = @()

$users = cat $users
$count = ($users | measure).count

$i = 0
ForEach ($user in $users){
    $pct = ($i/$count * 100)

    Write-Progress -Activity "checking user status" -Status "$i of $count - $user " -PercentComplete $pct
    $UserInfo = Get-ADInfo $user 
    forEach ($item in $UserInfo){
        $upn = $item.UserPrincipalName
        $Migration = Get-MigrationUser $upn -errorAction SilentlyContinue
        if (!($Migration)){
            $Migration = Get-MigrationUser $item.Mail -errorAction SilentlyContinue
        }

        $obj = "" | Select DisplayName, Mail, UserPrincipalName, AdSyncEnabled, AgencyCode, BatchID, Status, ErrorSummary
        $obj.DisplayName = $item.DisplayName
        $obj.Mail = $item.Mail
        $obj.UserPrincipalName = $upn
        $obj.AdSyncEnabled = $item.AdSyncEnabled
        $obj.AgencyCode = $item.AgencyCode
        $obj.BatchID = $Migration.BatchID
        $obj.Status = $Migration.Status
        $obj.ErrorSummary = $Migration.ErrorSummary
        $Report += $obj

        $i++
    }
}

$OutPath = "C:\Mig\" + $apName + "-MigrationReport.csv"
$Report | Export-Csv $OutPath -NoTypeInformation

Invoke-Item $OutPath
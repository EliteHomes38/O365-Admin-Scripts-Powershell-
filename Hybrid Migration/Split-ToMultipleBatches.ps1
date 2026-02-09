$allBatch = Import-Csv .\NewBatch.csv
$grouped = $allBatch | group -Property "AP Code"

ForEach ($item in $grouped){
    $Ap = $item.Group.'AP Code' | select -Unique
    $ap = $Ap.Replace("AP-","")
    $directory = "C:\Mig\Batches\Fix" + "\$ap" + "-Fix.csv"
    $item.Group | Select @{l="EmailAddress";e={$_.UserPrincipalName}} | Export-csv $directory -NoTypeInformation
    $item

}
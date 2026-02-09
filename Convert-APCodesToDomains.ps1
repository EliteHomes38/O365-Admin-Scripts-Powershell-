$users = import-csv C:\Mig\Users.csv

ForEach ($user in $users){
$group = $user.group
    $grp = (Get-MsolGroup -SearchString $group).ObjectId
    $mem = (Get-MsolGroupMember -GroupObjectId $grp).emailaddress[0]
    $admem = (Get-Aduser -Filter {UserprincipalName -eq $mem} -Properties mail).mail
    $domain = $admem.split("@")[1]
    $obj = "" | Select ApCode, Group, Domain
    $obj.Apcode = $user.code
    $obj.Group = $group
    $obj.Domain = $domain

    $obj | Export-Csv ApCodesAndDomains.csv -NoTypeInformation -Append
}

.\ApCodesAndDomains.csv 
$PGMUsers = Import-csv C:\mig\UmpUsers.csv

ForEach ($user in $PGMUsers){

    $upn = $user.AcrisureUPN
    $proxy = $user.ProxyCollections
    $AdUser = Get-aduser -Filter {UserprincipalName -eq $upn} -Properties Mail, ProxyAddresses
    $proxysplit = $proxy.split(";")
    if ($proxysplit.count -gt 1){
        Set-aduser $AdUser.DistinguishedName -add @{ProxyAddresses=$proxy -split ";"}
        Get-aduser $AdUser.DistinguishedName -Properties Mail, ProxyAddresses
    }
}
$domains = cat .\OnPremDomains.txt
$Report = @()

[System.Collections.Generic.List[string]]$Mxs = @()
ForEach ($domain in $domains){
    $result = Resolve-DnsName $domain -Type Mx

        if ($result){
        forEach ($item in $result){
            $MXs.Add($item.NameExchange)
        }
            $obj = "" | Select Domain, MX
            $obj.Domain = $domain
            [string]$obj.MX = $MXs     
        }
        else {
            $obj = "" | Select Domain, MX
            $obj.Domain = $domain
            [string]$obj.MX = "Not found"
        }
    $Report += $obj
    $obj = $MXs = ""
}

$Report | Export-csv AllMxRecordForOnPremAPs.csv -NoTypeInformation
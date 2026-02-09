$addreslists = import-csv .\APsGAL.csv

ForEach ($list in $addreslists){
    .\Create-CustomGAL-v1.ps1 -domainSuffix $list.Domain -APFriendlyName $list.FriendlyName -APCode $list.APCode

}
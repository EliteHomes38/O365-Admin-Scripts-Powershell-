$Addresslist = import-csv .\Documents\AddressBooks.csv

ForEach ($list in $Addresslist){
    $domainSuffix = $list.domains
    $adl = $list.Addresslists

    $recipientfilter = "(((EmailAddresses -like '*@$($domainSuffix)') -or (PrimarySmtpAddress -like '*@$($domainSuffix)')) -AND ((RecipientType -eq 'UserMailbox') -or (RecipientType -eq 'MailContact') -or (RecipientType -eq 'MailUser') -or (((RecipientType -eq 'MailUniversalDistributionGroup') -or (RecipientType -eq 'MailUniversalSecurityGroup') -or (RecipientType -eq 'MailNonUniversalGroup') -or (RecipientType -eq 'DynamicDistributionGroup')))))"
    
    Set-AddressList $adl -RecipientFilter $recipientfilter
}
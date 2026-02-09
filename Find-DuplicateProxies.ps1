# Hash table of email addresses.
$List = @{}

# Find all users with email addresses.
$Searcher = [adsisearcher]"(&(objectCategory=person)(objectClass=user)(proxyAddresses=*))"

$Results = $Searcher.FindAll()
ForEach ($Result In $Results)
{
    $DN = $Result.Properties.Item("distinguishedName")
    $Addresses = $Result.Properties.Item("proxyAddresses")
    ForEach ($Address In $Addresses)
    {
        If ($Address.Contains(":") -eq $True)
        {
            $Email = ($Address -Split ":")[1]
        }
        Else {$Email = $Address}
        If ($List.ContainsKey($Email))
        {
            $Temp = $List[$Email]
            $List[$Email] = "$Temp;$DN"
            "Duplicate email: $Email"
            $Names = $List[$Email] -Split ";"
            ForEach ($Name In $Names)
            {
                " -- $Name"
            }
        }
        Else
        {
            $List.Add($Email, $DN)
        }
    }
}
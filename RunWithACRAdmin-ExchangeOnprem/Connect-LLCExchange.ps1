$session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://ACRBARHMX01.acrisurellc.com/PowerShell/
Import-PSSession $Session -DisableNameChecking -AllowClobber
    
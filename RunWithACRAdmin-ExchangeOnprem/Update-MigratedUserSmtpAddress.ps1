
$users = cat C:\mig\ACI.txt | Get-RemoteMailbox

ForEach ($user in $users ){

    $addresses = $user.EmailAddresses

    $new = $addresses | % {
        if ($_ -like "*@acitx.com"){
            $_.Replace("smtp","SMTP") 
            
        }
        elseif ($_ -clike "SMTP:*"){
            $_.ToLower()
        }
        else {
            $_
        
        }
    }

    $new

    Set-Mailbox $user.PrimarySmtpAddress -EmailAddresses $new -EmailAddressPolicyEnabled:$false
}
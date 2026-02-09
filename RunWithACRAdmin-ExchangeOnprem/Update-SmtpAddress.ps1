
$users = cat C:\mig\ACIConsolidation.txt | get-mailbox

ForEach ($user in $users ){

    $addresses = $user.EmailAddresses
    $primary = ""

    $new = $addresses | % {
        if ($_ -like "*@AcrisureLLC.com"){
            $_.Replace("smtp","SMTP") 
            $primary = $_.Replace("smtp:","") 
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
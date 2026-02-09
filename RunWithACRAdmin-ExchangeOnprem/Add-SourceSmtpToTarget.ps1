function get-File {
        $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ 
            InitialDirectory = [Environment]::GetFolderPath('Desktop') 
            Filter           = 'CSV (*.csv)|*.csv'
        }
        $null = $FileBrowser.ShowDialog()
    
        return $FileBrowser.FileName
    }
    
$file = get-File

$Users = import-csv $file

ForEach($user in $Users){
    $Source = $user.'Source Email Address'
    $target = $user.'Destination Email Address'
     $login = $Source.Split("@")[0]
    $ExternalEmail = $login + "@acrisure.mail.onmicrosoft.com"

    $userCheck = Get-user $target
    if ($userCheck.RecipientTypeDetails -eq "User"){
        Enable-MailUser $target -ExternalEmailAddress $ExternalEmail -Confirm:$false
    }

    if(Get-MailUser $target){
        
        
         Write-Host "adding $source to smtp collection for $target" -ForegroundColor Green -NoNewline
         
         #$Primary = "SMTP:"+$Source
         try {
            Set-MailUser $target -PrimarySmtpAddress $Source  -EmailAddressPolicyEnabled:$false -ExternalEmailAddress $ExternalEmail  -ErrorAction Stop
         }
         catch
         {
            Write-Warning $Error[0].Exception
         }
    }
    else {
        Write-host "$target cannot be found" -ForegroundColor Cyan
    }
}
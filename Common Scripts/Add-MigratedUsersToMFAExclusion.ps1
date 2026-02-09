Connect-AzureAD -AccountId "aburns.adm@acrisurellc.com" -TenantId "c2ec94c0-ebd0-4630-aef2-2dcf0eb68ebd"
   function get-File {
        $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ 
            InitialDirectory = [Environment]::GetFolderPath('Desktop') 
            Filter           = 'TEXT (*.txt)|*.txt'
        }
        $null = $FileBrowser.ShowDialog()
      
        return $FileBrowser.FileName
    }
    $file = cat ( get-File )
    $MFAGroup = "724e0275-cc20-41a6-97f1-1f935a4e21e4"
    $PhoneGroup = "063004af-afb2-4738-a39e-a0c4d5642aef"
    $MFACurrentmembers = Get-AzureADGroupMember -ObjectId $MFAGroup -All:$true
    $MobileGroupmembers = Get-AzureADGroupMember -ObjectId $PhoneGroup -All:$true
    
    ForEach ($user in $MFACurrentmembers){
        Write-Host "Removing member $($user.DisplayName) in the group before adding new members"
        Remove-AzureADGroupMember -ObjectId $MFAGroup -MemberId $user.ObjectId

    }
    
    $file | % { 
        
        $aduser = Get-Recipient $_ -ErrorAction silentlycontinue
        $Ad = Get-AduSer -Filter {(mail -eq $_) -or (UserPrincipalName -eq $_)} -Properties EmployeeID

        if ($aduser.recipienttypedetails -ne "sharedMailbox"){
            try {
            $ok = $true
            
            if ($MFACurrentmembers.ObjectID -match $ADUser.ExternalDirectoryObjectId){

                Write-Host "$_ already added to MFA exclusion" -ForegroundColor Green -NoNewline
            }
            else{
                Write-Host "adding $_ to MFA exclusion" -ForegroundColor Green -NoNewline
                Add-AzureADGroupMember -ObjectId $MFAGroup -RefObjectId $ADUser.ExternalDirectoryObjectId
            }
            if ($MobileGroupmembers.ObjectID -match $ADUser.ExternalDirectoryObjectId){
                Write-Host "$_ already added to Phone Group" -ForegroundColor Green -NoNewline
            }
            else{
                Write-Host "Adding $_ to Mobile phone group " 
                Add-AzureADGroupMember -ObjectId $PhoneGroup -RefObjectId $aduser.ExternalDirectoryObjectId 
            }
        }
            catch {
            $ok = $false
            Write-Host "❌" -ForegroundColor Red
            Write-Warning $Error[0].Exception
        }
            If ($ok){
                Write-Host "✔" -ForegroundColor Green
            }
        }
    
    }
Connect-MsolService
   function get-File {
        $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ 
            InitialDirectory = [Environment]::GetFolderPath('Desktop') 
            Filter           = 'TEXT (*.txt)|*.txt'
        }
        $null = $FileBrowser.ShowDialog()
      
        return $FileBrowser.FileName
    }
    $file = cat ( get-File )

    $file | % { 
        Write-Host "Adding $_ to everyone-int-usr-AllowedMobileUsers " -ForegroundColor Green -NoNewline
        $ADSUer = Get-Recipient $_ 
        try {
            $ok = $true
            Add-MsolGroupMember -GroupObjectId "c6c7d7f4-2dfd-4c68-83b2-8fd334441be9" -GroupMemberObjectId $ADSUer.ExternalDirectoryObjectId 
        }
        catch {
            $ok - $false
            Write-Host "❌" -ForegroundColor Red
            Write-Warning $Error[0].Exception
        }
        If ($ok){
            Write-Host "✔" -ForegroundColor Green
        }
    
    }
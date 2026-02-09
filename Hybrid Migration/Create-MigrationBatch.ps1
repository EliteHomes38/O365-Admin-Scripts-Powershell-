 function get-File {
        $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ 
            InitialDirectory = [Environment]::GetFolderPath('Desktop') 
            Filter           = 'CSV (*.csv)|*.csv'
        }
        $null = $FileBrowser.ShowDialog()
    
        return $FileBrowser.FileName
    }
    
    $BatchName = Read-Host "Enter migration name e.g Cowden-COW-COW To O365"
    $file = get-File
    $MigEnpoint = Get-MigrationEndpoint
    
    New-MigrationBatch -Name $BatchName -SourceEndpoint $MigEnpoint.Identity -CSVData ([System.IO.File]::ReadAllBytes($file)) -NotificationEmails "o365_engineers@acrisurellc.com" `
        -TargetDeliveryDomain "acrisure.mail.onmicrosoft.com" -AutoStart
    
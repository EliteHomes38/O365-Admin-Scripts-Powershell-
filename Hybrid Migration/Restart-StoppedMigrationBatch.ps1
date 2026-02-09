Get-MigrationBatch -Status stopped | %{[string]$id = $_.identity; Start-MigrationBatch -Identity $id}

Sleep 300

Get-MigrationUser -Status Stopped  | Start-MigrationUser
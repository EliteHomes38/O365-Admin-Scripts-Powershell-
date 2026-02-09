$path = Read-Host "Enter Path for password" 
$pass = Read-Host "Enter Password" -AsSecureString
$pass | ConvertFrom-SecureString | Out-File $path

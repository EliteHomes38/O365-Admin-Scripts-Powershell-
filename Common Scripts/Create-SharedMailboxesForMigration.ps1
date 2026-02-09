$Report = @()
$ApCode = Read-Host "Enter Agency Code"
Connect-ExchangeOnline -UserPrincipalName aburns.adm@acrisurellc.com

function get-File {
        $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ 
            InitialDirectory = [Environment]::GetFolderPath('Desktop') 
            Filter           = 'CSV (*.csv)|*.csv'
        }
        $null = $FileBrowser.ShowDialog()
      
        return $FileBrowser.FileName
    }
$file = Import-csv ( get-File )

ForEach ($user in $file){
$DisplayName = $user.Name
$APEmail = $user.Email
$ACRUPN = $ApCode.Substring(7,3) + $APEmail.split("@")[0] + "@acrisurellc.com"



try {
    $ok = $true
    New-Mailbox -Name $DisplayName -DisplayName $DisplayName -PrimarySmtpAddress $ACRUPN -Shared -ErrorAction Stop
    Set-Mailbox $ACRUPN -CustomAttribute10 $APEmail -CustomAttribute11 $ApCode
    Get-Mailbox $ACRUPN | Select DisplayName, CustomAttribute10, CustomAttribute11
}
catch {
    $ok = $false
    Write-Warning "$ERROR on $DisplayName -  $($Error[0].ErrorDetails)"
    $ObjErr = "" | Select DisplayName, APCode, Email, APEmail, Error
    $objErr.DisplayName = $DisplayName
    $objErr.APCode = $ApCode
    $ObjErr.Email = $ACRUPN
    $objErr.APEmail = $APEmail
    $objErr.Error = $($Error[0].ErrorDetails)
    $Report += $ObjErr 
}
if ($ok){
    Write-Host "$DisplayName created successfully" -ForegroundColor Green
    $Obj = "" | Select DisplayName, APCode, Email, APEmail, Error
    $obj.DisplayName = $DisplayName
    $obj.APCode = $ApCode
    $Obj.Email = $ACRUPN
    $obj.APEmail = $APEmail
    $obj.Error = ""
    $Report += $Obj 
}

}

$Path = $env:USERPROFILE + "\Desktop\" + $apcode + "-SharedMailboxes.csv" 

$Report | export-csv $Path -NoTypeInformation

Invoke-Item $Path
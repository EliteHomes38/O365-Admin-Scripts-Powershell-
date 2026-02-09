#Bittitan credentials
$MigWizProjectName = Read-Host "Enter project name as listed in MigWiz"
$list = cat (Read-host "Enter list you want to compare with...use TXT file only")
$outpath = "$env:USERPROFILE\documents\" + $MigWizProjectName + ".csv"
$BTusername = "ttiamiyu@acrisure.com"
$BTpath = "C:\Users\ttiamiyu\documents\migwizpass.txt"

function Import-MigrationWizModule {
    if (((Get-Module -Name "BitTitanPowerShell") -ne $null) -or ((Get-InstalledModule -Name "BitTitanManagement" -ErrorAction SilentlyContinue) -ne $null)) {
        return
    }

    $currentPath = Split-Path -parent $script:MyInvocation.MyCommand.Definition
    $moduleLocations = @("$currentPath\BitTitanPowerShell.dll", "$env:ProgramFiles\BitTitan\BitTitan PowerShell\BitTitanPowerShell.dll",  "${env:ProgramFiles(x86)}\BitTitan\BitTitan PowerShell\BitTitanPowerShell.dll")
    foreach ($moduleLocation in $moduleLocations) {
        if (Test-Path $moduleLocation) {
            Import-Module -Name $moduleLocation
            return
        }
    }
    
    $msg = "INFO: BitTitan PowerShell SDK not installed."
    Write-Host -ForegroundColor Red $msg 

    Write-Host
    $msg = "ACTION: Install BitTitan PowerShell SDK 'bittitanpowershellsetup.msi' downloaded from 'https://www.bittitan.com'."
    Write-Host -ForegroundColor Yellow $msg

    Sleep 5

    $url = "https://www.bittitan.com/downloads/bittitanpowershellsetup.msi " 
    $result= Start-Process $url
    Exit

}

Write-Host "Logging on to MigWiz"
Import-MigrationWizModule 
$BTpass = cat $BTpath | ConvertTo-SecureString
$BTCred =  New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $BTUSERNAME,$BTpass


$mwTicket = Get-MW_Ticket -Credentials $BTcred -WorkgroupId "04b3eb66-ae4c-4874-96a6-851b2b88b746" -IncludeSharedProjects
$btTicket = Get-BT_Ticket -Credentials $BTcred -ServiceType BitTitan

# Get customer, filtered by company name
# Mailbox connector is scoped under customer
$customer = Get-BT_Customer -Ticket $btTicket -CompanyName 'Acrisure'


$connector = Get-MW_MailboxConnector -ticket $mwticket -Name $MigWizProjectName -OrganizationId "4fd7b530-dbd2-11ea-a815-000d3ac5e140"
$projectdata = Get-MW_Mailbox -ticket $mwticket -ConnectorId $connector.Id

forEach ($user in $list){
    if ($projectdata.ExportEmailAddress -match $user){
        Write-Host "$user is found" -ForegroundColor Green
        $ADinfo = Get-ADInfo -Users $user
        $obj = "" | select Name, Email, UPN, APCode, EmployeeID, AdSyncEnabled, FoundInMigWiz
        $obj.name = $ADinfo.DisplayName
        $obj.Email = $ADinfo.Mail
        $obj.UPN = $ADinfo.UserPrincipalName
        $obj.APCode = $ADinfo.AgencyCode
        $obj.EmployeeID = $ADinfo.EmployeeID
        $obj.AdSyncEnabled = $ADinfo.ADSyncEnabled
        $obj.FoundInMigWiz = "Yes"
        $obj | export-csv $outpath -NoTypeInformation -Append
        
    }
    else {
        Write-Host "$user is not found" -ForegroundColor Yellow
        $ADinfo = Get-ADInfo -Users $user
        $obj = "" | select Name, Email, UPN, APCode, EmployeeID, AdSyncEnabled, FoundinMigWiz
        $obj.name = $ADinfo.DisplayName
        $obj.Email = $ADinfo.Mail
        $obj.UPN = $ADinfo.UserPrincipalName
        $obj.APCode = $ADinfo.AgencyCode
        $obj.EmployeeID = $ADinfo.EmployeeID
        $obj.AdSyncEnabled = $ADinfo.ADSyncEnabled
        $obj.FoundInMigWiz = "No"
        $obj | export-csv $outpath -NoTypeInformation -Append
    }

}
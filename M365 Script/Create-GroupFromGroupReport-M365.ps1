
$groups = Import-csv ( Read-Host "Enter Group Report Path") 

$owner = Read-host "Enter Owner or backup Onwer email address (use its Acrisure UPN)"

$apname = Read-Host "AP Name or Last Three of AP Code"


$groups = $groups | Group-Object 'Distribution Group'

foreach ($group in $groups) {
    [string]$GroupEmail = $group.Group.'Distribution Group Primary SMTP address' | select -Unique
    $GroupName = $group.Group.'Distribution Group' | Select -Unique
    try {
        $ok = $true
        if ($GroupName -notmatch $apname){
            $GroupName = $GroupName + " " + $apname
        }
       
        New-UnifiedGroup -DisplayName $groupname -PrimarySmtpAddress $GroupEmail -RequireSenderAuthenticationEnabled:$false -Owner $owner -AutoSubscribeNewMembers $true
        Set-UnifiedGroup -Identity $GroupName -UnifiedGroupWelcomeMessageEnabled:$false
    }
    catch {
        $ok = $false
        Write-Warning "Error creating a new group for $group.name $($Error[0].Exception)" 
    
    }
    $newmembers = Foreach ($member in $group.Group.'Primary SMTP address') {
        Write-host "checking $member" -ForegroundColor Green;
        if ($member -ne $null) {
            (Get-mailbox $member -ea SilentlyContinue).UserPrincipalname
        }
    }
    if ($newmembers) {
        Add-UnifiedGroupLinks -Identity $GroupName -LinkType Members -Links ($newmembers | select -Unique)
             
        Write-Host "New members added to $GroupName successfully" -ForegroundColor Green
    
    }
}

$members = cat C:\Mig\WSILLC.txt
$owner = "lpolzin@AcrisureLLC.com"
$groupname = "zPresidio"
$GroupEmail = "zpresidio@presidiogrp.com"
   
   
    try {

       
        New-UnifiedGroup -DisplayName $groupname -PrimarySmtpAddress $GroupEmail -RequireSenderAuthenticationEnabled:$false -Owner $owner -AutoSubscribeNewMembers $true
        Set-UnifiedGroup -Identity $GroupName -UnifiedGroupWelcomeMessageEnabled:$false
    }
    catch {
        $ok = $false
        Write-Warning "Error creating a new group for $group.name $($Error[0].Exception)" 
    
    }
    $newmembers = Foreach ($member in $members) {
        Write-host "checking $member" -ForegroundColor Green;
        if ($member -ne $null) {
            (Get-mailbox $member -ea SilentlyContinue -RecipientTypeDetails UserMailbox).UserPrincipalname
        }
    }
    if ($newmembers) {
        Add-UnifiedGroupLinks -Identity $GroupName -LinkType Members -Links ($newmembers | select -Unique)
             
        Write-Host "New members added to $GroupName successfully" -ForegroundColor Green
    
    }

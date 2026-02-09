
$domain = Read-Host "Enter Group Domain"

$O365Groups = @()

$file = Get-ADGroup -Filter "mail -like '*$domain*'" -Properties ManagedBy,mail,ProxyAddresses,DisplayName | select DisplayName, ProxyAddresses,DistinguishedName,Mail, @{l="ManagedBy";e={(Get-aduSer $_.ManagedBy).UserPrincipalName}};

Write-Output -InputObject $file

$OWner = Read-Host "Enter Owner Email"

$file | % { 
    $AdGroup = $_ 
    Write-Host "Checking $($_.Mail) " -ForegroundColor Green -NoNewline

    if ($ADGroup) {
        try {
            $ok = $true
            $members = (Get-ADGroupMember $ADGroup.DistinguishedName | get-aduser).userPrincipalName
        }
        catch {
            $ok = $false
            Write-Host "❌" -ForegroundColor Red
            Write-Warning $Error[0].Exception
        }
        If ($ok) {
            Write-Host "✔" -ForegroundColor Green
            try {
                $ok = $true
                if ($ADGroup.ManagedBy -eq $null) {
                    New-UnifiedGroup -DisplayName $ADGroup.displayName -EmailAddresses $ADGroup.ProxyAddresses -RequireSenderAuthenticationEnabled:$false -AutoSubscribeNewMembers $true -Owner $owner 

                }
                else {
                    $adowner = $ADGroup.ManagedBy | select -First 1
                    $exsitingonwer = (get-user $adowner -ErrorAction SilentlyContinue).WindowsLiveID
                    if($exsitingonwer ){
                        $owner = $exsitingonwer
                    }
                    $GroupProxy = $ADGroup.ProxyAddresses | where {($_ -notmatch "gregory-agency") -and ($_ -notmatch "tri-tecemp")}
                    #New-UnifiedGroup -DisplayName $ADGroup.displayName -EmailAddresses $ADGroup.ProxyAddresses -RequireSenderAuthenticationEnabled:$false -Owner $owner -AutoSubscribeNewMembers $true
                    New-UnifiedGroup -DisplayName $ADGroup.displayName -EmailAddresses $GroupProxy -RequireSenderAuthenticationEnabled:$false -Owner $owner -AutoSubscribeNewMembers $true

                }
                Set-UnifiedGroup -Identity $ADGroup.displayName -UnifiedGroupWelcomeMessageEnabled:$false
            }
            catch {
                $ok = $false
                Write-Warning "Error creating a new group for $ADGroup.displayName $($Error[0].Exception)" 

            }
            if ($ok) {
                $obj = "" | select Group, Members, OWner
                $obj.group = $ADGroup.Mail 
                $obj.Members = $members
                $obj.Owner = $owner
                $O365Groups += $obj

            }

        }
    }
}

if ($O365Groups) {

    foreach ($group in $O365Groups) {
        $ok = $true
        Write-Host "adding new members to $($group.group)" -ForegroundColor Green
        $newmembers = Foreach ($member in $group.Members) {
            Write-host "checking $member" -ForegroundColor Green;
            if ($member -ne $null) {
                (Get-Recipient $member -ea SilentlyContinue).WindowsLiveID
            }
        }
        if (($newmembers |measure).count -gt 0) {
            Add-UnifiedGroupLinks -Identity $group.group -LinkType Members -Links ($newmembers | select -Unique)
                 
            Write-Host "New members added to $($group.group) successfully" -ForegroundColor Green
            if ($group.owner -eq "ttiamiyu.adm@acrisurellc.com") {
         
                Write-Host "Removing ttiamiyu.adm as owner and adding real owner"
             
                Remove-UnifiedGroupLinks -Identity $group.group -Links ttiamiyu.adm@acrisurellc.com -LinkType Owners -Confirm:$false
                Remove-UnifiedGroupLinks -Identity $group.group -Links ttiamiyu.adm@acrisurellc.com -LinkType Members -Confirm:$false
        
            }
            else {
                #Add-UnifiedGroupLinks -Identity $group.group -LinkType Members -Links $group.owner -Confirm:$false
                #Add-UnifiedGroupLinks -Identity $group.group -LinkType Owners -Links $group.owner -Confirm:$false
            }

        }
        else{
            Write-Warning "Members with mailbox not found"
        }
    }
}
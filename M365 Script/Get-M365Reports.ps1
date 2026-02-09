$APCode = Read-Host "Enter AP Code"
$UPN = Read-Host "Enter ADMIN UPN"
Connect-ExchangeOnline -UserPrincipalName $upn
Connect-AzureAD -AccountId $UPN

Function Get-AllPermissions {
  param(
    [switch]$FullAccess,
    [switch]$SendAs,
    [switch]$SendOnBehalf,
    [switch]$UserMailboxOnly,
    [switch]$AdminsOnly,
    [string]$MBNamesFile,
    [string]$APCode,
    [switch]$MFA
  )


  function Print_Output {
    #Get admin roles assigned to user 

    #Mailbox type based filter
    if (($UserMailboxOnly.IsPresent) -and ($MBType -ne "UserMailbox")) { 
      $Print = 0 
    }

    #Print Output
    if ($Print -eq 1) {
      $Result = @{'DisplayName' = $_.Displayname; 'UserPrinciPalName' = $upn; 'MailboxType' = $MBType; 'AccessType' = $AccessType; 'UserWithAccess' = $userwithAccess; } 
      $Results = New-Object PSObject -Property $Result 
      $Results | select-object DisplayName, UserPrinciPalName, MailboxType, AccessType, UserWithAccess| Export-Csv -Path $ExportCSV -Notype -Append 
    }
  }

  #Getting Mailbox permission
  function Get_MBPermission {
    $upn = $_.UserPrincipalName
    $DisplayName = $_.Displayname
    $MBType = $_.RecipientTypeDetails
    $Print = 0
    Write-Progress -Activity "`n     Processed mailbox count: $MBUserCount "`n"  Currently Processing: $DisplayName"

    #Getting delegated Fullaccess permission for mailbox
    if (($FilterPresent -eq 'False') -or ($FullAccess.IsPresent)) {
      $FullAccessPermissions = (Get-MailboxPermission -Identity $upn | where { ($_.AccessRights -contains "FullAccess") -and ($_.IsInherited -eq $false) -and -not ($_.User -match "NT AUTHORITY" -or $_.User -match "S-1-5-21") }).User
      if ([string]$FullAccessPermissions -ne "") {
        $Print = 1
        $UserWithAccess = ""
        $AccessType = "FullAccess"
        foreach ($FullAccessPermission in $FullAccessPermissions) {
          $UserWithAccess = $UserWithAccess + $FullAccessPermission
          if ($FullAccessPermissions.indexof($FullAccessPermission) -lt (($FullAccessPermissions.count) - 1)) {
            $UserWithAccess = $UserWithAccess + ","
          }
        }
        Print_Output
      }
    }

    #Getting delegated SendAs permission for mailbox
    if (($FilterPresent -eq 'False') -or ($SendAs.IsPresent)) {
      $SendAsPermissions = (Get-RecipientPermission -Identity $upn | where { -not (($_.Trustee -match "NT AUTHORITY") -or ($_.Trustee -match "S-1-5-21")) }).Trustee
      if ([string]$SendAsPermissions -ne "") {
        $Print = 1
        $UserWithAccess = ""
        $AccessType = "SendAs"
        foreach ($SendAsPermission in $SendAsPermissions) {
          $UserWithAccess = $UserWithAccess + $SendAsPermission
          if ($SendAsPermissions.indexof($SendAsPermission) -lt (($SendAsPermissions.count) - 1)) {
            $UserWithAccess = $UserWithAccess + ","
          }
        }
        Print_Output
      }
    }

    #Getting delegated SendOnBehalf permission for mailbox
    if (($FilterPresent -eq 'False') -or ($SendOnBehalf.IsPresent)) {
      $SendOnBehalfPermissions = $_.GrantSendOnBehalfTo
      if ([string]$SendOnBehalfPermissions -ne "") {
        $Print = 1
        $UserWithAccess = ""
        $AccessType = "SendOnBehalf"
        foreach ($SendOnBehalfPermissionDN in $SendOnBehalfPermissions) {
          $SendOnBehalfPermission = (Get-Mailbox -Identity $SendOnBehalfPermissionDN).UserPrincipalName
          $UserWithAccess = $UserWithAccess + $SendOnBehalfPermission
          if ($SendOnBehalfPermissions.indexof($SendOnBehalfPermission) -lt (($SendOnBehalfPermissions.count) - 1)) {
            $UserWithAccess = $UserWithAccess + ","
          }
        }
        Print_Output
      }
    }
  }



  function main {
    #Connect AzureAD and Exchange Online from PowerShell

    Write-Host Connected to MSOnline `n`nReport generation in progress...


    #Set output file
 
    $ExportCSV = "c:\CrossTenantMigration\" + $APCode + "-Permissions" + ".csv"
    $Result = "" 
    $Results = @()
    $MBUserCount = 0
    $RolesAssigned = ""

    #Check for AccessType filter
    if (($FullAccess.IsPresent) -or ($SendAs.IsPresent) -or ($SendOnBehalf.IsPresent))
    {}
    else {
      $FilterPresent = 'False'
    }

    #Check for input file
    if ($MBNamesFile -ne "") { 
      #We have an input file, read it into memory 
      $MBs = @()
      $MBs = Import-Csv -Header "DisplayName" $MBNamesFile
      foreach ($item in $MBs) {
        Get-Mailbox -Identity $item.displayname | Foreach {
          $MBUserCount++
          Get_MBPermission
        }
      }
    }
    #Getting all User mailbox
    else {
      Get-mailbox -ResultSize Unlimited | Where { $_.DisplayName -notlike "Discovery Search Mailbox" } | foreach {
        $MBUserCount++
        Get_MBPermission }
    }

 
    #Open output file after execution 
    Write-Host `nScript executed successfully
    if ((Test-Path -Path $ExportCSV) -eq "True") {
      Write-Host "Detailed report available in: $ExportCSV" 
      $Prompt = New-Object -ComObject wscript.shell  
      $UserInput = $Prompt.popup("Do you want to open output file?",`  
        0, "Open Output File", 4)  
      If ($UserInput -eq 6) {  
        Invoke-Item "$ExportCSV"  
      } 
    }
    Else {
      Write-Host No mailbox found that matches your criteria.
    }
    #Clean up session 
    #Get-PSSession | Remove-PSSession
  }
  . main
 
}
function Get-AllGroupMembership {

  #----------------
  # Script
  #----------------
  $output =@()
  $i = 0 

  $CSVfile = "c:\CrossTenantMigration\" + $APCode + "-DistributionGroups" + ".csv"

  $AllDG = Get-DistributionGroup -resultsize unlimited

  Foreach ($dg in $allDg) {
    $Members = Get-DistributionGroupMember $Dg.name -resultsize unlimited

    if ($members.count -eq 0) {
      
      $managers = $Dg  | Select -Expand ManagedBy | Get-Mailbox -ErrorAction SilentlyContinue 
     [string]$managersemails = $managers.PrimarySmtpAddress -join ";" 
     [string]$managersnames = $managers.DisplayName -join ";" 

      $userObj = New-Object PSObject

      $userObj | Add-Member NoteProperty -Name "DisplayName" -Value EmptyGroup
      $userObj | Add-Member NoteProperty -Name "Alias" -Value EmptyGroup
      $userObj | Add-Member NoteProperty -Name "RecipientType" -Value EmptyGroup
      $userObj | Add-Member NoteProperty -Name "Primary SMTP address" -Value EmptyGroup
      $userObj | Add-Member NoteProperty -Name "Distribution Group" -Value $DG.Name
      $userObj | Add-Member NoteProperty -Name "Distribution Group Primary SMTP address" -Value $DG.PrimarySmtpAddress
      $userObj | Add-Member NoteProperty -Name "Distribution Group Managers" -Value $managersnames
      $userObj | Add-Member NoteProperty -Name "Distribution Group Managers Primary SMTP address" -Value $managersemails
      $userObj | Add-Member NoteProperty -Name "Distribution Group Type" -Value $DG.GroupType
      $userObj | Add-Member NoteProperty -Name "Distribution Group Recipient Type" -Value $DG.RecipientType
      $userObj | Add-Member NoteProperty -Name "Not Allowed from Internet" -Value $DG.RequireSenderAuthenticationEnabled

      $output += $UserObj  

    }
    else {
      Foreach ($Member in $members) {

        $managers = $Dg  | Select -Expand ManagedBy | Get-Mailbox -ErrorAction SilentlyContinue 
        [string]$managersemails = $managers.PrimarySmtpAddress -join ";" 
        [string]$managersnames = $managers.DisplayName -join ";" 

        $userObj = New-Object PSObject

        $userObj | Add-Member NoteProperty -Name "DisplayName" -Value $Member.Name
        $userObj | Add-Member NoteProperty -Name "Alias" -Value $Member.Alias
        $userObj | Add-Member NoteProperty -Name "RecipientType" -Value $Member.RecipientType
        $userObj | Add-Member NoteProperty -Name "Primary SMTP address" -Value $Member.PrimarySmtpAddress
        $userObj | Add-Member NoteProperty -Name "Distribution Group" -Value $DG.Name
        $userObj | Add-Member NoteProperty -Name "Distribution Group Primary SMTP address" -Value $DG.PrimarySmtpAddress
        $userObj | Add-Member NoteProperty -Name "Distribution Group Managers" -Value $managersnames
        $userObj | Add-Member NoteProperty -Name "Distribution Group Managers Primary SMTP address" -Value $managersemails 
        $userObj | Add-Member NoteProperty -Name "Distribution Group Type" -Value $DG.GroupType
        $userObj | Add-Member NoteProperty -Name "Distribution Group Recipient Type" -Value $DG.RecipientType
        $userObj | Add-Member NoteProperty -Name "Not Allowed from Internet" -Value $DG.RequireSenderAuthenticationEnabled

        $output += $UserObj  

      }
    }
    # update counters and write progress
    $i++
    Write-Progress -activity "Scanning Groups . . ." -status "Scanned: $i of $($allDg.Count)" -percentComplete (($i / $allDg.Count) * 100)
    $output | Export-csv -Path $CSVfile -NoTypeInformation -Encoding UTF8

  }
}
function Create-MigrationFolder {
  if (!(Test-Path "c:\CrossTenantMigration\")) {
    New-Item -Path "c:\" -Name "CrossTenantMigration" -ItemType "directory"
  }
}
function Create-MigWiz ($password){
  $MSFTDomain = (Get-AzureADDomain | Where-Object {$_.IsInitial -eq $true }).Name
  $upn = "migwiz" + "@" + $MSFTDomain

  $PasswordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
  $PasswordProfile.Password = $password
  $AzureUser = (Get-AzureADUser -ObjectId $upn -ErrorAction SilentlyContinue)
  if ($AzureUser -eq $null){ 
    New-AzureADUser -AccountEnabled $True -DisplayName "migwiz" -PasswordProfile $PasswordProfile -MailNickName "migwiz" -UserPrincipalName $upn -UsageLocation "US"
    Write-Host "sleeping for 1 min for user to be availble"
    sleep -Seconds 60
  }
  else{
    $securepass = $password | ConvertTo-SecureString -AsPlainText -Force
    Set-AzureADUserPassword -ObjectId $upn -Password $securepass
    Get-AzureADUser -ObjectId $upn
  }
}
function Add-Licenses {
  $licenses = Get-AzureADSubscribedSku | where {($_.SkuPartNumber -match "E1") -or ($_.SkuPartNumber -match "Business") -or ($_.SkuPartNumber -match "f1") -or ($_.SkuPartNumber -match "f3") -or ($_.SkuPartNumber -match "Enterprise") -or ($_.SkuPartNumber -match "E3") -or ($_.SkuPartNumber -match "E5")}
  Write-Host -ForegroundColor Yellow -Object $type 
  
  for ($i=0; $i -lt $licenses.Length; $i++) {
      
      $license = $licenses[$i]
  
      if([string]::IsNullOrEmpty($license.SkuPartNumber)) {
          if($i -eq 0) {
              $defaultWorkgroupId = $license.SkuPartNumber 
              Write-Host -ForegroundColor Yellow -Object $i,"-",$defaultWorkgroupId
          }
          else {
              if($license.Id -ne $defaultWorkgroupId) {
                  Write-Host -Object $i,"-",$license.SkuPartNumber , "Consumed - ", $license.ConsumedUnits
              }
          }
      }
      else {
          Write-Host -Object $i,"-",$license.SkuPartNumber
      }
  }
  Write-Host -Object "x - Exit"
  Write-Host
  
  do {
  
     $result = Read-Host -Prompt ("Select 0-" + ($licenses.Length-1) + ", or x")
  
      
      if($result -eq "x")
      {
          Exit
      }
      if(($result -match "^\d+$") -and ([int]$result -ge 0) -and ([int]$result -lt $licenses.Length))
      {
          $LicenseSku=$licenses[$result]
          $EnabledPlans = $LicenseSku.SkuPartNumber
          #Get the LicenseSKU and create the Disabled ServicePlans object
          
         # $DisabledPlans = $LicenseSku.ServicePlans | ForEach-Object -Process { 
         #   $_ | Where-Object -FilterScript {$_.ServicePlanName -notin $EnabledPlans }
        #  }
          
          #Create the AssignedLicense object with the License and DisabledPlans earlier created
          $License = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicense
          $License.SkuId = $LicenseSku.SkuId
         # $License.DisabledPlans = $DisabledPlans.ServicePlanId
          
          #Create the AssignedLicenses Object 
          $AssignedLicenses = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicenses
          $AssignedLicenses.AddLicenses = $License
          $AssignedLicenses.RemoveLicenses = @()
  
          #Assign the license to the user
          Set-AzureADUserLicense -ObjectId $MigWizUSer.ObjectId -AssignedLicenses $AssignedLicenses
          Return $license
  
      }
  }
  while($true)
  
}
function get-mailboxstats {
$ReportPath = "c:\CrossTenantMigration\" 
$MailboxStatsPath = $ReportPath + $APCode + "-MailboxReport.csv"
$DomainsFoundPath = $ReportPath + $APCode + "-DomainsFound.csv"

$MailboxData = $domainreport = @()
#Import-Module ActiveDirectory

	
$Mailboxes = Get-Mailbox -resultsize Unlimited
$count = $Mailboxes.count
$i = 0

foreach ($Mailbox in $Mailboxes) {
	$i++
	Write-Host "checking $i of $count - $mailbox"

	$ArcMbx = ""
	$ArcMbx = ""
	$Arcstats = ""
	$smtp = [string]$Mailbox.PrimarySmtpAddress

	#primary
		
	try {
		$stats = Get-MailboxStatistics $smtp -erroraction SilentlyContinue
	}
	catch {

	}
	$error.Clear()
	#Archive
	try {
		$ArcMbx = Get-Mailbox $smtp -Archive -erroraction SilentlyContinue
	}
	catch {

	}
	$error.Clear()
	try {
		$Arcstats = Get-MailboxStatistics $smtp -archive -erroraction SilentlyContinue
	}
	catch {

	}
	$error.Clear()
			
	#Primary
	
	if ($stats) {
		[string]$Total = $stats.TotalItemSize.value
		$TotalItemSize = [double]$Total.SubString($Total.indexof("(") + 1, $Total.indexof(" b") - $Total.indexof("("))
		$TotalItemSizeGB = $TotalItemSize / 1GB
		$TotalItemSizeGB = "{0:N3}" -f $TotalItemSizeGB
		$TotalItemCount = $stats.ItemCount
		$DeletedItemCount = $stats.DeletedItemCount

		[string]$totalD = $stats.TotalDeletedItemSize.value
		$DeletedItemSize = [double]$TotalD.SubString($TotalD.indexof("(") + 1, $TotalD.indexof(" b") - $TotalD.indexof("("))
		$DeletedItemSizeGB = $DeletedItemSize / 1GB
		$DeletedItemSizeGB = "{0:N3}" -f $DeletedItemSizeGB

	}
	else {
		$TotalItemSizeGB = ""
	}
	#Primarymbx quota
	[string]$mbxquota = $mailbox.ProhibitSendReceiveQuota
	$mbxquotaSize = [double]$mbxquota.SubString($mbxquota.indexof("(") + 1, $mbxquota.indexof(" b") - $mbxquota.indexof("("))
	$mbxquotaSizeGB = $mbxquotaSize / 1GB
	$mbxquotaSizeGB = "{0:N3}" -f $mbxquotaSizeGB
		
	#Archive
		
	if ($Arcstats) {
		[string]$ArcTotal = $Arcstats.TotalItemSize.value
		$ArcTotalItemSize = [double]$ArcTotal.SubString($ArcTotal.indexof("(") + 1, $ArcTotal.indexof(" b") - $ArcTotal.indexof("("))
		$ArcTotalItemSizeGB = $ArcTotalItemSize / 1073741824
		$ArcTotalItemSizeGB = "{0:N3}" -f $ArcTotalItemSizeGB
	}
	else {
		$ArcTotalItemSizeGB = ""
	}
	#ArchiveMbx limit
		
	if ($ArcMbx) {
		[string]$Arcmbxquota = $ArcMbx.ArchiveQuota
		$ArcmbxquotaSize = [double]$Arcmbxquota.SubString($Arcmbxquota.indexof("(") + 1, $Arcmbxquota.indexof(" b") - $Arcmbxquota.indexof("("))
		$ArcmbxquotaSizeGB = $ArcmbxquotaSize / 1GB
		$ArcmbxquotaSizeGB = "{0:N3}" -f $ArcmbxquotaSizeGB
	}
	else {
		$ArcmbxquotaSizeGB = $null
	}
		
	$obj = $props = @()
    $emailAddresses = $Mailbox.EmailAddresses | where {($_ -like "*@*") -and ($_ -notlike "*onmicrosoft.com") -and ($_ -notlike "SPO:SPO*")}
    $Domains = $emailAddresses | % {
        
        $objD = "" | Select Domains
        $objD.Domains = $_.SPlit("@")[1]
        $domainreport += $objD
    }
    $emailAddresses = $emailAddresses -join ";"
		
	$props = [Ordered]@{

		'Active?'                         = "";
        'Login'                           = $mailbox.alias;
		'Name'                            = $Mailbox.DisplayName;
        'UPN'                             = $Mailbox.UserPrincipalName;
		'Email'                           = $smtp;
        'Mobile Number'                   = [string](Get-User $Mailbox.UserPrincipalName).MobilePhone
        'Remote ?'                        = "";
        'Found In Acrisure AD'            = "";
        'EmployeeIDInAcrisure'            = "";
        'AgencyCodeInAcrisure'            = "";
		'Primary-TotalItemSize(GB)'       = $TotalItemSizeGB;
		'Primary-TotalItemCount'          = $TotalItemCount;
		'Primary-DeletedItemSize(GB)'     = $DeletedItemSizeGB;
		'Primary-DeletedItemCount'        = $DeletedItemCount;
		'Primary-Mailbox Quota(GB)'       = $mbxquotaSizeGB;
		'Retention Policy'                = $mailbox.RetentionPolicy;
		'Archive-TotalItemSize(GB)'       = $ArcTotalItemSizeGB;
		'AutoExpandingArchiveEnabled'     = $ArcMbx.AutoExpandingArchiveEnabled;
		'RecipientType'                   = $Mailbox.RecipientTypeDetails;
        'ProxyCollections'               = $emailAddresses

	}		
	$obj = New-Object -TypeName PSObject -Property $props
	$MailboxData += $obj
	$props = $null
	$user = $null
	$mailbox = $null
	$obj = $null
		
}

if ($MailboxData)
{
    $MailboxData| Export-Csv $MailboxStatsPath -Encoding UTF8 -NoTypeInformation
    Invoke-Item $MailboxStatsPath
}
if ($domainreport){
    $domainreport | Select domains -Unique | Export-Csv $DomainsFoundPath -Encoding UTF8 -NoTypeInformation
    Invoke-Item $DomainsFoundPath
}
}
function validate-mailboxreport {
$q = Read-host "Validate report by populating Acrisure UPN - YOU MUST BE CONNECTED TO VPN BEFORE YOU PROCEED ? Y or N"
 While ($q -eq "Y"){
 Import-Module ActiveDirectory -ErrorAction SilentlyContinue

    if ((Get-Module ActiveDirectory) -ne $null) {

        Connect-ExchangeOnline -UserPrincipalName ttiamiyu.adm@acrisurellc.com -ErrorAction Stop
        $ReportPath = "c:\CrossTenantMigration\" 
        $MailboxStatsPath = $ReportPath + $APCode + "-MailboxReport.csv"
        $Report = $DuplicateReport = $Sobj = $Mobj = @()
        $Userlist = Import-csv $MailboxStatsPath

        forEach ($user in $Userlist) {

            $name = $user.Name
            $email = $user.Email
            $UPN = $user.UPN
            $login = $user.Login
            $usercheck = $o365Check = ""

            Write-Host "Checking $email" -ForegroundColor Green
    
            $UserCheck = Get-ADUser -filter { mail -eq $email }  -properties AgencyCode, ADSyncEnabled, EmployeeID, Mail

            if (!$usercheck) {
            
                $Sobj = "" | Select "Active ?", Login, Name, UPN, Email, "Mobile Number", "Remote ?", `
                    "AcrisureEmployeeID", "AcrisureAgencyCode", AdSyncEnabled, MbxSize, MbxItemCount, DumspterSize, ArchiveSize, `
                    "Found in Acrisure?", AcrisureO365Type, AcrisureEmail, AcrisureUPN, `
                    AcrisureDN, Company, "Retention Policy", RecipientType, ProxyCollections
        
                $Sobj.'Active ?' = ""
                $Sobj.Login = $user.Login
                $Sobj.Name = $user.Name
                $Sobj.UPN = $user.UPN
                $Sobj.Email = $user.Email
                $Sobj.'Mobile Number' = $user.'Mobile Number'
                $Sobj.'Remote ?' = $user.'Remote ?'
                $Sobj.'Found in Acrisure?' = "No"
                $Sobj.MbxSize = $user.'Primary-TotalItemSize(GB)'
                $Sobj.MbxItemCount = $user.'Primary-TotalItemCount'
                $Sobj.DumspterSize = $user.'Primary-DeletedItemCount'
                $Sobj.ArchiveSize = $user.'Archive-TotalItemSize(GB)'
                $sobj.AcrisureEmployeeID = "Not Found"
                $sobj.AcrisureO365Type = "Not Found"
                $sobj.AcrisureAgencyCode = "Not found"
                $Sobj.AcrisureDN = "Not found"
                $Sobj.AcrisureUPN = "Not found"
                $Sobj.AcrisureEmail = "Not found"
                $Sobj.AdSyncEnabled = "No"
                $Sobj.'Retention Policy' = $user.'Retention Policy'
                $Sobj.ProxyCollections = $user.'ProxyCollections'
                $Sobj.Company = ""
                $Sobj.RecipientType = $user.RecipientType

                $Report += $Sobj
            
            }
            else {

               
               
                    $o365Check = Get-User $email -ErrorAction SilentlyContinue
                if (($usercheck | measure).Count -eq 1) {
    
                    $Obj = "" | Select "Active ?", Login, Name, UPN, Email, "Mobile Number", "Remote ?", `
                        "AcrisureEmployeeID", "AcrisureAgencyCode", AdSyncEnabled, MbxSize, MbxItemCount, DumspterSize, ArchiveSize, `
                        "Found in Acrisure?", AcrisureO365Type, AcrisureEmail, AcrisureUPN, `
                        AcrisureDN, Company, "Retention Policy", RecipientType, ProxyCollections
        
                    $Obj.'Active ?' = ""
                    $Obj.Login = $user.Login
                    $Obj.Name = $user.Name
                    $Obj.UPN = $user.UPN
                    $Obj.Email = $user.Email
                    $Obj.'Mobile Number' = $user.'Mobile Number'
                    $Obj.'Remote ?' = $user.'Remote ?'
                    $Obj.'Found in Acrisure?' = "Yes"
                    $Obj.MbxSize = $user.'Primary-TotalItemSize(GB)'
                    $Obj.MbxItemCount = $user.'Primary-TotalItemCount'
                    $Obj.DumspterSize = $user.'Primary-DeletedItemCount'
                    $obj.ArchiveSize = $user.'Archive-TotalItemSize(GB)'
                    $Obj.AcrisureEmployeeID = $usercheck.EmployeeID
                    $Obj.AcrisureAgencyCode = $usercheck.AgencyCode
                    $obj.AcrisureO365Type = $o365Check.RecipientTypeDetails
                    $Obj.AcrisureDN = $usercheck.DistinguishedName
                    $Obj.AcrisureUPN = $usercheck.UserPrincipalName
                    $Obj.AcrisureEmail = $usercheck.Mail
                    $obj.AdSyncEnabled = $usercheck.ADSyncEnabled
                    $Obj.'Retention Policy' = $user.'Retention Policy'
                    $Obj.ProxyCollections = $user.'ProxyCollections'
                    $Obj.Company = $usercheck.Company
                    $Obj.RecipientType = $user.RecipientType

                    $Report += $Obj

                }
                <#
        else {

            foreach ($entry in $usercheck) {
                $Mobj = "" | Select Login, Name, UPN, Email, TotalItemSize, TotalItemCount, TotalDeletedItemSize, TotalDeletedItemCOunt, OnPremRecipientType, O365RecipientType, OnPremUPN, OnPremEmail, OnPremOU, Company, City, WindowsLiveID, WhenCreated, AP
                $Mobj.Login = $user.Login
                $Mobj.Name = $user.Name
                $Mobj.UPN = $user.UPN
                $Mobj.Email = $user.Email
                $Mobj.TotalItemSize = $user.'Primary-TotalItemSize(GB)'
                $Mobj.TotalItemCount = $user.'Primary-TotalItemCount'
                $Mobj.TotalDeletedItemSize = $user.'Primary-TotalItemSize(GB)'
                $Mobj.TotalDeletedItemCOunt = $user.'Primary-TotalItemCount'
                $Mobj.OnPremRecipientType = $entry.RecipientTypeDetails
                $Mobj.O365RecipientType = $o365Check.RecipientTypeDetails
                $Mobj.OnPremUPN = $entry.UserPrincipalName
                $Mobj.OnPremEmail = $entry.WindowsEmailAddress
                $Mobj.OnPremOU = $entry.OrganizationalUnit
                $Mobj.Company = $entry.Company
                $Mobj.City = $entry.City
                $Mobj.WindowsLiveID = $o365Check.WindowsLiveID
                $Mobj.WhenCreated = $entry.WhenCreated
                $Mobj.AP = $user.AP

                $DuplicateReport += $Mobj


            }
        }
        #>
            }

    
        }

        #$DuplicateReport | Export-csv Duplicatereport.csv -NoTypeInformation
        if ($Report.Count -gt 2) {
            $ReportPath = "c:\CrossTenantMigration\" 
            $MailboxStatsPath = $ReportPath + $APCode + "-MailboxReport-Validated.csv"
            $Report | Export-csv $MailboxStatsPath -NoTypeInformation -Encoding UTF8

        }
        Disconnect-ExchangeOnline -Confirm:$false
        $q = "N"
    }
    else {
        Write-Warning "Unable to import Active Directory Module - Please connect to Acrisure VPN and/or Close and Restart PowerShell session"
        $q = Read-Host "Try again ? -  Y or N"
    }
}

}

Create-MigrationFolder
$MigWizUSer = Create-MigWiz -password "C?#44qwdxz"
Get-AllPermissions -FullAccess -SendAs -SendOnBehalf -APCode $APCode
Get-AllGroupMembership
get-mailboxstats
Add-Licenses
New-RoleGroup -Name "Application Impersonation - MigWiz" -Roles ApplicationImpersonation -Members $MigWizUSer.ObjectId
validate-mailboxreport

Write-Host "IF LICENSE FOR MIGWIZ ACCOUNT FAILED - LOG ON TO THE TENANT TO ASSIGN LICENSE MANUALLY" -ForegroundColor Yellow
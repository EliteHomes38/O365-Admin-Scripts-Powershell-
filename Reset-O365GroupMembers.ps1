function Read-GroupMembersAndAutoSubscribe {
[CmdletBinding()]
param (
        [Parameter(Mandatory=$true,
        ValueFromPipeline=$true)]
        [String[]]
        $Group
    )

    $groupdetails = Get-UnifiedGroup $Group
    $owners = Get-UnifiedGroupLinks $Group -LinkType Owners
    $members = Get-UnifiedGroupLinks $Group -LinkType Members
    Add-UnifiedGroupLinks $Group -LinkType members -Links "ttiamiyu.adm@acrisurellc.com" -Confirm:$false
    Add-UnifiedGroupLinks $Group -LinkType Owners -Links "ttiamiyu.adm@acrisurellc.com" -Confirm:$false
    Remove-UnifiedGroupLinks $Group -LinkType Owners -Links ($Owners.PrimarySmtpAddress) -Confirm:$false
    Remove-UnifiedGroupLinks $Group -LinkType Members -Links $members.PrimarySmtpAddress -Confirm:$false
    Set-UnifiedGroup $group -RequireSenderAuthenticationEnabled:$false -AutoSubscribeNewMembers:$true
    Add-UnifiedGroupLinks $Group -LinkType Members -Links $members.PrimarySmtpAddress -Confirm:$false
    Add-UnifiedGroupLinks $Group -LinkType Owners -Links $owners.PrimarySmtpAddress -Confirm:$false
    Remove-UnifiedGroupLinks $Group -LinkType members -Links "ttiamiyu.adm@acrisurellc.com" -Confirm:$false
    Remove-UnifiedGroupLinks $Group -LinkType Owners -Links "ttiamiyu.adm@acrisurellc.com" -Confirm:$false
}
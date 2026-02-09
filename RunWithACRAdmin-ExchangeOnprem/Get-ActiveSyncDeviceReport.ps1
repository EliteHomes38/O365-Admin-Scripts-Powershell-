$USERS = Get-mailbox -Filter {EmailAddresses -like "*gulfshoreinsurance.com"}

forEach ($user in $USERS){
    $devices = Get-ActiveSyncDevice -Mailbox $user.UserPrincipalName

    ForEach ($device in $devices){
    $obj = "" | Select Displayname, Email, UPN, DN, SamAccountName, DeviceType, DeviceOperator, DeviceAccessState,IsDisabled, DeviceID, DeviceIMEI, DeviceModel,DeviceOS
    $obj.Displayname = $user.DisplayName
    $obj.Email = $user.WindowsEmailAddress
    $obj.UPN = $user.UserPrincipalName
    $obj.DN = $user.DistinguishedName
    $obj.SamAccountName = $user.SamAccountName
    $obj.DeviceType = $device.DeviceType
    $obj.DeviceOperator = $device.DeviceMobileOperator
    $obj.DeviceAccessState = $device.DeviceAccessState
    $obj.IsDisabled = $device.IsDisabled
    $obj.DeviceID = $device.DeviceId
    $obj.DeviceIMEI = $device.DeviceImei
    $obj.DeviceModel = $device.DeviceModel
    $obj.DeviceOS = $device.DeviceOS

    $Obj | Export-csv c:\mig\CampbellphoneReport.csv -Append -NoTypeInformation

    }

}
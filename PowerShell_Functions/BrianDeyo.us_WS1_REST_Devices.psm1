
<#***********************************
#  AirWatch REST API Functions
#
#   Brian Deyo
#   2018-06-20
#**********************************

###Change Log
    2019-03-29 - modified Set-AwDevice to use new endpoint

#>


Function Get-WS1BulkDeviceSettings {
<#
        .SYNOPSIS
            Retrieve Bulk Limits for various Device actions
        .DESCRIPTION
            Retreive limits for BUlk actions on devices
        .EXAMPLE
            Get-WS1BulkDeviceSettings -WS1Host xx123.awmdm.com -headers (HeaderHashTable)
        .PARAMETER WS1Host
            The URL to your API server. You can also use the Console URL 
  #>
param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$WS1Host,
        [Parameter(Mandatory=$true, Position=3,ValueFromPipelineByPropertyName=$true)]
        [Hashtable]$headers
     )
     $ws1BulkDeviceSettings = Invoke-WebRequest -Uri https://$WS1Host/api/mdm/devices/bulksettings -Method GET -Headers $headers
     return $ws1BulkDeviceSettings
}

###############################
###
###  INDIVIDUAL DEVICE MANAGEMENT CMDLETS
###
###############################


<# Send a QUERY or a SYNC command to a device #>
Function Find-ws1Device {
param (
        [Parameter(Mandatory=$true, Position=1)][string]$id,
        [Parameter(Mandatory=$true, Position=2)][ValidateSet("Query","SyncDevice")][string]$searchType,
        [Parameter(Mandatory=$true, Position=3,ValueFromPipelineByPropertyName=$true)][Hashtable]$headers
     )
     $ws1EnvUri = $headers.ws1ApiUri
     $ws1Find = Invoke-RestMethod -Method POST -Uri https://$ws1EnvUri/api/mdm/devices/$id/$searchType -Headers $headers
     return $ws1Find
}


Function Get-WS1Device {
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$WS1Host,
        [Parameter(Mandatory=$true, Position=1)]
        [ValidateSet("DeviceID","Macaddress","Udid","SerialNumber","ImeiNumber","EasId")]
        [string]$SearchBy,
        [Parameter(Mandatory=$true, Position=2)]
        [string]$alternateId,
        [Parameter(Mandatory=$true, Position=3,ValueFromPipelineByPropertyName=$true)]
        [Hashtable]$headers
     )
        
  
    $WS1Device = Invoke-RestMethod -Method GET -uri https://$WS1Host/api/mdm/devices?searchby=$searchBy"&"id=$alternateId -Headers $Headers
    return $WS1Device
}


Function Get-WS1BulkDevice {
<#
        .SYNOPSIS
            Retrieve Device Details in Bulk
        .DESCRIPTION
            Retrieve Device Details for more than a single device. Useful to reduce total number of API queries. This is intended for use from a script and not necessarily useful from the command line itself.
        .EXAMPLE
            Get-WS1BulkDevice -WS1Host xx123.awmdm.com -searchBy SerialNumber -bulkIdList (ARRAY OBJECT) "Asset123" -ownership "CorporateShared" -headers (HeaderHashTable)
        .PARAMETER awHost
            The URL to your API server. You can also use the Console URL
        .PARAMETER searchBy
            Unique Identifier used to specify which devices to delete. Possible values include : MacAddress,UDID,SerialNumber, DeviceID, IMEI
        .PARAMETER bulkIdList
            An array containing all the IDs for the Unique Identifier type you are searchign by
        
  #>
param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$WS1Host,
        [Parameter(Mandatory=$true, Position=1)]
        [ValidateSet("DeviceID","Macaddress","Udid","SerialNumber","ImeiNumber")]
        [string]$searchBy,
        [Parameter(Mandatory=$true, Position=2)]
        [array]$bulkIdList,
        [Parameter(Mandatory=$true, Position=3,ValueFromPipelineByPropertyName=$true)]
        [Hashtable]$headers
     )

     $body = @{
                BulkValues = @{Value = @($bulkIdList)}
            }
     if ($searchBy -ne "DeviceID") {
         $WS1BulkDevices = Invoke-RestMethod -Method POST -uri https://$WS1Host/api/mdm/devices?searchby=$searchBy -body (ConvertTo-Json $body) -Headers $Headers
        }
        elseif ($searchBy -eq "DeviceID") {
            $WS1BulkDevices = Invoke-RestMethod -Method POST -uri https://$WS1Host/api/mdm/devices/id -body (ConvertTo-Json $body) -Headers $Headers
            write-host $WS1BulkDevices.Devices | ft
        }
     return $WS1BulkDevices
}



<#
Retrieve *all* devices from an Environment
#>
Function Search-ws1Devices {
    param(
        [Parameter(mandatory=$false, Position=0)][string]$user,
        [Parameter(mandatory=$false, Position=1)][string]$model,
        [Parameter(mandatory=$false, Position=2)][string]$platform,
        [Parameter(mandatory=$false, Position=3)][dateTime]$lastSeen,
        [Parameter(mandatory=$false, Position=4)][string]$ownership,
        [Parameter(mandatory=$false, Position=5)][string]$lgid,
        [Parameter(mandatory=$false, Position=6)][bool]$compliantStatus,
        [Parameter(mandatory=$false, Position=7)][dateTime]$seenSince,
        [Parameter(mandatory=$false, Position=8)][int]$page,
        [Parameter(mandatory=$false, Position=9)][int]$pageSize,
        [Parameter(mandatory=$false, Position=10)][string]$orderBy,
        [Parameter(mandatory=$false, Position=11)][string]$sortOrder,
        [Parameter(mandatory=$false, Position=12)][bool]$allRecords,
        [Parameter(mandatory=$true, Position=13)][hashtable]$headers
    )
    
    $ws1EnvUri = $headers.ws1ApiUri
    
    $dev = $null
    $dev = Invoke-RestMethod -Method GET -Uri https://$ws1EnvUri/api/mdm/devices/search?lgid=$lgID"&"page=$page"&"pagesize=$pageSize -Headers $headers
    return $dev.Devices
}



<#
###  Move Devices into a different OG
#>



<##TO DO
Pipeline Id not being parsed before input... need to return Device.Id.value
#>
Function Clear-ws1Device {
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$ws1Host,
        [Parameter(Mandatory=$true, Position=1,ValueFromPipelineByPropertyName=$true)]
        [int]$Id,
        [Parameter(Mandatory=$true, Position=2)]
        [ValidateSet("EnterpriseWipe","DeviceWipe")]
        [string]$wipeType,
        [Parameter(Mandatory=$true, Position=3,ValueFromPipelineByPropertyName=$true)]
        [Hashtable]$headers
    )
    $ws1Wipe = Invoke-Restmethod -Method POST -Uri https://$ws1host/api/mdm/devices/$Id/commands?command=$wipeType -Headers $Headers
    $ws1WipeStatus = Get-WS1Device -WS1Host $ws1Host -SearchBy DeviceID -alternateId $Id -headers $headers
    return $ws1WipeStatus
}
    
<# Permanently Delete a Device
#>

Function Remove-WS1Device {
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$WS1Host,
        [Parameter(Mandatory=$true, Position=1)]
        [ValidateSet("Macaddress","Udid","SerialNumber","ImeiNumber")]
        [string]$searchBy,
        [Parameter(Mandatory=$true, Position=2)]
        [string]$alternateId,
        [Parameter(Mandatory=$true, Position=3,ValueFromPipelineByPropertyName=$true)]
        [Hashtable]$headers
    )
    $WS1Delete = Invoke-Restmethod -Method DELETE -Uri https://$WS1host/api/mdm/devices?searchby=$searchBy"&"id=$alternateId -Headers $Headers -TimeoutSec 15
    return $WS1Delete
}


<#
    Edit Device Details - Change Asset #, Friendly Name or Ownership


    !!!! - Currently the API guide indicates SN, UDID, and Mac can be used to find device. However in practice seems to not be working: 2018-09-17
#>

Function Set-ws1Device {
    <#
        .SYNOPSIS
            Edit Device Details
        .DESCRIPTION
            Change Asset Tag, Device Friendly Name, or Ownership type for a single device.
        .EXAMPLE
            Set-AwDevice -awHost xx123.awmdm.com -idType SerialNumber "serial1234" -assetNumber "Asset123" -ownership "CorporateShared"
        .PARAMETER awHost
            The URL to your API server. You can also use the Console URL
        .PARAMETER idType
            Unique Identifier used to specify which devices to delete. Possible values include : MacAddress,UDID,SerialNumber
        .PARAMETER assetNumber
            assetNumber
        .PARAMETER deviceFriendlyName
            DeviceFriendlyName
        .PARAMETER ownership
            Ownership type. Possible values includes : CorporateOwned, CorporateShared, or EmployeeOwned.
  #>
    param (
        [Parameter(Mandatory=$true, Position=0)][string]$ws1Host,
        [Parameter(Mandatory=$true, Position=1,ValueFromPipelineByPropertyName=$true)][ValidateSet("DeviceID","Macaddress","Udid","SerialNumber")][string]$idType,
        [Parameter(Mandatory=$true, Position=2)][string]$deviceId,
        [Parameter(Mandatory=$false, Position=3)][string]$assetNumber,
        [Parameter(Mandatory=$false, Position=4)][string]$deviceFriendlyName,
        [Parameter(Mandatory=$false, Position=5)][ValidateSet("CorporateOwned","CorporateShared","EmployeeOwned")][string]$ownership,
        [Parameter(Mandatory=$false, Position=6)][bool]$bluetooth,
        [Parameter(Mandatory=$false, Position=7)][bool]$voiceRoamingAllowed,
        [Parameter(Mandatory=$false, Position=8)][bool]$dataRoamingAllowed,
        [Parameter(Mandatory=$false, Position=9)][bool]$personalHotspotAllowed,
        [Parameter(Mandatory=$true, Position=10,ValueFromPipelineByPropertyName=$true)][Hashtable]$headers
    )


    ### Creation of JSON payload
    $body = @{}
    
    if ($assetNumber -ne $null) {
        $body.Add("AssetNumber", $assetNumber)
    }
    if ($deviceFriendlyName -ne $null) {
        $body.Add("DeviceFriendlyName", $deviceFriendlyName)
    }
    if ($ownership -ne $null) {
        $body.Add("Ownership", $ownership)
    }
    
     
    ### Different REST API URI depending on Unique Identifier used to pinpoint device
    if ($idType -eq "DeviceID") {
        $ws1DeviceEdited = Invoke-Restmethod -Method PUT -Uri https://$ws1host/api/mdm/devices/$deviceId/editdevice -Body (ConvertTo-Json $body) -Headers $Headers
        return $wsDeviceEdited
    }
    else {
        $ws1DeviceEdited = Invoke-Restmethod -Method PUT -Uri https://$ws1host/api/mdm/devices/$deviceId -Body (ConvertTo-Json $body) -Headers $Headers
        return $ws1DeviceEdited
    }
}


Function set-ws1deviceMangedSettings {
    <#
        .SYNOPSIS
            Short description
        .DESCRIPTION
            Long description
        .PARAMETER ws1Host
            Parameter description
        .PARAMETER idType
            Parameter description
        .PARAMETER bluetooth
            Parameter description
        .PARAMETER voiceRoamingAllowed
            Parameter description
        .PARAMETER dataRoamingAllowed
            Parameter description
        .PARAMETER personalHotspotAllowed
            Parameter description
        .PARAMETER headers
            Parameter description
        .EXAMPLE
            An example
        .NOTES
        General notes
    #>

    param (
        [Parameter(Mandatory=$true, Position=1,ValueFromPipelineByPropertyName=$true)][ValidateSet("DeviceID","Macaddress","Udid","ImeiNumber","SerialNumber","EasId")][string]$searchBy,
        [Parameter(Mandatory=$true, Position=2)][string]$deviceId,
        [Parameter(Mandatory=$false, Position=2)][string][ValidateSet("on","off")]$bluetooth,
        [Parameter(Mandatory=$false, Position=3)][string][ValidateSet("on","off")]$voiceRoamingAllowed,
        [Parameter(Mandatory=$false, Position=4)][string][ValidateSet("on","off")]$dataRoamingAllowed,
        [Parameter(Mandatory=$false, Position=5)][string][ValidateSet("on","off")]$personalHotspotAllowed,
        [Parameter(Mandatory=$true, Position=6,ValueFromPipelineByPropertyName=$true)][Hashtable]$headers
    )
    $ws1ApiUri = $headers.ws1ApiUri
    $body = @{}
    switch ($bluetooth) {
        off {$body.add("Bluetooth", "FALSE")}
        on {$body.add("Bluetooth", "TRUE")}
    }
    switch ($voiceRoamingAllowed) {
        off {$body.add("VoiceRoamingAllowed", "FALSE")}
        on {$body.add("VoiceRoamingAllowed", "TRUE")}
    }
    switch ($dataRoamingAllowed) {
        off {$body.add("DataRoamingAllowed", "FALSE")}
        on {$body.add("DataRoamingAllowed", "TRUE")}
    }
    switch ($personalHotspotAllowed) {
        off {$body.add("PersonalHotSpotAllowed", "FALSE")}
        on {$body.add("PersonalHotSpotAllowed", "TRUE")}
    }
    

    ###Execute settings and return values
    $ws1ManagedSettings = invoke-webrequest -method POST -URI https://$ws1ApiUri/api/mdm/devices/managedsettings?searchby=$searchBy"&"id=$deviceId -body (ConvertTo-Json $Body) -headers $Headers
    return $ws1ManagedSettings
}


###############################
###
###  BULK DEVICE AND USER CMDLETS
###
###############################


<# Delete multiple devices #>
Function Remove-BulkWS1Device {
    <#
    .SYNOPSIS
    Bulk Delete devices
    .DESCRIPTION
    Deletes multiple devices identified by device ID or alternate ID.
    .EXAMPLE
    Remove-AwBulkDevice -awHost ab123.contoso.com -SearchBy SerialNumber -headers [hashtable]$headers_in_json
    .PARAMETER awHost
    The URL to your API server. You can also use the Console URL
    .PARAMETER SearchBy
    Unique Identifier used to specify which devices to delete. Possible values include DeviceID,MacAddress,UDID,SerialNumber,ImeiNumber
    .PARAMETER bulkSnList
    Comma-separated Hashtable of Unique Identifers you want to delete. Must match type specified by SearchBy parameter
  #>
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$WS1Host,
        [Parameter(Mandatory=$true, Position=1)]
        [ValidateSet("DeviceID","Macaddress","Udid","SerialNumber","ImeiNumber")]
        [string]$SearchBy,
        [Parameter(Mandatory=$true, Position=2)]
        [Hashtable]$bulkDeviceList,
        [Parameter(Mandatory=$true, Position=3,ValueFromPipelineByPropertyName=$true)]
        [Hashtable]$headers
    )

     $body = @{
                BulkValues = @{Value = @($bulkDeviceList.Values)}
            }
    if ($SearchBy -eq "DeviceID") {
        $WS1Delete = Invoke-Restmethod -Method POST -Uri https://$WS1host/api/mdm/devices/bulk -Headers $Headers
        }
    else {
        $WS1Delete = Invoke-Restmethod -Method POST -Uri https://$WS1host/api/mdm/devices/bulk?searchby=$SearchBy -Body (ConvertTo-Json $body) -Headers $Headers
    }

    
        return $WS1Delete
}



###############################
###
###  MESSAGING CMDLETS
###
###############################

<# Delete multiple devices #>
Function send-WS1Message {
    <#
    .SYNOPSIS
    Send SMS/Email/Push
    .DESCRIPTION
    Send a message to a single device or in Bulk
    .EXAMPLE
    send-WS1Message -WS1Host -
    .PARAMETER WS1Host
    .PARAMETER sendCount
    .PARAMETER SearchBy
    .PARAMETER deviceId
    .PARAMETER messageType
    .PARAMETER message
    .PARAMETER headers
    
    #>
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$WS1Host,
        [Parameter(Mandatory=$true, Position=1)]
        [ValidateSet("Single","Bulk")]
        [String]$sendCount,
        [Parameter(Mandatory=$true, Position=2)]
        [ValidateSet("DeviceID","Macaddress","Udid","SerialNumber","ImeiNumber")]
        [string]$SearchBy,
        [Parameter(Mandatory=$true, Position=3)]
        [Hashtable]$deviceId,
        [Parameter(Mandatory=$true, Position=4)]
        [ValidateSet("SMS","Email","Push")]
        [string]$messageType,
        [Parameter(Mandatory=$true, Position=5)]
        [Hashtable]$message,
        [Parameter(Mandatory=$true, Position=6,ValueFromPipelineByPropertyName=$true)]
        [Hashtable]$headers
    )
    $body = @{
        bulkvalues = $bulkSnList
    }
    if ($sendCount -eq "Single") {
        
        $WS1send = Invoke-WebRequest -Method POST -Uri https://$WS1Host/api/mdm/devices/$deviceId/messages/push -Headers $headers
    }
    elseif ($sendCount -eq "Bulk") {
        $WS1Send = Invoke-WebRequest -Method POST -Uri https://$WS1Host/api/mdm/devices/$deviceId/messages/push -Headers $headers
    }
        return $WS1Send
}


Function move-ws1Device {
    <#.SYNOPSIS
    Move a device to a different OG
    .DESCRIPTION
    Move a device specified with a Unique Identifier to a new Organization Group.
    (Moving W10 devices if duplicate records exist in console may lead to unpredictable moves.
    Verify you are issuing a Unique Identifer for each device record.)
    
    .EXAMPLE
    move-ws1Device -WS1Host xxxxx.awmdm.com -
    .PARAMETER WS1Host
    .PARAMETER SearchBy
    .PARAMETER deviceId
    .PARAMETER ogId
    .PARAMETER headers
    #>
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$WS1Host,
        [Parameter(Mandatory=$true, Position=1)]
        [ValidateSet("DeviceID","Macaddress","Udid","SerialNumber","ImeiNumber")]
        [string]$SearchBy,
        [Parameter(Mandatory=$true, Position=2)]
        [string]$deviceId,
        [Parameter(Mandatory=$true, Position=3)]
        [Int]$ogId,
        [Parameter(Mandatory=$true, Position=4,ValueFromPipelineByPropertyName=$true)]
        [Hashtable]$headers
    )

    If ($SearchBy -ne "DeviceID") {
        $ws1DeviceMove = Invoke-WebRequest -Method POST -Uri https://$ws1Host/api/mdm/devices/commands/changeorganizationgroup?searchby=$SearchBy"&"id=$DeviceId"&"ogid=$ogid -Headers $headers
    }
    elseif ($SearchBy -eq "DeviceID") {
        $ws1DeviceMove = Invoke-WebRequest -Method PUT -Uri https://$ws1Host/api/mdm/devices/$DeviceId/commands/changeorganizationgroup/$ogID -Headers $headers   
    }
    else {
        return;
    }
    return;
}

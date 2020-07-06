###############################
###
###  TAG CMDLETS
###
###############################


Function Search-WS1Tags {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$WS1Host,
        [Parameter(Mandatory=$false, Position=1)]
        [string]$tagName,
        [Parameter(Mandatory=$false, Position=2)]
        [string]$GroupID,
        [Parameter(Mandatory=$false, Position=3)]
        [ValidateSet("Device","General", "All")]
        [string]$tagType,
        [Parameter(Mandatory=$false, Position=4)]
        [int]$page,
        [Parameter(Mandatory=$false, Position=5)]
        [int]$pageSize,
        [Parameter(Mandatory=$true, Position=5,ValueFromPipelineByPropertyName=$true)]
        [Hashtable]$headers
        )
        $searchString = ""
        if (!$tagName) {}
        else {
            $searchString = "name=$tagname"
        }
        if (!$GroupID) {
            $GroupID = Find-CustomerOGID -WS1Host $WS1Host -headers $headers
            $searchString = "organizationgroupid=$GroupID"
            }
        else {
            if (!$searchString) {
                $searchString = "organizationgroupid=$GroupID"
                }
            else {
                $searchString = $searchString + "&organizationgroupid=$GroupID"
            }
        }
        if ($tagType -like "All" ) {}
        else {
            if ($tagType -like "Device") {
                $tagTypeID = 1
            }
            else {
                $tagTypeID = 2
            }
            if (!$searchString) {
                $searchString = $searchString + "tagtype=$tagTypeID"
            }
            else {
                $searchString = $searchString + "&tagtype=$tagTypeID"
            }
        }
        
        if (!$Resultsize) {}
        else {
            if (!$searchString) {
                $searchString = $searchString + "pagesize=$pageSize"
            }
            else {
                $searchString = $searchString + "&pagesize=$pageSize"
            }
        }
        
        $WS1TagList = Invoke-RestMethod -Method GET -Uri https://$WS1Host/api/mdm/tags/search?$searchString -Headers $headers
        return $WS1TagList
}

Function Set-WS1DeviceTag {
    <#
        .SYNOPSIS
            Add or Remove devices from an existing Tag
        .DESCRIPTION
            Add or Remove devices from an existing Tag

            #ChangeLog
            2020-07-06  Brian Deyo      Change $tagAction to reflect correct URIs
                                            Removed requirement to specify $WS1Host parameter when calling function
        .EXAMPLE
            Get-WS1BulkDeviceSettings -WS1Host xx123.awmdm.com -headers (HeaderHashTable)
        .PARAMETER WS1Host
            The URL to your API server. You can also use the Console URL 
  #>
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [int]$tagId,
        [Parameter(Mandatory=$true, Position=1)]
        [string][ValidateSet("addDevices","removeDevices")]$tagAction,
        [Parameter(Mandatory=$true, Position=2)]
        [array]$Devices,
        [Parameter(Mandatory=$true, Position=3)]
        [Hashtable]$headers
    )

    ###Convert Array of DeviceIDs into JSON     
    $body = @{
                BulkValues = @{Value = @($Devices)}
            }

    $WS1TagAction = Invoke-Restmethod -Method POST -Uri https://$($headers.ws1ApiUri)/api/mdm/tags/$tagId/$tagAction -body (ConvertTo-Json $body) -Headers $headers

     
    return $WS1TagAction
}


Function Get-WS1TaggedDevices {
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$WS1Host,
        [Parameter(Mandatory=$true, Position=1)]
        [string]$tagId,
        [Parameter(Mandatory=$false, Position=2)]
        [datetime]$lastSeen,
        [Parameter(Mandatory=$true, Position=3,ValueFromPipelineByPropertyName=$true)]
        [Hashtable]$headers
    )

    if (!$lastSeen) {
        $ws1TaggedDevices = Invoke-RestMethod -Method GET -Uri https://$ws1Host/api/mdm/tags/$tagId/devices -Headers $headers
    }
    else {
        $ws1TaggedDevices = Invoke-RestMethod -Method GET -Uri https://$ws1Host/api/mdm/tags/$tagId/devices?lastseen=$lastSeen
    }
    return $ws1TaggedDevices
}
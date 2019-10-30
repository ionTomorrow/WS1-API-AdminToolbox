﻿###############################
###
###  TAG CMDLETS
###
###############################


Function Get-WS1Tag {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$WS1Host,
        [Parameter(Mandatory=$false, Position=1)]
        [string]$tagName,
        [Parameter(Mandatory=$false, Position=2)]
        [int]$GroupID,
        [Parameter(Mandatory=$true, Position=3)]
        [ValidateSet("Device","General", "All")]
        [string]$tagType,
        [Parameter(Mandatory=$true, Position=4)]
        [int]$Resultsize,
        [Parameter(Mandatory=$true, Position=5,ValueFromPipelineByPropertyName=$true)]
        [Hashtable]$headers
        )
        $searchString = ""
        if (!$tagName) {}
        else {
            $searchString = "name=$tagname"
        }
        if (!$GroupID) {}
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
                $searchString = $searchString + "pagesize=$Resultsize"
            }
            else {
                $searchString = $searchString + "&pagesize=$Resultsize"
            }
        }
       
        $WS1TagList = Invoke-RestMethod -Method GET -Uri https://$WS1Host/api/mdm/tags/search?$searchString -Headers $headers
        return $WS1TagList
}

Function Set-WS1DeviceTag {
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$WS1Host,
        [Parameter(Mandatory=$true, Position=1)]
        [array]$WS1TagDevices,
        [Parameter(Mandatory=$true, Position=2,ValueFromPipelineByPropertyName=$true)]
        [Hashtable]$headers
    )
    $tagId = "10023"
    $body = @{
                BulkValues = @{Value = @($WS1TagDevices)}
            }
    $WS1TagAction = Invoke-Restmethod -Method POST -Uri https://$WS1host/api/mdm/tags/$tagId/adddevices -body (ConvertTo-Json $body) -Headers $Headers
    return $WS1TagAction
}
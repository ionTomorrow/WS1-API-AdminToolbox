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
        [string]$GroupID,
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
        [string]$WS1Tag,
        [Parameter(Mandatory=$true, Position=2)]
        [array]$WS1TagDevices,
        [Parameter(Mandatory=$true, Position=3,ValueFromPipelineByPropertyName=$true)]
        [Hashtable]$headers
    )
    $WS1TagDevices = @("888","841","972")

    $bulkValues = @{}
           # foreach ($WS1Device in $WS1TagDevices) {
                $bulkValues.Add("Value", $WS1TagDevices)
           # }
    $body = @{
                BulkValues = $bulkValues
            }


$WS1TagAction # $WS1TagAction = Invoke-Restmethod -Method POST -Uri https://$awEnvUri/api/mdm/tags/$tagId/adddevices -body (ConvertTo-Json $body) -Headers $awRestConnection

    write-host "TagID = " $WS1Tag
    write-host "BulkValues :" $bulkValues
    write-host "Body : " $body
    write-host $WS1TagAction
    
    return $WS1TagAction
}
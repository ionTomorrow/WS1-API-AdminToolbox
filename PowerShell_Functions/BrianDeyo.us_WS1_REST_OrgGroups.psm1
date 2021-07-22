
###############################
###
###  ORGANIZATION GROUP CMDLETS
###
###############################


Function Find-CustomerOGID {
    param (
        [Parameter(Mandatory=$true, Position=2,ValueFromPipelineByPropertyName=$true)]
        [Hashtable]$headers
        )
    $WS1CustomerOG = Invoke-RestMethod -Method GET -Uri https://$($headers.ws1ApiUri)/api/system/groups/search?type=customer -Headers $headers

    return $WS1CustomerOG.LocationGroups.Id.value
}


Function clear-AwOrgGroup {
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$awHost,
        [Parameter(Mandatory=$true, Position=1)]
        [string]$awOgId,
        [Parameter(Mandatory=$true, Position=2,ValueFromPipelineByPropertyName=$true)]
        [Hashtable]$headers
        )
    $awOgDelete = Invoke-RestMethod -Method Delete -Uri https://$awhost/api/system/groups/$awOgId -Headers $Headers
    return $awOgDelete
}

Function get-AwOgTree {
param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$awHost,
        [Parameter(Mandatory=$true, Position=1)]
        [string]$awParentOgId,
        [Parameter(Mandatory=$true, Position=2,ValueFromPipelineByPropertyName=$true)]
        [Hashtable]$headers
        )
    $awOgTree = Invoke-RestMethod -Method Get -Uri https://$awhost/api/system/groups/$awParentOgId/children -Headers $Headers
    return $awOgTree
}

Function clear-AwOrgTree {
param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$awHost,
        [Parameter(Mandatory=$true, Position=1)]
        [string]$awParentOgId,
        [Parameter(Mandatory=$true, Position=2,ValueFromPipelineByPropertyName=$true)]
        [Hashtable]$headers
        )
    $awOgTree = Invoke-RestMethod -Method Get -Uri https://$awhost/api/system/groups/$awParentOgId/children -Headers $Headers
    ###Must add logic to prompt for a Y verification before actually deleting. Probably should include $awOgParentId.name or whatever
    $awOgList = @()
    $awOgArray = {$awOgList}.Invoke()
    foreach ($awOg in $awOgTree) {
        $awOgArray.Add($awOg.id.value)
    }
    $awOgArray = $awOgArray | Sort-Object -Descending
    foreach ($awOg in $awOgArray) {
        $awOgDelete = Invoke-RestMethod -Method Delete -Uri https://$awhost/api/system/groups/$awOg -Headers $Headers
        write-host "Deleting $awOg"
    }
}

Function Add-WS1OrgGroup {
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
  #>
  param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$awHost,
        [Parameter(Mandatory=$true, Position=1)]
        [string]$awOgParentId,
        [Parameter(Mandatory=$true, Position=2)]
        [string]$awOgName,
        [Parameter(Mandatory=$false, Position=3)]
        [string]$awOgGroupId,
        [Parameter(Mandatory=$true, Position=4)]
        [string]$awOgLocationGroupType,
        [Parameter(Mandatory=$true, Position=5)]
        [string]$awOgCountry,
        [Parameter(Mandatory=$true, Position=6)]
        [string]$awOgLocale,
        [Parameter(Mandatory=$true, Position=7)]
        [string]$awOgAddDefaultLocation,
        [Parameter(Mandatory=$true, Position=8,ValueFromPipelineByPropertyName=$true)]
        [Hashtable]$headers
        )

    ### Creation of JSON payload
    $body = @{}
    
    if ($awOgName -ne $null) {
        $body.Add("Name", $awOgName)
    }
    if ($awOgGroupId -ne $null) {
        $body.Add("GroupId", $awOgGroupId)
    }
    if ($awOgLocationGroupType -ne $null) {
        $body.Add("LocationGroupType", $awOgLocationGroupType)
    }
    if ($awOgCountry -ne $null) {
        $body.Add("Country", $awOgCountry)
    }
    if ($awOgLocale -ne $null) {
        $body.Add("Locale", $awOgLocale)
    }
    if ($awOgAddDefaultLocation -ne $null) {
        $body.Add("AddDefaultLocation", $awOgAddDefaultLocation)
    }
    

    

    $newAwOg = Invoke-RestMethod -Method POST -Uri https://$awhost/Api/System/groups/$awOgParentId -Body (ConvertTo-Json $body) -Headers $Headers
    return $newAwOg
}


Function Find-WS1OrgGroup {
 <#
    .SYNOPSIS
    Find Org Group by searching
    .DESCRIPTION
    Uses specific attributes to search for a specific OG
    .EXAMPLE
    find-ws1OrgGroup -name -type -groupid -orderby -page -pagesize - sortorder -headers
    .PARAMETER awHost
    The URL to your API server. You can also use the Console URL
    .PARAMETER SearchBy
    Unique Identifier used to specify which devices to delete. Possible values include DeviceID,MacAddress,UDID,SerialNumber,ImeiNumber
  #>
  param (
        [Parameter(Mandatory=$false, Position=0)]
        [string]$ws1OgName,
        [Parameter(Mandatory=$false, Position=1)]
        [string]$ws1OgType,
        [Parameter(Mandatory=$false, Position=2)]
        [int]$ws1OgId,
        [Parameter(Mandatory=$false, Position=3)]
        [ValidateSet("Id","Name","GroupId","LocationGroupType")]
        [string]$orderBy,
        [Parameter(Mandatory=$false, Position=4)]
        [int]$page,
        [Parameter(Mandatory=$false, Position=5)]
        [int]$pagesize,
        [Parameter(Mandatory=$false, Position=6)]
        [ValidateSet("ASC","DESC")]
        [string]$sortOrder,
        [Parameter(Mandatory=$true, Position=7,ValueFromPipelineByPropertyName=$true)]
        [Hashtable]$headers
        )

       
    $searchString = $ws1OgId
    
    try {
        $ws1OgResults = Invoke-RestMethod -Method GET -Uri https://$($headers.ws1ApiUri)/Api/System/groups/search?$searchString -Headers $Headers
    }
    catch {
        write-host "Search error... finish this script buddy"
    }
    return $ws1OgResults
}


Function get-ws1OrgGroup {
    <#
       .SYNOPSIS
       Find Org Group by ID
       .DESCRIPTION
       Required knowing OGID
       .EXAMPLE
       get-ws1OrgGroup -name -type -groupid  -headers
       .PARAMETER awHost
       The URL to your API server. You can also use the Console URL
       .PARAMETER SearchBy
       Unique Identifier used to specify which devices to delete. Possible values include DeviceID,MacAddress,UDID,SerialNumber,ImeiNumber
     #>
     param (
           [Parameter(Mandatory=$true, Position=0)]
           [int]$ws1OgId,
           [Parameter(Mandatory=$true, Position=7,ValueFromPipelineByPropertyName=$true)]
           [Hashtable]$headers
           )
   
    try {
        $ws1OgResults = Invoke-webRequest -Method GET -Uri https://$($headers.ws1ApiUri)/Api/System/groups/$ws1OgId -Headers $Headers
        $ws1OgResults = ConvertFrom-Json $ws1OgResults
    }
    catch [Exception] {
        if ($_.ErrorDetails) {
            $ws1OgResults = ConvertFrom-Json($_.ErrorDetails)
        }
    }
    return $ws1OgResults
}

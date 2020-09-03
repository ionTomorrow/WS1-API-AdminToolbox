###############################
###
###  INDIVIDUAL USER CMDLETS
###
###############################
<#
    2019-03-05 - Initial Creation
#>

Function New-WS1User {
    <#
        .SYNOPSIS
            Create a new BASIC or DIRECTORY User
        .DESCRIPTION
            Creates a new user account.
        .EXAMPLE
            New-WS1User -
        .PARAMETER ws1EnvUri
            The URL to your API server. You can also use the Console URL
   
        .PARAMETER SecurityType
        .PARAMETER UserName
        .PARAMETER Password
        .PARAMETER FirstName
        .PARAMETER LastName
        .PARAMETER Status
        .PARAMETER Email        
        .PARAMETER ContactNumber
        .PARAMETER MobileNumber
        .PARAMETER Group
        .PARAMETER LocationGroupId
        .PARAMETER Role
        .PARAMETER MessageType
        .PARAMETER MessageTemplateId

  #>

    param (
        [Parameter(Mandatory=$true, Position=0)]
            [string]$ws1EnvUri,
        [Parameter(Mandatory=$true, Position=1)]    
            [int]$SecurityType,
        [Parameter(Mandatory=$true, Position=2)]
            [string]$UserName,
        [Parameter(Mandatory=$false, Position=3)]
            [string]$Password,
        [Parameter(Mandatory=$false, Position=4)]
            [string]$FirstName,
        [Parameter(Mandatory=$false, Position=5)]
            [string]$LastName,
        [Parameter(Mandatory=$false, Position=6)]
            [ValidateSet("active","inactive")]
            [string]$Status,
        [Parameter(Mandatory=$false, Position=7)]
            [string]$Email,
        [Parameter(Mandatory=$false, Position=8)]           
           [string]$ContactNumber,
        [Parameter(Mandatory=$false, Position=9)]
            [string]$MobileNumber,
        [Parameter(Mandatory=$false, Position=10)]
            [int]$Group,
        [Parameter(Mandatory=$false, Position=11)]
            [int]$LocationGroupId,
        [Parameter(Mandatory=$false, Position=12)]
            [string]$Role,
        [Parameter(Mandatory=$false, Position=13)]
            [string]$MessageType,
        [Parameter(Mandatory=$false, Position=14)]
            [int]$MessageTemplateId,
        [Parameter(Mandatory=$true, Position=15,ValueFromPipelineByPropertyName=$true)]
            [Hashtable]$headers,
        [Parameter(Mandatory=$false, Position=16)]
            [int]$StagingMode,
        [Parameter(Mandatory=$false, Position=17)]
            [ValidateSet("true","false")]
            [string]$StagingEnabled
    )


    ### Creation of JSON payload
    $body = @{}
    $body.Add("SecurityType", $SecurityType)
    if ($UserName -ne $null) {$body.Add("UserName", $UserName)}
    if ($Password -ne $null) {$body.Add("Password", $Password)}
    if ($FirstName -ne $null) {$body.Add("FirstName", $FirstName)}
    if ($LastName -ne $null) {$body.Add("LastName", $LastName)}
    if ($Status -eq "active") {$body.Add("Status", "true")}
        else {$body.Add("Status","inactive")}
    if ($Email -ne $null) {$body.Add("Email", $Email)}        
    if ($ContactNumber -ne $null) {$body.Add("ContactNumber", $ContactNumber)}
    if ($MobileNumber -ne $null) {$body.Add("MobileNumber", $MobileNumber)}
    if ($Group -ne $null) {$body.Add("Group", $Group)}
    if ($LocationGroupId -ne $null) {$body.Add("LocationGroupId", $LocationGroupId)}
    if ($Role -ne $null) {$body.Add("Role", $Role)}
    if ($MessageType -ne $null) {$body.Add("MessageType", $MessageType)}
    if ($MessageTemplateId -ne $null) {$body.Add("MessageTemplateId", $MessageTemplateId)}
    if ($StagingMode -ne $null) {$body.add("StagingMode", $StagingMode)}
    if ($StagingEnabled) {$body.add("DeviceStagingEnabled", $StagingEnabled)}
    
    $ws1UserAdd = Invoke-Restmethod -Method POST -Uri https://$WS1EnvUri/api/system/users/adduser -Body (ConvertTo-Json $body) -Headers $Headers
    return $ws1UserAdd
}


function find-ws1User {
    param (
        [Parameter(Mandatory=$false, Position=0)]
            [string]$FirstName,
        [Parameter(Mandatory=$false, Position=1)]
            [string]$LastName,
        [Parameter(Mandatory=$false, Position=2)]
            [string]$Email,
        [Parameter(Mandatory=$false, Position=3)]
            [int]$LocationGroupId,
        [Parameter(Mandatory=$false, Position=4)]
            [string]$Role,
        [Parameter(Mandatory=$false, Position=5)]
            [string]$UserName,
        [Parameter(Mandatory=$false, Position=6)]           
           [int]$page,
        [Parameter(Mandatory=$false, Position=7)]
            [int]$pagesize,
        [Parameter(Mandatory=$false, Position=8)]
            [string]$orderBy,
        [Parameter(Mandatory=$false, Position=9)]
        [ValidateSet("ASC","DESC")]
            [string]$sortOrder,
        [Parameter(Mandatory=$true, Position=10,ValueFromPipelineByPropertyName=$true)]
            [Hashtable]$headers
        )
        $headers = convertTo-ws1HeaderVersion -headers $headers -ws1ApiVersion 1
        $ws1EnvUri = $headers.ws1ApiUri

        $userSearch = Invoke-WebRequest -method GET -Uri https://$($headers.ws1ApiUri)/api/system/users/search?username=$username -Headers $headers
        return $userSearch
}


###Retreive ENrollment User's Details
function get-ws1User {
    param (
        [Parameter(Mandatory=$true, Position=0)]
            $userId,
        [Parameter(Mandatory=$true, Position=1)]
            [Hashtable]$headers
    )
    
    $ws1EnvApi = $headers.'aw-tenant-code'
    $ws1EnvUri = $headers.ws1ApiUri

    $ws1user = invoke-webrequest -Method GET -Uri https://$ws1EnvUri/api/system/users/$userId -Headers $headers
    return $ws1user

}


###Update Enrollment User's Details
function set-ws1User {
    param (
        [Parameter(Mandatory=$true, Position=0)]$UserId,
        [Parameter(Mandatory=$false, Position=1)]$ContactNumber,
        [Parameter(Mandatory=$false, Position=2)]$DisplayName,
        [Parameter(Mandatory=$false, Position=3)]$Password,
        [Parameter(Mandatory=$false, Position=4)]$FirstName,
        [Parameter(Mandatory=$false, Position=5)]$LastName,
        [Parameter(Mandatory=$false, Position=6)]$Email,
        [Parameter(Mandatory=$false, Position=7)]$mobileNumber,
        [Parameter(Mandatory=$false, Position=8)]$GroupId,
        [Parameter(Mandatory=$true, Position=9)]$LocationGroupId,
        [Parameter(Mandatory=$false, Position=10)]$Role,
        [Parameter(Mandatory=$false, Position=11)][ValidateSet("Email","SMS","None")]$MessageType,
        [Parameter(Mandatory=$false, Position=12)]$MessageTemplateId,
        [Parameter(Mandatory=$false, Position=13)]$ExternalId,
        [Parameter(Mandatory=$true, Position=14)][Hashtable]$headers,
        [Parameter(Mandatory=$false, Position=16)][int]$StagingMode,
        [Parameter(Mandatory=$false, Position=17)][ValidateSet("true","false")][string]$StagingEnabled
    )

    $ws1EnvUri = $headers.ws1ApiUri
 ### Creation of JSON payload
if ($userId -ne $null) {
    $body = @{}
    if ($ContactNumber -ne $null) {$body.Add("ContactNumber", $ContactNumber)}
    if ($DisplayName -ne $null) {$body.Add("UserName", $DisplayName)}
    if ($Password -ne $null) {$body.Add("Password", $Password)}
    if ($FirstName -ne $null) {$body.Add("FirstName", $FirstName)}
    if ($LastName -ne $null) {$body.Add("LastName", $LastName)}
    if ($Email -ne $null) {$body.Add("Email", $Email)}
    if ($MobileNumber -ne $null) {$body.Add("MobileNumber", $MobileNumber)}
    if ($Group -ne $null) {$body.Add("Group", $Group)}
    if ($LocationGroupId -ne $null) {$body.Add("LocationGroupId", $LocationGroupId)}
    if ($Role -ne $null) {$body.Add("Role", $Role)}
    if ($MessageType -ne $null) {$body.Add("MessageType", $MessageType)}
    if ($MessageTemplateId -ne $null) {$body.Add("MessageTemplateId", $MessageTypeId)}
    if ($StagingMode -ne $null) {$body.add("StagingMode", $StagingMode)}
    if ($deviceStagingEnabled) {$body.add("deviceStagingEnabled", $deviceStagingEnabled)}
    if ($deviceStagingType) {$body.add("deviceStagingEnabled", $deviceStagingType)}
}

$ws1user = Invoke-WebRequest -Uri https://$ws1EnvUri/api/system/users/$userId/update -Method POST -Body (ConvertTo-Json $body) -Headers $headers
return $ws1User
}




<#
Copyright 2016-2021 Brian Deyo
Copyright 2021 VMware, Inc.
SPDX-License-Identifier: MPL-2.0

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at https://mozilla.org/MPL/2.0/.
#>



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
        [Parameter(Mandatory=$true, Position=1)]    
            [int]$SecurityType,
        [Parameter(Mandatory=$true, Position=2)]
            [string]$UserName,
        [Parameter(Mandatory=$false, Position=3)]
            [secureString]$Password,
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
    if ($Password -ne $null) {$body.Add("Password", (ConvertFrom-SecureString -AsPlainText $Password))}
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
    
    $ws1UserAdd = Invoke-Restmethod -Method POST -Uri https://$($headers.ws1ApiUri)/api/system/users/adduser -Body (ConvertTo-Json $body) -Headers $Headers
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
    
    $ws1user = invoke-webrequest -Method GET -Uri https://$($headers.ws1ApiUri)/api/system/users/$userId -Headers $headers
    return $ws1user

}


###Update Enrollment User's Details
function set-ws1User {
    param (
        [Parameter(Mandatory=$true, Position=0)][int]$UserId,
        [Parameter(Mandatory=$false, Position=1)][string]$ContactNumber,
        [Parameter(Mandatory=$false, Position=2)][string]$DisplayName,
        [Parameter(Mandatory=$false, Position=3)][secureString]$Password,
        [Parameter(Mandatory=$false, Position=4)][string]$FirstName,
        [Parameter(Mandatory=$false, Position=5)][string]$LastName,
        [Parameter(Mandatory=$false, Position=6)][string]$Email,
        [Parameter(Mandatory=$false, Position=7)][string]$mobileNumber,
        [Parameter(Mandatory=$false, Position=8)][int]$GroupId,
        [Parameter(Mandatory=$true, Position=9)][int]$LocationGroupId,
        [Parameter(Mandatory=$false, Position=10)][array]$Role,
        [Parameter(Mandatory=$false, Position=11)][ValidateSet("Email","SMS","None")][string]$MessageType,
        [Parameter(Mandatory=$false, Position=12)][int]$MessageTemplateId,
        [Parameter(Mandatory=$false, Position=13)][string]$ExternalId,
        [Parameter(Mandatory=$true, Position=14)][Hashtable]$headers,
        [Parameter(Mandatory=$false, Position=16)][int]$StagingMode,
        [Parameter(Mandatory=$false, Position=17)][ValidateSet("true","false")][string]$StagingEnabled
    )

    
 ### Creation of JSON payload
if ($null -ne $userId) {
    $body = @{}
    if ($null -ne $ContactNumber) {$body.Add("ContactNumber", $ContactNumber)}
    if ($null -ne $DisplayName) {$body.Add("UserName", $DisplayName)}
    if ($null -ne $Password) {$body.Add("Password", (ConvertFrom-SecureString -AsPlainText $Password))}
    if ($null -ne $FirstName) {$body.Add("FirstName", $FirstName)}
    if ($null -ne $LastName) {$body.Add("LastName", $LastName)}
    if ($null -ne $Email) {$body.Add("Email", $Email)}
    if ($null -ne $MobileNumber) {$body.Add("MobileNumber", $MobileNumber)}
    if ($null -ne $Group) {$body.Add("Group", $Group)}
    if ($null -ne $LocationGroupId) {$body.Add("LocationGroupId", $LocationGroupId)}
    if ($null -ne $Role) {$body.Add("Role", $Role)}
    if ($null -ne $MessageType) {$body.Add("MessageType", $MessageType)}
    if ($null -ne $MessageTemplateId) {$body.Add("MessageTemplateId", $MessageTypeId)}
    if ($null -ne $StagingMode) {$body.add("StagingMode", $StagingMode)}
    if ($deviceStagingEnabled) {$body.add("deviceStagingEnabled", $deviceStagingEnabled)}
    if ($deviceStagingType) {$body.add("deviceStagingEnabled", $deviceStagingType)}
}

$ws1user = Invoke-WebRequest -Uri https://$($headers.ws1ApiUri)/api/system/users/$userId/update -Method POST -Body (ConvertTo-Json $body) -Headers $headers
return $ws1User
}


Function update-ws1UserOutput {
    <#.SYNOPSIS
    Appends columns/attributes to user output.
    .DESCRIPTION
    Helps build out an array that has User Properties even is user isn't actually found
    
    .EXAMPLE
    update-ws1UserOutput $device
    .PARAMETER user
    .PARAMETER userType

    #>
    param (
        [Parameter(Mandatory=$true, Position=0)][array]$user,
        [Parameter(Mandatory=$true, Position=0)][ValidateSet("users","admins")][array]$userType
    )
    if ($null -eq $user.FirstName) {$user | add-member -Name "FirstName" -MemberType NoteProperty -Value "NoSampleRetrieved"}
    if ($null -eq $user.LastName) {$user | add-member -Name "LastName" -MemberType NoteProperty -Value "NoSampleRetrieved"}   
    if ($null -eq $user.Email) {$user | add-member -Name "Email" -MemberType NoteProperty -Value "NoSampleRetrieved"}
    if ($null -eq $user.LocationGroupId) {$user | add-member -Name "LocationGroupId" -MemberType NoteProperty -Value "NoSampleRetrieved"}
    if ($null -eq $user.OrganizationGroupUuid) {$user | add-member -Name "OrganizationGroupUuid" -MemberType NoteProperty -Value "NoSampleRetrieved"}
    if ($null -eq $user.Id) {$user | add-member -Name "Id" -MemberType NoteProperty -Value "NoSampleRetrieved"}
    if ($null -eq $user.Uuid) {$user | add-member -Name "Uuid" -MemberType NoteProperty -Value "NoSampleRetrieved"}

    switch ($userType) {
        "admins" {
            if ($null -eq $user.LocationGroup) {$user | add-member -Name "LocationGroup" -MemberType NoteProperty -Value "NoSampleRetrieved"}
            if ($null -eq $user.TimeZone) {$user | add-member -Name "TimeZone" -MemberType NoteProperty -Value "NoSampleRetrieved"}
            if ($null -eq $user.Locale) {$user | add-member -Name "Locale" -MemberType NoteProperty -Value "NoSampleRetrieved"}
            if ($null -eq $user.InitialLandingPage) {$user | add-member -Name "InitialLandingPage" -MemberType NoteProperty -Value "NoSampleRetrieved"}
            if ($null -eq $user.LastLoginTimeStamp) {$user | add-member -Name "LastLoginTimeStamp" -MemberType NoteProperty -Value "NoSampleRetrieved"}
            if ($null -eq $user.Roles) {$user | add-member -Name "Roles" -MemberType NoteProperty -Value "NoSampleRetrieved"}
            if ($null -eq $user.IsActiveDirectoryUser) {$user | add-member -Name "IsActiveDirectoryUser" -MemberType NoteProperty -Value "NoSampleRetrieved"}
            if ($null -eq $user.RequiresPasswordChange) {$user | add-member -Name "RequiresPasswordChange" -MemberType NoteProperty -Value "NoSampleRetrieved"}
            if ($null -eq $user.MessageTemplateId) {$user | add-member -Name "MessageTemplateId" -MemberType NoteProperty -Value "NoSampleRetrieved"}
        }
        "users" {
            if ($null -eq $user.Status) {$user | add-member -Name "Status" -MemberType NoteProperty -Value "NoSampleRetrieved"}
            if ($null -eq $user.SecurityType) {$user | add-member -Name "SecurityType" -MemberType NoteProperty -Value "NoSampleRetrieved"}
            if ($null -eq $user.ContactNumber) {$user | add-member -Name "ContactNumber" -MemberType NoteProperty -Value "NoSampleRetrieved"}
            if ($null -eq $user.MobileNumber) {$user | add-member -Name "MobileNumber" -MemberType NoteProperty -Value "NoSampleRetrieved"}
            if ($null -eq $user.MessageType) {$user | add-member -Name "MessageType" -MemberType NoteProperty -Value "NoSampleRetrieved"}
            if ($null -eq $user.EmailUserName) {$user | add-member -Name "EmailUserName" -MemberType NoteProperty -Value "NoSampleRetrieved"}
            if ($null -eq $user.Group) {$user | add-member -Name "Group" -MemberType NoteProperty -Value "NoSampleRetrieved"}
            if ($null -eq $user.LocationGroupId) {$user | add-member -Name "LocationGroupId" -MemberType NoteProperty -Value "NoSampleRetrieved"}
            if ($null -eq $user.Role) {$user | add-member -Name "Role" -MemberType NoteProperty -Value "NoSampleRetrieved"}
            if ($null -eq $user.EnrolledDevicesCount) {$user | add-member -Name "EnrolledDevicesCount" -MemberType NoteProperty -Value "NoSampleRetrieved"}
            if ($null -eq $user.CustomAttribute1) {$user | add-member -Name "CustomAttribute1" -MemberType NoteProperty -Value "NoSampleRetrieved"}
            if ($null -eq $user.CustomAttribute2) {$user | add-member -Name "CustomAttribute2" -MemberType NoteProperty -Value "NoSampleRetrieved"}
            if ($null -eq $user.CustomAttribute3) {$user | add-member -Name "CustomAttribute3" -MemberType NoteProperty -Value "NoSampleRetrieved"}
            if ($null -eq $user.CustomAttribute4) {$user | add-member -Name "CustomAttribute4" -MemberType NoteProperty -Value "NoSampleRetrieved"}
            if ($null -eq $user.CustomAttribute5) {$user | add-member -Name "CustomAttribute5" -MemberType NoteProperty -Value "NoSampleRetrieved"}
            if ($null -eq $user.ExternalId) {$user | add-member -Name "ExternalId" -MemberType NoteProperty -Value "NoSampleRetrieved"}
            if ($null -eq $user.StagingMode) {$user | add-member -Name "StagingMode" -MemberType NoteProperty -Value "NoSampleRetrieved"}
            if ($null -eq $user.DeviceStagingEnabled) {$user | add-member -Name "DeviceStagingEnabled" -MemberType NoteProperty -Value "NoSampleRetrieved"}
        }
    }

    return $user
}



function remove-ws1User {
    <#.SYNOPSIS
    Deletes a User account
    .DESCRIPTION
    Deletes a user account using either the v1 or v2 API
    
    .EXAMPLE
    remove-ws1User -userid <userId> -headers <headers>
    remote-ws1User -v2 -userUuid <userUuid. -headers <headers>
    .PARAMETER userId
    .PARAMETER headers
    #>
    param (
        [Parameter(ParameterSetName='v2',Mandatory=$false, Position=0)]
            [switch]$v2,
        [Parameter(ParameterSetName='v2',Mandatory=$true, Position=0)]
            [string]$useruuid,    
        [Parameter(Mandatory=$false, Position=0)]
            [int]$userId,
        [Parameter(Mandatory=$true, Position=1)]
            [Hashtable]$headers
    )


    ###Convert Headers to use v2 API


    if ($v2) {
        [int]$apiVersion = 2
    }
    else {
        [int]$apiVersion = 1
    }

    switch ($apiVersion) {
        1 {
            try {
                $ws1user = invoke-webrequest -Method DELETE -Uri https://$($headers.ws1ApiUri)/api/system/users/$($userId)/delete -Headers $headers
            }
            catch [exception] {            
            }
        }
        2 {
            $headers = convertTo-ws1HeaderVersion $headers -ws1APIVersion 2

            try {
                $ws1user = Invoke-WebRequest -Method DELETE -Uri https://$($headers.ws1ApiUri)/api/system/users/$($useruuid) -Headers $headers                
            }
            catch [exception] {

            }
        }
    }
    
    return $ws1user

}


function disable-ws1User {
    <#.SYNOPSIS
    Deactivates a User account
    .DESCRIPTION
    Deactivates a user account
    
    .EXAMPLE
    deactivate-ws1User -userid <userId> -headers <headers>
    .PARAMETER userId
    .PARAMETER headers
    #>
    param (
        [Parameter(Mandatory=$false, Position=0)]
            [int]$userId,
        [Parameter(Mandatory=$true, Position=1)]
            [Hashtable]$headers
    )


    try {
        #$ws1user = Invoke-WebRequest -Method POST -uri https://$($headers.ws1ApiUri)/api/system/users/$($userId)/deactivate -Headers $headers
        $ws1User = Invoke-RestMethod -Method POST -uri https://$($headers.ws1ApiUri)/api/system/users/$($userId)/deactivate -headers $headers
    }
    catch [exception] {
        $ws1user = $error[0]        
    }
    
    return $ws1user

}

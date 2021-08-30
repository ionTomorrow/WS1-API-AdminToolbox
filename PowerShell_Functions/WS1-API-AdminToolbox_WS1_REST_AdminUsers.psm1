<#
Copyright 2016-2021 Brian Deyo
Copyright 2021 VMware, Inc.
SPDX-License-Identifier: MPL-2.0

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at https://mozilla.org/MPL/2.0/.
#>


#####
### ADMIN USERS
#####

function find-ws1AdminUser {
    <#
        .SYNOPSIS
            PS Function for https://(Your WS1 URL)/api/help/#!/apis/10008?!/AdminsV1/AdminsV1_SearchAsync
        .DESCRIPTION
            Performs necessary checks and search for the admin users based on the request query.
        .EXAMPLE
            
        .PARAMETER headers
            Generated from the select-ws1Config cmdlet           
        .PARAMETER UserName
            Username in Workspace ONE. This can match on partial strings
        .PARAMETER FirstName
            First name in Workspace ONE. This can match on partial strings
        .PARAMETER LastName
            Last name in Workspace ONE. This can match on partial strings
        .PARAMETER Email
            Email address in Workspace ONE. This can match on partial strings
        .PARAMETER LocationGroupId
            The OG ID you are looking at
        .PARAMETER Role
            The Role Name. NOT the Role ID
        .PARAMETER Status
            The admin status. Allowed values are Active or Inactive. Defaults to all, if this attribute is not specified.
        

  #>
    [CmdletBinding()]
    param (  
        [Parameter(Mandatory=$false, Position=5)][string]
            $UserName,
        [Parameter(Mandatory=$false, Position=0)][string]$FirstName,
        [Parameter(Mandatory=$false, Position=1)][string]$LastName,
        [Parameter(Mandatory=$false, Position=2)][string]$Email,
        [Parameter(Mandatory=$false, Position=3)][int]$LocationGroupId,
        [Parameter(Mandatory=$false, Position=4)][string]$Role,    
        [Parameter(Mandatory=$false, Position=6)][int]$page,
        [Parameter(Mandatory=$false, Position=7)][int]$pagesize,
        [Parameter(Mandatory=$false, Position=8)][string]$orderBy,
        [Parameter(Mandatory=$false, Position=9)][ValidateSet("ASC","DESC")][string]$sortOrder,
        [Parameter(Mandatory=$false, Position=9)][ValidateSet("Active","Inactive")][string]$status,
        [Parameter(Mandatory=$false, Position=10)][ValidateSet(1,2)][int]$ws1APIVersion,
        [Parameter(Mandatory=$true, Position=10,ValueFromPipelineByPropertyName=$true)][Hashtable]$headers
    )
      
        [hashtable] $stringBuild =@{}
        if ($UserName) {$stringBuild.add("Username",$UserName)}
        if ($FirstName) {$stringBuild.add("Firstname",$FirstName)}
        if ($LastName) {$stringBuild.add("LastName",$LastName)}
        if ($Email) {$stringBuild.add("Email",$Email)}
        if ($LocationGroupId) {$stringBuild.add("LocationGroupId",$LocationGroupId)}
        if ($Role) {$stringBuild.add("Role",$role)}
        if ($page) {$stringBuild.add("page",$page)}
        if ($pagesize) {$stringBuild.add("pagesize",$pagesize)}
        if ($orderBy) {$stringBuild.add("orderBy",$orderBy)}
        if ($sortOrder) {$stringBuild.add("sortOrder",$sortOrder)}
        if ($status) {$stringBuild.add("status",$status)}

        
        $searchUri = "https://$($headers.ws1ApiUri)/api/system/admins/search"
        $uri = New-HttpQueryString -Uri $searchUri -QueryParameter $stringBuild

        #verbose
        switch ($PSBoundParameters['Verbose']) {
            ($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $true) {
                $adminSearch = Invoke-WebRequest -method GET -Uri $uri -Headers $headers
            }
            default {
                $adminSearch = Invoke-RestMethod -method GET -Uri $uri -Headers $headers
            }
        }        
    return $adminSearch
}

Function New-WS1AdminUser {
    <#
        .SYNOPSIS
            Create a new BASIC or DIRECTORY Admin User
            https://cn1506.awmdm.com/api/help/#!/apis/10008?!/AdminsV1/AdminsV1_Put
        .DESCRIPTION
            Creates a new Admin user account.

            This cmdlet requires the -Roles parameter to have an valid array as input.
        .EXAMPLE
            New-WS1AdminUser -Username (username) -Password "(password)" -Firstname "(firstname)" -LastName "(surname)" -email (emailAddress) -IsActiveDirectoryUser $false -Roles $role -LocationGroupID <OGid> -headers $headers
        .PARAMETER headers
            Generated from the select-ws1Config cmdlet
   
        .PARAMETER IsActiveDirectoryUser
        .PARAMETER UserName
        .PARAMETER Password
        .PARAMETER FirstName
        .PARAMETER LastName
        .PARAMETER Status
        .PARAMETER Email        
        .PARAMETER IsActiveDIrectoryUser
        .PARAMETER TimeZone
        .PARAMETER LocationGroupId
        .PARAMETER Locale
        .PARAMETER InitialLandingPage
        .PARAMETER Roles
            ARRAY
        .PARAMETER RoleID
        .PARAMETER LocationGroupId
        .PARAMETER RequiresPasswordChange
  #>
    
    param (
        
        [Parameter(Mandatory=$true, Position=0)][string]$UserName,
        [Parameter(Mandatory=$true, Position=1)][securestring]$Password,
        [Parameter(Mandatory=$true, Position=2)][string]$FirstName,
        [Parameter(Mandatory=$true, Position=3)][string]$LastName,
        [Parameter(Mandatory=$true, Position=4)][string]$Email,
        [Parameter(Mandatory=$true, Position=5)][bool]$IsActiveDirectoryUser, 
        [Parameter(Mandatory=$false, Position=6)][string]$TimeZone,
        [Parameter(Mandatory=$true, Position=7)][int]$LocationGroupId,
        [Parameter(Mandatory=$false, Position=8)][string]$Locale,
        [Parameter(Mandatory=$false, Position=9)][string]$InitialLandingPage,      
        [Parameter(Mandatory=$true, Position=10)][array]$Roles,
        [Parameter(Mandatory=$false, Position=11)][bool]$RequiresPasswordChange,
        [Parameter(Mandatory=$false, Position=12)][string]$MessageType,
        [Parameter(Mandatory=$false, Position=13)][int]$MessageTemplateId,
        [Parameter(Mandatory=$true, Position=14,ValueFromPipelineByPropertyName=$true)][Hashtable]$headers
    )

    
    ### Creation of JSON payload
    $body = @{}
    $body.Add("IsActiveDirectoryUser", $IsActiveDirectoryUser)
    
###LDAP users should already have this information populated 
    if ($IsActiveDirectoryUser -eq $false) {
        if ($UserName -ne $null) {$body.Add("UserName", $UserName)}
        if ($Password -ne $null) {$body.Add("Password", (ConvertFrom-SecureString -AsPlainText $Password))}
        if ($FirstName -ne $null) {$body.Add("FirstName", $FirstName)}
        if ($LastName -ne $null) {$body.Add("LastName", $LastName)}
        if ($Email -ne $null) {$body.Add("Email", $Email)}        
        if ($TimeZone -ne $null) {$body.Add("TimeZone", $TimeZone)}
        if ($LocationGroupId -ne $null) {$body.Add("LocationGroupId", $LocationGroupId)}
        if ($Locale -ne $null) {$body.Add("Locale", $Locale)}
        if ($Roles -ne $null) {$body.Add("Roles",$roles)}
        if ($MessageType -ne $null) {$body.Add("MessageType", $MessageType)}
        if ($MessageTemplateId -ne $null) {$body.Add("MessageTemplateId", $MessageTemplateId)}
    }

    $ws1AdminAdd = Invoke-Restmethod -Method POST -Uri https://$($headers.ws1ApiUri)/api/system/admins/addadminuser -Body (ConvertTo-Json $body) -Headers $Headers
    return $ws1AdminAdd
}

Function Set-ws1AdminUser {

    <#
        .SYNOPSIS
            Create a new BASIC or DIRECTORY Admin User
        .DESCRIPTION
            https://cn1506.awmdm.com/api/help/#!/apis/10008?!/AdminsV1/AdminsV1_UpdateAdminUser
            https://cn1506.awmdm.com/api/help/#!/apis/10008?!/AdminsV1/AdminsV1_ChangePassword

            Updates an existing admin user.
            The -Password parameter needs to be a secureString to work
                You can use the read-host -asSecureString cmdlet to securely capture the password.

        .EXAMPLE
            
        .PARAMETER ws1adminId
        .PARAMETER IsActiveDirectoryUser
        .PARAMETER UserName
        .PARAMETER Password
        .PARAMETER FirstName
        .PARAMETER LastName
        .PARAMETER Status
        .PARAMETER Email        
        .PARAMETER TimeZone
        .PARAMETER LocationGroupId
        .PARAMETER Locale
        .PARAMETER InitialLandingPage
        .PARAMETER Roles
        .PARAMETER RoleID
        .PARAMETER LocationGroupId
        .PARAMETER RequiresPasswordChange

  #>
    
  param (
    
    [Parameter(Mandatory=$true, Position=0)][int]$ws1adminId,
    [Parameter(Mandatory=$false, Position=1)][string]$UserName,
    [Parameter(Mandatory=$false, Position=2)][securestring]$Password,
    [Parameter(Mandatory=$false, Position=3)][string]$FirstName,
    [Parameter(Mandatory=$false, Position=4)][string]$LastName,
    [Parameter(Mandatory=$false, Position=5)][string]$Email,
    [Parameter(Mandatory=$false, Position=6)][bool]$IsActiveDirectoryUser, 
    [Parameter(Mandatory=$false, Position=7)][string]$TimeZone,
    [Parameter(Mandatory=$false, Position=8)][int]$LocationGroupId,
    [Parameter(Mandatory=$false, Position=9)][string]$Locale,
    [Parameter(Mandatory=$false, Position=10)][string]$InitialLandingPage,      
    [Parameter(Mandatory=$false, Position=11)][array]$Roles,
    [Parameter(Mandatory=$false, Position=12)][bool]$RequiresPasswordChange,
    [Parameter(Mandatory=$false, Position=13)][string]$MessageType,
    [Parameter(Mandatory=$false, Position=14)][int]$MessageTemplateId,
    [Parameter(Mandatory=$true, Position=15,ValueFromPipelineByPropertyName=$true)][Hashtable]$headers
    )

    
    ### Creation of JSON payload
    $body = @{}
    $body.Add("IsActiveDirectoryUser", $IsActiveDirectoryUser)


    if ($IsActiveDirectoryUser -eq $false) {
        if ($UserName -ne $null) {$body.Add("UserName", $UserName)}
        if ($Password -ne $null) {$body.Add("Password", (ConvertFrom-SecureString -AsPlainText $Password))}
        if ($FirstName -ne $null) {$body.Add("FirstName", $FirstName)}
        if ($LastName -ne $null) {$body.Add("LastName", $LastName)}
        if ($Email -ne $null) {$body.Add("Email", $Email)}        
        if ($LocationGroupId -ne $null) {$body.Add("LocationGroupId", $LocationGroupId)}
        if ($TimeZone -ne $null) {$body.Add("TimeZone", $TimeZone)}
        if ($Locale -ne $null) {$body.Add("Locale", $Locale)}
        if ($InitialLandingPage -ne $null) {$body.Add("InitialLandingPage", $InitialLandingPage)}
        if ($Roles -ne $null) {$body.Add("Roles",$roles)}
        if ($MessageType -ne $null) {$body.Add("MessageType", $MessageType)}
        if ($MessageTemplateId -ne $null) {$body.Add("MessageTemplateId", $MessageTemplateId)}
    }
    
    if ($Password) {
        $ws1AdminUpdate = Invoke-RestMethod -Method POST -uri https://$($headers.ws1ApiUri)/api/system/admins/$ws1adminId/changepassword -Body (convertTo-Json $body) -Headers $headers
    }

    
    
    $ws1AdminUpdate = Invoke-RestMethod -Method POST https://$($headers.ws1ApiUri)/api/system/admins/$ws1adminId/update -Body (ConvertTo-Json $body) -Headers $headers

    return $ws1AdminUpdate
}

function remove-ws1AdminUser {
    <#
        .SYNOPSIS
            Delete an Admin account
        .DESCRIPTION
            Deletes and Admin account using the V2 API
            https://cn1506.awmdm.com/api/help/#!/apis/10009?!/AdminsV2/AdminsV2_Delete
        .EXAMPLE
            Remove-ws1AdminUser -userUuid test1234 -headers $headers
        .PARAMETER userUuid
        .PARAMETER headers

  #>
    param (
        [Parameter(Mandatory=$true, Position=0)]
            $userUuid,
        [Parameter(Mandatory=$true, Position=1)]
            [Hashtable]$headers
    )
    
    $headers = convertTo-ws1HeaderVersion -ws1APIVersion 2 -headers $headers
    $ws1EnvUri = $headers.ws1ApiUri
    Try{
        $ws1AdminUser = invoke-webrequest -Method DELETE -Uri https://$ws1EnvUri/api/system/admins/$userUuid -Headers $headers
        
    }
    catch [Exception]{
        $ws1AdminUser = $_.exception
    }
    return $ws1AdminUser

}




function get-ws1AdminUser {
    <#
        .SYNOPSIS
            Get an Admin account
        .DESCRIPTION
            Get an Admin account using the V2 API
            https://$($headers.ws1ApiUri)/api/help/#!/apis/10007?!/AdminsV2/AdminsV2_Get
        .EXAMPLE
            get-ws1AdminUser -userUuid test1234 -headers $headers
        .PARAMETER userUuid
        .PARAMETER headers

  #>
    param (
        [Parameter(Mandatory=$true, Position=0)]
            $userUuid,
        [Parameter(Mandatory=$true, Position=1)]
            [Hashtable]$headers
    )
    
    $headers = convertTo-ws1HeaderVersion -ws1APIVersion 2 -headers $headers
    $ws1EnvUri = $headers.ws1ApiUri
    Try{
        $ws1AdminUser = invoke-webrequest -Method GET -Uri https://$ws1EnvUri/api/system/admins/$userUuid -Headers $headers
        
    }
    catch [Exception]{
        $ws1AdminUser = $_.exception
    }
    return $ws1AdminUser
}

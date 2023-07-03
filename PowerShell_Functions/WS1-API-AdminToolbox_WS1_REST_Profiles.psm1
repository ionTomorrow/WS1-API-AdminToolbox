<#
Copyright 2016-2021 Brian Deyo
Copyright 2021 VMware, Inc.
SPDX-License-Identifier: MPL-2.0

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at https://mozilla.org/MPL/2.0/.

###Change Log
    2019-03-29 - modified Set-AwDevice to use new endpoint

#>

function find-ws1Profile {
    <#
        .SYNOPSIS
            The search result will contain basic profile's basic informations.
        .DESCRIPTION
            https://cn1506.awmdm.com/api/help/#!/apis/10003?!/ProfilesV2/ProfilesV2_Search

            This API call does not have a valid version 1 API. This cmdlet defaults to v2

        .EXAMPLE
            find-ws1profile -payLoadName Restriction -platform Apple -headers $headers
       
    #>
    [CmdletBinding()]
    param (          
        [Parameter(Mandatory=$false)]
            [int]
            $organizationGroupId,
        [Parameter(Mandatory=$false)]
            [string]
            $organizationGroupUuid,
        [Parameter(Mandatory=$false)]
            [ValidateSet("apple","android","AppleOsX","qnx","windowsPC")]
            [string]
            $platform,
        [Parameter(Mandatory=$false)]
            [string]
            $profileType,
        [Parameter(Mandatory=$false)]
            [ValidateSet("active","inactive")]
            [string]
            $status,
        [Parameter(Mandatory=$false)]
            [string]
            $searchText,
        [Parameter(Mandatory=$false)]
            [string]
            $orderBy,
        [Parameter(Mandatory=$false)]
            [ValidateSet("ASC","DESC")]
            [string]
            $sortOrder,        
        [Parameter(Mandatory=$false)]
            [int]
            $page,
        [Parameter(Mandatory=$false)]
            [int]
            $pagesize,
        [Parameter(Mandatory=$false)]
            [bool]
            $includeAndroidForWork,
        [Parameter(Mandatory=$false)]
            [ValidateSet("Passcode","Email","Wi-Fi","Restriction","Vpn","CustomSetting","CustomAttribute","ExchangeActiveSync","ExchangeWebServices","Device","SharedDevice","Notifications","HomeScreenLayout","GoogleAccount","ManagedDomains","WebClips","BookmarkSettings","SingleAppMode","SingleSignOn","Permissions","PublicAppAutoUpdate","CustomMessages","ApplicationControl","NetworkSharePoint","DiskEncryption","KernelExtension","PrivacyPreferences","SmartCard","ConferenceRoomDisplay","WindowsLicensing","OemUpdates","WindowsAutomaticUpdates","Encryption","BIOS","UserData","Customization","PassportForWork","Scep","Firewall","Proxy","Windows10Kiosk","Antivirus","P2PBranchCacheSettings","UnifiedWriteFilter","AssignedAccess","ShortcutSettings","Certificate")]
            [string]
            $payloadName,      
        [Parameter(Mandatory=$true, Position=10,ValueFromPipelineByPropertyName=$true)]
            [Hashtable]
            $headers
    )
    
        ###Convert Headers to v2 API
        $headers = convertTo-ws1HeaderVersion -headers $headers -ws1APIVersion 2

        ###Build string
        [hashtable] $stringBuild =@{}
        if ($orgGroupId) {$stringBuild.add("organizationGroupId",$organizationGroupId)}
        if ($organizationGroupUuid) {$stringBuild.add("organizationGroupUuid",$organizationGroupUuid)}
        if ($platform) {$stringBuild.add("platform",$platform)}
        if ($profileType) {$stringBuild.add("profileType",$profileType)}
        if ($status) {$stringBuild.add("status",$status)}
        if ($searchText) {$stringBuild.add("searchText",$searchText)}
        if ($orderBy) {$stringBuild.add("orderBy",$orderBy)}
        if ($sortOrder) {$stringBuild.add("sortOrder",$sortOrder)}
        if ($page) {$stringBuild.add("page",$page)}
        if ($pagesize) {$stringBuild.add("pagesize",$pagesize)}
        if ($includeAndroidForWork) {$stringBuild.add("includeAndroidForWork",$includeAndroidForWork)}
        if ($payloadName) {$stringBuild.add("payloadName",$payloadName)}
                
        $searchUri = "https://$($headers.ws1ApiUri)/api/mdm/profiles/search"
        $uri = New-HttpQueryString -Uri $searchUri -QueryParameter $stringBuild

        #debug
        switch ($PSBoundParameters['debug']) {
            ($PSCmdlet.MyInvocation.BoundParameters["debug"].IsPresent -eq $true) {
                $profileFind = Invoke-WebRequest -method GET -Uri $uri -Headers $headers
            }
            default {
                $profileFind = Invoke-RestMethod -method GET -Uri $uri -Headers $headers
            }
        }        
    return $profileFind
}

function get-ws1Profile {
     <#
        .SYNOPSIS
            The result will return a specific profile
        .DESCRIPTION
            https://cn1506.awmdm.com/api/help/#!/apis/10003?!/ProfilesV2/ProfilesV2_GetDeviceProfileDetailsAsync

            This API call does not have a valid version 1 API. This cmdlet defaults to v2

        .EXAMPLE
            get-ws1profile -profileId 1234 -headers $headers
       
    #>
    [CmdletBinding()]
    param (          
        [Parameter(Mandatory=$false)]
            [int]
            $profileId,
        [Parameter(Mandatory=$true)]
            [hashtable]
            $headers
    )
    
    switch ($PSBoundParameters['debug']) {
        ($PSCmdlet.MyInvocation.BoundParameters["debug"].IsPresent -eq $true) {
            $profileDetails = Invoke-WebRequest -method GET -Uri https://$($headers.ws1ApiUri)/api/mdm/profiles/$profileId -Headers $headers
        }
        default {
            $profileDetails = Invoke-RestMethod -method GET -Uri https://$($headers.ws1ApiUri)/api/mdm/profiles/$profileId -Headers $headers
        }
    }        
return $profileDetails
}
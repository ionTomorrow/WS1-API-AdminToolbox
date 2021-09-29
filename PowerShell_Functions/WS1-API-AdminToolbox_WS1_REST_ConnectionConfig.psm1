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
###  CONNECTION CMDLETS
###
###############################

###Creation of Headers for use with scripted API calls.
### 2019-07-31 - Updated for WS1 branding and include URL in header for convenience
Function New-ws1RestConnection {
     <#
        .SYNOPSIS
            (DEPRECATED CMDLET) New WS1 Connection -- This is only here for version continuity
        .DESCRIPTION
            (DEPRECATED CMDLET)        
    #>
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$apiUri,
        [Parameter(Mandatory=$true, Position=1)]
        [string]$apikey,
        [Parameter(Mandatory=$false, Position=2)]
        [switch]$certAuth
        )

        ###Need to add code to validate creds are entered & fail gracefully if not
        Do {
            $Credential = Get-Credential -Message "Please Enter U&P for account that has Workspace ONE API Access."
                    
            $EncodedUsernamePassword = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($('{0}:{1}' -f $Credential.UserName,$Credential.GetNetworkCredential().Password)))
        
            #Test the Headers build
            $headers = @{'Authorization' = "Basic $($EncodedUsernamePassword)";'aw-tenant-code' = "$APIKey";'Content-type' = 'application/json';'Accept' = 'application/json;version=1';'ws1ApiUri' = "$ApiUri";'ws1ApiAdmin' = "$($credential.username)"}
            write-host -ForegroundColor Cyan "Attempting connection to the following environment: "  $apiUri "||" $headers.'aw-tenant-code'

            ###Test for correct connection before returning a value. This can prevent useless API calls and prevent Directory-based auth account lockout.
            $testWs1Connection = test-ws1RestConnection -headers $headers
            
            if ($testWs1Connection  -ne "FAIL") {
            $testResults = ConvertFrom-Json $testWs1Connection.content
                Write-Host "Conntected to:"
                foreach ($api in $testResults.Resources.Workspaces) {
                    write-host -ForegroundColor Green "           $($api.location)"
                }
            }
            elseif ($testWs1Connection.statusCode -eq 1005) {
                write-host -ForegroundColor Yellow "     Invalid Credentials for environment. Please try again."
            }
            else {
                write-host -ForegroundColor Red "Connection Failed to $($headers.ws1ApiUri)"
            }

        } Until ($testWs1Connection.statusCode -eq 200)
        
    return $headers
}


####Updated Auth connection to include basic, cba, oauth


Function open-ws1RestConnection {
    <#
    .SYNOPSIS
        Opens the REST API connection to Workspace ONE
    .DESCRIPTION
        This cmdlet is responsible for creating the Headers that will be used with any API call to Workspace ONE
    .EXAMPLE
        $headers = open-ws1RestConnection -ws1ApiUri as123.awmdm.com -ws1ApiKey <aw-tenant-code> -authType basic
    .PARAMETER headers
        Output from select-ws1Config
    .PARAMETER password
        secureString
#>
    [CmdletBinding(DefaultParameterSetName = 'basic')]
    param (
        [Parameter(ParameterSetName = "basic")]
        [Parameter(ParameterSetName = "cert")]
        [Parameter(ParameterSetName = "oauth")]
        [Parameter(Mandatory=$true)]
            [uri]$ws1ApiUri,
        [Parameter(ParameterSetName = "basic", Mandatory=$true)]
        [Parameter(ParameterSetName = "cert", Mandatory=$true)]
            [string]$ws1ApiKey,
        [Parameter(Mandatory=$true)]
            [string]
            [ValidateSet("basic","cert","oauth")]
            $authType,
        [Parameter(ParameterSetName = "basic")]
            [string]
            $username,
        [Parameter(ParameterSetName = "basic")]
        [Parameter(ParameterSetName = "cert")]
            [secureString]
            $Password,
        [Parameter(ParameterSetName = "cert")]
            [System.IO.FileSystemInfo]
            $certFilename,
        [Parameter(ParameterSetName = "cert")]
            [securestring]
            $certPassword,
        [Parameter(ParameterSetName = "oauth", Mandatory=$true)]
            [string]
            $client_Id,
        [Parameter(ParameterSetName = "oauth", Mandatory=$true)]
            [securestring]
            $client_Secret,
        [Parameter(ParameterSetName = "oauth", Mandatory=$true)]
            [uri]
            $oauthAccessTokenUrl
    )

###Need to add code to validate creds are entered & fail gracefully if not
###Parameter set info: https://blog.simonw.se/powershell-functions-and-parameter-sets/

    ###Process ws1EnvUri to validate it is a good URI
    if ($ws1ApiUri.Scheme -ne "https") {
        [uri]$ws1ApiUri = "https://"+$ws1ApiUri
    }
    $ws1ApiUri = $ws1ApiUri.Host

    switch ($authType) {
        "basic" {
            ###Need to add code to validate creds are entered & fail gracefully if not
        
            if (!$username) {
                $Credential = Get-Credential -Message "Please Enter U&P for account that has Workspace ONE API Access."
                $EncodedUsernamePassword = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($('{0}:{1}' -f $Credential.UserName,$Credential.GetNetworkCredential().password)))
                $username = $Credential.UserName                   
            }
            else {
                $EncodedUsernamePassword = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($('{0}:{1}' -f $username,(ConvertFrom-SecureString -AsPlainText $Password))))                   
            }
        
            $headers = @{'Authorization' = "Basic $($EncodedUsernamePassword)";'aw-tenant-code' = "$ws1ApiKey";'Content-type' = 'application/json';'Accept' = 'application/json;version=1';'ws1ApiUri' = "$ws1ApiUri";'ws1ApiAdmin' = "$username"}
        }
        "cert" {
            <###Learned from https://dexterposh.blogspot.com/2015/01/powershell-rest-api-basic-cms-cmsurl.html
                This needs to be cleaned up to add error checking
            #>
            
            if (!$certFilename) {
                $certFilename = (get-childitem (read-host "What is the path to the cert you downloaded from WS1? (.p12 format)"))
                [secureString]$certPassword = read-host -AsSecureString "What is the password for the certificate? (will be entered as a SecureString)"
                Get-ChildItem $certFilename
            }
            $global:ws1Certificate = Get-PfxCertificate -FilePath $certFilename -Password $certPassword
        }
        "oauth" {
            ###Credit to Brooks Peppin for a good write-up https://www.brookspeppin.com/2021/07/24/rest-api-in-workspace-one-uem/           
            $oauthToken = $null
            
            $body = @{'grant_type' = "client_credentials";'client_id' = "$client_id";'client_secret' = (ConvertFrom-SecureString -AsPlainText $client_secret)}


            
            try {
                #write-host "Client_Secret" $body.client_secret
                #Write-Verbose "Client_ID" $body.client_Id
                #write-Verbose "grant_type" $body.grant_type

                #Write-Verbose "Connecting to $($oauthAccessTokenUrl)"
                $oauthToken = Invoke-RestMethod -Method POST -uri $oauthAccessTokenUrl.AbsoluteUri -Body $body
                
            }
            catch [Exception] {
                Write-Error "Unable to retrieve token from: $($oauthAccessTokenUrl)"
            }
            
            #[string]$oauthString = "{0} {1}" -f $oauthToken.token_type,$oauthToken.access_token
            [string]$oauthString = $oauthToken.token_type,$oauthToken.access_token -join " "
            
            
            $headers = @{'Authorization'=$oauthString;'Accept'='application/json;version=1';'ws1ApiUri'="$($ws1ApiUri)";'ws1ApiAdmin'="$($client_Id)";'oauthTokenExpiration'=((Get-date).AddSeconds(3600))}
        }
    }


    ###Run test-ws1Connection to provide feedback on authentication
    Write-Host "Attempting connection to the following environment: $($ws1ApiUri)"

    ###Test for correct connection before returning a value. This can prevent useless API calls and prevent Directory-based auth account lockout.
    $testWs1Connection = test-ws1RestConnection -headers $headers
    

        
    return $headers
}


function get-ws1SystemInfo {
    <#
    .SYNOPSIS
        Retrieves information about WS1 platform
    .DESCRIPTION
        https://cn1506.awmdm.com/api/help/#!/apis/10008?/Info    
    .PARAMETER headers
        Output from select-ws1Config
    #>
    [CmdletBinding()]
    param (
        [Hashtable]$headers
        )
    try {
        [uri]$uri = "https://$($headers.ws1ApiUri)/api/system/info"



        if ($PSBoundParameters['verbose']) {
            $ws1connection = Invoke-WebRequest -Uri $uri -Headers $headers
        }
        else {
            $ws1connection = Invoke-RestMethod -Uri $uri -Headers $headers
        }
    }
    catch [System.Net.WebException]
    {
        ###error
    }
    return $ws1connection
}


###Validate current connection is OK before continuing any script. This will prevent account lockout when entinering incorrect credentials
function test-ws1RestConnection {
    <#
    .SYNOPSIS
        Performs a test of the current WS1 Headers
    .DESCRIPTION
        Performs a test of the Headers by accessing the Info API

        https://cn1506.awmdm.com/api/help/#!/apis/10008?/Info    
    .PARAMETER headers
        Output from select-ws1Config
    #>
    param (
        [Hashtable]$headers
        )        
    Try {
        [string]$testStatus
        [string]$testMessage
        [int]$testCode
        $ws1connection = get-ws1SystemInfo -headers $headers -Verbose
        if ($ws1connection.statusCode -eq 200) {
            $testCode = $ws1connection.statusCode
            $testStatus = "success"
            $testMessage = "Connection Established at $($ws1connection.headers.Date). API Calls reamining $($ws1connection.headers.'X-RateLimit-Remaining')"
            $testCode = 200
            Write-Host "Conntected to:"
            $testResults = (ConvertFrom-Json $ws1connection)
            foreach ($api in $testResults.Resources.Workspaces) {
                write-host -ForegroundColor Green "          $($api.location)"
            }
        }               
                    
    }
    Catch  [System.Net.WebException] {
        if ($_.ErrorDetails) {
            $errorEvent = ConvertFrom-Json $_.ErrorDetails
        }
        else {
            $errorEvent = $_.Exception
        }        
        $testStatus = "FAIL"
        $testCode = $errorEvent.errorCode
        $testMessage = $errorEvent.message        
    }
    $testReturn = New-Object psobject @{"testStatus"=$testStatus;"testCode"=$testCode;"testMessage"=$testMessage}
    return $testReturn

}
            

function convertTo-ws1HeaderVersion {
    <#
        .SYNOPSIS
            Converts existing Headers from the select-ws1Config cmdlet to a specific API Version number
        .DESCRIPTION
            Some APIs have been enhanced over time and have different versions.
            Often these higher-level versions are a superior API and include functions and parameters not found in earlier versions.

            Do not use this function in isolation, it needs to be returned to a variable.

            Some cmdlets call this function independently if the higher-level API is significantly better.
            The default value of the select-ws1Config is Version 2. 
        .EXAMPLE
            $headers = convertTo-Ws1HeaderVersion -headers $headers -ws1APIVersion 2
        .PARAMETER headers
            Output from select-ws1Config
        .PARAMETER ws1ApiVersion
            The version of the API you are trying to call. 


    #>
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [hashtable]$headers,
        [Parameter(Mandatory=$true, Position=1)]
        [ValidateSet(1,2,3,4)][int]$ws1APIVersion
        )
    $headers.Remove("Accept")
    $headers.Remove("Version")
    switch ($ws1ApiVersion) {
        1 {$headers.Add("Accept","application/json;version=1")}
        2 {$headers.Add("Accept","application/json;version=2")}
        3 {$headers.Add("Accept","application/json;version=3")}
        4 {$headers.Add("Accept","application/json;version=4")}
        Default {$headers.Add("Accept","application/json;version=1")}
    }
    return $headers
}

<#
    TEST FUNCTIONS
#>
function test-ws1EventNotification {
    param (
        [Parameter(Mandatory=$true, Position=0)]
            [uri]$ws1EventListenerUri
    )

###Connect to API using Oauth
$headers = @{'Content-type' = 'application/json'}

$device= @{
    'EventId' = 12345;
    'DeviceId' = 1234;
    'EventType' = 'PowerShell Test';
    'EnrollmentUserId' = 123;    
    'DeviceFriendlyName' = 'PowerShell Test';
    'EventTime' = 'PowerShell Test';
    'EnrollmentStatus' = 'PowerShell Test';
    'CompromisedTimeStamp' = 'PowerShell Test';
    'Udid' = 'PowerShell Test';
    'SerialNumber' = 'PowerShell Test';
    'AssetNumber' = 'PowerShell Test';
    'EnrollmentEmailAddress' = 'PowerShell Test';
    'EnrollmentUserName' = 'PowerShell Test';
    'CompromisedStatus' = 'PowerShell Test';
    'ComplianceStatus' = 'PowerShell Test';
    'PhoneNumber' = 'PowerShell Test';
    'MACAddress' = 'PowerShell Test';
    'DeviceIMEI' = 'PowerShell Test';
    'Platform' = 'PowerShell Test';
    'OperatingSystem' = 'PowerShell Test';
    'Ownership' = 'PowerShell Test';
    'SIMMCC' = 'PowerShell Test';
    'CurrentMCC' = 'PowerShell Test';
    'OrganizationGroupName' = 'PowerShell Test';
}

$body = @{}
$body = $device
$eventTest = Invoke-WebRequest -Method Post -Uri $ws1EventListenerUri -body (convertto-json $body) -headers $headers

return $eventTest
}


function convertTo-ws1CertAuth {
    <#
     .SYNOPSIS
            Converts existing Headers from the select-ws1Config cmdlet to use the CMSURL certificate-based authentication scheme
        .DESCRIPTION
            Certificate-based authentication (CBA) is superior to basic authentication in several ways.
            * More secure
            * Doesn't expose password in 'Authorization' header
            * WS1 admin passwords on Basic accounts expire within 60-90 days
            
            The use of CBA in Workspace ONE will require each cmdlet to individually convert the headers to use CMSURl. This is due to the URI itself being part of the header.
            This function will be called within any other function that is flagged as using CBA.

            Thank you to Dexter Posh for documenting this capability:
            https://dexterposh.blogspot.com/2015/01/powershell-rest-api-basic-cms-cmsurl.html
        .EXAMPLE
            $headers = convertTo-ws1CertAuth -headers $headers -Certificate <object> -uri <uri>
        .PARAMETER headers
            Output from select-ws1Config
        .PARAMETER Certificate
            A certificate of type [System.Security.Cryptography.X509Certificates.X509Certificate]
            This can be obtained using the open-ws1RestConnection cmdlet and specifying -authType Cert
        .PARAMETER uri
            This is the URL of the API call that needs to be made. The .AbsolutePath property of the URI is included in the header generation
    
    #>

    param (          
        [Parameter(Mandatory=$true)]
            [System.Security.Cryptography.X509Certificates.X509Certificate]$Certificate,
        [Parameter(Mandatory=$true)]
            [uri]$uri,
        [Parameter(Mandatory=$true)]
            [hashtable]
            $headers
    )

    #Open Memory Stream passing the encoded bytes
    $memstream = New-Object -TypeName System.Security.Cryptography.Pkcs.ContentInfo -ArgumentList (,$bytes) -ErrorAction Stop
    $bytes = [System.Text.Encoding]::UTF8.GetBytes(($uri.absolutePath))

    #Create the Signed CMS Object providing the ContentInfo (from Above) and True specifying that this is for a detached signature
    $SignedCMS = New-Object -TypeName System.Security.Cryptography.Pkcs.SignedCms -ArgumentList $MemStream,$true -ErrorAction Stop

    #Create an instance of the CMSigner class - this class object provide signing functionality
    $CMSigner = New-Object -TypeName System.Security.Cryptography.Pkcs.CmsSigner -ArgumentList $Certificate -Property @{IncludeOption = [System.Security.Cryptography.X509Certificates.X509IncludeOption]::EndCertOnly} -ErrorAction Stop

    #Add the current time as one of the signing attribute
    $null = $CMSigner.SignedAttributes.Add((New-Object -TypeName System.Security.Cryptography.Pkcs.Pkcs9SigningTime))

    #Compute the Signatur
    $SignedCMS.ComputeSignature($CMSigner)

    #As per the documentation the authorization header needs to be in the format 'CMSURL `1 <Signed Content>'
    #One can change this value as per the format the Vendor's REST API documentation wants.
    $CMSHeader = '{0}{1}{2}' -f 'CMSURL','`1 ',$([System.Convert]::ToBase64String(($SignedCMS.Encode())))

    $headers.Remove('Authorization')
    $headers.add('Authorization',$CMSHeader)

    return $headers

}
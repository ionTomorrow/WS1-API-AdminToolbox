###Consider it best practice to create an API Key for every account that needs API access. Easier to manage access that way.

###Should use a script right here

### Add-AwRestConfig will capture API settings and add them to a .csv file. If this .csv exists it will append these settings.

###############################
###
###  CONNECTION CMDLETS
###
###############################


Function New-AwRestConnection { 
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$apiUri,
        [Parameter(Mandatory=$true, Position=1)]
        [string]$apikey
        )

        ###Need to add code to validate creds are entered & fail gracefully if not
        Do {
        $Credential = Get-Credential -Message "Please Enter U&P for account that has AirWatch API Access."
        }
        Until ($Credential -ne $nul)
        $EncodedUsernamePassword = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($('{0}:{1}' -f $Credential.UserName,$Credential.GetNetworkCredential().Password)))
        
        New-Variable -Name headers -option AllScope
        $headers = @{'Authorization' = "Basic $($EncodedUsernamePassword)";'aw-tenant-code' = "$APIKey";'Content-type' = 'application/json';'Accept' = 'application/json';'version' = '2'}

        write-host -ForegroundColor Cyan "Connecting to the following environment: "  $apiUri "||" $headers.'aw-tenant-code'
    return $headers
}

###Creation of Headers for use with scripted API calls.
### 2019-07-31 - Updated for WS1 branding and include URL in header for convenience
Function New-ws1RestConnection { 
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
            $headers = @{'Authorization' = "Basic $($EncodedUsernamePassword)";'aw-tenant-code' = "$APIKey";'Content-type' = 'application/json';'Accept' = 'application/json';'version' = '2';'ws1ApiUri' = "$ApiUri";'ws1ApiAdmin' = "$($credential.username)"}
            write-host -ForegroundColor Cyan "Attempting connection to the following environment: "  $apiUri "||" $headers.'aw-tenant-code'

            ###Test for correct connection before returning a value. This can prevent useless API calls and prevent Directory-based auth account lockout.
            $testWs1Connection = test-ws1RestConnection -headers $headers
            

            if ($testWs1Connection  -ne "FAIL") {
            $testResults = ConvertFrom-Json $testWs1Connection.content
                Write-Host "Conntected to:"
                foreach ($api in $testResults.Resources.Workspaces) {
                    write-host -ForegroundColor Green "          " $api.location
                }
            }
            elseif ($testWs1Connection.statusCode -eq 1005) {
                write-host -ForegroundColor Yellow "     Invalid Credentials for environment. Please try again."
            }
            else {
                write-host -ForegroundColor Red "Connection Failed to $headers.ws1ApiUri"
            }

        } Until ($testWs1Connection.statusCode -eq 200)
        
    return $headers
}

###Validate current connection is OK before continuing any script. This will prevent account lockout when entinering incorrect credentials
function test-ws1RestConnection {
    param (
        [Hashtable]$headers
        )
        $apiUri = $headers.ws1ApiUri
    Try {
        $ws1connection = Invoke-WebRequest -Uri https://$apiUri/api/system/info -Headers $headers
    }
    Catch  [System.Net.WebException] {
        if ($_.ErrorDetails) {
            $errorEvent = ConvertFrom-Json $_.ErrorDetails
        }
        else {
            $errorEvent = $_.Exception
        }
        if ($ws1connection.statusCode -eq "200") {
            ###Connection is OK
            
        }
        elseif  ($errorEvent.errorCode -eq "1005") {

            write-host -ForegroundColor Red "'Error Validating Credentials. Please enter credentials again. Script will fail to prevent lockout after 3 tries"
            $ws1connection = $errorEvent.errorCode
        }
        else {
            $ws1connection = "FAIL"
        }
    }
    return $ws1connection

}
            







<#
###Selection Menu - Further instructions found at : https://4sysops.com/archives/if-else-switch-conditional-statements-in-powershell/
#>

function select-WS1Config {
   
    Do {
        Write-host "     [1] - Use existing WS1Settings file"
        Write-Host "     [2] - Create temporary session headers and do not save API key to this computer"
        write-host "     [3] - Create new WS1Config File"
        Write-Host "     [4] - Add new Environment to existing WS1settings file"
        Write-Host "     [5] - Import Existing file from old install"
        Write-Host "     [6] - EXIT"
    
        switch ([int]$menuChoice = Read-host -Prompt "Select an option to start") {
            1 {
                $ws1RestConnection = get-ws1SettingsFile
            }
            2 {
                $ws1ApiUri = read-host -Prompt "What is the API uri (example asXXX.awmdm.com?)"
                $ws1ApiKey = Read-Host -Prompt "What is the API key?"
                New-ws1RestConnection -apiUri $ws1ApiUri -apikey $ws1ApiKey
            }
            3 {
                Update-ws1EnvConfigFile
            }
            4 {
                Update-ws1EnvConfigFile
            }
            5 {
                Update-ws1EnvConfigFile
            }
            6 {
                ###Must Exit entirety of Powershell, not just this switch or function. This will also exist the PowerShell ISE.
                [Environment]::Exit(1)
            }
        }
    }
    until ($ws1RestConnection -ne $null)
    return $ws1RestConnection
}

###############################
###
###  CONFIG FILE MANGAGEMENT CMDLETS
###
###############################

###Retrieve contents of Settings file
function get-ws1SettingsFile {

    ###Check valid file. If file is OK display contents. If no file is found or no selection is made loop
    Do {
        $ws1ConfigValid = test-ws1EnvConfigFile -configPath config\ws1EnvConfig.csv
        if ($ws1ConfigValid -eq $true) {
            $ws1settings = import-csv "config\ws1EnvConfig.csv"
                Do {
                    Write-Host -ForegroundColor Yellow "     Currently detected WS1 Environments"    
                    foreach ($ws1Env in $WS1Settings) {
                        write-host -ForegroundColor Cyan $ws1Env.ws1EnvNumber "-" $ws1Env.ws1EnvName "-" $ws1env.ws1EnvUri
                    }
                    [int]$menuChoice = read-host "Choose your environment by picking its number."
                }
                until ($menuChoice -le $ws1Settings.Count)
                $choice = $WS1Settings | where-object {$_.ws1EnvNumber -eq $menuChoice}

                $ws1RestConnection = New-ws1RestConnection -apiUri $choice.ws1EnvUri -apikey $choice.ws1EnvApi
                Return $ws1RestConnection
        }
        else {
            Update-ws1EnvConfigFile
        }
    }
    Until ($ws1RestConnection -ne $null)
 
      
}


###Validates a config file as functional. Returns $true or $false
function test-ws1EnvConfigFile {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$configPath
    )
        ###Check to make sure file exists. Without this it's an ugly error.
        if (test-path $configPath) {
                
            ###Check to make sure it's a .csv
                if ((Get-Item $configPath).Extension -eq ".csv") {
                    $fileCheck = import-csv $configPath
                        ###Check .csv file and make sure it has correct headers
                            if ($filecheck[0].psobject.Properties.name -notcontains 'ws1EnvApi') {
                                Write-Host -ForegroundColor Red "Correct Columns not found in file. Please try a different config file!"
                            }
                            elseif ($filecheck[0].psobject.Properties.name -notcontains 'ws1EnvUri') {
                                Write-Host -ForegroundColor Red "Correct Columns not found in file. Please try a different config file!"
                            }
                            elseif ($filecheck[0].psobject.Properties.name -notcontains 'ws1EnvNumber') {
                                Write-Host -ForegroundColor Red "Correct Columns not found in file. Please try a different config file!"
                            }
                            elseif ($filecheck[0].psobject.Properties.name -notcontains 'ws1EnvName') {
                                Write-Host -ForegroundColor Red "Correct Columns not found in file. Please try a different config file!"
                            }
                            else {
                                ###Returns $true if last operation succeeds
                                $?
                            }
                        }
                    else {
                            write-host -ForegroundColor Yellow "Config file must be a .csv filetype. Please try again"
                    }
               }
               else {
                   write-host -ForegroundColor Yellow "Config file not found using filename. Please try again"
               }
}


function import-ws1EnvConfigFile {
    $ws1EnvConfig = $null
    Do {
        $configPath = read-host -Prompt "Please type the FULL path to the existing config file including the .csv file extension (example: h:\start-dDaaS\config\ws1EnvConfig.csv)"
        $ws1ConfigValid = test-ws1EnvConfigFile -configPath $configPath
    
        if ($ws1ConfigValid = $true) {
            Copy-Item $configPath config\ws1EnvConfig.csv -Force
            $Ws1EnvConfig = Get-Item config\ws1EnvConfig.csv
        }

    }
    until ($ws1EnvConfig -ne $null)
}
    

Function Add-ws1RestConfig {
param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$ws1EnvName,
        [Parameter(Mandatory=$true, Position=1)]
        [string]$ws1EnvUri,
        [Parameter(Mandatory=$true, Position=2)]
        [string]$ws1EnvApi
        )
        $ws1Env = @(
        [pscustomobject]@{
            ws1EnvName = $ws1EnvName
            ws1EnvApi = $ws1EnvApi
            ws1EnvUri = $ws1EnvUri
            }
        )
    return $ws1Env
}


function Update-ws1EnvConfigFile {

    ###Menu just for updating the file
    function show-ws1EnvConfigFileMenu {
        Do {
            write-host -ForegroundColor Cyan "1 - Create new file or update existing Config file"
            write-host -ForegroundColor Cyan "2 - Locate and import existing Config file"
            write-host -ForegroundColor DarkCyan "3 - Quit"
            [int]$choice = Read-Host -Prompt "Do you want to locate an existing ws1EnvConfig.csv file or create a new one?"
        }
        until ($choice -le 3)
        return $choice
    }


    Do {
        ###Prompt to create new file or locate existing one

        
        $choice = show-ws1EnvConfigFileMenu
        switch ($choice) {
            ###Create New File and then return as an object.
            1 {
                write-host -ForegroundColor Yellow "Creating Workspace ONE config file under \config folder. Please answer the following questions:"
                $ws1EnvName = read-host -prompt "Please type an easy-to remember name for the environment (UAT,PROD,etc.)"
                $ws1EnvApi = read-host -Prompt "Please type or paste your API KEY"
                $ws1EnvUri = read-host -Prompt "Please input the URL you are connecting to (example: xx123.awmdm.com)"
                $ws1EnvConfigFile = "config\ws1EnvConfig.csv"
                $i=0
                if (Test-Path $ws1EnvConfigFile) {
                    write-host "Appending new environment to existing settings config"
                    $i = (import-csv $ws1EnvConfigFile).count
                }
                else {
                    $WS1Example = New-Object psobject -Property @{ws1EnvNumber=$i;ws1EnvName="ExampleEnvironment";ws1EnvApi="ExampleAPI";ws1EnvUri="ExampleURI"}
                    $WS1Example | Export-Csv -Path $WS1EnvConfigFile -NoTypeInformation -Append
                    $i++
                }
                
                $WS1Env = New-Object psobject -Property @{ws1EnvNumber=$i;ws1EnvName=$ws1EnvName;ws1EnvApi=$ws1EnvApi;ws1EnvUri=$ws1EnvUri}
                $WS1Env | Export-Csv -Path $WS1EnvConfigFile -NoTypeInformation -append
                $ws1EnvConfig = "config\ws1EnvConfig.csv"
                
            }
            ###Locate Existing File
            2 {
                import-ws1EnvConfigFile
                $ws1EnvConfig = "config\ws1EnvConfig.csv"
            }
            3 {
                write-host "exiting"
            }
        }
    }
    until ($ws1EnvConfig -ne $null)

}





function convertTo-ws1HeaderVersion {
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [hashtable]$headers,
        [Parameter(Mandatory=$true, Position=1)]
        [ValidateSet(1,2)][int]$ws1APIVersion
        )

        $headers.Remove("Accept")
        $headers.Remove("Version")
    if ($ws1ApiVersion -eq 1) {
        $headers.Add("Accept","application/json;version=1")
    }
    elseif ($ws1ApiVersion -eq 2) {
        $headers.Add("Accept","application/json;version=2")
    }
    return $headers
}
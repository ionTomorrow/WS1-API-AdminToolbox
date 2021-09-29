###############################
###
###  CONFIG FILE MANGAGEMENT CMDLETS
###
###############################

function select-WS1Config {
    <#
     .SYNOPSIS
         Interactive menu to create required headers
     .DESCRIPTION
         Performs a test of the Headers by accessing the Info API
 
         https://cn1506.awmdm.com/api/help/#!/apis/10008?/Info    
     .PARAMETER headers
         Output from select-ws1Config
     #>
 
     Do {
         Write-host "     [1] - Use existing WS1Settings file"
         Write-Host "     [2] - Create temporary BASIC session headers and do not save API information to this computer"
         write-host "     [3] - Create new WS1Config File"
         Write-Host "     [4] - Add new Environment to existing WS1settings file"
         Write-Host "     [5] - Import Existing file from old install"
         Write-Host "     [6] - Exit to PowerShell prompt"
         Write-Host "     [7] - EXIT PowerShell session completely"
         
         do {
            [hashtable]$ws1RestConnection = @{}
             switch ([int][ValidateSet(1,2,3,4,5,6,7)]$menuChoice = Read-host -Prompt "Select an option to start") {
                 1 {
                     ###Finds and retrieves existing file. Will display menu to pick an environment from the file.
                     ###IF a file is not found, it will walk through creating new file.
                     $ws1Env = get-ws1SettingsFile
                     $ws1RestConnection = open-ws1RestConnection -ws1ApiUri $ws1Env.ws1EnvUri -ws1Apikey $ws1Env.ws1EnvApi -authType $ws1Env.authType                
                 }
                 2 {
                     ###Obtain basic information to start an API session. 
                     ###Not including -username will force cmdlet to prompt for U&P
                     [uri]$ws1ApiUri = read-host -Prompt "What is the full API URL (example https://asXXX.awmdm.com)"
                     [string]$ws1ApiKey = Read-Host -Prompt "What is the API key?"
                     $ws1RestConnection = open-ws1RestConnection -ws1ApiUri $ws1ApiUri -ws1Apikey $ws1ApiKey -authType basic
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
                     #do nothing to end function
 
                 }
                 7 {
                     ###Must Exit entirety of Powershell, not just this switch or function. This will also exist the PowerShell ISE.
                     [Environment]::Exit(1)
                 }
             }             
         } until ($menuChoice)
     }
     until ($null -ne $ws1RestConnection)
     return $ws1RestConnection
 }

 
function get-ws1SettingsFile {

    ###Check valid file. If file is OK display contents. If no file is found or no selection is made loop
    Do {
        $ws1ConfigValid = test-ws1EnvConfigFile -configPath config\ws1EnvConfig.csv
        if ($ws1ConfigValid -eq $true) {
            $ws1settings = import-csv "config\ws1EnvConfig.csv"
                Do {
                    Write-Host -ForegroundColor Yellow "     Currently detected WS1 Environments"    
                    foreach ($ws1Env in $WS1Settings) {
                        write-host -ForegroundColor Cyan "$($ws1Env.ws1EnvNumber) | $($ws1Env.ws1EnvName) | $($ws1env.ws1EnvUri) | $($ws1env.authType)"
                    }
                    [int]$menuChoice = read-host "Choose your environment by picking its number."
                }
                until ($menuChoice -le $ws1Settings.Count)
                #$choice = $WS1Settings | where-object {$_.ws1EnvNumber -eq $menuChoice}
                $ws1Env = $ws1settings[$menuChoice]

                ###Must check quality of input file. If someone manually edited the file it would cause downstream issues:
                #Check validity of all columns

                ###Parse the $ws1EnvUri and make sure it is a URL. This will take the string found in the .csv and convert it to a correct URL, and then pull out the .Host parameter to pass along as output
                if ($ws1Env.ws1EnvUri.SubString(0,7) -ne "https://") {
                    $ws1Env.ws1EnvUri = "https://"+$ws1Env.ws1EnvUri
                }
        }
        else {
            Update-ws1EnvConfigFile
        }
    }
    Until ($null -ne $ws1Env)
    Return $ws1Env
      
}

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
            elseif ($filecheck[0].psobject.Properties.name -notcontains 'authType') {
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
        [string]$ws1EnvApi,
        [Parameter(Mandatory=$true, Position=3)]
            [ValidateSet("basic","cert","oauth")]
            $ws1AuthType
        )
        $ws1Env = @(
        [pscustomobject]@{
            ws1EnvName = $ws1EnvName
            ws1EnvApi = $ws1EnvApi
            ws1EnvUri = $ws1EnvUri
            ws1AuthType = $ws1AuthType
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
                [string]$ws1EnvName = read-host -prompt "Please type an easy-to remember name for the environment (UAT,PROD,etc.)"
                [string]$ws1EnvApi = read-host -Prompt "Please type or paste your API KEY"
                do {
                    [uri]$ws1EnvUri = read-host -Prompt "Please input the URL you are connecting to (example: https://asXXX.awmdm.com)"
                    if ($nul -eq $ws1EnvUri.host) {Write-Error "You must include the https:// scheme with your URL!"}
                }
                Until ($nul -ne $ws1EnvUri.host)
                [string][ValidateSet("basic","cert","oauth")]$authType = read-host -Prompt "What authentication type will you use? (basic, cert, oauth)"
                $ws1EnvConfigFile = "config\ws1EnvConfig.csv"
                
                $i=0
                if (Test-Path $ws1EnvConfigFile) {
                    write-host "Appending new environment to existing settings config"
                    $i = (import-csv $ws1EnvConfigFile).count
                }
                else {
                    $WS1Example = New-Object psobject -Property @{ws1EnvNumber=$i;ws1EnvName="ExampleEnvironment";ws1EnvApi="ExampleAPI";ws1EnvUri="ExampleURI";authType="authentication type"}
                    New-Item -Path "config"-Name "ws1EnvConfig.csv" -ItemType File
                    $WS1Example | Export-Csv -Path $WS1EnvConfigFile -NoTypeInformation -Append
                    $i++
                }
                
                $WS1Env = New-Object psobject -Property @{ws1EnvNumber=$i;ws1EnvName=$ws1EnvName;ws1EnvApi=$ws1EnvApi;ws1EnvUri=$ws1EnvUri;authType=$authType}
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
    until ($null -ne $ws1EnvConfig)

}




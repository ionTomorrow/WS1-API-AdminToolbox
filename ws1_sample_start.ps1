<#
    Clear Powershell $error Logging. This is most useful for debugging purposes as only the errors from the previous script will show up.
        Of course you must press ctrl+c to exit before they are cleared.

        This entire thing be discarded. It would be much cleaner to have a start-ws1ToolBox cmdlet, that imports the modules and automatically launches the select-ws1config cmdlet
#>
$error.clear()
###Clear the Screen
clear-host

$ws1Functions = "PowerShell_Functions"
$ws1Modules = Get-ChildItem -file -Name *.psm1 $ws1Functions -Recurse
foreach ($ws1Module in $ws1Modules) {
    $ws1Import = "{0}\{1}\{2}" -f $PSScriptRoot,$ws1Functions,$ws1Module
    Import-Module $ws1Import -Force
    write-host "Importing 3rd-party Tools module: " $ws1Module
    
}

###Setting up folder structure
get-ws1Folders


###Set TLS version
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12


write-host -ForegroundColor Cyan "use the command select-ws1config to get started!"
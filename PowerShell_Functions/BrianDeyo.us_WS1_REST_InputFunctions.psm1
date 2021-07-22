Function Import-WS1Csv {
    <#.SYNOPSIS
    Imports a .csv and obtains specific characteristics of the .csv useable for WS1 scripts and functions
    .DESCRIPTION
    Imports a .csv and identifies the column of the .csv that includes the unique identifier for each row.
    The .csv can be specified using the inputCsv parameter. If that parameter is left blank the function will prompt for a filename.
    Optionally a filehash can be produced for comparison against an existed .csv.

    CHANGELOG
    2020-07-09 - modified header retrieval to strip off quote marks ".
    2020-09-22 - Added the inputCsv option as a way to automate ingestion of a file and suppress prompting for the filename on the first attempt
                    This should really be changed to remove the defaultFilename parameter completely, or at least switch it to false. 
                        It has been left primarily for backwards compatibility with existing scripts.

    
    .EXAMPLE
    import-ws1Csv -defaultFileName "Device Inventory" -getFileHash $true -uniqueHeader "Serial Number" -inputCsv input.csv
    .PARAMETER defaultFileName
    .PARAMETER getFileHash
    .PARAMETER uniqueHeader
    .PARAMETER inputCsv
    #>
    param(
        [Parameter(Mandatory=$true,Position=0)][string]$defaultFilename,
        [Parameter(Mandatory=$false,Position=1)][bool]$GetFileHash,
        [Parameter(Mandatory=$false,Position=2)][string]$uniqueHeader,
        [Parameter(Mandatory=$false,Position=3)][string]$inputCsv
    )

    <#Retrieve CSV from input directory #>
    $inputPath = ((get-location).path)+"\input\"
    if ((test-path $inputPath) -eq $false) {
        $errorMsg = "[ERROR] $inputPath is an invalid location!"
        ###This should probably prompt for someone to actually type in the correct path...
        return $errorMsg
        exit
    }

    $inputList = @()
    
      
    
    Do {
    
    
        Try {
            do {
                if (!$inputCsv) {
                    $inputCsv = Read-Host -Prompt "Please input name of the csv (with or without .csv extension). Press enter to use default file name ($defaultFilename)"
                    if (!$inputCsv) {
                        $inputCsv = $defaultFilename
                    }
                }
            }
            until ($inputCsv)
            
            ###Pull last four characters of input file name. This will allow people to include or exclude the .csv file extension
            ###Included from examples at https://ss64.com/ps/right.html
            $startchar = [math]::min($inputCsv.length - 4,$inputCsv.length)
            $startchar = [math]::max(0, $startchar)
            $length = [math]::min($inputCsv.length, 4)
            if ($inputCsv.SubString($startchar ,$length) -ne ".csv") {
                $inputCsv=$inputCsv+".csv"
            }

            $verifyCsv = get-item -path ($inputpath+$inputCsv)

            ###Retreieve hash
            if ($GetFileHash) {
                $hashCsv = ($verifyCsv | Get-FileHash -Algorithm SHA256).hash
            }
            else {
                [string]$hashCsv = "fileHashNotGenerated"
            }
            [System.Collections.ArrayList]$headerRow = @()

            ###obtain header row for .csv and remove extra Quotes that are put in during import.
            [System.Collections.ArrayList]$headerRow = (Get-Content $verifyCsv | Select-Object -First 1).Split(",")
            
            ###Remove Double Quote marks from inputCsv if it comes with them.
            if ($headerRow.count -gt 1) {
                $headerRow = $headerRow | ForEach-Object {$_.trim('"')}
            }
            else {
                ###Still not solved... this is still importing the single row as a string
                ###but got lucky since header had no quotes
                $headerRow.trim('"')
            }
            
            
            ###Validate that the Unique Identifier presented in the function call or found in the input is valid
            Do {
                
                ###On first run check if uniqueHeader parameter was passed in function call. If not parse header for possible options to choose from
                if (!$uniqueHeader) {

                    if (!$validHeader) {
                        $i=0
                        for ($i=0;$i -lt $headerRow.count;$i++) {
                            write-host "[$i] - $($headerRow[$i])"
                            
        
                        }
                    }
                    [int]$uniqueColumn = Read-Host -Prompt "Type Number of the Unique Identifier for the input file or push enter to repreat the list of imported headers."
                    [string]$uniqueHeader = $headerRow[$uniqueColumn]
                    
                }
                else {
                    $uniqueHeader = $uniqueHeader -replace '["]',''
                }
                
                if ($headerRow -contains $uniqueHeader){
                    [bool]$validHeader = $true
                }
                else {
                    write-host -ForegroundColor Yellow "    WARNING: Unique Header not found with specified value. Please try again!"
                    remove-variable uniqueHeader
                    
                }
                
            }
            Until ($validHeader)

            $inputList = import-csv $verifyCsv
            if ($inputList) {
                $validCsv = $true
            }


        }
        Catch {
            write-host -ForegroundColor Red "[ERROR] Unable to Import filename $($inputCsv). Please try again"
            $validCsv = $false
            remove-variable inputCsv
        }
    }
    Until ($validCsv)

    ###return imported CSV as an object, uniqueHeader and the filehash if requested by script.
    ###Multiple values can be retrieved by accessing results like an array - https://social.technet.microsoft.com/Forums/ie/en-US/65d3bf7f-c710-498a-b535-46c64cbf92e7/return-multiple-values-in-powershell?forum=ITCG
    $uniqueHeader = $uniqueHeader -replace '["]',''
    $importCsvReturn = New-Object psobject @{importList=$inputList;hash=$hashCsv;uniqueHeader=$uniqueHeader;inputFileName=$($verifyCsv.basename)}
    #$importCsvReturn.add($inputList)
    #$importCsvReturn.add($hashCsv)
    #$importCsvReturn.Add($uniqueHeader)
    #Return $inputList, $hashCsv, $uniqueHeader
    Return $importCsvReturn

}

function get-threadCount {
    <#
    .SYNOPSIS
    Retrieve maximum number of threads based off logicalCPU count of the host machine.
    
    .DESCRIPTION
    Retrieve maximum number of threads based off logicalCPU count of the host machine.
    
    .EXAMPLE
    $example = get-threadCount
    
    .NOTES
    Should detect whether underlying platform is macOS, Linux, or Windows and return appropriately.
    #>

    ###Check if Windows. This should probably be reversed since *most* people will run PowerShell Scripts on Windows
    if ($PSVersionTable.Platform -eq "Win32NT") {
        $psVer = ($PSVersionTable.PSVersion).Major
        if ($psVer -gt 5) {
            [int]$threads = ((Get-CimInstance -ClassName Win32_Processor).NumberOfLogicalProcessors -2)
        }
        else {
            [int]$threads = ((Get-WmiObject -Class Win32_processor).NumberOfLogicalProcessors -2)
        }
    }
    else {
        $logicalCpuCount = sysctl hw.logicalcpu
        $cpuLine = $null
        $cpuLine = $logicalCpuCount.Split(": ")
        [int]$cpuCount = $cpuLine[1]
        [int]$threads = ($cpuCount -2)
    }

    ###Return a minimum of 1 for total threads
    if ($threads -le 1) {
        $threads = 1
    }
    return $threads
}


<###############################
###
###  LOGGING FUNCTIONS
###
###############################>

Function get-timestamp() {
    <#
    .SYNOPSIS
    Create a consistent timestamp format for any logs or folders created from the WS1 scripts
    
    .DESCRIPTION
    Create a consistent timestamp format for any logs or folders created from the WS1 scripts
    
    .EXAMPLE
    $example = get-timestamp
    
    .NOTES
    This probably isn't necessary if you are not logging output from your scripts.

    #>
    $WS1LogTime = Get-Date -Format yyyyMMdd.HH.mm.ss
    return $WS1LogTime
}



###Logging Format Setup
###
### Took hints from https://stackoverflow.com/questions/31982926/new-item-changes-function-return-value to use the | Out-NULL to remove extra paths with New-Item

Function get-ws1LogFolder {
    <#
    .SYNOPSIS
    Create a hierarchy of folders used to stored output
    
    .DESCRIPTION
    It's a common practice to store the log data associated with running scripts against WS1 API. 
    After a few dozen script runs it becomes very tedious to parse log files. Having pre-built nested folders for logging can reduce this problem.
    
    .EXAMPLE
    $example = get-ws1LogFolder
    $output_from_other_script | export-csv -path $example -noTypeInformation -append
    
    .NOTES
    This probably isn't necessary if you are not logging output from your scripts.

    #>
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$ws1EnvUri
        )
    $logYear = Get-Date -Format yyyy
    $logMonth = Get-Date -Format MM
    $logDate = Get-Date -Format dd

    
    If ((Test-Path -path output\$logYear) -eq $false) {
        New-Item -Path output\$logYear -ItemType Directory | Out-Null
    }
    If ((Test-Path -Path output\$logYear\$logMonth) -eq $false) {
        New-Item -Path output\$logYear\$logMonth -ItemType Directory | Out-Null
    }
    If ((Test-Path -Path output\$logYear\$logMonth\$logDate) -eq $false) {
        New-Item -Path output\$logYear\$logMonth\$logDate -ItemType Directory | Out-Null
    }
    If ((Test-Path -Path output\$logYear\$logMonth\$logDate\$ws1EnvUri) -eq $false) {
        New-Item -Path output\$logYear\$logMonth\$logDate\$ws1EnvUri -ItemType Directory | Out-Null
    }
    
    $ws1LogPath = (Get-Item output\$logYear\$logMonth\$logDate\$ws1EnvUri).FullName
    return  $ws1LogPath;
}



Function get-ws1InputArchive {
    
    $currentUser = [Environment]::UserName
    $logYear = Get-Date -Format yyyy
    $logMonth = Get-Date -Format MM
    $logDate = Get-Date -Format dd

    $inputPath = ((get-location).path)+"\input"
    $archivePath = ((get-location).path)+"\input\archive"

    if (!(Test-path -path ($inputPath+"\archive"))) {
        New-Item -path ($inputPath+"\archive") -ItemType Directory | Out-Null
    }

    If ((Test-Path -path $archivePath\$logYear) -eq $false) {
        New-Item -Path $archivePath\$logYear -ItemType Directory | Out-Null
    }
    If ((Test-Path -Path $archivePath\$logYear\$logMonth) -eq $false) {
        New-Item -Path $archivePath\$logYear\$logMonth -ItemType Directory | Out-Null
    }
    If ((Test-Path -Path $archivePath\$logYear\$logMonth\$logDate) -eq $false) {
        New-Item -Path $archivePath\$logYear\$logMonth\$logDate -ItemType Directory | Out-Null
    }
    If ((Test-Path -Path $archivePath\$logYear\$logMonth\$logDate\$ws1EnvUri) -eq $false) {
        New-Item -Path $archivePath\$logYear\$logMonth\$logDate\$ws1EnvUri -ItemType Directory | Out-Null
    }
    <#If (!(Test-path -path $archivePath\$logYear\$logMonth\$logDate\$currentUser)) {
        New-Item -Path $archivePath\$logYear\$logMonth\$logDate\$currentUser -ItemType Directory | Out-Null
    }
    #>
    
    $ws1InputArchive = (Get-Item $archivePath\$logYear\$logMonth\$logDate).FullName
    return  $ws1InputArchive;
}

Function new-ws1InputArchive {
    param(
        [Parameter(Mandatory=$true,Position=0)][string]$logYear,
        [Parameter(Mandatory=$true,Position=1)][string]$logMonth,
        [Parameter(Mandatory=$true,Position=2)][string]$logDate
    )
    
    $inputPath = "{0}\input" -f ((get-location).path)
    $archivePath = "{0}\input\archive" -f ((get-location).path)

    if (!(Test-path -path ($archivePath))) {
        New-Item -path ($archivePath) -ItemType Directory | Out-Null
    }
    If ((Test-Path -path $archivePath\$logYear) -eq $false) {
        New-Item -Path $archivePath\$logYear -ItemType Directory | Out-Null
    }
    If ((Test-Path -Path $archivePath\$logYear\$logMonth) -eq $false) {
        New-Item -Path $archivePath\$logYear\$logMonth -ItemType Directory | Out-Null
    }
    If ((Test-Path -Path $archivePath\$logYear\$logMonth\$logDate) -eq $false) {
        New-Item -Path $archivePath\$logYear\$logMonth\$logDate -ItemType Directory | Out-Null
    }
    [string]$archivePath = "{0}\{1}\{2}\{3}" -f $archivePath,$logYear,$logMonth,$logDate
    return $archivePath
}

<###############################
###
###  PS DRIVE FUNCTIONS
###
###############################>



###Create necessary subfolders if they don't already exist.
function get-ws1Folders {
$folders = @("config","input","output")
foreach ($folder in $folders) {
    If (Test-Path .\$folder) {
    }
    else {
        New-Item -ItemType Directory $folder
    }
}
}


###Query string function from https://www.powershellmagazine.com/2019/06/14/pstip-a-better-way-to-generate-http-query-strings-in-powershell/
function New-HttpQueryString
<#
.SYNOPSIS
A cleaner way to create a query string used by many of the search-ws1* cmdlets

.DESCRIPTION
This was created here and is included because it is useful. 
https://www.powershellmagazine.com/2019/06/14/pstip-a-better-way-to-generate-http-query-strings-in-powershell/

.NOTES
This script should not be called directly, it is used as part of the other functions.

#>
{
    [CmdletBinding()]
    param 
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Uri,
 
        [Parameter(Mandatory = $true)]
        [Hashtable]
        $QueryParameter
    )
 
    # Add System.Web
    Add-Type -AssemblyName System.Web
 
    # Create a http name value collection from an empty string
    $nvCollection = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
 
    foreach ($key in $QueryParameter.Keys)
    {
        $nvCollection.Add($key, $QueryParameter.$key)
    }
 
    # Build the uri
    $uriRequest = [System.UriBuilder]$uri
    $uriRequest.Query = $nvCollection.ToString()
 
    return $uriRequest.Uri.OriginalString
}
 
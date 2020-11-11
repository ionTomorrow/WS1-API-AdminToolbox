<#Technical Debt Log

Change the import to automatically strip off the .csv if someone includes it. 
    https://techibee.com/powershell/get-filename-with-or-without-extension-from-full-path-using-powershell/2800

Importing a bad filename is going to result in an error and not return anything of value.

#>


Function Import-WS1DeviceCsv {
    param(
        [Parameter(Mandatory=$true,Position=0)][string]$defaultFilename,
        [Parameter(Mandatory=$false,Position=1)][bool]$GetFileHash,
        [Parameter(Mandatory=$false,Position=2)][string]$ColumnName
    )

    <#Retrieve CSV from input directory #>
    write-host `n
    $inputPath = ((get-location).path)+"\input\"
    #Write-host -ForegroundColor Cyan "The expectation is that the .csv file with Serial Numbers is found in the $inputPath Scripting folder."
    $inputList = @()
    $inputCsv = $null
    
    
    
    Do {
    $inputCsv = Read-Host -Prompt "please input name of the csv (without .csv extension) that includes the serial numbers. Press enter to use default file name ($defaultFilename)"
    
        Try {
            if ($null -eq $inputCsv) {
                $inputCsv = $defaultFilename
            }
            
            $validCsv = Test-Path -Path $inputpath$inputCsv".csv"
            $verifyCsv = get-item -path $inputpath$inputCsv".csv"
            $verifyCsvFileName = $verifyCsv.name   
            $hashCsv = ($verifyCsv | Get-FileHash -Algorithm SHA256).hash
            $inputList = import-csv $inputPath$verifyCsvFilename
            
            <#if (!$ColumnName) {
                $inputList
                [string]$columnName = Read-Host "what is the column name?"
            }#>
        }
        Catch {
            write-host -ForegroundColor Red "Error Importing filename"
            $validCsv = $false
        }
    }
    Until ($validCsv -ne $false)

    ###return imported CSV as an object and the filehash if requested by script.
    ###Multiple values can be retrieved by accessing results like an array - https://social.technet.microsoft.com/Forums/ie/en-US/65d3bf7f-c710-498a-b535-46c64cbf92e7/return-multiple-values-in-powershell?forum=ITCG
    Return $inputList
#    Return $ColumnName
    if ($GetFileHash) {
        Return $hashCsv
    }

}

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

function New-WS1Batch {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$batchsize,
        [Parameter(Mandatory=$true, Position=1)]
        [hashtable]$batchInput
    )
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
    $WS1LogTime = Get-Date -Format yyyyMMdd.HH.mm.ss
    return $WS1LogTime
}

<#
Function Update-WS1Log{
param (
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateSet("PreCheck","Error","PostCheck")]
        [string]$logType,
        [Parameter(Mandatory=$true, Position=1)]
        [ValidateSet("iOS","Windows")]
        [string]$platform
       <# UnitID
        ErrorCode
        ErrorMessage
        ErrorActivityID
        

        )

}
#>


###Logging Format Setup
###
### Took hints from https://stackoverflow.com/questions/31982926/new-item-changes-function-return-value to use the | Out-NULL to remove extra paths with New-Item

Function get-ws1LogFolder {
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
$folders = @("code","config","documentation","input","output","tools","test")
foreach ($folder in $folders) {
    If (Test-Path .\$folder) {
        write-host "$folder Found!"
    }
    else {
        New-Item -ItemType Directory $folder
    }
}
}

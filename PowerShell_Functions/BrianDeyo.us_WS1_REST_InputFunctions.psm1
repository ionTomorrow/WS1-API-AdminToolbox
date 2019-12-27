<#Technical Debt Log

Change the import to automatically strip off the .csv if someone includes it. 
    https://techibee.com/powershell/get-filename-with-or-without-extension-from-full-path-using-powershell/2800

Importing a bad filename is going to result in an error and not return anything of value.

#>


Function Import-WS1DeviceCsv {
    param(
        [Parameter(Mandatory=$true,Position=0)][string]$defaultFilename,
        [Parameter(Mandatory=$false,Position=1)][bool]$GetFileHash
    )

    <#Retrieve CSV from input directory #>
    write-host `n
    $inputPath = ((get-location).path)+"\input\"
    Write-host -ForegroundColor Cyan "The expectation is that the .csv file with Serial Numbers is found in the $inputPath Scripting folder."
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
    if ($GetFileHash) {
        Return $hashCsv
    }

}

function New-WS1Batch {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$batchsize,
        [Parameter(Mandatory=$true, Position=1)]
        [hashtable]$batchInput
    )
}
<#Technical Debt Log

Change the import to automatically strip off the .csv if someone includes it. 
    https://techibee.com/powershell/get-filename-with-or-without-extension-from-full-path-using-powershell/2800

Importing a bad filename is going to result in an error and not return anything of value.

#>


Function Import-WS1DeviceCsv {
    param(
        [Parameter(Mandatory=$true,Position=0)][string]$defaultFilename,
        [Parameter(Mandatory=$false,Position=1)][ref]$hash
    )

    <#Retrieve CSV from input directory #>
    write-host `n
    Write-host "The expectation is that the .csv file with Serial Numbers is found in the \Input Scripting folder."
    $snList = @()
    $snCSV = $null

    Do {
    $snCsv = Read-Host -Prompt "please input name of the csv (with no .csv extensions) that includes the serial numbers. Press enter to use default file name ($defaultFilename)"
    
    if ($snCsv -ne "") { 
        $snCsv = $SnCsv + ".csv"
    }
    else {
        write-host -ForegroundColor Cyan "Using Default Filename!"
        $snCsv = $defaultFilename + ".csv"
    }
    }
    Until ($snCSV -ne $null)

    ###Verify the .csv name is valid
    $snCsvExists = Test-Path -path \input\$snCsv
    
    If ($snCsvExists -eq $true) {
        $snList = import-csv \input\$snCsv
    }
    ELSE {
        write-host -ForegroundColor Red "ERROR: File $snCsv doesn't exist. Please check the name and rerun bulk delete script."
        Write-Host -ForegroundColor Yellow "EXITING"
    }

    <#
    #return updated hash if requested by script. Must fix this script to verify the filetype is actuall a .csv, then pipe that directly to get-filehash

    $hash_obj = get-filehash \input\$snCsv
    $hash.Value = $hash_obj.Hash
    #>
    Return $snList


}

function New-WS1Batch {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$batchsize,
        [Parameter(Mandatory=$true, Position=1)]
        [hashtable]$batchInput
    )
}
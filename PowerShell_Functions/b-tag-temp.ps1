do {
    
    if (!$tagId) {
        $tagList = Search-WS1Tags -WS1Host $headers.ws1ApiUri -GroupID 570 -page 0 -pageSize 1000 -tagType Device -headers $headers
        
        $tagList.tags | Select-Object "TagName","Id"
        
    }
    [int]$tagId = read-host "Enter numeric TagID if known. Press enter to display list of all tags for Environment"
}
while ($tagId -eq 0)

#$tagId = 10072
#

    ###Device the imported list into batches
    [int]$batchSize = 1000
    [int]$batches = [math]::Ceiling($ws1DevicesToTag.count / $batchSize)
    [int]$batch = 0
    [int]$tagTotal = 0
    [int]$tagError = 0

$ws1DevicesToTag = Import-WS1DeviceCsv -defaultFilename "Profile Details by Device" -GetFileHash $false

$batch=2
$addDevices = $ws1DevicesToTag.'Serial Number' | Select-Object -Skip ($batch * $batchSize) -First $batchSize


$ws1DeviceIdList = Get-WS1BulkDevice -WS1Host $headers.ws1ApiUri -searchBy SerialNumber -bulkIdList $addDevices -headers $headers


$tagResults = set-ws1DeviceTag -ws1Host $headers.ws1ApiUri -tagId $tagId -addDevices $ws1DeviceIdList.Devices.id.value -headers $headers
Write-Host $tagResults
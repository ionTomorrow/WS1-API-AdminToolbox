Function get-ws1SmartGroup {
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [int]$ws1SGId,
        [Parameter(Mandatory=$true, Position=1,ValueFromPipelineByPropertyName=$true)]
        [Hashtable]$headers
        )
    $WS1CustomerOG = Invoke-RestMethod -Method GET -Uri https://$($headers.ws1ApiUri)/api/mdm/smartgroups/$ws1SGId -Headers $headers

    return $WS1CustomerOG
}
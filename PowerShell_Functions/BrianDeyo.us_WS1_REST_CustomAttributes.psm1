###############################
###
###  CUSTOM ATTRIBUTES CMDLETS
###
###############################

function get-ws1DeviceCustomAttribute {
    param (
        [Parameter(Mandatory=$true, Position=1)]
        [ValidateSet("OrganizationGroupId","DeviceID","SerialNumber")]
        [string]$searchBy,
        [Parameter(Mandatory=$true, Position=2)]
        [string]$searchId,
        [Parameter(Mandatory=$false, Position=3)]
        [datetime]$StartDateTime,
        [Parameter(Mandatory=$false, Position=4)]
        [datetime]$EndDateTime,
        [Parameter(Mandatory=$true, Position=5,ValueFromPipelineByPropertyName=$true)]
        [Hashtable]$headers
        )

        $ws1EnvUri = $headers.ws1ApiUri
    Try {
            $ws1Attributes = Invoke-WebRequest -Method GET -Uri https://$ws1EnvUri/api/mdm/devices/customattribute/search?$searchBy=$searchId -Headers $headers
            $ws1Attributes = (ConvertFrom-Json $ws1Attributes.Content)
            
        }
    Catch  [System.Net.WebException] {
        write-host -ForegroundColor Red "Error retrieving attributes"
        }
        return $ws1Attributes
}

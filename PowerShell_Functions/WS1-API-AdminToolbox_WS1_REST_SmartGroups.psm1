<#
Copyright 2016-2021 Brian Deyo
Copyright 2021 VMware, Inc.
SPDX-License-Identifier: MPL-2.0

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at https://mozilla.org/MPL/2.0/.
#>


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

function find-ws1SmartGroup {
    param (
        [Parameter(Mandatory=$false,Position=0)][string]$name,
        [Parameter(Mandatory=$false,Position=1)][int]$ogID,
        [Parameter(Mandatory=$false,Position=2)][int]$managedByOgID,
        [Parameter(Mandatory=$false,Position=3)][datetime]$modifiedFrom,
        [Parameter(Mandatory=$false,Position=4)][datetime]$modifiedTill,
        [Parameter(Mandatory=$false,Position=5)][string]$orderBy,
        [Parameter(Mandatory=$false,Position=6)][ValidateSet("ASC","DESC")][string]$sortOrder, 
        [Parameter(Mandatory=$false,Position=7)][int]$page,
        [Parameter(Mandatory=$false,Position=8)][int]$pagesize,
        [Parameter(Mandatory=$false,Position=10)][hashtable]$headers

    )

    $searchString = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
    if ($name) {$searchString.add('name',$name)}
    if ($ogID) {$searchString.Add('organizationgroupid',$ogID)}
    if ($managedByOgID) {$searchString.Add('managedbyorganizationgroupid',$managedByOgID)}
    if ($modifiedFrom) {$searchstring.add('modifiedfrom',$modifiedFrom)}
    if ($modifiedTill) {$searchstring.add('modifiedtill',$modifiedTill)}
    if ($orderBy) {$searchString.Add('orderby',$orderBy)}
    if ($sortOrder) {$searchString.Add('sortorder',$sortOrder)}
    if ($page) {$searchString.Add('page',$page)}
    if ($pagesize) {$searchString.Add('pagesize',$page)}

    try {
        $searchResults = Invoke-RestMethod -method GET -URI https://$($headers.ws1ApiUri)/api/mdm/smartgroups/search?$($searchString.ToString()) -Headers $headers
    }
    catch [Exception] {

    }

    return $searchResults
}
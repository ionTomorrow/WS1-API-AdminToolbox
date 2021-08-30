# Workspace ONE REST API 
#
## This is a series of reuseable PowerShell Core cmdlets targeting common admin functions 

The primary purpose of this project is to create a set of reuseable cmdlets to interact with the WS1 API via PowerShell. 
I have seen a lot of great scripts put online, but one thing I see in common is they all spend a lot of unnecessary effort re-creating basic functions. 
The publicly available APIs from VMware are reasonably well-documented and contain clearly known parameters.

The goal for this is to reduce the time for a WS1 admin to write scripts for their environment.
Let's focus on getting things done and not creating 10 ways to do the same thing.


These updated functions should be capable of working under PowerShell Core



## List of Modules and generalized purpose if not clear by name:

* AdminUsers.psm1 -- Work with Admin Accounts
* ConnectionConfig.psm1 -- setup of the API connection, getting credentials, etc.
* Devices.psm1 -- Work with Devices
* InputFunctions.psm1 -- Functions for importing .csv files and helping setup scripting environment
* OrgGroups.psm1 -- Work with OGs
* SmartGroups.psm1 -- Work with SGs
* TAGs.psm1 -- Work with TAGs
* Users.psm1 -- Work with standard User accounts

## USAGE
### 1. Import cmdlets
To use these cmdlets, they must be imported as modules. You can use the ./ws1_sample_start.ps1 script to import them. The modules reference each other to reduce code reuse, so you should import all of the modules and not skip any.

### 2. run select-ws1config
    Once the modules have been imported, assign a variable to the `select-ws1Config` cmdlet to generate REST API Headers.
    `$headers = select-ws1Config`
    
    The select-ws1Config will walk you through how you want to connect to the API.


### 3. use cmdlets like any other PS cmdlet including tab completion.

    When you need to use the **-header** parameter,
Functions in each script can have their help contents retrieved like other cmdlets.
    get-help *-ws1*


## AdminUsers
```
* find-ws1AdminUser
* new-ws1AdminUser
* set-ws1AdminUser
* remove-ws1AdminUser
* get-ws1AdminUser
```

## ConnectionConfig
```
* new-ws1RestConnection
* select-ws1Config
* get-ws1SettingsFile
* test-ws1EnvConfigFile
* add-ws1RestConfig
* update-ws1EnvConfigFile
* convertTo-ws1HeaderVersion
* trace-ws1Error
```

## Devices
```
* get-ws1BulkDeviceSettings
* find-ws1Device
* get-ws1Device
* get-ws1BulkDevice
* search-ws1Devices
* clear-ws1Device
* clear-ws1DeviceV2
* remove-ws1Device
* set-ws1Device
* set-ws1DeviceManagedSettings
* remove-ws1BulkDevice
* send-ws1Message
* move-ws1Device
* get-ws1DeviceCount
* update-ws1DeviceOutput
```

## InputFunctions
```
* import-ws1DeviceCsv
* import-ws1Csv (deprecated)
* get-threadCount
* get-ws1LogFolder
* get-ws1InputArchive
* new-ws1InputArchive
* get-ws1Folders
```

## OrgGroups
```
* find-CustomerOGID
* get-awOgTree
* clear-awOrgTree
* add-ws1OrgGroup
* find-ws1OrgGroup
* get-ws1OrgGroup
```
## SmartGroups
```
* get-ws1SmartGroup
* find-ws1SmartGroup
```

## TAGs
```
* search-ws1Tags
* set-ws1DeviceTag
* get-ws1TaggedDevices
```
## Users
```
* new-ws1User
* find-ws1User
* get-ws1User
* set-ws1User
* update-ws1UserOutput
* remove-ws1User
* disable-ws1User
```

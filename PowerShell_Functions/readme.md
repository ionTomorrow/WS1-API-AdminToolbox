The primary purpose of this project is to create a set of reuseable cmdlets to interact with the WS1 API via PowerShell. 
I have seen a lot of great scripts put online, but one thing I see in common is they all spend a lot of unnecessary effort re-creating basic functions. 
The publicly available APIs from VMware are reasonably well-documented and contain clearly known parameters.

The goal for this is to reduce the time for a WS1 admin to write scripts for their environment.
Let's focus on getting things done and not creating 10 ways to do the same thing.


These updated functions should be capable of working under PowerShell Core



List of Modules and generalized purpose if not clear by name:

* AdminUsers.psm1
* Apps.psm1
* ConnectionConfig.psm1 -- setup of the API connection, getting credentials, etc.
* CustomAttributes.psm1
* Devices.psm1
* InputFunctions.psm1 -- Functions for importing .csv files and helping setup scripting environment
* OrgGroups.psm1
* SmartGroups.psm1
* TAGs.psm1
* Users.psm1


Functions in each script can have their help contents retrieved like other 


## AdminUsers
* find-ws1AdminUser
* new-ws1AdminUser
* set-ws1AdminUser
* remove-ws1AdminUser
* get-ws1AdminUser

##Apps
* get-ws1AppDetails

##ConnectionConfig
* new-ws1RestConnection
* select-ws1Config
* get-ws1SettingsFile
* test-ws1EnvConfigFile
* add-ws1RestConfig
* update-ws1EnvConfigFile
* convertTo-ws1HeaderVersion
* trace-ws1Error

##CustomAttributes
* get-ws1DeviceCustomAttribute

##Devices
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

##InputFunctions
* import-ws1DeviceCsv
* import-ws1Csv (deprecated)
* get-threadCount
* get-ws1LogFolder
* get-ws1InputArchive
* new-ws1InputArchive
* get-ws1Folders

##OrgGroups
* find-CustomerOGID
* get-awOgTree
* clear-awOrgTree
* add-ws1OrgGroup
* find-ws1OrgGroup
* get-ws1OrgGroup

##SmartGroups
* get-ws1SmartGroup
* find-ws1SmartGroup

##TAGs
* search-ws1Tags
* set-ws1DeviceTag
* get-ws1TaggedDevices

##Users
* new-ws1User
* find-ws1User
* get-ws1User
* set-ws1User
* update-ws1UserOutput
* remove-ws1User
* disable-ws1User

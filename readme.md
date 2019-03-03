# brshSysInfo - Powershell System Information module

All the system information that's fit to print (although some only work with Admin rights - cuz reasons)

The big bright shiny function from this module is the SystemReport - via `get-siSystemReport`, but the info is available in bite sized psobject'ed morsels in the following functions:

| Command                    | Description                                                  | SystemReport |
| -------------------------- | ------------------------------------------------------------ | ------------ |
| Get-siSysInfoHelp          | List commands available in the brshSysInfo Module            |              |
| Get-siSystemReport         | Create a report of System Info (with BGInfo support)         |              |
| Get-siSystemReportSettings | Get the Settings for the System Report                       |              |
| Set-siSystemReportSettings | Change the Settings for the System Report                    |              |
| Get-siOSInfo               | Pulls Operating System info from all over the place          | True         |
| Get-siDriveInfo            | Pulls Drive info from WMI                                    | True         |
| Get-siNetworkInfo          | Pulls Network info from WMI                                  | True         |
| Get-siServerRoleInfo       | Pulls system role information (what's this thing serving)    | True         |
| Get-siAWSInfo              | Pulls Data from AWS Local Instance service                   | True         |
| Get-siIISBindingInfo       | Pulls IIS site and binding information                       | True         |
| Get-siSQLVersionInfo       | Pulls sql version and patch information                      | True         |
| Get-siWinUpdateInfo        | Get Info about pending Windows Updates on the Local Computer | False        |
| Get-siUserSessionInfo      | Pulls currently logged on user information                   | True         |
| Get-siSystemUserEventInfo  | Pulls logon and reboot info from the EventLog                | True         |

By default, not everything shows up in the System Report - that's because on some systems the Windows Update script can run very slow. You can toggle the on/off of any item with the `Set-siSystemReportSettings` function.

You can also control the order of the information chunks. Use the `Get-siSystemReportSettings` to see the existing order.

I still need to adjust formatting for the any new items (Get-siSystemUserEventInfo I think is the only one), so that won't yet show up in the System Report.

#### BGInfo
If you've looked at my BGInfo repo, you'll notice some similarities ... cuz these were ripped completely from there. As such, this _should_ work out-of-the-box with BGInfo. I haven't spent much time testing that yet, and there's no vbs wrapper written yet. But soon!

#### Coming
* Save System Report Settings
* Tested BGInfo config with working VBS
* More formatting!
* More information!

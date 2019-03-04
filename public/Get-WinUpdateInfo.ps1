function Get-siWinUpdateInfo {
	<#
.SYNOPSIS
Pulls Info about pending Windows Updates on the Local Computer

.DESCRIPTION
This will pull
	* The most recent, successful install date of Windows updates (from WMI via the Get-Hotfix cmdlet)
	* Whether a reboot is pending (via a registry key)
	* How many updates are pending (via the Update.Session COM object)
	* How many pending updates are "Critical" (again, via the Update.Session COM object)
	* The date of the oldest pending update (once more from the Update.Session)
	* The date of the newest pending update (really working this Update.Session thing)

If it errors, it will try to write the failure message to the Application event log as event 9999 from source WinUpdateInfo.
Of course, it will need to have registered the Event Log source... which requires running as admin at least once.

It outputs either a simple object with the requisite information or (as text):

	<<< Windows Update Check Script >>>
	RunTime  UpdateCount  CriticalsCount  OldestPendingUpdate  NewestPendingUpdate  LastInstallDate  RebootPending

.PARAMETER Automate
True or False (false by default). Outputs text in an ugly but easily parsed format

.INPUTS
None

.OUTPUTS
A simple object with the requisite information
or (as text):
<<< Header >>>
RunTime  UpdateCount  CriticalsCount  OldestPendingUpdate  NewestPendingUpdate  LastInstallDate  RebootPending

.EXAMPLE
Get-WinUpdateInfo.ps1

Runs the script

.EXAMPLE
Get-WinUpdateInfo.ps1 -Verbose

Runs the script but prints additional information

.EXAMPLE
Get-WinUpdateInfo.ps1 -Automate

Runs the script but outputs as text, not the object
#>

	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false, Position = 0)]
		[Alias('Text', 'Ugly', 'CheckMK', 'Monitor')]
		[switch] $Automate = $false
	)

	Write-Verbose "** Script Start: $(Get-Date) ***"
	[datetime] $LastInstallDate = (Get-Date).AddYears(-100)
	[datetime] $OldestUpdate = (Get-Date).AddYears(100)
	[datetime] $NewestUpdate = (Get-Date).AddYears(-100)
	[int] $criticals = 0
	[int] $TotalUpdates = 0

	Write-Verbose "Searching/sorting all installed hotfixes for the last successful install"
	try {
		$LastInstallDate = (Get-Hotfix | Sort-Object InstalledOn -Descending | Select-Object InstalledOn -First 1).InstalledOn
		Write-Verbose "... Most recent install was $LastInstallDate"
	} catch {
		Write-Verbose "... Could not pull the date!"
		Write-Verbose "... $_.Exception.Message"
	}

	Write-Verbose "Polling the registry to check if a reboot is pending (for Updates)"
	[bool] $RebootPending = $false
	if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired") {
		$RebootPending = $true
	}
	Write-Verbose "... Reboot Pending: $RebootPending"

	Write-Verbose "Polling the registry to get the current update server"
	[string] $UpdateServer = ''
	if (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate") {
		try {
			$UpdateServer = (get-itemproperty hklm:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate -Name WUServer -ErrorAction Stop).WUServer
		} catch {
			$UpdateServer = 'Error Reading Registry'
		}
	}
	Write-Verbose "... Update Server: $UpdateServer"

	Write-Verbose "Polling Windows Update for Pending Updates"
	try {
		$updateSession = new-object -com "Microsoft.Update.Session" -ErrorAction Stop
		$updates = $updateSession.CreateupdateSearcher().Search($criteria).Updates
		$TotalUpdates = $updates.Count
		Write-Verbose "... Updates Pending: $TotalUpdates"

		$updates | ForEach-Object {
			if ($_.AutoSelectOnWebSites) { $criticals ++ }
			[datetime] $updateDate = $_.LastDeploymentChangeTime
			if ([string] $updateDate -as [datetime]) {
				if ($updateDate -gt $NewestUpdate) { $NewestUpdate = $updateDate }
				if ($updateDate -lt $OldestUpdate) { $OldestUpdate = $updateDate }
			}
		}
		Write-Verbose "... Criticals Pending: $criticals"
	} catch {
		$criticals = 9999
		$TotalUpdates = 9999
		$message = "Failed to get Windows Updates`r`n`r`n"
		$message = $message + "Script: $((get-variable myinvocation -scope script).value.Mycommand.Definition)`r`n`r`n"
		$message = $message + "Error Message: $($_.exception.Message)`r`n`r`n"
		$message = $message + "Generally: `r`n"
		$message = $message + "  Error 0x80072EE2: problems reaching/finding Update Server`r`n"
		$message = $message + "  Error 0x8024401C: a timeout (network or process) with the Update Server`r`n"
		$message = $message + "  Error 0x80040154: the Update Agent's COM Object isn't registered`r`n"
		$message = $message + "  Error 0x80244022: HTTP_STATUS_SERVICE_UNAVAIL HTTP 503 against the Update Server`r`n"
		$message = $message + "  Error 0x80240440: Probably Firewall - check denies`r`n"
		$message = $message + "  Error 0x80240438: There is no route or network connectivity to the endpoint`r`n"
		$message = $message + "`r`n"
		$message = $message + "Update server is defined as $UpdateServer`r`n"

		Write-Verbose "... $($_.Exception.Message)"
		Write-Verbose "... See the Event Log for details (source WinUpdateInfo, event ID 9999)"
		if ($PSVersionTable.PSVersion.Major -lt 6) {
			New-EventLog -LogName Application -Source "WinUpdateInfo" -ErrorAction SilentlyContinue
			Write-EventLog -LogName "Application" -Source "WinUpdateInfo" -eventid 9999 -EntryType Error -Message $Message -ErrorAction SilentlyContinue
		}
	}

	$out = [PSCustomObject] @{
		Updates         = $TotalUpdates
		Criticals       = $criticals
		Oldest          = $OldestUpdate.ToShortDateString()
		Newest          = $NewestUpdate.ToShortDateString()
		LastInstallDate = $LastInstallDate.ToShortDateString()
		RebootPending   = $RebootPending
		RunTime         = $(Get-Date).ToShortDateString()
		UpdateServer    = $UpdateServer
	}

	if ($Automate) {
		"<<< Windows Update Check Script >>>"
		"$($Out.RunTime) `t $($Out.Updates) `t $($Out.Criticals) `t $($Out.Oldest) `t $($Out.Newest) `t $($Out.LastInstallDate) `t $($Out.RebootPending)"
	} else {
		$out.PSObject.TypeNames.Insert(0, 'brshSysInfo.PatchInfo')
		$out
	}

	Write-Verbose "** Script End: $(Get-Date) ***"
}

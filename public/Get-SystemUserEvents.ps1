function Get-siSystemUserEventInfo {
	<#
	.SYNOPSIS
	Pulls logon and reboot info from the EventLog

	.DESCRIPTION
	The event log is a treasure trove of information that you most times can't use. It can be difficult
	to parse visually because it holds sooo much stuff. This function does a quick parse to pick up
	user logon and logoff events, as well as system startup, shutdown, and renames.

	.PARAMETER Computer
	This might let you connect to another computer - assuming the stars are all properly aligned

	.PARAMETER Days
	How many days back to search - defaults to 1

	.EXAMPLE
	Get-siSystemUserEventInfo

	Pulls the info from the past 1 day

	.EXAMPLE
	Get-siSystemUserEventInfo -Days 20

	Pulls the info from the past 20 days
	#>

	[cmdletbinding()]
	param (
		[string]$Computer = $env:COMPUTERNAME,
		[int]$Days = 1
	)

	$filterXml = "
        <QueryList>
            <Query Id='0' Path='System'>
            <Select Path='System'>

				*[System[Provider[
					@Name='eventlog' or
					@Name = 'Microsoft-Windows-Winlogon' or
					@Name='Microsoft-Windows-Kernel-Power'
				]
				and
			        TimeCreated[@SystemTime >= '$(get-date (get-date).AddDays(-$Days) -UFormat '%Y-%m-%dT%H:%M:%S.000Z')']
                ]]
            </Select>
            </Query>
        </QueryList>
    "
	try {
		$Logs = Get-WinEvent -FilterXml $filterXml -ComputerName $Computer -ErrorAction Stop

		if ($Logs) {
			$(foreach ($Log in $Logs) {
					switch ($Log.ID) {
						7001 {$Type = 'User Logon'; break}
						7002 {$Type = 'User Logoff'; break}
						6011 {$Type = 'System Renamed'; break}
						6008 {$Type = 'Unexpected Shutdown'; break}
						6006 {$Type = 'Clean Shutdown'; break}
						6005 {$Type = 'Clean Startup'; break}
						#107 { $Type = 'Resume'; break }
						42 {$Type = 'Sleep'; break}
						41 {$Type = 'Boot from Unexpected Shutdown'; break}
						default {$Type = ''; continue}
					}
					if ($Type.Length -gt 0) {
						if ($Log.Properties.value.value) {
							$logvalue = (New-Object System.Security.Principal.SecurityIdentifier $Log.Properties.value.value).Translate([System.Security.Principal.NTAccount])
						} else {
							try {
								$logvalue = (New-Object System.Security.Principal.SecurityIdentifier $Log.UserID).Translate([System.Security.Principal.NTAccount])
							} catch {
								$logvalue = 'n/a'
							}
						}
						$out = New-Object PSObject -Property @{
							Time      = $Log.TimeCreated.ToString('MM/dd/yyyy hh:mm:ss tt')
							EventID   = $Log.ID
							EventType = $Type
							User      = $logvalue
							Message   = ($Log.Message.ToString().Split('.'))[0]
							System    = $Log.MachineName.ToString().Split('.')[0]
							Level     = $Log.LevelDisplayName
							Provider  = $Log.ProviderName
						}
						$out.PSObject.TypeNames.Insert(0, 'brshSysInfo.SystemUserEventInfo')
						$out
					}
				}) # | Sort-Object time -Descending
		} else {
			Write-Host "Problem with $Computer."
			Write-Host "If you see a 'Network Path not found' error, try starting the Remote Registry service on that computer."
			Write-Host 'Or there are no logon/logoff events (XP requires auditing be turned on)'
		}
	} catch {
		Write-Verbose 'Error getting event logs'
		Write-Verbose $_.Exception.Message
	}
}

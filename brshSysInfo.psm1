﻿param (
	[switch] $Quiet = $False
)
#region Private Variables
# Current script path
[string] $ScriptPath = Split-Path (get-variable myinvocation -scope script).value.Mycommand.Definition -Parent
#endregion Private Variables

#region Private Helpers

# Dot sourcing private script files
Get-ChildItem $ScriptPath/private -Recurse -Filter "*.ps1" -File | ForEach-Object {
	. $_.FullName
}
#endregion Load Private Helpers

[string[]] $script:showhelp = @()
$script:IncludeInSystemReport = @{}

# Dot sourcing public script files
Get-ChildItem $ScriptPath/public -Recurse -Filter "*.ps1" -File | ForEach-Object {
	. $_.FullName

	# From https://www.the-little-things.net/blog/2015/10/03/powershell-thoughts-on-module-design/
	# Find all the functions defined no deeper than the first level deep and export it.
	# This looks ugly but allows us to not keep any uneeded variables from poluting the module.
	([System.Management.Automation.Language.Parser]::ParseInput((Get-Content -Path $_.FullName -Raw), [ref] $null, [ref] $null)).FindAll( { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false) | Foreach {
		Export-ModuleMember $_.Name
		$script:showhelp += $_.Name
		if ($_.Name -match 'Info$') {
			$script:IncludeInSystemReport.Add($_.Name, @{Enabled = $true; Position = 50})
		}
	}
}
#endregion Load public Helpers

if (test-path $ScriptPath\formats\brshSysInfo.format.ps1xml) {
	Update-FormatData $ScriptPath\formats\brshSysInfo.format.ps1xml
}

#Remove the ones that are not Info
$script:IncludeInSystemReport.Remove('Get-siSystemReport')
$script:IncludeInSystemReport.Remove('Get-SystemReportSettings')
$script:IncludeInSystemReport.Remove('Get-siSysInfoHelp')

#Specifically set items NOT to be in the System Report
$script:IncludeInSystemReport['Get-siWinUpdateInfo'].Enabled = $false

#Put some items first
$script:IncludeInSystemReport['Get-siOSInfo'].Position = 1
$script:IncludeInSystemReport['Get-siDriveInfo'].Position = 2
$script:IncludeInSystemReport['Get-siNetworkInfo'].Position = 3
$script:IncludeInSystemReport['Get-siServerRoleInfo'].Position = 4
$script:IncludeInSystemReport['Get-siUserSessionInfo'].Position = 98
$script:IncludeInSystemReport['Get-siSystemUserEventInfo'].Position = 99

if (-not $Quiet) {
	Get-siSysInfoHelp
}

###################################################
## END - Cleanup

#region Module Cleanup
$ExecutionContext.SessionState.Module.OnRemove = {
	# cleanup when unloading module (if any)
	Get-ChildItem alias: | Where-Object { $_.Source -match "brshSysInfo" } | Remove-Item
	Get-ChildItem function: | Where-Object { $_.Source -match "brshSysInfo" } | Remove-Item
	Get-ChildItem variable: | Where-Object { $_.Source -match "brshSysInfo" } | Remove-Item
}
#endregion Module Cleanup

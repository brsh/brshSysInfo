Function Get-siSysInfoHelp {
	<#
	.SYNOPSIS
	List commands available in the brshSysInfo Module

	.DESCRIPTION
	List all available commands in this module

	.EXAMPLE
	Get-siSysInfoHelp
	#>
	Write-Host ""
	Write-Host "Getting available functions..." -ForegroundColor Yellow

	$all = @()
	$list = Get-Command -Type function -Module "brshSysInfo" | Where-Object { $_.Name -in $script:showhelp}
	$list | ForEach-Object {
		if ($PSVersionTable.PSVersion.Major -lt 6) {
			$RetHelp = Get-help $_.Name -ShowWindow:$false -ErrorAction SilentlyContinue
		} else {
			$RetHelp = Get-help $_.Name -ErrorAction SilentlyContinue
		}
		if ($RetHelp.Description) {
			$position = $script:IncludeInSystemReport[$_.Name].Position
			if (-not $position) { $position = -1 }
			$Infohash = @{
				Command      = $_.Name
				Description  = $RetHelp.Synopsis
				SystemReport = $script:IncludeInSystemReport[$_.Name].Enabled
				Position     = $script:IncludeInSystemReport[$_.Name].Position
			}
			$out = New-Object -TypeName psobject -Property $InfoHash
			$all += $out
		}
	}
	$all | sort-object Position, Command |
		format-table Command, Description, SystemReport -Wrap -AutoSize | Out-String | Write-Host
}

function Get-siSystemReportSettings {
	<#
	.SYNOPSIS
	Get the Settings for the System Report

	.DESCRIPTION
	The System Report pulls all the functions together in to a pretty report. BUT some of the
	information is ... excessive (or just slow, I'm looking at you windows updates). This function
	lists the functions involved in the System Report as well as the position they'll be in the
	report.

	To change a setting - disable a function or change its position - use the Set-siSystemReportSettings
	function.

	.EXAMPLE
	Get-siSystemReportSettings

	#>
	[cmdletbinding()]
	param (
		[ArgumentCompleter( {
				param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
				if ($WordToComplete) {
					(Get-siSystemReportSettings -Name "$WordToComplete").Name
				} else {
					(Get-siSystemReportSettings).Name
				}
			})]
		[string] $Name
	)

	$all = @()
	$script:IncludeInSystemReport.GetEnumerator() | Sort-Object Name | ForEach-Object {
		$all += new-object -TypeName psobject -Property @{
			Name     = $_.Name
			Enabled  = $_.Value.Enabled
			Position = $_.Value.Position
		}
	}
	if ($Name) {
		$all | Where-Object { $_.Name -match $Name }
	} else {
		$all | Sort-Object Position
	}
}

function Set-siSystemReportSettings {
	<#
	.SYNOPSIS
	Change the Settings for the System Report

	.DESCRIPTION
	The System Report pulls all the functions together in to a pretty report. BUT some of the
	information is ... excessive (or just slow, I'm looking at you windows updates). This function
	can change the position of a function within the report, or disable/enable the function.

	To view the settings, use the Get-siSystemReportSettings function.

	Note: Position is not exactly a literal thing. The position number is sorted from lowest to
	highest (so lowest is first). In the event of a duplicate position number, it's kinda
	random which one will be first. I like to think of it as a bit of a lotto - will you
	be lucky?!?!

	.EXAMPLE
	Set-siSystemReportSettings -Name Get-siOSInfo -Enabled

	Toggles the Enabled/Disabled setting for Get-siOSInfo

	.EXAMPLE
	Set-siSystemReportSettings -Name Get-siOSInfo -Position 10

	Sets the Position in the report to "position" 10

	#>
	[cmdletbinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ArgumentCompleter( {
				param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
				if ($WordToComplete) {
					(Get-siSystemReportSettings -Name "$WordToComplete").Name
				} else {
					(Get-siSystemReportSettings).Name
				}
			})]
		[string] $Name,
		[Parameter(Mandatory = $true, ParameterSetName = 'Enabled')]
		[switch] $Enabled,
		[Parameter(Mandatory = $true, ParameterSetName = 'Position')]
		[int] $Position

	)
	if ($PsCmdlet.ParameterSetName -eq 'Position') {
		$script:IncludeInSystemReport[$Name].Position = $Position
	} else {
		$script:IncludeInSystemReport[$Name].Enabled = (-not $script:IncludeInSystemReport[$Name].Enabled)
	}
	Get-siSystemReportSettings -Name $Name
}

function Get-siSystemReport {
	<#
.SYNOPSIS
    Create a report of System Info (with BGInfo support)

.DESCRIPTION
    It's always nice to know things about the system you're using. Things like name, ip, drive space,
	what functions it might be serving, db instances, iis sites, etc. This script does that, wrapping
	all the misc. system info scripts into a single prettified report.

	Plus, as an added benefit, this report can be extra-formatted to look nice as a BGInfo wallpaper.
	Of course, BGInfo only supports VBScript, not PowerShell, so you still need to wrap the call to
	this function in a nice vbs wrapper - so you're wrapping a wrapper. What a world!

.EXAMPLE
	Get-brshSystemReport

	Outputs the report

.EXAMPLE
	Get-brshSystemReport -bginfo

	Outputs the report with extra tabs for BGInfo
#>


	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false)]
		[switch] $BGInfo = $false
	)

	$Formats = (Get-Command -Module 'brshSysInfo' -Name 'Format-*').Name
	#$formats

	Get-siSystemReportSettings | Where-Object { $_.Enabled } | Select-Object Name | ForEach-Object {
		$Format = $_.Name -Replace ("^Get-", 'Format-')
		#$format
		#$Formats -contains $Format
		Try {
			#$_.Name
			if ($Formats -contains $Format) {
				Write-Verbose "Found: $Format"
				Write-Verbose "Trying: $($_.Name)"
				$Response = & $_.Name
				if ($Response) {
					$Response | & $($format) -BGInfo:$BGInfo
				}
			}
		} catch {
			Write-Verbose "Error running $_"
			Write-Verbose $_.Exception.Message
		}
	}

}

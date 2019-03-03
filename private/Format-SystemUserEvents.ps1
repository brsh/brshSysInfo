function Format-siSystemUserEventInfo {
	<#
    .SYNOPSIS
        Formats the output of Get-siSystemUserEventInfo.ps1

    .EXAMPLE
        Get-siSystemUserEventInfo.ps1 | Format-siSystemUserEventInfo

        This script must be dot sourced (i.e., run '. .\Format-siSystemUserEventInfo')
    #>


	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
		[string] $Time,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
		[string] $EventType,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
		[string] $User,
		[Parameter(Mandatory = $false)]
		[switch] $BGInfo = $false
	)

	BEGIN {
		$columns = "{0,-23} {1,-25} {2}"
		Write-Host ($columns -f 'Time', 'EventType', 'User')
		[string] $tab = "`t`t"
		if ($BGInfo) { $tab = "`t"}
	}

	PROCESS {
		Write-Host ($columns -f $Time, $EventType, $User)
	}

	END {
		Write-Host ""
	}

}

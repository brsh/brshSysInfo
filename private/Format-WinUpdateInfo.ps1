function Format-siWinUpdateInfo {
	<#
    .SYNOPSIS
        Formats the output of Get-WinUpdateInfo.ps1

    .EXAMPLE
        Get-WinUpdateInfo.ps1 | Format-WinUpdateInfo

        This script must be dot sourced (i.e., run '. .\Format-WinUpdateInfo')
    #>


	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
		[int] $Updates,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
		[int] $Criticals,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
		[datetime] $LastInstallDate,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
		[bool] $RebootPending,
		[Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
		[string] $UpdateServer,
		[Parameter(Mandatory = $false)]
		[switch] $BGInfo = $false
	)

	BEGIN {
		[string] $tab = "`t`t"
		if ($BGInfo) { $tab = "`t"}
		[string] $indent = "${Tab}`t"
	}

	PROCESS {
		$Header = "Win Updates:`t"
		Write-Host $Header -NoNewLine
		Write-Host "Critical: " -NoNewLine
		if (($Criticals -eq 9999) -or (-not $Criticals)) {
			Write-Host "Error" -NoNewline
		} else {
			Write-Host $Criticals -NoNewline
		}
		Write-Host "    Total: " -NoNewLine
		if (($Updates -eq 9999) -or (-not $Updates)) {
			Write-Host "Error" -NoNewline
		} else {
			Write-Host $Updates -NoNewline
		}
		Write-Host ""

		$Header = "Update Server:`t"
		Write-Host $Header -NoNewLine
		Write-Host $UpdateServer

		$Header = "Last Patch:`t"
		Write-Host $Header -NoNewLine
		Write-Host $LastInstallDate.ToString("ddd, MMM dd, yyyy - h:mm tt")

		if ($RebootPending) {
			$Header = "Reboot Pending:`t"
			Write-Host $Header -NoNewLine
			write-host "Yes"
		}

		Write-Host ""
	}

	END { }

}

function Get-siDriveInfo {
	<#
.SYNOPSIS
    Pulls Drive info from WMI

.DESCRIPTION
    Pulls local drive info from WMI....

.EXAMPLE
    Get-DriveInfo.ps1

#>
	[CmdletBinding()]
	param ()

	BEGIN {
		[string] $Filter = "DriveType='2' or DriveType='3' or DriveType='4'"
		$drives = Get-CimInstance -Class Win32_LogicalDisk -Filter $Filter
 }

	PROCESS {
		$drives | ForEach-Object {
			$out = New-Object psobject
			[string] $label = $_.VolumeName
			if ($label.Length -eq 0) { $label = "(No Label)" }

			[bool] $pagefile = $false
			[bool] $bootdrive = $false
			[bool] $systemdrive = $false

			try {
				if ($_.DriveType -eq "3") {
					$driveletter = $_.DeviceID
					$hold = Get-CimInstance Win32_Volume -Filter "DriveLetter='$driveletter'"
					$pagefile = $hold.PageFilePresent
					$bootdrive = $hold.BootVolume
					$systemdrive = $hold.SystemVolume
					$BlockSize = $hold.BlockSize
					$Compressed = $hold.Compressed
				}
			} catch {
				Write-Verbose 'Error'
				Write-Verbose $_.Exception.Message
			}

			[string] $dtype = switch ($_.DriveType) {
				1 { "Rootless" }
				2 { "Removable" }
				3 { "Local" }
				4 { "Network" }
				5 { "CD" }
				6 { "RAMDisk" }
				Default { "Unknown" }
			}

			try {
				Add-Member -InputObject $out -MemberType NoteProperty -Name "FreeSpace" -Value $([int] ([math]::Round(($_.FreeSpace / 1GB), 0)))
			} catch {
				Add-Member -InputObject $out -MemberType NoteProperty -Name "FreeSpace" -Value -1
			}
			Try {
				Add-Member -InputObject $out -MemberType NoteProperty -Name "UsedSpace" -Value $([int] ([math]::Round(($_.Size - $_.FreeSpace) / 1GB, 0)))
			} catch {
				Add-Member -InputObject $out -MemberType NoteProperty -Name "UsedSpace" -Value -1
			}
			try {
				Add-Member -InputObject $out -MemberType NoteProperty -Name "Size" -Value $([int] ($_.Size / 1GB))
			} catch {
				Add-Member -InputObject $out -MemberType NoteProperty -Name "Size" -Value -1
			}
			try {
				Add-Member -InputObject $out -MemberType NoteProperty -Name "FreePercent" -Value $([int] (($_.FreeSpace / $_.Size) * 100))
			} catch {
				Add-Member -InputObject $out -MemberType NoteProperty -Name "FreePercent" -Value -1
			}
			try {
				Add-Member -InputObject $out -MemberType NoteProperty -Name "UsedPercent" -Value $([int] ((($_.Size - $_.FreeSpace) / $_.Size) * 100))
			} catch {
				Add-Member -InputObject $out -MemberType NoteProperty -Name "UsedPercent" -Value -1
			}
			Add-Member -InputObject $out -MemberType NoteProperty -Name "VolumeName" -Value $label
			Add-Member -InputObject $out -MemberType NoteProperty -Name "Drive" -Value $_.DeviceID
			Add-Member -InputObject $out -MemberType NoteProperty -Name "FileSystem" -Value $_.FileSystem
			Add-Member -InputObject $out -MemberType NoteProperty -Name "IsDirty" -Value ([bool] $_.VolumeDirty)
			Add-Member -InputObject $out -MemberType NoteProperty -Name "Compressed" -Value ([bool] $Compressed)
			Add-Member -InputObject $out -MemberType NoteProperty -Name "DriveType" -Value $dtype
			Add-Member -InputObject $out -MemberType NoteProperty -Name "BootDrive" -Value ([bool] $bootdrive)
			Add-Member -InputObject $out -MemberType NoteProperty -Name "PageFile" -Value ([bool] $pagefile)
			Add-Member -InputObject $out -MemberType NoteProperty -Name "SystemDrive" -Value ([bool] $systemdrive)
			Add-Member -InputObject $out -MemberType NoteProperty -Name "BlockSize" -Value ([int32] $BlockSize)
			$out.PSObject.TypeNames.Insert(0, 'brshSysInfo.DriveInfo')
			$out
		}
	}

	END { }

}

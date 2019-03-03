function Get-siIISBindingInfo {
	<#
	.SYNOPSIS
	Pulls IIS site and binding information

	.DESCRIPTION
	Sites can be bound to ip address, "host headers", and/or ports. It's nice to know what's what

	.EXAMPLE
	Get-siIISBindingInfo
	#>

	[CmdletBinding()]
	param ()
	Try {
		Import-Module WebAdministration -ErrorAction Stop -Verbose:$false
		$all = @()
		Try {
			Get-ChildItem iis:\sites -ErrorAction Stop | where-object { $_.State -eq "Started" } | ForEach-Object {
				$out = New-Object psobject
				Add-member -InputObject $out -MemberType NoteProperty -Name "Site" -Value "$($_.Name)"
				Add-Member -InputObject $out -MemberType NoteProperty -Name "Path" -Value "$($_.PhysicalPath.ToString().Replace('\Empty', ''))"
				[string[]] $bindings = @()
				$_.Bindings.Collection | where-object { ($_.Protocol -match "http") -or ($_.Protocol -match "ftp") } | foreach-object {
					$bindings += "$($_.Protocol)/$($_.BindingInformation.ToString().Trim(":"))"
				}
				Add-member -InputObject $out -MemberType NoteProperty -Name "Bindings" -Value $bindings
				$out.PSObject.TypeNames.Insert(0, 'brshSysInfo.IISInfo')
				$all += $out
			}
			$all
		} Catch {
			# No sites Found
		}
	} catch {
		Write-Verbose 'Could not import module: WebAdministration'
		Write-Verbose $_.Exception.Message
	}
}
